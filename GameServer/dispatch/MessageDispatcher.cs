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
    private const string ClientVersion = "1.337"; // версия клиента, сверяется при LOGIN

    private readonly BazaStorage _storage;
    private readonly Func<IEnumerable<Session>> _allSessions;

    // Игровые id кораблей
    private static int _nextShipId = 10000;
    // userID -> активная сессия (для DOUBLE_LOGGED_IN)
    private readonly ConcurrentDictionary<int, Session> _online = new();

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
            case ClientCommands.Ping:        session.SendMessage(ServerCommands.Session, "PNC"); break; // echo keep-alive
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
        if (p.Length < 4 ||
            !int.TryParse(p[1], out int userId) ||
            !int.TryParse(p[3], out _))
        {
            SendError(session, ServerCommands.ErrInvalidSession);
            session.Client.Close();
            return;
        }
        string sessionId = p[2];
        string version = p[3];

        // Проверка версии клиента
        if (version != ClientVersion)
        {
            session.SendMessage(ServerCommands.Session, ServerCommands.ServerVersion, ClientVersion);
            SendError(session, ServerCommands.ErrInvalidSession);
            session.Client.Close();
            return;
        }

        // Проверка sessionID: здесь — простая схема "sess<userID>", в реальном сервере сверяется с login-сервером.
        if (sessionId != $"sess{userId}")
        {
            Console.WriteLine($"[login] #{session.Id} user={userId}: неверный sessionID '{sessionId}' → ERR|4");
            SendError(session, ServerCommands.ErrInvalidSession);
            session.Client.Close();
            return;
        }

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
        session.SendMessage(ServerCommands.LogMessage, $"Добро пожаловать на сервер, {profile.Username}!");
    }

    // ---------------- RDY|MAP → выдача мира ----------------
    private void HandleReady(Session session, string[] p)
    {
        if (!session.LoggedIn || session.Profile is null)
        {
            SendError(session, ServerCommands.ErrNotLoggedIn);
            return;
        }
        if (p.Length < 3 || p[2] != "MAP") return; // нас интересует готовность спейсмэпа

        session.MapReady = true;
        var profile = session.Profile;
        var map = Maps.Registry.TryGetValue(profile.MapId, out var m) ? m : Maps.Registry[4];

        // 1) HERO_INIT ("I") — порядок параметров по ConnectionManager.as case HERO_INIT ([2]..[31])
        int shipId = Interlocked.Increment(ref _nextShipId);
        session.Hero = new HeroInfo { ShipId = shipId, SessionId = session.Id, Profile = profile };

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
            0,                            // [19] ??? (lastHitAgo)
            profile.Premium ? 1 : 0,      // [20] premium
            profile.ExperiencePoints,     // [21] EP
            profile.HonorPoints,          // [22] HP (честь)
            profile.Level,                // [23] level
            profile.Credits,              // [24] credits
            profile.Uridium,              // [25] uridium
            profile.JackpotAmount,        // [26] jackpot
            profile.AdminLevel,           // [27] admin level (21 = admin)
            profile.ClanTag,              // [28] clan tag
            0                             // [29..] прочие
        );

        // 2) Карта и объекты
        session.SendMessage(ServerCommands.NewMap, map.Id, map.Name, map.Width, map.Height);
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

        // 3) Атрибуты стартового состояния
        SendAttributes(session);
        Console.WriteLine($"[world] #{session.Id}: выдан мир карты {map.Id}, heroShipId={shipId}");
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
        session.SendMessage(ServerCommands.MapReadyHandshake, mapId);
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
    private void SendAttributes(Session session)
    {
        if (session.Profile is not { } pr) return;
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.HitpointsInfo, pr.Hp, pr.MaxHp);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.ShieldInfo, pr.Shield, pr.MaxShield);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.CreditsUpdate, pr.Credits);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.CargoChange, pr.Cargo, pr.MaxCargo);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.ExperiencePointsUpdate, pr.ExperiencePoints);
        session.SendMessage(ServerCommands.SetAttribute, ServerCommands.AmmunitionCapacityChange, pr.LaserAmmo, pr.MaxLaserCapacity);
    }

    private void SendError(Session session, int code) =>
        session.SendMessage(ServerCommands.Session, ServerCommands.Error, code);

    private void BroadcastExcept(Session source, string command, params object[] parts)
    {
        foreach (var s in _allSessions())
            if (s != source && s.MapReady)
                s.SendMessage(command, parts);
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
