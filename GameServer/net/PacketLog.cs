namespace GameServer.Net;

/// <summary>
/// Глобальный переключатель/логгер отображения входящих и исходящих пакетов в консоли.
/// Включение: команда "packets" (или "packets on") в консоли сервера, либо запуск с аргументом "--packets".
/// </summary>
public static class PacketLog
{
    private static readonly object _lock = new();

    /// <summary>true — показывать пакеты в консоли.</summary>
    public static volatile bool Enabled;

    /// <summary>Максимальная длина строки пакета при выводе (остальное обрезается «…»).</summary>
    public const int MaxDisplayLength = 300;

    public static void Incoming(Session s, string line)
    {
        if (!Enabled) return;
        Print("<--", $"#{s.Id}", line);
    }

    public static void Outgoing(Session s, string message)
    {
        if (!Enabled) return;
        Print("-->", $"#{s.Id}", message);
    }

    public static void Broadcast(Session from, IEnumerable<Session> targets, string message)
    {
        if (!Enabled) return;
        var ids = string.Join(",", targets.Select(t => "#" + t.Id));
        Print("<<*", $"#{from.Id} → [{ids}]", message);
    }

    private static void Print(string arrow, string who, string payload)
    {
        // убираем завершающий перевод строки фрейминга, схлопываем внутренние \r\n для читаемости
        var text = payload.TrimEnd('\n', '\r').Replace("\n", "\\n");
        if (text.Length > MaxDisplayLength)
            text = text[..MaxDisplayLength] + "…";

        lock (_lock)
        {
            var prev = Console.ForegroundColor;
            Console.ForegroundColor = arrow.StartsWith("<") ? ConsoleColor.Cyan : ConsoleColor.Green;
            Console.WriteLine($"[{DateTime.Now:HH:mm:ss.fff}] {arrow,-3} {who,-8} | {text}");
            Console.ForegroundColor = prev;
        }
    }
}
