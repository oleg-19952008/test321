namespace GameServer.World;

/// <summary>Герой на карте (живое представление профиля в сессии).</summary>
public sealed class HeroInfo
{
    public int ShipId;             // игровой id корабля героя (назначает сервер)
    public int SessionId;          // id TCP-сессии владельца
    public PlayerProfile Profile = null!;
    public int TargetId = -1;      // текущая цель атаки
    public bool Alive = true;
}

/// <summary>Объект карты: руда, бонус-бокс, станция, портал, мина.</summary>
public enum MapObjectType { Ore, Box, Station, Portal, Mine }

public sealed class MapObject
{
    public int Id;
    public MapObjectType Type;
    public int X, Y;
    public int Amount;             // руда: количество; бокс: тип содержимого и т.п.
    public bool Collected;
}

/// <summary>Статическое описание карты (id, имя, размеры, координаты станций/порталов).</summary>
public sealed record MapInfo(
    int Id,
    string Name,
    int Width,
    int Height,
    MapObject[] Objects);

public static class Maps
{
    private static int _objId = 5000;

    /// <summary>Реестр карт (упрощённый — см. раздел 4.2 документации).</summary>
    public static readonly Dictionary<int, MapInfo> Registry = new()
    {
        [4] = Build(4, "X-1", 3800, 2600),
        [5] = Build(5, "X-2", 3800, 2600),
        [6] = Build(6, "X-3", 3800, 2600),
    };

    private static MapInfo Build(int id, string name, int w, int h)
    {
        var objs = new List<MapObject>
        {
            new() { Id = ++_objId, Type = MapObjectType.Station, X = 700,  Y = 700 },
            new() { Id = ++_objId, Type = MapObjectType.Portal,  X = 3200, Y = 2000 },
            new() { Id = ++_objId, Type = MapObjectType.Ore,     X = 1500, Y = 900,  Amount = 10 },
            new() { Id = ++_objId, Type = MapObjectType.Ore,     X = 2400, Y = 1600, Amount = 15 },
            new() { Id = ++_objId, Type = MapObjectType.Box,     X = 1900, Y = 1200, Amount = 1 },
        };
        return new MapInfo(id, name, w, h, objs.ToArray());
    }
}
