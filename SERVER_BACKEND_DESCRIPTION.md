# Описание клиентского кода и архитектура серверной части (DarkOrbit)

Документ составлен на основе декомпилированных ActionScript-классов клиента
(`extracted/net_bigpoint_darkorbit_net_*.as`) и описывает:

1. Как устроен сетевой слой клиента (что именно делает сервер).
2. Формат протокола обмена сообщениями.
3. Полный перечень команд, которые сервер должен принимать и отправлять.
4. Рекомендуемую архитектуру и план написания серверной части.

---

## 1. Обзор клиентского сетевого слоя

### 1.1. Ключевые классы

| Класс | Роль |
|---|---|
| `ConnectionManager` | Центральный сетевой менеджер: TCP-соединение (`XMLSocket`), отправка команд (`sendCommand`), приём и первичный разбор входящих сообщений (`onData` — switch по ~93 командам). |
| `ClientCommands` | Константы команд **клиент → сервер**. |
| `ServerCommands` | Константы команд **сервер → клиент** (около 500 констант, многие — подкоманды). |
| `BaseAssembly` / `*Assembly` | «Декодеры» server-сообщений по доменам (см. 1.3). Каждый — синглтон со словарём `delegateDict: код команды → метод-обработчик`. |
| `CooldownCommandMap` | Карта кулдаунов: связывает функцию и список команд (для обработки `CLD/CLR`). |
| `models/*` | Модели данных клиента: `TechModel`, `SkillDesignsModel`, `TechItem`, `SkillDesignItem` и т.д. Сервер определяет их содержимое (слоты техов, скиллы, кулдауны). |

### 1.2. Соединение (`ConnectionManager`)

* Транспорт: **`flash.net.XMLSocket`** — обычный **TCP-сокет**, порт **8080** (`public var port:int = 8080;`).
  Несмотря на имя «XML», данные — не XML, а текстовые строки (см. раздел 2).
* Адрес игрового сервера берётся из конфигурации карт (`Main.mapsXML ... gameserverIP`) или из `Settings.defaultGameServer`; функция `connectToMap(mapID)` выбирает IP карты и соединяется.
* Сразу после подключения клиент шлёт (**`handleGameServerConnect`**):

```
LOGIN|<userID>|<sessionID>|<version>[|<factionID>]
```

  где `factionID` добавляется только для арены/фракционной карты (map 255).
  **Сервер обязан проверить `sessionID`** и в случае неуспеха послать `S|ERR|4` (INVALID_SESSION) либо закрыть соединение.
* keep-alive: таймер каждые **25 секунд** шлёт `PNG`; сервер может отвечать тем же (или не отвечать — клиент просто мониторит живость соединения таймером `connectionMonitorTimer` (500 мс)).
* Загрузка карты: когда клиент закончил загружать спейсмэп и UI, он шлёт handshake-готовность:

```
RDY|MAP        (READY_COMMAND|SPACEMAP_LOADED)
```

  Только **после этого** сервер должен отправить состояние мира: `I` (HERO_INIT), `C` (CREATE_SHIP), `s` (станции), `p` (порталы), `r/c/L` (руда/ящики/мины) и т.д. Клиент выставляет флаги `isHeroLoaded / isMapLoaded`.
* Мониторинг обрыва: при потере соединения клиент переподключается / показывает ошибку; сервер должен корректно обрабатывать разрыв (снятие корабля с карты, сохранение состояния).

### 1.3. Assembly-классы (домены серверных сообщений)

`ConnectionManager.onData` разбивает входящий пакет по `|` и по значению **элемента [1]** маршрутизирует сообщение: либо сам обрабатывает в giant-switch, либо делегирует «assembly»:

| Assembly | Команда верхнего уровня | Домен ответственности |
|---|---|---|
| `AssetAssembly` | `CRE` (NEW_ASSET) | Станции, NPC-ассеты, creation-блоки (`AST`), попадания по ассетам (`HIT`) |
| `BoxCollectResponseAssembly` | `y` (BOX_COLLECT_RESPONSE) | Содержимое бонус-боксов (руда, кредиты, EP, HP, ракеты, мины `AMI`, джекпот…) |
| `GroupSystemAssembly` | `ps` (GROUPSYSTEM) | Группа/пати: init, invite, kick, promote, ping, ошибки |
| `MapEventsAssembly` | `n` (MAP_EVENT) | События карты (визуальные эффекты, события типа Rage/Saboteur/Neon) |
| `POIAssembly` | `POI` | Зоны POI (Create/Ready/Enter/Leave/Damage) |
| `PetAssembly` | `PET` | Пит-дроны: init, статус, шестерни, протоколы, ремонт, уровень |
| `QuestAssembly` | `9` (QUESTFM_INFO) | Квесты: init/update/accomplished/cancel/fail |
| `RocketLauncherAssembly` | `RL` | Пусковая установка ракет: статус/атака/зарядка |
| `SetAttributeAssembly` | `A` (SET_ATTRIBUTE) | Атрибуты кораблей (HP, щит, груз, опыт, кулдауны CPU, уровни) |
| `SettingsAssembly` | `7` (CLIENT_SETTING) | Подтверждение/синхронизация настроек клиента |
| `SkillsAssembly` | `SD` (SKILL_DESIGNS) | Скилл-дизайны кораблей (Solace, Diminisher, Spectrum, Sentinel, Venom, Lightning) |
| `TechAssembly` | `TX` (TECHS) | Теx-системы (Energy Leech, Chain Bolt, RPM, Shield Backup, BRB, Speed Leech) |
| `UserInterfaceAssembly` | `UI` | Окна, кнопки, камера, миникарта, стрелки, баннеры, меню |

Внутри каждого assembly работает паттерн «делегат»: `param1[2]` — подкоманда, поиск в `delegateDict`, вызов обработчика. Остальные элементы массива — параметры.

**Вывод для сервера:** структура исходящих сообщений трёхуровневая:
`<сеанс>|<команда>|<подкоманда>|<параметры…>` — см. раздел 2.

---

## 2. Формат протокола

Из `ConnectionManager`:

```
COMMAND_SEPARATOR = "|"   (ATTRIBUTE_SEPERATOR)
LIST_SEPARATOR    = ","   (LIST_SEPERATOR)
Параметры special: "%!" и "%2!" (PARAM_1/PARAM_2 — используются в текстах лута боксов)
```

* Каждое сообщение — **одна строка, оканчивающаяся `\n`** (XMLSocket требует терминатор; `sendCommand` добавляет `\n` сам).
* Отправка (`sendCommand`): `"CMD" + "|" + args.join("|") + "\n"`.
* Приём (`onData`): `data.split("|")`, где:
  * `[0]` — номер сессии/коннекта (клиент его игнорирует при разборе; сервер обычно ставит ID соединения или `0`);
  * `[1]` — код команды (`ServerCommands.*`);
  * `[2]` — подкоманда (код домена, `ServerCommands.*` второго уровня);
  * `[3…]` — параметры (числа — десятичные строки, булевы — `0/1`, списки — через `,`).
* Кодировка ASCII/UTF-8 (текст чата, имена).

Примеры реальных сообщений:

```
0|1|42|1200|800|0            # SHIP_MOVEMENT: корабль 42 -> (1200,800), направление 0
0|T|1200|800|90              # HERO_MOVEMENT героя: x y rotation
0|a|42|77|1                  # LASER_ATTACK: атакующий 42, цель 77, damage 1(...)
0|A|42|SHD|1500|2000         # SET_ATTRIBUTE: shipID=42, щит 1500/2000
0|RDY|MAP                    # клиент: карта загружена
LOGIN|1001|sessXYZ|1.337     # клиент: вход
```

---

## 3. Команды, которые сервер ДОЛЖЕН реализовывать

### 3.1. Входящие (клиент → сервер) — `ClientCommands` + служебные

| Константа | Код | Назначение (что делает сервер) |
|---|---|---|
| — | `LOGIN` | Авторизация: userID, sessionID, version [, factionID]. Ответ — HERO_INIT и состояние мира. |
| — | `RDY\|MAP/SHP/WND/QSL/CHA/LOG` | Handshake готовности клиента к получению мира. |
| — | `PNG` | Ping keep-alive (~25 с). |
| SELECT_SHIP | `SEL` | Выбрать корабль для наблюдения/управления. |
| SELECT | `S` | Выбор цели (target). |
| SELECT_LASER / SELECT_ROCKET | `u` / `d` | Выбранное оружие (первичка/вторичка). |
| SELECT_CLOAK | `CLK` | Включить/выбрать плащ-невидимку. |
| LASER_STOP | `G` | Стоп атака лазером. |
| COLLECT_ORE / COLLECT_BOX | `w` / `x` | Сбор руды / бонус-бокса (id объекта). |
| PORTAL_JUMP | `j` | Прыжок через портал (id портала). |
| TELEPORT | `tele` | Телепорт (jump drive / X-jump). |
| CONFIGURATION | `CFG` | Смена конфигурации корабля. |
| INSTAREPAIR | `IR` | Мгновенный ремонт за URI. |
| ROBOT / AROL / RLLB / AIM | `ROB`,`ARL`,`RLC`,`AIM` | Использование роботов/CPU (авто-ремонт, авто-рокет, aim-CPU). |
| FORCE_INIT | `i` | Принудительная ре-инициализация (например, после смены оружия). |
| GROUPSYSTEM + подкоманды | `ps` (+ `png/pos/usr/lv/kick/lc/s/i/flw/blk`) | Создание/вход в группу, пинг позиции/игрока, кик, повышение, follow, блок инвайтов. |
| ROCKETLAUNCHER + подкоманды | `RL` (`A`,`L`,`SEL`) | Атака/зарядка/выбор ракет из установки. |
| MINE | `MIN` | Установка мин. |
| TRADE_WINDOW_MINIMIZED | `TWC` | UI-состояние окна торговли. |
| SET_SPECIAL_OFFERS_AVAILABLE | `SOA` | Каталог спец-предложений. |
| REQUEST | `RQ` | Запрос данных (цены руды/боеприпасов и т.п.). |
| CLIENT_SETTING | `7` | Сохранение настройки клиента (ключ-значение, см. `SET_*` в ServerCommands). |
| BUY | `5` | Покупка (`b` — батареи, `r` — ракеты; в станциях — предметы). |
| SELL_ORE / EXCHANGE_PALLADIUM | `T` / `XCP` | Продажа руды / обмен палладия. |
| GET_ORE_PRICES | `b` | Запрос рыночных цен. |
| CHANGE_MAP | `z` | Переход на другую карту. |
| LOGOUT / LOGOUT_CANCEL_FROM_CLIENT | `l` / `o` | Выход / отмена выхода. |
| LAB + `UPD/GET/SET/REF/PROD` | `LAB` | Лаборатория исследования (NC). |
| TECHS_ACTIVATE/DEACTIVATE | `TX`+`A/D` | Активация тех-систем. |
| SKILLS_ACTIVATE/DEACTIVATE | `SD`+`A/D` | Активация скилл-дизайнов. |
| ADD_TO_PET/REMOVE_FROM_PET/SELECT/PET_RESET | `PET`-домен | Управление дроном. |

> Примечание: часть входящих команд (движение, атака) клиент шлёт raw-строками через `sendRawCommand`; сервер должен принимать и их. Движение героя клиент считает локально, сервер — периодическую синхронизацию `TR` (TRACKING: id,x,y,…,hp,shield,ammo…).

### 3.2. Исходящие (сервер → клиент) — основные группы `ServerCommands`

**Сессия и ошибки**
* `S|ERR` c кодами: `NO_HITPOINTS=1`, `NOT_LOGGED_IN=2`, `DOUBLE_LOGGED_IN=3`, `INVALID_SESSION=4`; `KIK` (кик), `l` (logout), `t` (server-initiated logout), `VERSION` (несовместимая версия).
* `LM` (LogMessage) — сообщения в игровой лог; `STD/KMS/STM` — текстовые/локализованные сообщения.

**Инициализация героя и кораблей**
* `I` (HERO_INIT) — огромное стартовое сообщение: id, имя, тип корабля, x, y, …, maxLaserCapacity, maxRocketCapacity, premium, EP, HP(честь), level, credits, uridium, jackpot, mapID, clanTag и т.д. (точный порядок параметров — `ConnectionManager`, `case HERO_INIT`).
* `C` (CREATE_SHIP) — создание корабля на карте: id, тип, x, y, имя, клан, hp/щит, фракция…
* `N` (SHIP_SELECTED), `R` (REMOVE_SHIP), `K` (DESTROY_SHIP + причина/убийца), `1` (SHIP_MOVEMENT: id,x,y,dir), `T` (HERO_MOVEMENT), `D` (BEACON), `U` (анимация портала), `i` (PORTAL_JUMP-ответ).
* `SLE` — доступные корабли на карте.

**Бой**
* `a` LASER_ATTACK (attackerId, targetId, dmg, hit?, shieldHit?), `v` ROCKET_ATTACK, `PA/PBA` prepare attack, `F/J` attack stopped, `M/Z` shoot missed, `H/Y` info об атаке, `O` out of range, `W` no ammunition, `P` no-attack zone, `X` target in range, `4` auto ammo change, `BOOOM`, `SAB_SHOT`.

**Атрибуты и значения (самый важный домен — `A` SET_ATTRIBUTE)**
Подкоманды: `SHD` щит (cur/max), `HPT` хитпоинты, `EP` опыт, `C` кредиты, `LUP` уровень, `v` скорость, `c` трюм, `a` боезапас, `CC` конфиги, `BS` бустеры, `PH/PHC` статистика пиратской охоты, `RHE/NFO/END` ranked hunt, `CLI` консоль, `FWX/FWL/FWI/FWG/WIZ/DCR` фейерверки, `RS/SHS` скорость ремонта/щита, `REP` данные ремонта, `HL` лечение, `CLD` старт кулдауна (id, type, seconds), `CLR` конец кулдауна, частные кулдауны `MIN/SMB/ISH/ROK/RSB/PLA/EMP/SJ`, `CPU` инфо CPU-слотов (`J/T/D/E/A/C/R/Y`), `JV` jump-ваучеры, `BK` booty keys.

**Карта и объекты**
* `m` NEW_MAP (id, name, size…), `s` CREATE_STATION, `p` CREATE_PORTAL, `r` CREATE_ORE, `c` CREATE_BOX, `L` CREATE_MINE, `q` REMOVE_ORE, `2` REMOVE_BOX, `e` ORE_COLLECTED_BY_HERO, `f` CARGO_FULL, `h` BOX_DISABLED, `y` BOX_COLLECT_RESPONSE (тип содержимого: `CAR/JPE/CRE/URI/EP/HON/HTP/ROK/BAT/BMP/DHP/XEN/AMI/PFL/JV/NL/FW/MIN...`), `MIN/ACM/EMP/SAB/DDM` мины, `SMP/CSS` статус PvP/станций, `n` MAP_EVENT (`MSG/RCO/BCO/LSH/USH/INV/d/e/w/s/t/trm/pt/MDL/SMB/ISH/EMP/fbo/MAL/pvp/Spawn/Despawn/HEAL_RAY/ID4/SET/REM/ssi/ssc/sss/isi/isc/isw/ctb…/tdm…/quu/msg`).
* `CRE` NEW_ASSET-домен: `AST` create asset, `NFO` asset info, `HIT` попадание по ассету; `AMS` матершип; `SE` special enemy.
* `POI`: `CRE`(id,x,y,type), `RDY`, `ENT`, `LEA`, `DMG`, `POIRDY`.

**Группы (`ps`)**: `init/grp/plr`, `inv(new/name/rjc/rji/del/ack/byes/bno/err…)`, `err(conn/…)`, `all/me/grp`, `upd`, `end`, `nl`, `chib`, `sc`, `jump`, `png`, `kill`, `lp(lv/kick/none)`, `mlo`, `back`, `blk`.

**Теxники и скиллы**: `TX` (`ELA/ECI/RPM/SBU/BRB/S` status, кулдауны), `SD` (`IH/WS/PS/FOR/SIN/SPEED_BUFF/SB/A/D/R`), `fx start/end` (`RAGE/SABOTEUR_DEBUFF/SKULL/INVINCIBILITY/KAM`).

**UI (`UI`)**: `MM` миникарта, `CAM` (`LTH/LTS/LTC`), `AR` (`SA/HA`), `W` (`SW/HW/MIW/MAW/WD`), `B` (`SB/HB`), `SF/HF`, `MV SM/HM`, `MBA EB/DB`, `AD` баннер, `AST`, `VID CW/DW`, `NP`, `MARK/NOMARK`, `SON`.

**Настройки (`7`)**: эхо/подтверждение всех `SET_*` (CLIENT_RESOLUTION, QUICKBAR_SLOT, SLOTMENU_ORDER/POSITION, MAINMENU_POSITION, WINDOW_SETTINGS, MINIMAP_SCALE, AUTO_REFINEMENT, SHOW_DRONES, AUTO_START, DOUBLECLICK_ATTACK, PLAY_SFX/MUSIC, SELECTED_BATTERY/ROCKET, DISPLAY_*, AUTO_AMMO_CHANGE, QUALITY_*, REM).

**Магазины/экономика**: `5` buy (`b/r/o/f/F/S` — успех/нет денег/нет места), `g/a/r` цены руды/боеприпасов, `E` кол-во руды, `LD/RD/DIS` скидки, `NB/QB/BB` бустеры, `LOT` лут-предметы, `BTB/BAH` ошибки боксов, `JPW` джекпот, `LAB`-ответы (`INFO/UPD/SET/REF/PROD`).

**Пит-дрон (`PET`)**: `I` init, `Q` acquired, `L/C/D/Z` активация/деактивация/уничтожение, `SL`, `RB`, `R` repair, `S` status, `G/P/A/E` gear/protocol/attribute/buff, `FL` топливо, `NOFL`, `TW`, `IDLE`, `TL`, `LS`, `W`, `EV`, `RESET`, `LUP`.

**Прочее**: `ach set/rm/end/buy` (ачивки), `9` квесты (`ini/upd/p/a/c/f/SUBSEQ/HLT`), `RL` (`A/a/S/s/R`), `TR` tracking, `HS` map-ready handshake, `IOLOG/DCH` (админ), `LOG`.

---

## 4. Что сервер должен считать и хранить (бизнес-логика)

1. **Сессии и авторизация**: проверка `LOGIN(userID, sessionID)`, поддержка одной активной сессии (`DOUBLE_LOGGED_IN`), обработка обрывов.
2. **Мир/карты**: реестр карт (id, IP/game-server, размеры, моб-спавны, станции, порталы), переходы между картами (`z`, `i`, portal, jump/teleport с кулдауном `SJ/J`).
3. **Корабль игрока**: тип (63=SOLACE, 64=DIMINISHER, 65=SENTINEL, 66=SPECTRUM, 67=VENOM, 73=LIGHTNING — см. `SkillDesignShipNames`), hp/shield/max, cargo, ammo (лазеры/ракеты по уровням), скорость (`v`), XP/level/credits/uri/honor/jackpot, конфигурации (`CFG`, `CC`), бустеры (`BS`).
4. **Движение**: сервер — источник истины для NPC; позиция героя синхронизируется (`1`, `T`, `TR`). Нужен tick-цикл карты (обычно 1–2 Гц broadcast позиций).
5. **Бой**: расчёт урона (лазер: точность/множители по дистанции, ракеты: probability maximizer tech, leech/stealth modifiers), смерть (`K` + лут-бокс `c`), агр-листы, no-attack zones, friendly-fire в группе, награды за kill (EP/HP, `kill` в группе).
6. **Кулдауны**: CPU (`CLD/CLR` + конкретные типы), теxи (`TX` cooldown per slot, 5 слотов, типы 1..7), скилл-дизайны (6 слотов, базовый cooldown 15 c — `SkillDesignItem.cooldownSeconds`), jump drive, ремонтные юниты. Сервер хранит таймеры и шлёт `CLD` при старте, `CLR` по окончании.
7. **Экономика**: цены руды (динамические), покупка/продажа, инвентарь/трюм, лаборатории, dtron/palladium.
8. **Объекты карты**: спавн/респаун руды, бонус-боксов (содержимое — `y` + `CAR/…`), мин, мобов (AI, patrol/aggro), NPC-ассетов (`CRE AST/NFO/HIT`), станций (ремонт `REP`, торговля), portals.
9. **Группы, квесты, ачивки,Ranked Hunting / TDM / Capture-the-Beacon (`ctb`) / Invasion** — отдельные подсистемы со своими протоколами (см. таблицы выше).
10. **Настройки клиента**: хранение key-value per user, эхо-подтверждения `7`.

---

## 5. Рекомендуемая архитектура сервера

```
game-server/
├── net/                # TCP-сервер (порт 8080), readline-framing, Session
│   ├── ConnectionHandler      # читает строки, split('|'), диспетчер
│   └── OutboundQueue          # batch-отправка, "\n"-терминация
├── protocol/
│   ├── ClientCommands.java    # константы входящих (см. 3.1)
│   ├── ServerCommands.java    # константы исходящих (см. 3.2)
│   └── MessageBuilder         # "sid|cmd|sub|args..." форматирование
├── dispatch/           # роутеры по доменам (аналог Assembly, но для входящих)
│   ├── LoginRouter, MovementRouter, AttackRouter, GroupRouter, ...
├── world/              # Map, ShipManager, NpcAI, OreSpot, Box, Mine, Station, Portal
├── entity/             # Hero, Ship(NPC), Pet, Asset, Collectable
├── combat/             # damage calc, aggro, death/loot
├── cooldown/           # CooldownManager (CLD/CLR)
├── economy/            # prices, shop, cargo, lab
├── persistence/        # БД игроков/настроек/инвентаря
└── admin/              # kick, IOLOG, tracking
```

Технические требования:
* **Event-driven I/O** (Netty/Node.js/Go/gRPC-не нужен — простой line-based TCP), один обработчик на сессию.
* Игровой цикл на карту: tick 500–1000 мс (движение NPC, regen щита/hp, кулдауны, респауны).
* Все исходящие строки сериализовать как `"<sessionId>|<CMD>|<sub>|<p1>|…<pn>\n"`; sessionId в поле [0] клиентом не используется, но должен присутствовать.
* Порядок handshakes критичен: `LOGIN` → (проверка) → ждать `RDY|MAP` → `I` (HERO_INIT) → мир → регулярные broadcasts.
* Валидация на сервере: расстояние до цели/руды, наличие боеприпасов, кулдауны, привилегии (premium/clan/hero), anti-spam (client может слать быстро) — клиентский код ничего не проверяет, вся правда на сервере.

### 5.1. Минимальный MVP по шагам

1. TCP-echo каркас + парсер `split('|')` + фрейминг по `\n`.
2. `LOGIN` → заглушка-успех → `RDY|MAP` → `HERO_INIT` (реплика поля порядка из `ConnectionManager`) → пустая карта `m`.
3. `CREATE_STATION`/`CREATE_PORTAL`/`CREATE_SHIP` при входе; movement-эхо (`1`, `T`, `TR`).
4. Атрибуты: `A|SHD`, `A|HPT`, регенерация на tick.
5. Лазерная атака: `G/u/S` входящие → `a` исходящие → `A|HPT/SHD` → `K` смерть.
6. Руда/боксы: `r/c` спавн, `w/x` сбор, `e/y` ответы.
7. Кулдауны `CLD/CLR`, телепорт/смена карт `z/i`.
8. Затем: группы (`ps`), петы (`PET`), теxи (`TX`), скиллы (`SD`), квесты (`9`), ачивки (`ach`), UI-окна (`UI`), настройки (`7`), магазин (`5`), POI, события карт (`n`).

---

## 6. Шпаргалка: быстрый индекс кодов

Разделители: команд `|`, списков `,`, спец-параметры `%!`/`%2!`; терминал строки `\n`; порт 8080; ping 25 с.

Входящие: `LOGIN RDY PNG SEL S u d CLK G w x j tele CFG IR ROB ARL RLC AIM i ps RL MIN TWC SOA RQ 7 5 b T XCP z l o LAB TX SD PET …`

Исходящие (верхний уровень): `I C N R K 1 T D U i a v PA PBA F J M Z H Y O W P X 4 A CRE POI m s p r c L q 2 e f h y n UI 7 5 g a r E S ps 9 ach TX SD fx PET RL TR HS LM STD STM ERR KIK …`

Полные таблицы — раздел 3. Точные индексы параметров каждой команды следует воспроизводить строго по обработчикам в `ConnectionManager.onData` и соответствующих `*Assembly.as` (например, `HERO_INIT` — поля `[2]…[31]`, `SHIP_MOVEMENT` — `[2]=shipId,[3]=x,[4]=y,[5]=dir`).
