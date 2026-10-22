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
        using var reader = new StreamReader(session.Stream, Encoding.UTF8, false, 4096, leaveOpen: true);
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
