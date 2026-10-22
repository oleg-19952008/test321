using System.Net;
using System.Net.Sockets;
using System.Text;
using GameServer.Dispatch;

namespace GameServer.Net;

/// <summary>
/// TCP-сервер (XMLSocket-совместимый): слушает порт 8080, фрейминг по '\n',
/// для каждого соединения создаёт Session и передаёт строки диспетчеру.
/// </summary>
public sealed class TcpGameServer
{
    private readonly TcpListener _listener;
    private readonly MessageDispatcher _dispatcher;
    private CancellationTokenSource _cts = new();

    public IEnumerable<Session> Sessions => _sessions.Values;
    private readonly ConcurrentDictionarySafe<int, Session> _sessions = new();

    public event Action<Session>? SessionClosed;

    public TcpGameServer(int port, MessageDispatcher dispatcher)
    {
        _listener = new TcpListener(IPAddress.Any, port);
        _dispatcher = dispatcher;
    }

    public void Start()
    {
        _listener.Start();
        _ = AcceptLoopAsync(_cts.Token);
        Console.WriteLine($"[net] TCP-сервер запущен на {_listener.LocalEndpoint} (ожидается клиент на порт 8080)");
    }

    public void Stop()
    {
        _cts.Cancel();
        _listener.Stop();
    }

    public bool RegisterSession(Session s) => _sessions.Add(s.Id, s);
    public void UnregisterSession(Session s)
    {
        _sessions.Remove(s.Id);
        SessionClosed?.Invoke(s);
    }

    private async Task AcceptLoopAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            TcpClient client;
            try
            {
                client = await _listener.AcceptTcpClientAsync(ct);
            }
            catch (OperationCanceledException) { break; }
            catch (ObjectDisposedException) { break; }
            catch (Exception ex)
            {
                Console.WriteLine($"[net] accept error: {ex.Message}");
                continue;
            }

            var session = new Session(client);
            _sessions.Add(session.Id, session);
            Console.WriteLine($"[net] + соединение #{session.Id} ({client.Client.RemoteEndPoint})");
            _ = HandleAsync(session, ct);
        }
    }

    private async Task HandleAsync(Session session, CancellationToken ct)
    {
        // flashpolicy: если клиент прислал <policy-file-request/>, отвечаем XML-политикой и закрываем соединение.
        // Иначе переходим в обычный line-based режим.
        var peekBuf = new byte[512];
        int peekLen = 0;
        try
        {
            if (session.Stream.CanRead)
            {
                // ждём первые данные не дольше 3 секунд
                var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(ct);
                timeoutCts.CancelAfter(TimeSpan.FromSeconds(3));
                try
                {
                    peekLen = await session.Stream.ReadAsync(peekBuf.AsMemory(0, peekBuf.Length), timeoutCts.Token);
                }
                catch (OperationCanceledException) { /* нет данных — просто закрываем */ }
                finally { timeoutCts.Dispose(); }
            }
        }
        catch (IOException) { /* разорвано */ }

        if (peekLen <= 0)
        {
            Console.WriteLine($"[net] - соединение #{session.Id} (нет данных)");
            await session.DisposeAsync();
            return;
        }

        var firstChunk = Encoding.UTF8.GetString(peekBuf, 0, peekLen);
        if (firstChunk.Contains("<policy-file-request"))
        {
            const string policyXml = "<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"8080\" /></cross-domain-policy>\0";
            var bytes = Encoding.UTF8.GetBytes(policyXml);
            try { await session.Stream.WriteAsync(bytes, ct); } catch { }
            Console.WriteLine($"[net] - соединение #{session.Id} (flashpolicy отправлен)");
            await session.DisposeAsync();
            return;
        }

        // обычный протокол: читаем строки до \n
        using var reader = new BufferedReaderWithPrefix(session.Stream, firstChunk, peekBuf, peekLen);
        var writerCts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        var writerTask = session.WriterLoopAsync(writerCts.Token);

        try
        {
            string? line;
            while (!ct.IsCancellationRequested && (line = await reader.ReadLineAsync(ct)) != null)
            {
                session.LastActivityUtc = DateTime.UtcNow;
                if (line.Length == 0) continue;
                PacketLog.Incoming(session, line);
                try
                {
                    _dispatcher.Handle(session, line);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[dispatch] ошибка обработки \"{line}\": {ex.Message}");
                }
            }
        }
        catch (IOException) { /* обрыв соединения */ }
        catch (OperationCanceledException) { }
        finally
        {
            Console.WriteLine($"[net] - соединение #{session.Id}");
            writerCts.Cancel();
            try { await writerTask; } catch { }
            _sessions.Remove(session.Id);
            SessionClosed?.Invoke(session);
            await session.DisposeAsync();
        }
    }
}

/// <summary>
/// Читатель строк поверх NetworkStream, который сначала «доедает» уже прочитанный при peek кусок
/// (важно: байтыpeek'а уже изъяты из потока и теряются при обычном StreamReader), затем читает из потока.
/// Фрейминг: строки до '\n' (поддерживается и '\r\n').
/// </summary>
internal sealed class BufferedReaderWithPrefix : IDisposable
{
    private readonly NetworkStream _stream;
    private readonly byte[] _prefix;   // сырые байты первого peek-чтения
    private int _pos;
    private readonly byte[] _single = new byte[1];
    private readonly List<byte> _line = new();

    public BufferedReaderWithPrefix(NetworkStream stream, string firstChunkText, byte[] peekBuf, int peekLen)
    {
        _stream = stream;
        // перекодируем корректно: берём исходные байты, а не текст (чтобы не резать мультибайт/не терять хвост строки)
        _prefix = new byte[peekLen];
        Array.Copy(peekBuf, _prefix, peekLen);
    }

    public async Task<string?> ReadLineAsync(CancellationToken ct)
    {
        while (true)
        {
            // сначала разбираем prefix-байты
            while (_pos < _prefix.Length)
            {
                byte b = _prefix[_pos++];
                if (b == (byte)'\n')
                {
                    var s = System.Text.Encoding.UTF8.GetString(_line.ToArray());
                    _line.Clear();
                    return s.TrimEnd('\r');
                }
                _line.Add(b);
            }

            // затем читаем из потока по одному байту (медленно, но надёжно для small packets)
            int one = 0;
            try
            {
                one = await _stream.ReadAsync(_single.AsMemory(0, 1), ct);
            }
            catch (IOException) { one = 0; }
            if (one <= 0)
            {
                // поток закрыт; если в буфере есть незавершённая строка — отдадим её
                if (_line.Count > 0)
                {
                    var s = System.Text.Encoding.UTF8.GetString(_line.ToArray());
                    _line.Clear();
                    return s.TrimEnd('\r');
                }
                return null;
            }

            byte nb = _single[0];
            if (nb == (byte)'\n')
            {
                var s = System.Text.Encoding.UTF8.GetString(_line.ToArray());
                _line.Clear();
                return s.TrimEnd('\r');
            }
            _line.Add(nb);
        }
    }

    public void Dispose() { }
}

/// <summary>Простейшая потокобезопасная обёртка над Dictionary (.NET 8 не имеет ConcurrentDictionary-safe API под наши нужды именования).</summary>
internal sealed class ConcurrentDictionarySafe<TKey, TValue> where TKey : notnull
{
    private readonly Dictionary<TKey, HashSet<TValue>> _map = new();
    private readonly object _lock = new();

    public bool Add(TKey key, TValue value)
    {
        lock (_lock)
        {
            if (!_map.TryGetValue(key, out var set)) _map[key] = set = new HashSet<TValue>();
            return set.Add(value);
        }
    }

    public void Remove(TKey key, TValue? value = default)
    {
        lock (_lock)
        {
            if (value is null) { _map.Remove(key); return; }
            if (_map.TryGetValue(key, out var set)) { set.Remove(value); if (set.Count == 0) _map.Remove(key); }
        }
    }

    public IEnumerable<TValue> Values
    {
        get { lock (_lock) return _map.Values.SelectMany(s => s).ToList(); }
    }

    public int Count
    {
        get { lock (_lock) return _map.Values.Sum(s => s.Count); }
    }
}
