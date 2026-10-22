using GameServer.Dispatch;
using GameServer.Net;
using GameServer.Persistence;
using GameServer.Protocol;

const int Port = 8080;                 // порт XMLSocket-клиента (см. ConnectionManager: port = 8080)
const int TickMs = 1000;               // игровой tick: регенерация, кулдауны и т.п.
string bazaPath = Path.Combine(AppContext.BaseDirectory, "baza.txt");

Console.OutputEncoding = System.Text.Encoding.UTF8;
Console.WriteLine("=== DarkOrbit Game Server (.NET 8, консоль) ===");
Console.WriteLine($"Хранилище: {bazaPath}");

// --packets: сразу включить показ входящих/исходящих пакетов
if (args.Contains("--packets", StringComparer.OrdinalIgnoreCase))
    PacketLog.Enabled = true;

var storage = new BazaStorage(bazaPath);

// MessageDispatcher нужен серверу при создании, сервер (сессии) нужен диспетчеру — разрываем цикл ленивой лямбдой.
MessageDispatcher? dispatcherRef = null;
var server = new TcpGameServer(Port, new RouterDispatcher(() => dispatcherRef!));
var dispatcher = new MessageDispatcher(storage, () => server.Sessions);
dispatcherRef = dispatcher;
server.SessionClosed += s => dispatcher.OnSessionClosed(s);
server.Start();

// Игровой цикл (tick): регенерация щита/hp
var cts = new CancellationTokenSource();
_ = Task.Run(async () =>
{
    while (!cts.Token.IsCancellationRequested)
    {
        try
        {
            await Task.Delay(TickMs, cts.Token);
            dispatcher.TickRegen(server.Sessions);
        }
        catch (OperationCanceledException) { break; }
    }
});

Console.WriteLine("Команды консоли: help | save | kick <userID> | packets [on|off] | quit");
while (true)
{
    string? input;
    try { input = Console.ReadLine(); }
    catch (IOException) { break; }   // консоль недоступна (nohup/redirect stdin) — работаем в фоновом режиме
    if (input is null) break;
    var parts = input.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
    if (parts.Length == 0) continue;

    switch (parts[0].ToLowerInvariant())
    {
        case "quit":
        case "exit":
            Console.WriteLine("Остановка сервера, сохранение профилей...");
            foreach (var s in server.Sessions) dispatcher.SaveProfile(s);
            cts.Cancel();
            server.Stop();
            return;

        case "save":
            foreach (var s in server.Sessions) dispatcher.SaveProfile(s);
            Console.WriteLine("Профили сохранены в baza.txt.");
            break;

        case "kick":
            if (parts.Length >= 2 && int.TryParse(parts[1], out int uid))
            {
                var target = server.Sessions.FirstOrDefault(s => s.Profile?.UserId == uid);
                if (target is not null)
                {
                    target.SendMessage(ServerCommands.Session, ServerCommands.Kicked, 0);
                    target.Client.Dispose();
                    Console.WriteLine($"Пользователь {uid} кикнут.");
                }
                else Console.WriteLine("Такого пользователя нет в сети.");
            }
            else Console.WriteLine("Использование: kick <userID>");
            break;

        case "packets" or "packetlog" or "pk":
            // packets — переключить, packets on/off — задать явно
            bool newState = parts.Length >= 2
                ? parts[1].ToLowerInvariant() switch
                {
                    "on" or "1" or "true" or "вкл" => true,
                    "off" or "0" or "false" or "выкл" => false,
                    _ => PacketLog.Enabled
                }
                : !PacketLog.Enabled;
            PacketLog.Enabled = newState;
            Console.WriteLine(newState
                ? "Показ пакетов ВКЛЮЧЁН (--> исходящие, <-- входящие)."
                : "Показ пакетов ВЫКЛЮЧЕН.");
            break;

        case "help":
            Console.WriteLine("save — сохранить профили в baza.txt");
            Console.WriteLine("kick <userID> — кикнуть игрока");
            Console.WriteLine("packets [on|off] — показывать/скрыть входящие и исходящие пакеты");
            Console.WriteLine("quit — остановить сервер");
            break;

        default:
            Console.WriteLine("Неизвестная команда. help — список команд.");
            break;
    }
}

/// <summary>Тонкий роутер: разрываем циклическую зависимость TcpGameServer <-> MessageDispatcher.</summary>
internal sealed class RouterDispatcher : MessageDispatcher
{
    private readonly Func<MessageDispatcher> _provider;
    public RouterDispatcher(Func<MessageDispatcher> provider) => _provider = provider;
    public override void Handle(Session session, string line) => _provider().Handle(session, line);
}
