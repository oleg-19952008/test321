namespace GameServer.Protocol;

/// <summary>
/// Константы входящих команд (клиент -> сервер).
/// Источник: extracted/net_bigpoint_darkorbit_net_ClientCommands.as + ConnectionManager.as
/// </summary>
public static class ClientCommands
{
    // Служебные (не из ClientCommands.as, но шлются клиентом)
    public const string Login = "LOGIN";          // LOGIN|userID|sessionID|version[|factionID]
    public const string Ready = "RDY";            // RDY|MAP / SHP / WND / QSL / CHA / LOG
    public const string Ping = "PNG";             // keep-alive каждые ~25 сек

    public const string SelectShip = "SEL";       // выбрать корабль для наблюдения
    public const string Select = "S";             // выбор цели (target)
    public const string SelectLaser = "u";        // выбранная батарея (первичка)
    public const string SelectRocket = "d";       // выбранная ракета (вторичка)
    public const string SelectCloak = "CLK";      // плащ-невидимка
    public const string LaserStop = "G";          // стоп лазерная атака
    public const string CollectOre = "w";         // сбор руды (id объекта)
    public const string CollectBox = "x";         // сбор бонус-бокса (id объекта)
    public const string PortalJump = "j";         // прыжок через портал (id портала)
    public const string Teleport = "tele";        // телепорт (jump drive / X-jump)
    public const string Configuration = "CFG";    // смена конфигурации корабля
    public const string InstantRepair = "IR";     // мгновенный ремонт за URI
    public const string Robot = "ROB";            // использование робота/CPU
    public const string AutoRocket = "ARL";       // auto rocket launcher CPU
    public const string RocketLauncherCpu = "RLC"; // rocket launcher CPU
    public const string AimCpu = "AIM";           // aim-CPU
    public const string ForceInit = "i";          // принудительная ре-инициализация
    public const string GroupSystem = "ps";       // группы (с подкомандами)
    public const string RocketLauncher = "RL";    // ракетная установка (A/L/SEL)
    public const string Mine = "MIN";             // установка мин
    public const string TradeWindowMinimized = "TWC";
    public const string SpecialOffers = "SOA";
    public const string Request = "RQ";           // запрос данных (цены и т.п.)
    public const string ClientSetting = "7";      // сохранение настройки клиента key-value
    public const string Buy = "5";                // покупка (b — батареи, r — ракеты)
    public const string SellOre = "T";            // продажа руды
    public const string ExchangePalladium = "XCP";// обмен палладия
    public const string GetOrePrices = "b";       // запрос рыночных цен
    public const string ChangeMap = "z";          // переход на другую карту
    public const string Logout = "l";             // выход
    public const string LogoutCancel = "o";       // отмена выхода
    public const string Lab = "LAB";              // лаборатория (NC)
    public const string Techs = "TX";             // TECHS_ACTIVATE/DEACTIVATE (A/D)
    public const string SkillDesigns = "SD";      // SKILLS_ACTIVATE/DEACTIVATE (A/D)
    public const string Pet = "PET";              // управление дроном
    public const string Movement = "TR";          // TRACKING: id,x,y,... синхронизация позиции героя
    public const string LaserAttack = "a";        // raw-строки атак (client sendRawCommand)

    // Подкоманды GROUPSYSTEM
    public static class Group
    {
        public const string Ping = "png";
        public const string PingPosition = "pos";
        public const string PingUser = "usr";
        public const string Leave = "lv";
        public const string Kick = "kick";
        public const string Promote = "lc";
        public const string SetRemote = "s";
        public const string ChangeInvitationBehaviour = "i";
        public const string Follow = "flw";
        public const string BlockInvitations = "blk";
    }
}
