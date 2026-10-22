using System.Collections.Concurrent;
using System.Net.Sockets;
using System.Text;
using GameServer.World;

namespace GameServer.Net;

/// <summary>
/// Одна TCP-сессия клиента (порт 8080, line-based протокол).
/// Входящие строки читаются в HandleAsync, исходящие ставятся в очередь и пишутся WriterLoopAsync.
/// </summary>
public sealed class Session : IAsyncDisposable
{
    private static int _nextId = 1000;

    public int Id { get; } = Interlocked.Increment(ref _nextId);
    public TcpClient Client { get; }
    public NetworkStream Stream { get; }

    // Состояние handshake (см. раздел 1.2 документации)
    public bool LoggedIn;
    public bool MapReady;          // получен RDY|MAP — можно слать состояние мира
    public string? SessionId;      // sessionID из LOGIN (для проверки)
    public PlayerProfile? Profile;
    public HeroInfo? Hero;         // когда герой на карте

    public DateTime LastActivityUtc = DateTime.UtcNow;

    private readonly ConcurrentQueue<string> _outbound = new();
    private readonly SemaphoreSlim _signal = new(0);
    private readonly TaskCompletionSource _writerDone = new(TaskCreationOptions.RunContinuationsAsynchronously);

    public Session(TcpClient client)
    {
        Client = client;
        Client.NoDelay = true;
        Stream = client.GetStream();
    }

    /// <summary>Ставит сообщение в очередь отправки (формат уже собран MessageBuilder, включая \n).</summary>
    public void Send(string message)
    {
        _outbound.Enqueue(message);
        _signal.Release();
    }

    public void SendMessage(string command, params object[] parts) =>
        Send(Protocol.MessageBuilder.Build(Id, command, parts));

    public async Task WriterLoopAsync(CancellationToken ct)
    {
        var buffer = new byte[64 * 1024];
        try
        {
            while (!ct.IsCancellationRequested)
            {
                await _signal.WaitAsync(ct).ConfigureAwait(false);

                int pos = 0;
                while (_outbound.TryDequeue(out var msg))
                {
                    var bytes = Encoding.UTF8.GetBytes(msg);
                    if (pos + bytes.Length > buffer.Length)
                    {
                        // не влезает — отправляем текущий батч, это сообщение вернём в очередь
                        _outbound.Enqueue(msg);
                        _signal.Release();
                        break;
                    }
                    Buffer.BlockCopy(bytes, 0, buffer, pos, bytes.Length);
                    pos += bytes.Length;
                }

                if (pos > 0)
                    await Stream.WriteAsync(buffer.AsMemory(0, pos), ct).ConfigureAwait(false);
            }
        }
        catch
        {
            // соединение разорвано или сервер останавливается
        }
        finally
        {
            _writerDone.TrySetResult();
        }
    }

    public async ValueTask DisposeAsync()
    {
        try { Stream.Close(); } catch { }
        Client.Close();
        await _writerDone.Task;
    }
}
