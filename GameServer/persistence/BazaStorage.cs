using System.Globalization;

namespace GameServer.Persistence;

/// <summary>
/// Хранилище игровых профилей в текстовом файле baza.txt (вместо БД).
/// Формат: блоки "PLAYER <userID>", далее строки "key=value", пустая строка — конец блока.
/// Настройки клиента хранятся как setting.&lt;ключ&gt;=&lt;значение&gt;.
/// Все операции сериализуются lock'ом и пишутся атомарно (во временный файл + replace).
/// </summary>
public sealed class BazaStorage
{
    private readonly string _path;
    private readonly object _sync = new();

    // userID -> (ключ -> значение)
    private readonly Dictionary<int, Dictionary<string, string>> _players = new();

    public BazaStorage(string path)
    {
        _path = path;
        Load();
    }

    public void Load()
    {
        lock (_sync)
        {
            _players.Clear();
            if (!File.Exists(_path)) return;

            int currentId = -1;
            Dictionary<string, string>? current = null;
            foreach (var raw in File.ReadLines(_path))
            {
                var line = raw.Trim();
                if (line.StartsWith("PLAYER ", StringComparison.Ordinal))
                {
                    Flush(current, currentId);
                    currentId = int.TryParse(line[7..].Trim(), out var id) ? id : -1;
                    current = _players.TryGetValue(currentId, out var existing)
                        ? existing : (_players[currentId] = new Dictionary<string, string>());
                    continue;
                }
                if (line.Length == 0 || line.StartsWith("#", StringComparison.Ordinal))
                {
                    Flush(current, currentId);
                    current = null;
                    currentId = -1;
                    continue;
                }
                if (current is null) continue;
                int eq = line.IndexOf('=');
                if (eq <= 0) continue;
                current[line[..eq]] = line[(eq + 1)..];
            }
            Flush(current, currentId);
        }
    }

    private void Flush(Dictionary<string, string>? data, int id)
    {
        if (data is not null && id >= 0 && data.Count > 0)
            _players[id] = data;
    }

    public Dictionary<string, string> GetOrCreate(int userId)
    {
        lock (_sync)
        {
            if (!_players.TryGetValue(userId, out var d))
                _players[userId] = d = new Dictionary<string, string>();
            return new Dictionary<string, string>(d); // копия наружу
        }
    }

    public bool Exists(int userId)
    {
        lock (_sync) return _players.ContainsKey(userId);
    }

    /// <summary>Сохраняет профиль (полностью заменяет данные по userID) и пишет baza.txt.</summary>
    public void Save(int userId, Dictionary<string, string> data)
    {
        lock (_sync)
        {
            _players[userId] = new Dictionary<string, string>(data);
            Write();
        }
    }

    public void Set(int userId, string key, string value)
    {
        lock (_sync)
        {
            if (!_players.TryGetValue(userId, out var d))
                _players[userId] = d = new Dictionary<string, string>();
            d[key] = value;
            Write();
        }
    }

    private void Write()
    {
        var tmp = _path + ".tmp";
        using (var w = new StreamWriter(tmp, false, System.Text.Encoding.UTF8))
        {
            w.WriteLine("# baza.txt — хранилище игровых профилей (замена БД). Не редактируйте на ходу работающего сервера.");
            foreach (var (id, data) in _players.OrderBy(p => p.Key))
            {
                w.WriteLine($"PLAYER {id.ToString(CultureInfo.InvariantCulture)}");
                foreach (var (k, v) in data)
                    w.WriteLine($"{k}={v}");
                w.WriteLine();
            }
        }
        if (File.Exists(_path))
            File.Replace(tmp, _path, null);
        else
            File.Move(tmp, _path);
    }

    // ---- типизированные геттеры ----
    public static int GetInt(Dictionary<string, string> d, string key, int def) =>
        d.TryGetValue(key, out var v) && int.TryParse(v, NumberStyles.Integer, CultureInfo.InvariantCulture, out var r) ? r : def;

    public static long GetLong(Dictionary<string, string> d, string key, long def) =>
        d.TryGetValue(key, out var v) && long.TryParse(v, NumberStyles.Integer, CultureInfo.InvariantCulture, out var r) ? r : def;

    public static double GetDouble(Dictionary<string, string> d, string key, double def) =>
        d.TryGetValue(key, out var v) && double.TryParse(v, NumberStyles.Float, CultureInfo.InvariantCulture, out var r) ? r : def;

    public static string GetStr(Dictionary<string, string> d, string key, string def) =>
        d.TryGetValue(key, out var v) ? v : def;
}
