using System.Globalization;
using System.Text;

namespace GameServer.Protocol;

/// <summary>
/// Форматирование исходящих сообщений: "&lt;sessionId&gt;|&lt;CMD&gt;|&lt;sub&gt;|&lt;p1&gt;...|&lt;pn&gt;\n".
/// Разделитель команд — '|', списков — ','; терминатор строки — '\n' (см. SERVER_BACKEND_DESCRIPTION.md, раздел 2).
/// </summary>
public static class MessageBuilder
{
    public const char CommandSeparator = '|';
    public const char ListSeparator = ',';

    /// <summary>Собирает строку вида "sid|cmd|part1|part2|...\n".</summary>
    public static string Build(int sessionId, string command, params object[] parts)
    {
        var sb = new StringBuilder(64);
        sb.Append(sessionId.ToString(CultureInfo.InvariantCulture))
          .Append(CommandSeparator)
          .Append(command);
        foreach (var p in parts)
        {
            sb.Append(CommandSeparator);
            AppendValue(sb, p);
        }
        sb.Append('\n');
        return sb.ToString();
    }

    private static void AppendValue(StringBuilder sb, object value)
    {
        switch (value)
        {
            case null:
                break;
            case string s:
                sb.Append(s);
                break;
            case bool b:
                sb.Append(b ? '1' : '0');
                break;
            case float f:
                sb.Append(f.ToString("0.###", CultureInfo.InvariantCulture));
                break;
            case double d:
                sb.Append(d.ToString("0.###", CultureInfo.InvariantCulture));
                break;
            case IEnumerable<int> ints:
                sb.Append(string.Join(ListSeparator, ints));
                break;
            case IEnumerable<string> strs:
                sb.Append(string.Join(ListSeparator, strs));
                break;
            case IFormattable form:
                sb.Append(form.ToString(null, CultureInfo.InvariantCulture));
                break;
            default:
                sb.Append(value);
                break;
        }
    }

    /// <summary>Разбор входящей строки по '|' (пустые хвостовые элементы сохраняются как "").</summary>
    public static string[] Parse(string line) =>
        line.Trim('\r', '\n', '\0').Split(CommandSeparator);
}
