using GameServer.Persistence;

namespace GameServer.World;

/// <summary>Игровой профиль героя (то, что сервер хранит/считает; см. раздел 4 документации).</summary>
public sealed class PlayerProfile
{
    public int UserId;
    public string Username = "Player";
    public string ClanTag = "";
    public int ShipType = 16;          // стандартный корабль (M5A/M6A etc.)
    public int FactionId;
    public int MapId = 4;              // стартовая карта (X-1)

    public int X = 2000, Y = 2000;
    public int Rotation;
    public int Velocity = 460;

    public int Hp, MaxHp = 3000;
    public int Shield, MaxShield = 4500;

    public long Credits;
    public double Uridium;
    public double ExperiencePoints;
    public double HonorPoints;
    public double JackpotAmount;
    public int Level = 1;

    public int Cargo, MaxCargo = 100;
    public int LaserAmmo, MaxLaserCapacity = 500;
    public int RocketAmmo, MaxRocketCapacity = 250;

    public bool Premium;
    public int AdminLevel;

    /// <summary>Настройки клиента (домен "7") — key-value per user.</summary>
    public Dictionary<string, string> Settings = new();

    public PlayerProfile() { }

    public PlayerProfile(BazaStorage storage, int userId)
    {
        var d = storage.GetOrCreate(userId);
        UserId = userId;
        Username = BazaStorage.GetStr(d, "username", $"Player{userId}");
        ClanTag = BazaStorage.GetStr(d, "clanTag", "");
        ShipType = BazaStorage.GetInt(d, "shipType", ShipType);
        FactionId = BazaStorage.GetInt(d, "factionId", 0);
        MapId = BazaStorage.GetInt(d, "mapId", MapId);
        X = BazaStorage.GetInt(d, "x", X);
        Y = BazaStorage.GetInt(d, "y", Y);
        MaxHp = BazaStorage.GetInt(d, "maxHp", MaxHp);
        Hp = BazaStorage.GetInt(d, "hp", MaxHp);
        MaxShield = BazaStorage.GetInt(d, "maxShield", MaxShield);
        Shield = BazaStorage.GetInt(d, "shield", MaxShield);
        Credits = BazaStorage.GetLong(d, "credits", 100_000);
        Uridium = BazaStorage.GetDouble(d, "uridium", 0);
        ExperiencePoints = BazaStorage.GetDouble(d, "ep", 0);
        HonorPoints = BazaStorage.GetDouble(d, "hp_points", 0);
        JackpotAmount = BazaStorage.GetDouble(d, "jackpot", 0);
        Level = BazaStorage.GetInt(d, "level", 1);
        MaxCargo = BazaStorage.GetInt(d, "maxCargo", MaxCargo);
        Cargo = BazaStorage.GetInt(d, "cargo", 0);
        MaxLaserCapacity = BazaStorage.GetInt(d, "maxLaser", MaxLaserCapacity);
        LaserAmmo = BazaStorage.GetInt(d, "laserAmmo", MaxLaserCapacity);
        MaxRocketCapacity = BazaStorage.GetInt(d, "maxRocket", MaxRocketCapacity);
        RocketAmmo = BazaStorage.GetInt(d, "rocketAmmo", MaxRocketCapacity);
        Premium = BazaStorage.GetInt(d, "premium", 0) != 0;
        AdminLevel = BazaStorage.GetInt(d, "admin", 0);

        foreach (var k in d.Keys.Where(k => k.StartsWith("setting.", StringComparison.Ordinal)).ToList())
            Settings[k["setting.".Length..]] = d[k];
    }

    public Dictionary<string, string> ToDict()
    {
        var d = new Dictionary<string, string>
        {
            ["username"] = Username,
            ["clanTag"] = ClanTag,
            ["shipType"] = ShipType.ToString(),
            ["factionId"] = FactionId.ToString(),
            ["mapId"] = MapId.ToString(),
            ["x"] = X.ToString(),
            ["y"] = Y.ToString(),
            ["hp"] = Hp.ToString(),
            ["maxHp"] = MaxHp.ToString(),
            ["shield"] = Shield.ToString(),
            ["maxShield"] = MaxShield.ToString(),
            ["credits"] = Credits.ToString(),
            ["uridium"] = Uridium.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ["ep"] = ExperiencePoints.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ["hp_points"] = HonorPoints.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ["jackpot"] = JackpotAmount.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ["level"] = Level.ToString(),
            ["cargo"] = Cargo.ToString(),
            ["maxCargo"] = MaxCargo.ToString(),
            ["laserAmmo"] = LaserAmmo.ToString(),
            ["maxLaser"] = MaxLaserCapacity.ToString(),
            ["rocketAmmo"] = RocketAmmo.ToString(),
            ["maxRocket"] = MaxRocketCapacity.ToString(),
            ["premium"] = (Premium ? 1 : 0).ToString(),
            ["admin"] = AdminLevel.ToString(),
        };
        foreach (var (k, v) in Settings)
            d["setting." + k] = v;
        return d;
    }
}
