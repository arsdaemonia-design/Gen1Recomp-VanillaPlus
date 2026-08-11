# Manual de Desarrollo de Misiones (Quest System)

**Vanilla Plus — Starter Stories**

Este manual explica **línea por línea** los archivos `bulbasaur.lua` y `squirtle.lua`,
qué hace cada bloque de código, cómo se usa y qué alternativas existen.
El objetivo es que puedas crear una misión nueva copiando uno de estos dos como plantilla.

---

## Índice

1. [Arquitectura general](#1-arquitectura-general)
2. [Estructura de archivos](#2-estructura-de-archivos)
3. [Máquina de estados (el corazón de la misión)](#3-máquina-de-estados)
4. [Comandos personalizados (`mod.content.commands`)](#4-comandos-personalizados)
5. [Condiciones de progresión (flags vanilla)](#5-condiciones-de-progresión)
6. [Sprites personalizados](#6-sprites-personalizados)
7. [Entrenadores](#7-entrenadores)
8. [Textos y traducción ES (`mod.content.text` + `game.ready`)](#8-textos-y-traducción)
9. [Objetos de mapa (`mod.content.maps:patch`)](#9-objetos-de-mapa)
10. [Scripts por mapa (`mod.content.map_scripts:register`)](#10-scripts-por-mapa)
11. [API de comandos — catálogo comentado](#11-api-de-comandos)
12. [onEnter, onStep, talk — cuándo se disparan](#12-onenter-onstep-talk)
13. [Movimiento de NPCs — lo que NO debes olvidar](#13-movimiento-de-npcs)
14. [Combates — salvajes, de entrenador y "guardianes"](#14-combates)
15. [Eventos globales (`pokemon.caught`, `game.ready`)](#15-eventos-globales)
16. [Registro en el diario (quest_system)](#16-registro-en-el-diario)
17. [Errores clásicos y su solución](#17-errores-clásicos)
18. [Plantilla mínima para tu propia misión](#18-plantilla-mínima)

---

## 1. Arquitectura general

Cada misión es un **módulo Lua que exporta una función**:

```lua
return function(mod)  -- squirtle.lua:1 / bulbasaur.lua:1
    -- ...todo el código de la misión va aquí (se ejecuta al cargar)...
end
```

- `mod` es el objeto del mod (vanilla-plus). Tiene todo lo necesario:
  `mod.content.*` (registrar contenido), `mod.save` (persistencia),
  `mod.events` (eventos), `mod.find(...)` (buscar otros mods), etc.
- La función se ejecuta **una sola vez al cargar el juego**.
- Los handlers (`onStep`, `onEnter`, `talk`) **no** se ejecutan ahí; solo se
  registran. Se ejecutan después, cuando el jugador juega.
- No usa `local` fuera del closure a propósito: todo queda aislado por misión,
  lo que evita colisiones de nombres entre misiones.

---

## 2. Estructura de archivos

```
mods/vanilla-plus/
├── main.lua              → orquesta las misiones
│     local function loadQuest(relative) { ... compile + pcall(chunk)(mod) }
│     loadQuest("quests/bulbasaur.lua")
│     loadQuest("quests/squirtle.lua")
│
└── quests/
    ├── bulbasaur.lua     → misión "The Lost Bulbasaur"
    ├── squirtle.lua      → misión "The Problematic Squirtle"
    └── running_shoes.lua → misión original (más sencilla)
```

`loadQuest` (main.lua):
1. Lee el archivo.
2. Lo compila (`compile`).
3. Lo ejecuta con `pcall` → obtiene la función.
4. La invoca con `(mod)`.
5. Si algo falla en cualquiera de esos pasos, **error fatal de carga**
   (el juego no arranca). Por eso es crucial que la sintaxis siempre sea válida.

**Cómo verificar sintaxis sin abrir el juego** (Lua 5.1 + LOVE):

```lua
-- main.lua de un proyecto temporal
function love.load()
  local a = loadfile([[E:\Pokemon 3d\gen1recomp\mods\vanilla-plus\quests\squirtle.lua]])
  print(a and "SQUIRTLE SYNTAX OK" or "SQUIRTLE SYNTAX FAIL")
  os.exit(0)
end
```

Ejecutar con `love <carpeta>` y leer la consola. No necesitas que `mod` exista:
`loadfile` solo compila, no ejecuta la función.

---

## 3. Máquina de estados

Ambas misiones modelan el progreso con un **entero** guardado en el save.

### squirtle.lua:6-11 (estados documentados)

```lua
-- squirtle_stage:
--   0 = NOT_STARTED
--   1 = STARTED       (no se usa en la práctica actual)
--   2 = CHASING       (en persecución: oficiales ya presentados)
--   3 = CAUGHT        (Squirtle capturado, antes de hablar con Jenny)
--   4 = COMPLETED     (todo terminado)
```

### bulbasaur.lua:6-10

```lua
-- bulbasaur_stage:
--   0 = NOT_STARTED
--   1 = STARTED
--   2 = CAUGHT
--   3 = COMPLETED
```

### Los accesores (squirtle.lua:23-43, bulbasaur.lua:19-39)

```lua
local STAGE_KEY = "squirtle_stage"          -- nombre de la key en el save

local function getState(key, default)        -- leer: mod.save:get
    return mod.save:get(key, default)
end

local function setState(key, value)          -- escribir: mod.save:set
    mod.save:set(key, value)
end

local function rivalKey(key)                 -- prefija flags de rivales
    return "squirtle_" .. tostring(key)      -- "rival1_beat" → "squirtle_rival1_beat"
end

local function rivalBeaten(key)              -- ¿ese rival ya fue vencido?
    return getState(rivalKey(key), false) and true or false
end

local function setRivalBeaten(key)           -- marcar como vencido
    setState(rivalKey(key), true)
end
```

> **Por qué `and true or false`**: `mod.save:get` podría devolver `nil` o `false`;
> la expresión normaliza a booleano puro. No es estrictamente necesario, pero
> es defensivo y legible.

**Uso típico**:

```lua
if getState(STAGE_KEY, 0) ~= 2 then return false end   -- solo avanzar en stage 2
if not rivalBeaten("rival1_beat") then ... end          -- si no ha sido vencido
setRivalBeaten("rival1_beat")                            -- marcarlo vencido
setState(STAGE_KEY, 3)                                   -- avanzar de etapa
```

**Alternativa**: usar flags de evento vanilla (`set_flag`/`check_flag`). Las
flags `squirtle_*` en `mod.save` son ajenas a las flags de evento del juego, lo
cual aísla la misión. Elige `mod.save` para estado privado de misión y flags
vanilla para reutilizar progresión del juego base.

---

## 4. Comandos personalizados

Son verbos que los scripts pueden invocar vía `{ "nombre:mk", args... }`.
Se registran con `mod.content.commands:register`.

### Lectura/escritura de stage (squirtle.lua:49-64)

```lua
mod.content.commands:register("squirtle:set_stage", function(ctx, value)
    setState(STAGE_KEY, tonumber(value) or 0)          -- convierte a número
end)

mod.content.commands:register("squirtle:check_stage", function(ctx, value)
    ctx.lastCheck =
        getState(STAGE_KEY, 0) == (tonumber(value) or -1)  -- compara con el valor
end)

mod.content.commands:register("squirtle:set_rival", function(ctx, key)
    setRivalBeaten(key)
end)

mod.content.commands:register("squirtle:check_rival", function(ctx, key)
    ctx.lastCheck = rivalBeaten(key)
end)
```

**Puntos clave del contrato de comandos**:

- El **primer parámetro es siempre `ctx`** (contexto: `ctx.game`,
  `ctx.overworld`, `ctx.runner`, `ctx.save`, `ctx.lastCheck`...).
- `ctx.lastCheck` es la **variable que leen `jump_if_true`/`jump_if_false`**.
  Por eso `check_*` la puebla y `set_*` no la toca.
- El script llama a estos así (ver bulbasaur.lua:629):

```lua
{ "bulbasaur:set_stage", 1 },
...
{ "bulbasaur:check_stage", 3 },
{ "jump_if_true", "done" },
```

### Comando especial: combate sin captura (`squirtle:guardian_battle`, squirtle.lua:71-97)

Este es un ejemplo de **comando personalizado que lanza un combate salvaje
completo**, imitando a `start_battle`:

```lua
mod.content.commands:register("squirtle:guardian_battle", function(ctx)
    local BattleState = require("src.battle.BattleState")
    local runner = ctx.runner

    local battle = BattleState.newWild(ctx.game, "STARMIE", 19)  -- especie, nivel
    battle.noCatch = true            -- STARMIE no se puede capturar

    battle.onFinish = function(result)
        ctx.lastBattleResult = result          -- "win", "caught", "lost", "fled"...
        ctx.lastCheck = result == "win"        -- para jump_if_true
        if ctx.overworld then
            if result == "win" then
                -- post-procesa la victoria DESPUÉS de que el texto del
                -- script termine (evita que una evolución tappe por encima).
                ctx.afterScript = ctx.afterScript or {}
                table.insert(ctx.afterScript, function()
                    ctx.overworld:afterBattle(result, battle)
                end)
            else
                ctx.overworld:afterBattle(result, battle)
            end
        end
        runner:resume()              -- el runner sigue con el siguiente comando
    end

    if ctx.overworld and ctx.overworld.pushBattle then
        ctx.overworld:pushBattle(battle)   -- con transición de pantalla
    else
        ctx.game.stack:push(battle)
    end
    runner:yield()                   -- pausa el script hasta que acabe el combate
end)
```

**Cómo se usa** (squirtle.lua:1640):

```lua
{ "squirtle:guardian_battle" },
{ "check_battle_result", "win" },
{ "jump_if_false", "end_final" },
```

> `ctx.lastBattleResult` alimenta directamente a `Commands.check_battle_result`
> (ver sección 14), por eso funciona encadenado.

---

## 5. Condiciones de progresión

Funciones helper que consultan **flags del juego base** para decidir si la
misión debe iniciar.

### squirtle.lua:115-143

```lua
local function hasStarter(game)
    local flags = game and game.save and game.save.flags
    return not not (flags and flags.EVENT_GOT_STARTER)
end

local function choseSquirtle(game)
    local flags = game and game.save and game.save.flags
    return not not (flags and flags.EVENT_CHOSE_SQUIRTLE)
end

local function questEligible(game)               -- es elegible para este save
    if not hasStarter(game) then return false end
    if choseSquirtle(game) then return false end -- el dueño del starter no vuelve a cazarlo
    return true
end
```

- `not not (...)` convierte cualquier valor en booleano (`nil` → `false`).
- Se evalúa **dentro del handler** que recibe `game` (p. ej. `onEnter`).
- En Cerulean se usa `questEligible` en `onEnter` (squirtle.lua:737-741) para
  **mostrar el objeto inicial** y en `onStep` (squirtle.lua:764) para el trigger.

### bulbasaur.lua:76-99 (versión con medalla)

```lua
local function hasBoulderBadge(game)
    local inventory = game and game.save and game.save.inventory or {}
    return (inventory["BOULDERBADGE"] or 0) > 0
end
```

**Alternativa**: `events` (por ejemplo `EVENT_BEAT_BROCK`). El comentario del
código (bulbasaur.lua:71-73) explica por qué se prefiere la medalla:
representa progresión persistente y funciona en partidas donde el mod se
instala **después** de vencer a Brock.

---

## 6. Sprites personalizados

### squirtle.lua:149-167

```lua
mod.content.sprites:register("SPRITE_FOLLOWER_SQUIRTLE", {
    id = "SPRITE_FOLLOWER_SQUIRTLE",
    image = mod.assets:path("assets/poke_followers/follower_007.png"),
    frames = 6,        -- 6 frames de animación de caminar
    walker = true,     -- tiene ciclo de caminado (no es un objeto estático)
    trueColor = true,
})
```

- El **id** debe coincidir con el usado en `sprite = ...` al crear el objeto.
- `frames`, `walker`, `trueColor` controlan la animación del overworld.
- Reutiliza PNGs que ya vienen con el mod (carpeta `assets/`).

**Alternativa**: usar sprites existentes del juego base (`SPRITE_YOUNGSTER`,
`SPRITE_GUARD`, `SPRITE_COOLTRAINER_F`, `SPRITE_FISHER`...) en vez de crear
uno. Ambas misiones lo hacen para los NPCs humanos; solo el pokémon usa sprite
personalizado.

---

## 7. Entrenadores

### squirtle.lua:172-243 / bulbasaur.lua:121-178

```lua
mod.content.trainers:register("STARTER_STORIES_SQUIRTLE_RIVAL1", {
    id = "STARTER_STORIES_SQUIRTLE_RIVAL1",
    name = "Derek",            -- nombre mostrado
    basePic = "OPP_YOUNGSTER", -- imagen (sprite de rival)
    baseMoney = 30,            -- dinero por derrota

    parties = {                -- lista de equipos (uno solo aquí)
        {
            { level = 15, species = "RATTATA" },
            { level = 15, species = "EKANS" },
            { level = 16, species = "ODDISH" },
        },
    },
})
```

- `parties` puede tener varias entradas; la primer se usa por defecto (a menos
  que uses flags para equipos rematch, que no es el caso aquí).
- `basePic` usa los valores **generados del ROM** (`OPP_...`, `SPR_...`).

**Cómo se usa en combate** (squirtle.lua:1359):

```lua
{ "start_battle", "trainer", "STARTER_STORIES_SQUIRTLE_RIVAL1", 1 }
```

Y en el objeto del mapa (`text = ...` no; el objeto solo es el sprite de
overworld; el combate lo dispara el script).

---

## 8. Textos y traducción

### Patrón base en INGLÉS (squirtle.lua:254-258)

```lua
mod.content.text:register(
    "_SquirtleStart1",
    "SQUIRTLE!\n" ..
    "Wait!"        -- ".." concatena la cadena de la siguiente línea Lua
)
```

**Reglas de la caja de diálogo (máx. 18 columnas por línea)**:

- `\n` = salto de línea ordinario (baja el carro).
- `\v` = pausa, flechita ▼, al pulsar A/B la 2ª línea sube y se escribe debajo.
- `\f` = salto de página: limpia la caja y empieza de nuevo desde arriba.
- El motor hace **soft-wrap** automático si una palabra excede 18 columnas;
  no necesitas medir a mano, pero conviene separar en líneas bonitas.

Ejemplo correcto con `\v` y `\f` (bulbasaur.lua:187-190):

```lua
mod.content.text:register(
    "_BulbaPewterHint",
    "Have you seen a\ngirl looking for\vher BULBASAUR?\fShe looked\nreally worried."
)
```

### Traducción ES en runtime (squirtle.lua:417-556 / bulbasaur.lua:302-391)

```lua
mod.events:on("game.ready", function(ev)
    local game = ev and ev.game
    local mods = game and game.mods and game.mods.mods
    local spanish = mods and mods["recomp-spanish"]

    if not (spanish and spanish.enabled) then
        return                     -- español no activo → nada que hacer
    end

    local text = game.data and game.data.text
    if not text then
        return
    end

    -- Sobrescribimos en MEMORIA la cadena ya registrada:
    text._SquirtleStart1 =
        "¡SQUIRTLE!\n" ..
        "¡Espera!"
end)
```

> **IMPORTANTE — no uses `mod.content.text:register` dentro de `game.ready`.**
> La base de datos de contenido se congela después de la carga; registrar tarde
> provocaría crash. Por eso la traducción **muta la tabla RAM** `game.data.text`.

`report_*` **nunca** se traduce al español por contenido; solo se muta.

---

## 9. Objetos de mapa

Añaden NPCs/objetos a un mapa sin tocar el ROM.

### squirtle.lua:559-727 (índices 90-98)

```lua
mod.content.maps:patch("ROUTE_25", {
    objects = {
        __append = {              -- clave mágica: añade, no reemplaza
            {
                index = 90,
                name = "STARTER_STORIES_SQUIRTLE_RIVAL2",
                text = "TEXT_STARTER_STORIES_SQUIRTLE_RIVAL2",
                sprite = "SPRITE_YOUNGSTER",
                x = 3,
                y = 9,
                movement = "STAY",     -- no deambula
                range = "RIGHT",       -- facing inicial (reloj: RIGHT=→ etc.)
                hidden = true,         -- invisible hasta show_object
            },
            -- ...más objetos (91..98)...
        },
    },
})
```

**Campos que importan**:

- `index`: **número** único por mapa (NO confundir con el `name`).
  Los comandos `place_npc`/`move_npc`/`face_object` usan `index`.
- `name`: identifica al objeto en `show_object`/`hide_object` y en `talk`.
- `text`: key de diálogo que se muestra al interactuar (busca el handler en
  la tabla `talk` del mapa).
- `x, y`: posición por defecto.
- `movement`: `STAY` (quieto), `WALK`, `SPIN`... `STAY` es lo más predecible.
- `range`: facing inicial y/o patrón de desplazamiento (`UP`, `DOWN`, `LEFT`,
  `RIGHT`...).
- `hidden = true`: no aparece hasta que un script lo muestra. Estándar para
  escenas.

**Alternativas de visibilidad**:
- `hidden` en la definición → aparece tras `show_object`.
- Sin `hidden` → visible siempre.
- `place_npc` mueve **al instante** un objeto ya existente; no lo muestra.
  Para mostrarlo y moverlo al mismo "lugar", usa `show_object` + `place_npc`
  (ver escena de los oficiales en squirtle.lua:855-885).

---

## 10. Scripts por mapa

La API central. Toda misión necesita al menos una de estas tablas:

```lua
mod.content.map_scripts:register("ROUTE_25", {
    onEnter = function(game, ow, ...) end,  -- al entrar al mapa
    onStep  = function(game, ow, x, y) end, -- al dar un paso por el mapa
    talk    = { <OBJ_NAME> = { ...script... }, ... },  -- al hablar con un objeto
})
```

### Registro para bulbasaur (bulbasaur.lua:507-516)

```lua
mod.content.map_scripts:register("PEWTER_CITY", {
    talk = {
        TEXT_STARTER_STORIES_BULBA_PEWTER_LASSIE = {
            { "show_text", "_BulbaPewterHint" },
        },
    },
})
```

> El **nombre del handler en `talk` debe ser EXACTAMENTE el `text = "..."`** que
> definiste en el objeto. Ese es el enganche.

---

## 11. API de comandos (catálogo comentado)

Todos son arrays Lua: `{ verbo, arg1, arg2, ... }`.

| Comando | Argumentos | Qué hace |
|---|---|---|
| `stop_music` | — | Apaga la música de mapa (para escena con tema propio). |
| `play_music` | `id` | Toca una canción (`Music_MeetMaleTrainer`, `Music_MeetFemaleTrainer`...). |
| `play_default_music` | — | Restaura el tema del mapa. |
| `play_cry` | especie | Sonido del Pokémon. Opcional 2º arg `true` = esperar botón. |
| `emote` | `"player"`, bubble, frames | Burbuja de exclamación `"shock"`/`"!"` sobre el target. |
| `wait` | frames | Espera N frames (30 ≈ 0,5s). |
| `show_object` | mapId, name | Hace visible el objeto. |
| `hide_object` | mapId, name | Oculta el objeto. |
| `place_npc` | index, x, y, facing? | Teletransporta al instante (opcional facing inicial). |
| `move_npc` | index, dir, tiles | Camina N casillas en dirección fija. **Seguro.** |
| `move_npc_to` | index, tx, ty | Camina a una coordenada (BFS). **Puede fallar.** |
| `face_player` | — | El `ctx.npc` del runner se gira hacia el jugador. |
| `face_object` | index, dir | Gira un objeto a la dirección dada sin moverlo. |
| `face_npc` | — | El **jugador** se gira hacia el `ctx.npc`. |
| `face_player_dir` | dir | Gira al jugador a una dirección fija. |
| `show_text` | textId | Muestra la caja de diálogo. |
| `ask` | textId | Texto + caja Sí/No (resultado en `ctx.lastCheck`). |
| `start_battle` | `"wild"`/`"trainer"`, id, nivel | Lanza combate. |
| `check_battle_result` | `"win"`/`"caught"`… | `lastCheck = resultado == arg`. |
| `jump` | label | Salta incondicionalmente. |
| `jump_if_true` | label | Salta si `ctx.lastCheck` es `true`. |
| `jump_if_false` | label | Salta si `ctx.lastCheck` es `false`. |
| `label` | label | Marca un destino de salto. |
| `warp` | mapId, x, y, facing | Teletransporta al jugador entre mapas. |
| `set_flag` / `clear_flag` / `check_flag` | name | Flags de evento vanilla. |
| `check_item` / `check_dex_owned` | — | Inventario / dex (para comprobar requisitos). |

### Flujo de control: labels (squirtle.lua:1324-1432)

```lua
{ "squirtle:set_stage",   3 },           -- avanza
{ "jump_if_false",   "after_squirtle" }, -- si lastCheck es false, salta
...
{ "label", "after_squirtle" },           -- destino
```

> `jump_if_*` lee LO ÚLTIMO que puso un comando en `ctx.lastCheck`
> (`check_battle_result`, `check_stage`, `check_rival`...). No leerlo es un bug
> típico.

---

## 12. onEnter, onStep, talk

### onEnter (squirtle.lua:1150-1246, bulbasaur.lua:745-800)

Se ejecuta **al entrar al mapa**. Uso típico:

```lua
onEnter = function(game, ow)
    local stage = getState(STAGE_KEY, 0)
    if stage ~= 2 and stage ~= 3 then
        return                       -- fuera de la ventana de la misión
    end

    local rows = {}                  -- construimos comandos dinámicamente

    if stage == 2 then
        if not rivalBeaten("rival2_beat") then
            table.insert(rows, { "show_object", "ROUTE_25", "..." })
        end
        -- ...
    end

    ow:queueScript(rows)             -- los ejecuta al refrescar
end
```

**Por qué `queueScript` y no `runner:run`**: `queueScript` encola el script
para que el motor lo ejecute cuando le toque (sin colisionar con otros).
`runner:run` (usado en `onStep`) lanza en el momento.

### onStep (squirtle.lua:1291+, bulbasaur.lua:806+)

Se ejecuta **cada vez que el jugador pisa un tile**. Dos guardianes CRÍTICOS:

```lua
onStep = function(game, ow, x, y)

    if ow.runner:isRunning() then    -- control: si ya hay una escena, no otra
        return false
    end

    -- (squirtle) solo en stage 2
    if getState(STAGE_KEY, 0) ~= 2 then
        return false
    end
```

**Devuelve `false`** para no bloquear el avance. Devuelve `true` cuando la
escena se apoderó del control (tras `queueScript`).

**Patrón de zona** (squirtle.lua:1265-1290):

```lua
local function zoneTrigger(rx, ry)
    return math.abs(x - rx) <= 2 and math.abs(y - ry) <= 2
end
```

**Segundo encuentro (squirtle.lua:1417-1441)**: el trigger calcula distancia y
hace `move_npc` de huida.

### talk (squirtle.lua:1760+, bulbasaur.lua:1111+)

Script que corre al pulsar A frente a un objeto cuyo `text` coincide:

```lua
TEXT_STARTER_STORIES_SQUIRTLE_JENNY = {
    { "face_player" },
    { "show_text", "_SquirtleJenny1" },
    -- ...
    { "squirtle:set_stage", 4 },
    { "hide_object", ... },
},
```

**Alternativas de ramificación** en un solo handler (bulbasaur.lua:649-729):
el patrón `check_stage` → `jump_if_true` → label permite que UN handler haga
de "situación": completada / capturada / en curso.

---

## 13. Movimiento de NPCs

### La regla de oro

**`move_npc` con dirección y pasos fijos es la vía segura.**

```lua
{ "move_npc", 90, "up", 2 }    -- 2 casillas al norte
{ "move_npc", 92, "right", 5 } -- 5 casillas al este
```

Direcciones: `"up"` (`y-1`), `"down"` (`y+1`), `"left"` (`x-1`), `"right"`
(`x+1`). El NPC mira automáticamente hacia donde camina
(`e.facing = mv.dir` en el motor).

**`move_npc_to` usa BFS y rutas el mapa**. Es más cómodo (le das una
coordenada destino y "va solo"), pero **falla sin ruta limpia** — fue la causa
de un crash que ya arreglamos en el proyecto (Hatch: "move_npc_to: no path").
Siempre que puedas, usa pasos fijos.

### mover un NPC "desde lejos" (escena de oficiales, squirtle.lua:871-899)

```lua
-- 1) teletransportarlo al punto de inicio, fuera de cámara
table.insert(introRows, { "place_npc", 91, 22, 15, "up" })
-- 2) que camine hasta su sitio
table.insert(introRows, { "move_npc", 91, "up", 2 })   -- Y15 → Y13
```

Esto le da un recorrido visible. En Cerúleo, los oficiales nacen al sur y
suben para hablar desde Y13.

### facing al terminar

- `move_npc` deja al NPC mirando en la dirección del último tramo.
- `face_player`: el NPC se gira hacia el jugador (requiere `ctx.npc`, es decir
  que el runner se creó con `{ npc = npc }`).
- `face_object index dir`: gira a un NPC concreto sin contexto de runner.
  (Usado para Jenny y escoltas en squirtle.lua:1615-1629.)

### Runner: pasar `npc`

```lua
ow.runner:run(rows, { npc = npc })   -- squirtle.lua:1393
```

Esto alimenta `ctx.npc` que usan `face_player`, `face_npc`, etc.

---

## 14. Combates

### Salvaje (bulbasaur.lua:1325, squirtle.lua:1597-1600)

```lua
{ "start_battle", "wild", "BULBASAUR", 12 }   -- especie y nivel
{ "check_battle_result", "caught" }           -- ¿lo capturó?
{ "jump_if_true", "captured" }
```

`play_cry` antes de `start_battle` hace que el rugido suene en el overworld.

### De entrenador (squirtle.lua:1359-1370)

```lua
{ "start_battle", "trainer", "STARTER_STORIES_SQUIRTLE_RIVAL1", 1 }  -- nº de party (1)
{ "check_battle_result", "win" }
{ "jump_if_false", "end_ambush" }
```

### Decidir "no captó ⇒ se puede volver" (squirtle.lua:1559-1560)

```lua
{ "check_battle_result", "caught" }
{ "jump_if_false", "after_squirtle" }   -- si NO lo capturó, salta y deja el
                                           -- objeto visible → re-enfrentable
```

El objeto **no se oculta** y la misión no avanza de stage hasta capturar de
verdad (bulbasaur.lua:1335-1411 muestra el trío completo
capturado / derrotado / huido).

---

## 15. Eventos globales

### `pokemon.caught` (squirtle.lua:1918+, bulbasaur.lua:1426-1441)

Backup de seguridad: si el jugador captura al pokémon por cualquier vía,
sincroniza la misión:

```lua
mod.events:on("pokemon.caught", function(e)
    if not e then return end
    if e.species ~= "SQUIRTLE" then return end
    if getState(STAGE_KEY, 0) ~= 2 then return end
    setState(STAGE_KEY, 3)          -- el script ve que ya está capturado
end)
```

> No entrega el pokémon ni modifica sus movimientos: solo avanza el stage.

---

## 16. Registro en el diario

Al final de cada misión (squirtle.lua:1942-2032, bulbasaur.lua:1447-1527):

```lua
mod.events:on("game.ready", function(payload)
    local journal = mod.find("quest_system")

    if not (journal and journal.exports and journal.exports.register) then
        return                     -- el mod diario no está instalado
    end

    pcall(journal.exports.register, {
        id = "starter_stories_squirtle",
        title = "The Problematic Squirtle",
        source = "Starter Stories",
        sort = 160,
        description = "...",
        objective = function()
            -- devuelve el texto según el stage
        end,
        location = function() ... end,
        reward = "Wild Squirtle, Level 18",
        progress = function()
            return { current = stage, total = 4 }
        end,
    })
end)
```

- `pcall` evita que un fallo del diario tumbe el juego.
- `objective`/`location`/`progress` son funciones (se llaman cuando se pinta
  el diario), no cadenas estáticas.

---

## 17. Errores clásicos y su solución

| Síntoma | Causa | Solución |
|---|---|---|
| **Error fatal al cargar** | Sintaxis incorrecta | `loadfile` + LOVE para validar (sección 2) |
| **Escena no se dispara** | `onStep` devuelve `false` por stage/flag | Revisa los guardas de entrada (¿stage correcto? ¿runner libre?) |
| **Doble escena simultánea** | `onStep` sin `runner:isRunning()` | Comprueba `ow.runner:isRunning()` al inicio |
| **NPC "aparece de la nada"** | Objeto oculto que se muestra de golpe | `show_object` + `place_npc` lejano + `move_npc` recorrido visible |
| **Crash al mover NPC** | `move_npc_to` sin ruta limpia | Cambiar a `move_npc` con dirección y pasos fijos |
| **`jump_if_true` no salta** | Nadie escribió `ctx.lastCheck` | Asegurar un `check_*`/`check_battle_result` antes |
| **Texto en inglés aunque hay español** | El mod de español no está activo, o editaste con `content:register` en `game.ready` | Usar mutación `text._X = ...` en `game.ready` |
| **Hablas al NPC y no pasa nada** | Falta handler en `talk` con el `name` exacto | Coincidir `text` del objeto con la key de `talk` |
| **El pokémon desaparece al derrotarlo** | `hide_object` incondicional tras batalla | Verificar el resultado (`check_battle_result caught`) antes de ocultar |

---

## 18. Plantilla mínima

```lua
-- ============================================================
-- miniquest.lua — plantilla para una misión nueva
-- ============================================================
return function(mod)

    local STAGE_KEY = "miniquest_stage"

    local function getState(k, d)  return mod.save:get(k, d) end
    local function setState(k, v)  mod.save:set(k, v) end

    -- 1) comando para avanzar el estado desde un script
    mod.content.commands:register("miniquest:set_stage", function(ctx, v)
        setState(STAGE_KEY, tonumber(v) or 0)
    end)

    -- 2) texto base (inglés)
    mod.content.text:register("_MiniHello", "Hello there!\nWelcome to my quest.")

    -- 3) personaje en el mapa
    mod.content.maps:patch("ROUTE_3", {
        objects = { __append = {
            {
                index = 60,
                name = "MINI_NPC",
                text = "TEXT_MINI_NPC",
                sprite = "SPRITE_YOUNGSTER",
                x = 14, y = 9,
                movement = "STAY", range = "DOWN",
                hidden = true,
            },
        } },
    })

    -- 4) script por paso en el mapa
    mod.content.map_scripts:register("ROUTE_3", {
        onEnter = function(game, ow)
            if getState(STAGE_KEY, 0) == 0 then
                ow:queueScript({
                    { "show_object", "ROUTE_3", "MINI_NPC" },
                })
            end
        end,
        onStep = function(game, ow, x, y)
            if ow.runner:isRunning() then return false end
            if getState(STAGE_KEY, 0) ~= 0 then return false end
            if math.abs(x - 14) > 2 or math.abs(y - 9) > 2 then return false end

            local npc = ow:npcByIndex(60)
            if not npc or npc.moving then return false end

            ow.runner:run({
                { "stop_music" },
                { "play_music", "Music_MeetMaleTrainer" },
                { "emote", "player", "shock", 30 },
                { "wait", 20 },
                { "move_npc", 60, "left", math.max(0, 14 - x - 1) },
                { "face_player" },
                { "show_text", "_MiniHello" },
                { "miniquest:set_stage", 1 },
                { "play_default_music" },
            }, { npc = npc })

            return true
        end,
    })
end
```

---

## Epílogo

Las dos misiones (`squirtle.lua`, `bulbasaur.lua`) son plantillas sólidas en
las que **todo está modularizado por secciones numeradas**:

- `0` estado, `1` comandos, `2` requisitos, `3` sprites, `4` trainers,
  `5` textos, `6` español, `7` objetos, `8+` scripts por mapa, `final` diario.

Copia esa disciplina de numeración y debugging cuando hagas tu misión:
**valida sintaxis, guarda el estado de la máquina, y nunca dejes un
`move_npc_to` donde bastan pasos fijos**.