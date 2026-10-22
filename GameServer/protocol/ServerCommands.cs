namespace GameServer.Protocol;

/// <summary>
/// Константы исходящих команд (сервер -> клиент).
/// Источник: extracted/net_bigpoint_darkorbit_net_ServerCommands.as
/// </summary>
public static class ServerCommands
{
    // ==== Сессия / ошибки ====
    public const string Session = "S";                 // домен ошибок: S|ERR|code
    public const string Error = "ERR";
    public const string Kicked = "KIK";
    public const string Logout = "l";
    public const string ServerVersion = "VERSION";
    public const int ErrNoHitpoints = 1;
    public const int ErrNotLoggedIn = 2;
    public const int ErrDoubleLoggedIn = 3;
    public const int ErrInvalidSession = 4;

    public const string LogMessage = "LM";             // сообщение в игровой лог
    public const string ServerMsg = "STD";             // текстовое сообщение
    public const string LocalizedServerMsg = "STM";

    // ==== Инициализация героя и кораблей ====
    public const string HeroInit = "I";
    public const string CreateShip = "C";
    public const string ShipSelected = "N";
    public const string RemoveShip = "R";
    public const string DestroyShip = "K";
    public const string ShipMovement = "1";            // id,x,y,dir
    public const string HeroMovement = "T";            // x,y,rotation
    public const string Beacon = "D";
    public const string PortalAnimation = "U";
    public const string PortalJumpResponse = "i";
    public const string AvailableShipsOnMap = "SLE";
    public const string Tracking = "TR";
    public const string MapReadyHandshake = "HS";

    // ==== Бой ====
    public const string LaserAttack = "a";             // attackerId,targetId,dmg,hit?,shieldHit?
    public const string RocketAttack = "v";
    public const string PrepareAttackA = "PA";
    public const string PrepareAttackB = "PBA";
    public const string AttackStoppedA = "F";
    public const string AttackStoppedT = "J";
    public const string ShootMissedA = "M";
    public const string ShootMissedZ = "Z";
    public const string AttackInfoH = "H";
    public const string AttackInfoY = "Y";
    public const string OutOfRange = "O";
    public const string NoAmmunition = "W";
    public const string NoAttackZone = "P";
    public const string TargetInRange = "X";
    public const string AutoAmmoChange = "4";

    // ==== Атрибуты (SET_ATTRIBUTE, домен "A") ====
    public const string SetAttribute = "A";
    public const string ShieldInfo = "SHD";            // cur,max
    public const string HitpointsInfo = "HPT";         // cur,max
    public const string ExperiencePointsUpdate = "EP";
    public const string CreditsUpdate = "C";
    public const string LevelUpdate = "LUP";
    public const string VelocityUpdate = "v";
    public const string CargoChange = "c";
    public const string AmmunitionCapacityChange = "a";
    public const string UpdateConfigurationCount = "CC";
    public const string InitUpdateBoosters = "BS";
    public const string SetCooldown = "CLD";           // id,type,seconds
    public const string CooldownCompleted = "CLR";     // id,type
    public const string RepairSkillUpdate = "RS";
    public const string ShieldSkillUpdate = "SHS";
    public const string SetRepairData = "REP";
    public const string Heal = "HL";

    // ==== Карта и объекты ====
    public const string NewMap = "m";
    public const string CreateStation = "s";
    public const string CreatePortal = "p";
    public const string CreateOre = "r";
    public const string CreateBox = "c";
    public const string CreateMine = "L";
    public const string RemoveOre = "q";
    public const string RemoveBox = "2";
    public const string OreCollectedByHero = "e";
    public const string CargoFull = "f";
    public const string BoxDisabled = "h";
    public const string BoxCollectResponse = "y";
    public const string MapEvent = "n";

    // Содержимое бонус-боксов (подкоманды y)
    public const string BoxContentOre = "CAR";
    public const string BoxContentJackpot = "JPE";
    public const string BoxContentCredits = "CRE";
    public const string BoxContentUridium = "URI";
    public const string BoxContentExperiencePoints = "EP";
    public const string BoxContentHonorPoints = "HON";
    public const string BoxContentHitpoints = "HTP";

    // ==== Настройки клиента ====
    public const string ClientSetting = "7";

    // ==== Экономика ====
    public const string BuyResult = "5";               // b/r/o/f/F/S
    public const string OrePriceG = "g";
    public const string OreAmount = "E";
    public const string BoxTooBig = "BTB";
    public const string BoxAlreadyCollected = "BAH";

    // ==== Группы ====
    public const string GroupSystem = "ps";
    public const string GroupError = "err";
    public const string GroupErrorConnection = "conn";
}
