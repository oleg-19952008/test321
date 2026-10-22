using System.Collections.Concurrent;
using GameServer.Net;
using GameServer.Persistence;
using GameServer.Protocol;
using GameServer.World;

namespace GameServer.Dispatch;

/// <summary>
/// Центральный диспетчер входящих сообщений (аналог ConnectionManager.onData):
/// split по '|', маршрутизация по элементу [1]. Обслуживает MVP из раздела 5.1 документации:
/// LOGIN → RDY|MAP → HERO_INIT → мир → движение/атака/руды/боксы/атрибуты/настройки/смена карт.
/// </summary>
public class MessageDispatcher
{
    private const string ClientVersion = "4.1"; // ожидаемая версия клиента (сверяется нестрого)
    // Формат версии клиента: MAJOR.MINOR[.PATCH] — например 4.1, 1.337, 12.0.5
    private static readonly System.Text.RegularExpressions.Regex VersionPattern =
        new(@"^\d+(\.\d+){1,3}$", System.Text.RegularExpressions.RegexOptions.Compiled);

    private readonly BazaStorage _storage;
    private readonly Func<IEnumerable<Session>> _allSessions;

    // Игровые id кораблей
    private static int _nextShipId = 10000;
    // userID -> активная сессия (для DOUBLE_LOGGED_IN)
    private readonly ConcurrentDictionary<int, Session> _online = new();
    // известные sessionID -> userID (реестр сессий: неизвестный sessionID принимается как новый, повторный — проходит)
    private readonly ConcurrentDictionary<string, int> _knownSessions = new();

    protected MessageDispatcher()
    {
        _storage = null!;
        _allSessions = Array.Empty<Session>;
    }

    public MessageDispatcher(BazaStorage storage, Func<IEnumerable<Session>> allSessions)
    {
        _storage = storage;
        _allSessions = allSessions;
    }

    /// <summary>Разбор строки и маршрутизация.</summary>
    public virtual void Handle(Session session, string line)
    {
        var p = MessageBuilder.Parse(line);
        if (p.Length < 2) return;

        // LOGIN не имеет префикса сессии: "LOGIN|userID|sessionID|version[|factionID]"
        if (p[0] == ClientCommands.Login)
        {
            HandleLogin(session, p);
            return;
        }

        // обычный формат: [0]=sid (клиент шлёт 0/игнорируется), [1]=команда
        string cmd = p[1];
        switch (cmd)
        {
            case ClientCommands.Ready:       HandleReady(session, p); break;
            case ClientCommands.Ping:        HandlePing(session, p); break; // keep-alive (см. ConnectionManager.as)
            case ClientCommands.Movement:    HandleMovement(session, p); break;
            case ClientCommands.Select:      HandleSelect(session, p); break;
            case ClientCommands.SelectLaser: HandleSelectLaser(session, p); break;
            case ClientCommands.LaserStop:   HandleLaserStop(session, p); break;
            case ClientCommands.LaserAttack: HandleLaserAttack(session, p); break;
            case ClientCommands.CollectOre:  HandleCollectOre(session, p); break;
            case ClientCommands.CollectBox:  HandleCollectBox(session, p); break;
            case ClientCommands.ChangeMap:   HandleChangeMap(session, p); break;
            case ClientCommands.ClientSetting: HandleClientSetting(session, p); break;
            case ClientCommands.SellOre:     HandleSellOre(session, p); break;
            case ClientCommands.Logout:      HandleLogout(session, p); break;
            default:
                Console.WriteLine($"[dispatch] #{session.Id}: необработанная команда \"{cmd}\" ({line.Trim()})");
                break;
        }
    }

    // ---------------- LOGIN ----------------
    private void HandleLogin(Session session, string[] p)
    {
        // p = [LOGIN, userID, sessionID, version, factionID?]
        // Версия — строка вида "4.1"/"1.337", поэтому проверяем формат, а не int.
        if (p.Length < 4 ||
            !int.TryParse(p[1], out int userId) ||
            !VersionPattern.IsMatch(p[3]))
        {
            Console.WriteLine($"[login] #{session.Id}: некорректный пакет LOGIN ({string.Join("|", p)}) → ERR|4");
            SendError(session, ServerCommands.ErrInvalidSession);
            session.Client.Close();
            return;
        }
        string sessionId = p[2];
        string version = p[3];
        session.ClientVersion = version; // A|VERSION эхо-ит версию, присланную клиентом (не захардкоженную 1337)

        // Проверка версии клиента: несовпадение НЕ блокирует вход (dev-режим), только предупреждение.
        if (version != ClientVersion)
        {
            Console.WriteLine($"[login] #{session.Id}: версия клиента '{version}' ≠ ожидаемой '{ClientVersion}' — вход разрешён (dev-режим).");
        }

        // Проверка sessionID. В реальном сервере sessionID выдаёт login-сервер и игра сверяет его при LOGIN.
        // Здесь база локальная (baza.txt): неизвестный sessionID принимаем как новую сессию и регистрируем,
        // повторный вход с тем же sessionID проходит нормально. Блокируем только пустой sessionID.
        if (string.IsNullOrEmpty(sessionId))
        {
            Console.WriteLine($"[login] #{session.Id} user={userId}: пустой sessionID → ERR|4");
            SendError(session, ServerCommands.ErrInvalidSession);
            session.Client.Close();
            return;
        }
        _knownSessions.TryAdd(sessionId, userId);

        // Одна активная сессия на пользователя
        if (_online.TryGetValue(userId, out var old) && old != session)
        {
            SendError(old, ServerCommands.ErrDoubleLoggedIn);
            _ = old.DisposeAsync();
        }
        _online[userId] = session;

        var profile = new PlayerProfile(_storage, userId)
        {
            FactionId = p.Length > 4 && int.TryParse(p[4], out int f) ? f : 0,
        };
        if (profile.Hp <= 0) { profile.Hp = profile.MaxHp; profile.Shield = profile.MaxShield; }

        session.Profile = profile;
        session.SessionId = sessionId;
        session.LoggedIn = true;

        Console.WriteLine($"[login] #{session.Id}: пользователь {userId} ({profile.Username}) зашёл, карта {profile.MapId}");

        // Полная последовательность инициализации сразу после LOGIN.
        // Клиент (ConnectionManager.as) не шлёт RDY|MAP до загрузки спейсмэпа, а спейсмэп не грузится
        // без HERO_INIT ("I") + данных карты ("m") + чанка настроек ("A|SET"). Если ждать RDY|MAP —
        // клиент зависает на загрузке (символьный экран) и присылает только PNG keep-alive.
        SendLoginInit(session, profile);
    }

    /// <summary>
    /// Инициализационный burst после LOGIN: LM → VERSION → I (герой) → m/SMP (карта+объекты) →
    /// A|BS (бустеры) → A|SET (24 значения настроек) → HS (handshake готовности) → атрибуты →
    /// A|v (скорость) → B (батареи) → 3 (ракеты/спец-амуниция).
    /// Порядок важен: клиент (ConnectionManager.as / SetAttributeAssembly.as) создаёт героя в case
    /// HERO_INIT, а UI (top menu / settings window) — только в assembleSettingsChunk (A|SET).
    /// Пакеты B/3 обязательны: без них Hero.laserBatteryAmounts/rocketAmounts пусты — меню атаки
    /// и кнопки боезапаса не активируются; стандартные серверы шлют их сразу после атрибутов
    /// (см. карту пакетов SendUserShit()/UpdateShip_(): A|v, B|..., 3|...).
    /// </summary>
    private void SendLoginInit(Session session, PlayerProfile profile)
    {
        session.SendMessage(ServerCommands.LogMessage, $"Добро пожаловать на сервер, {profile.Username}!");
        // Версия игры: часть сборок клиента показывает "некорректную версию" и не переходит к загрузке
        // мира без VERSION. Формат: sid|A|VERSION|<номер> (SetAttributeAssembly.assembleServerVersion).
        // Значение = версия, присланная клиентом в LOGIN (эхо), а не захардкоженный номер сборки:
        // сверка идёт по строке версии клиента, поэтому несоответствие (например, 1337 vs "4.1")
        // блокирует переход из LOADING в космос.
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.ServerVersion, session.ClientVersion);
        SendHeroInit(session, profile);
        SendMap(session, profile);
        // A|BS|<boosters через "/"> — пустой список бустеров (assembleInitBoostersUpdate читает param1[3]).
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.InitUpdateBoosters, "");
        SendFlashSettings(session, profile);
        // HS (MAP_READY_HANDSHAKE): клиент обновляет окно карт; сам по себе он не обязателен для загрузки,
        // но стандартные приватные серверы шлют его сразу после SET.
        session.SendMessage(ServerCommands.MapReadyHandshake, profile.MapId);
        SendAttributes(session);
        // Скорость героя: A|v|<speed> (SetAttributeAssembly.assembleVelocityUpdate читает param1[3]).
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.VelocityUpdate, profile.Velocity);
        SendWeaponInfo(session, profile);
        Console.WriteLine($"[init] #{session.Id}: выдан init-набор (I, m, A|BS, A|SET, HS, атрибуты, A|v, B, 3) — карта {profile.MapId}, shipType={profile.ShipType}");
    }

    /// <summary>
    /// Боезапас по слотам (по case PRIMARY_WEAPON_INFO / SECONDARY_WEAPON_INFO в ConnectionManager.as):
    ///   B|bat0..bat11            — 12 батарей ([2]..[13] → laserBatteryAmounts[0..11]); у выбранной
    ///                              батареи (LaserAmmo) количество = текущий боекомплект, остальные 0.
    ///   3|r0..r6|m0..m6          — [2]..[8] ракеты R310/PLT2026/PLT2021/PLT3030/PLD8/DCR250/WIZ,
    ///                              [9]..[15] спец-амуниция MINE/SMARTBOMB/INSTASHIELD/EMP/MINE_EMP/MINE_SAB/MINE_DDM.
    /// В reference-карте это пакеты №2 (B), №6 (3) из UpdateShip_/SendUserShit().
    /// </summary>
    private void SendWeaponInfo(Session session, PlayerProfile profile)
    {
        var bats = new object[12];
        for (int i = 0; i < 12; i++)
            bats[i] = (i + 1 == profile.LaserAmmo) ? profile.MaxLaserCapacity : 0;
        session.SendMessage(ServerCommands.PrimaryWeaponInfo, bats);

        // Ракеты: активный слот R310 ([2]) получает RocketAmmo, если выбрана ракета (RocketAmmo>0);
        // иначе весь ракетный боезапас нулевой (выбрана только батарея). Спец-амуниция обнулена (MVP).
        int r310 = profile.RocketAmmo > 0 ? profile.RocketAmmo : 0;
        session.SendMessage(ServerCommands.SecondaryWeaponInfo,
            r310, 0, 0, 0, 0, 0, 0,                   // [2]..[8]  R310..WIZ
            0, 0, 0, 0, 0, 0, 0);                    // [9]..[15] MINES/SMB/ISH/EMP/EMPM01/SABM01/DDM01
    }

    /// <summary>
    /// HERO_INIT ("I") — порядок параметров по ConnectionManager.as case HERO_INIT ([2]..[31]).
    /// ВАЖНО: клиент читает строго индексы [2]..[31], включая [31] (isKilledByAttack). Меньше 32 полей —
    /// ArrayIndexOutOfBounds внутри switch и герой не создаётся.
    /// </summary>
    private void SendHeroInit(Session session, PlayerProfile profile)
    {
        var map = Maps.Registry.TryGetValue(profile.MapId, out var m) ? m : Maps.Registry[4];

        // Валидация типа корабля: клиент рисует только известные shell-типы (1,5,7,9,10,11,13,14,16,
        // 18,19,20,23,24,26,27,28,29,30,32,33,34,35,37,38,40,41,42,44,49,50,51,52,55,56,57,58,59,60,
        // 61,62,63,64,65,66,67,68,69,70,71,74,75,77,79,80,81,82,83,84). getMappedShipType() конвертирует
        // только маппинг [171→71, 173→73, ...], остальные значения проходят как есть. Неизвестный id →
        // ShipPattern не найден → createShip возвращает null → HERO_INIT молча прерывается ("return"),
        // герой НЕ появляется на карте. Поэтому при недопустившемся значении — откат к Ghost(1).
        if (!IsValidShipType(profile.ShipType))
        {
            Console.WriteLine($"[init] #{session.Id}: shipType={profile.ShipType} не является допустимым для клиента — откат к 1 (Ghost). " +
                              "Исправьте поле shipType в базе или выдайте корабль через A|C|CREATE_SHIP.");
            profile.ShipType = 1;
        }

        int shipId;
        if (session.Hero is { } existing)
        {
            shipId = existing.ShipId; // при повторном RDY|MAP не меняем id героя
        }
        else
        {
            shipId = Interlocked.Increment(ref _nextShipId);
            session.Hero = new HeroInfo { ShipId = shipId, SessionId = session.Id, Profile = profile };
        }

        session.SendMessage(ServerCommands.HeroInit,
            shipId,                       // [2] shipId
            profile.Username,             // [3] name
            profile.ShipType,             // [4] ship type
            profile.Velocity,             // [5] speed (клиент умножит на 0.97)
            profile.Shield,               // [6] shield current
            profile.MaxShield,            // [7] shield max
            profile.Hp,                   // [8] hitpoints
            profile.MaxHp,                // [9] max hitpoints
            profile.Cargo,                // [10] cargo used
            profile.MaxCargo,             // [11] cargo max
            profile.X,                    // [12] x
            profile.Y,                    // [13] y
            map.Id,                       // [14] map id
            profile.FactionId,            // [15] faction
            profile.Rotation,             // [16] rotation
            profile.MaxLaserCapacity,     // [17] maxLaserCapacity
            profile.MaxRocketCapacity,    // [18] maxRocketCapacity
            0,                            // [19] lastHitAgo
            profile.Premium ? 1 : 0,      // [20] premium
            profile.ExperiencePoints,     // [21] EP
            profile.HonorPoints,          // [22] HP (честь)
            profile.Level,                // [23] level
            profile.Credits,              // [24] credits
            profile.Uridium,              // [25] uridium
            profile.JackpotAmount,        // [26] jackpot
            profile.AdminLevel,           // [27] admin level (21 = admin)
            profile.ClanTag,              // [28] clan tag
            0,                            // [29] ??? (clan id / group)
            0,                            // [30] ??? (обязательный заполнитель — сдвигает [31])
            0                             // [31] isKilledByAttack (жив — 0)
        );
    }

    /// <summary>Карта "m" + PVP-статус "SMP" + статические объекты.</summary>
    private void SendMap(Session session, PlayerProfile profile)
    {
        var map = Maps.Registry.TryGetValue(profile.MapId, out var m) ? m : Maps.Registry[4];

        session.SendMessage(ServerCommands.NewMap, map.Id, map.Name, map.Width, map.Height);
        session.SendMessage(ServerCommands.MapPvpStatus, 0, profile.FactionId);
        foreach (var o in map.Objects)
        {
            switch (o.Type)
            {
                case MapObjectType.Station:
                    session.SendMessage(ServerCommands.CreateStation, o.Id, o.X, o.Y, "KraKEN_Shop", 0);
                    break;
                case MapObjectType.Portal:
                    session.SendMessage(ServerCommands.CreatePortal, o.Id, o.X, o.Y, "11", 0);
                    break;
                case MapObjectType.Ore:
                    session.SendMessage(ServerCommands.CreateOre, o.Id, o.X, o.Y, o.Amount);
                    break;
                case MapObjectType.Box:
                    session.SendMessage(ServerCommands.CreateBox, o.Id, o.X, o.Y, o.Amount);
                    break;
            }
        }
    }

    /// <summary>
    /// Чанк flash-настроек "A|SET|v0..v23" (SetAttributeAssembly → SettingsAssembly.assembleSettingsChunk).
    /// Клиент вызывает createTopMenu()/createSettingsWindow() только получ этот пакет — без него UI
    /// не инициализируется и RDY|MAP никогда не отправляется. Индексы (после splice(3)):
    /// 0 autoBoost, 4 displayPlayerNames, 7 displayResources, 8 displayBonusBoxes,
    /// 11 playSFX, 12 playMusic, 14 displayHitpointBubbles, 15 selectedLaser, 16 selectedRocket,
    /// 18 displayChat, 21 displayFreeCargoBoxes, 22 displayNotFreeCargoBoxes, 23 autochangeAmmo.
    /// </summary>
    private void SendFlashSettings(Session session, PlayerProfile profile)
    {
        bool Get(string key, bool def) =>
            profile.Settings.TryGetValue(key, out var v) && int.TryParse(v, out int i) ? i != 0 : def;

        int[] s = new int[24];
        s[0]  = Get("AUTO_BOOST", true) ? 1 : 0;              // autoBoost
        s[4]  = Get("DISPLAY_PLAYER_NAMES", true) ? 1 : 0;    // displayPlayerNames
        s[7]  = Get("DISPLAY_ORE", true) ? 1 : 0;             // displayResources
        s[8]  = Get("DISPLAY_BONUS_BOXES", true) ? 1 : 0;     // displayBonusBoxes
        s[11] = Get("PLAY_SFX", true) ? 1 : 0;                // playSFX
        s[12] = Get("PLAY_MUSIC", true) ? 1 : 0;              // playMusic
        s[14] = Get("DISPLAY_HITPOINT_BUBBLES", true) ? 1 : 0;// displayHitpointBubbles
        s[15] = profile.LaserAmmo > 0 ? 1 : 0;                // selectedLaser (базовая батарея)
        s[16] = 0;                                            // selectedRocket
        s[18] = Get("DISPLAY_CHAT", true) ? 1 : 0;            // displayChat
        s[21] = Get("DISPLAY_FREE_CARGO_BOXES", true) ? 1 : 0;
        s[22] = Get("DISPLAY_NOT_FREE_CARGO_BOXES", true) ? 1 : 0;
        s[23] = Get("AUTO_AMMO_CHANGE", true) ? 1 : 0;

        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.FlashSettings, s);
    }

    // ---------------- PNG (keep-alive) ----------------
    // По декомпилированному ConnectionManager.as клиент НЕ ожидает ответа на PNG:
    // в giant-switch метода onData нет case ServerCommands.PING ("PNG"), строка
    // уходит в default и молча игнорируется. Сервер просто отмечает активность.
    // Эхо "S|PNC" (домен ошибок + неизвестный код) не отправляется никогда —
    // оно сбивало разбор пакетов у части сборок клиента.
    // Флаг SendPong оставлен только для совместимости с консольной командой `pong [on|off]`;
    // эхо по-прежнему не шлётся (отключено навсегда).
    public static bool SendPong { get; set; }

    private void HandlePing(Session session, string[] p)
    {
        // keep-alive: ничего не отвечаем (см. комментарий выше).
    }

    // ---------------- RDY|MAP → подтверждение готовности клиента ----------------
    private void HandleReady(Session session, string[] p)
    {
        if (!session.LoggedIn || session.Profile is null)
        {
            SendError(session, ServerCommands.ErrNotLoggedIn);
            return;
        }
        if (p.Length < 3 || p[2] != "MAP") return; // нас интересует готовность спейсмэпа

        var profile = session.Profile;

        // Страховка: если по какой-то причине клиент прислал RDY|MAP без героя (например, потерянный
        // init-набор после LOGIN) — выдаём мир заново. В норме Hero уже создан на LOGIN.
        if (session.Hero is null)
        {
            SendHeroInit(session, profile);
            SendMap(session, profile);
            SendFlashSettings(session, profile);
            SendAttributes(session);
            session.SendMessage(ServerCommands.SetAttribute, ServerCommands.VelocityUpdate, profile.Velocity);
            SendWeaponInfo(session, profile);
        }

        session.MapReady = true;
        Console.WriteLine($"[world] #{session.Id}: клиент подтвердил готовность карты {profile.MapId} (RDY|MAP), heroShipId={session.Hero?.ShipId}");
    }

    // ---------------- Движение ----------------
    private void HandleMovement(Session session, string[] p)
    {
        // TR|id|x|y|... или raw T-подобное — сохраняем позицию и рассылаем остальным как SHIP_MOVEMENT
        if (session.Hero is not { } hero || p.Length < 5) return;
        if (!int.TryParse(p[3], out int x) || !int.TryParse(p[4], out int y)) return;
        hero.Profile.X = x;
        hero.Profile.Y = y;
        BroadcastExcept(session, ServerCommands.ShipMovement, hero.ShipId, x, y, hero.Profile.Rotation);
    }

    // ---------------- Цель / атака ----------------
    private void HandleSelect(Session session, string[] p)
    {
        if (session.Hero is not { } hero) return;
        if (p.Length >= 3 && int.TryParse(p[2], out int targetId))
        {
            hero.TargetId = targetId;
            session.SendMessage(ServerCommands.ShipSelected, targetId);
        }
    }

    private void HandleSelectLaser(Session session, string[] p)
    {
        // u|batteryId — запоминаем выбранную батарею (MVP: просто подтверждаем боезапас)
        if (session.Hero is { } hero)
            session.SendMessage(ServerCommands.SetAttribute, ServerCommands.AmmunitionCapacityChange,
                hero.Profile.LaserAmmo, hero.Profile.MaxLaserCapacity);
    }

    private void HandleLaserStop(Session session, string[] p)
    {
        if (session.Hero is { } hero) hero.TargetId = -1;
        session.SendMessage(ServerCommands.AttackStoppedA);
    }

    private void HandleLaserAttack(Session session, string[] p)
    {
        // a|attackerId|targetId|... — сервер считает урон (раздел 4.5 документации, упрощённо)
        if (session.Hero is not { } hero || p.Length < 4) return;
        if (!int.TryParse(p[3], out int targetId)) return;

        int damage = 40 + Random.Shared.Next(0, 20);
        // MVP: цель — сам герой (учебный огонь по себе) либо заглушка NPC
        bool hit = Random.Shared.NextDouble() > 0.1;
        session.SendMessage(ServerCommands.LaserAttack, hero.ShipId, targetId, hit ? damage : 0, hit ? 1 : 0, 0);

        if (hit && targetId == hero.ShipId)
        {
            ApplyDamage(hero.Profile, damage);
            SendAttributes(session);
            if (hero.Profile.Hp <= 0)
            {
                session.SendMessage(ServerCommands.DestroyShip, hero.ShipId, 0, "self");
                hero.Alive = false;
                SaveProfile(session);
            }
        }
    }

    private void ApplyDamage(PlayerProfile pr, int damage)
    {
        if (pr.Shield > 0)
        {
            int shieldDmg = Math.Min(pr.Shield, damage);
            pr.Shield -= shieldDmg;
            damage -= shieldDmg;
        }
        pr.Hp = Math.Max(0, pr.Hp - damage);
    }

    // ---------------- Руда / боксы ----------------
    private void HandleCollectOre(Session session, string[] p)
    {
        // w|oreId
        if (session.Hero is not { } hero || p.Length < 3 || !int.TryParse(p[2], out int oreId)) return;
        int amount = 10;
        if (hero.Profile.Cargo + amount > hero.Profile.MaxCargo)
        {
            session.SendMessage(ServerCommands.CargoFull);
            return;
        }
        hero.Profile.Cargo += amount;
        hero.Profile.Credits += amount * 500;
        session.SendMessage(ServerCommands.OreCollectedByHero, oreId, amount);
        session.SendMessage(ServerCommands.RemoveOre, oreId);
        SendAttributes(session);
        SaveProfile(session);
    }

    private void HandleCollectBox(Session session, string[] p)
    {
        // x|boxId
        if (p.Length < 3 || !int.TryParse(p[2], out int boxId)) return;
        int credits = 1000 + Random.Shared.Next(0, 4000);
        if (session.Hero is { } hero)
        {
            hero.Profile.Credits += credits;
            hero.Profile.ExperiencePoints += 100;
        }
        session.SendMessage(ServerCommands.BoxCollectResponse, ServerCommands.BoxContentCredits, credits);
        session.SendMessage(ServerCommands.RemoveBox, boxId);
        SendAttributes(session);
        SaveProfile(session);
    }

    // ---------------- Экономика ----------------
    private void HandleSellOre(Session session, string[] p)
    {
        if (session.Hero is not { } hero) return;
        long sum = (long)hero.Profile.Cargo * 500;
        hero.Profile.Credits += sum;
        hero.Profile.Cargo = 0;
        session.SendMessage(ServerCommands.BuyResult, "S", sum);
        SendAttributes(session);
        SaveProfile(session);
    }

    // ---------------- Смена карты ----------------
    private void HandleChangeMap(Session session, string[] p)
    {
        // z|mapId
        if (session.Profile is not { } profile || p.Length < 3 || !int.TryParse(p[2], out int mapId)) return;
        if (!Maps.Registry.ContainsKey(mapId))
        {
            session.SendMessage(ServerCommands.LogMessage, "Карта недоступна.");
            return;
        }
        profile.MapId = mapId;
        profile.X = 2000; profile.Y = 2000;
        SaveProfile(session);
        session.MapReady = false;              // клиент снова пришлёт RDY|MAP после загрузки
        // Полный init-набор на новой карте (тот же состав, что при входе: I, m, объекты, HS,
        // атрибуты, скорость, боезапас B/3) — иначе меню атаки не проинициализировано.
        SendHeroInit(session, profile);
        SendMap(session, profile);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.InitUpdateBoosters, "");
        SendFlashSettings(session, profile);
        session.SendMessage(ServerCommands.MapReadyHandshake, mapId);
        SendAttributes(session);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.VelocityUpdate, profile.Velocity);
        SendWeaponInfo(session, profile);
        Console.WriteLine($"[map] #{session.Id}: переход на карту {mapId}");
    }

    // ---------------- Настройки клиента ----------------
    private void HandleClientSetting(Session session, string[] p)
    {
        // 7|<ключ>|<значение...> — эхо-подтверждение + сохранение per-user (раздел 4.10)
        if (session.Profile is not { } profile || p.Length < 3) return;
        string key = p[2];
        string value = p.Length > 3 ? string.Join(MessageBuilder.CommandSeparator.ToString(), p[3..]) : "";
        profile.Settings[key] = value;
        session.SendMessage(ServerCommands.ClientSetting, key, value);
        SaveProfile(session);
    }

    // ---------------- Logout ----------------
    private void HandleLogout(Session session, string[] p)
    {
        SaveProfile(session);
        session.SendMessage(ServerCommands.Session, ServerCommands.Logout);
        session.Client.Dispose();
    }

    // ---------------- Утилиты ----------------
    /// <summary>Допустимые для клиента id корпусов кораблей (см. ShipPatterns; совпадает с реальными приватниками).</summary>
    private static readonly HashSet<int> ValidShipTypes = new()
    {
        1, 5, 7, 9, 10, 11, 13, 14, 16, 18, 19, 20, 23, 24, 26, 27, 28, 29, 30, 32, 33, 34, 35,
        37, 38, 40, 41, 42, 44, 49, 50, 51, 52, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66,
        67, 68, 69, 70, 71, 74, 75, 77, 79, 80, 81, 82, 83, 84,
        // shell-варианты, которые getMappedShipType() конвертирует в базовые:
        171, 173, 175, 176, 177, 178, 179, 181, 183,
    };

    private static bool IsValidShipType(int t) => ValidShipTypes.Contains(t);

    private void SendAttributes(Session session)
    {
        if (session.Profile is not { } pr) return;
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.HitpointsInfo, pr.Hp, pr.MaxHp);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.ShieldInfo, pr.Shield, pr.MaxShield);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.CreditsUpdate, pr.Credits);
        // A|c|maxCargo — assembleCargoChange читает ТОЛЬКО param1[3] (лишние поля игнорируются, но
        // формат одного значения каноничен).
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.CargoChange, pr.MaxCargo);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.ExperiencePointsUpdate, pr.ExperiencePoints);
        // A|a|maxLaser|maxRocket — ammunition capacity (пары [3]/[4] поassembleAmmunitionChange).
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.AmmunitionCapacityChange, pr.MaxLaserCapacity, pr.MaxRocketCapacity);
    }

    private void SendError(Session session, int code) =>
        session.SendMessage(ServerCommands.Session, ServerCommands.Error, code);

    private void BroadcastExcept(Session source, string command, params object[] parts)
    {
        var message = Protocol.MessageBuilder.Build(source.Id, command, parts);
        var targets = new List<Session>();
        foreach (var s in _allSessions())
            if (s != source && s.MapReady)
                targets.Add(s);

        Net.PacketLog.Broadcast(source, targets, message);
        foreach (var s in targets)
            s.Send(message);
    }

    public void SaveProfile(Session session)
    {
        if (session.Profile is { } pr)
            _storage.Save(pr.UserId, pr.ToDict());
    }

    public void OnSessionClosed(Session session)
    {
        if (session.Profile is { } pr)
        {
            _storage.Save(pr.UserId, pr.ToDict());
            _online.TryRemove(pr.UserId, out _);
            Console.WriteLine($"[save] профиль {pr.UserId} сохранён в baza.txt");
        }
    }

    /// <summary>Тик регенерации щита/hp для всех живых героев (раздел 4.4: tick-цикл).</summary>
    public void TickRegen(IEnumerable<Session> sessions)
    {
        foreach (var s in sessions)
        {
            if (s.Profile is not { } pr || !s.MapReady || s.Hero is not { Alive: true }) continue;
            bool changed = false;
            if (pr.Shield < pr.MaxShield) { pr.Shield = Math.Min(pr.MaxShield, pr.Shield + 50); changed = true; }
            else if (pr.Hp < pr.MaxHp)    { pr.Hp = Math.Min(pr.MaxHp, pr.Hp + 10); changed = true; }
            if (changed)
            {
                s.SendMessage(ServerCommands.SetAttribute, ServerCommands.ShieldInfo, pr.Shield, pr.MaxShield);
                s.SendMessage(ServerCommands.SetAttribute, ServerCommands.HitpointsInfo, pr.Hp, pr.MaxHp);
            }
        }
    }
}
