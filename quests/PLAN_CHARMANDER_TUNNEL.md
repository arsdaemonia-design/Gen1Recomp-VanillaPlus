# Plan: El Chico del Túnel (Misión Charmander)

**Vanilla Plus — Starter Stories**

Quest #4 del arco. El chico perdió a su Charmander en el Túnel Roca y **te acompaña
como NPC follower** por la cueva hasta recuperarlo. Incluye un follower de NPC
ligero (el chico camina detrás tuyo en tiempo real) que **se encola al final de
la fila** si el mod de followers de Kanto (Wilds of Kanto) está activo, sin
interferir con él.

---

## 1. Resumen

| campo | valor |
|-------|-------|
| Quest id | `charmander` |
| Arco | Starter Stories (posterior a SS Anne) |
| Gate | `EVENT_SS_ANNE_LEFT` (flag 1506) |
| Mapas | `ROUTE_10`, `ROCK_TUNNEL_1F`, `ROCK_TUNNEL_B1F` |
| NPC principal | El chico (follower) |
| Encuentro | Charmander salvaje L12 (ruta B) / rescate (ruta A) |
| Recompensa | Charmander + objeto; hint de follower |
| Contrato | `mod.quests.register("charmander", ...)` — completed = stage ≥ 4 |
| Independiente | Sí — no depende de bulbasaur/squirtle/running_shoes |

### Máquina de estados (`charmander_stage`)

| stage | nombre | comportamiento |
|------:|--------|----------------|
| 0 | `NOT_STARTED` | Chico invisible. Nada ocurre hasta `EVENT_SS_ANNE_LEFT`. |
| 1 | `INTRO` | Chico visible en ROUTE_10. Talk → intro → stage 2. |
| 2 | `FOLLOWING` | Chico **sigue al jugador** en ROUTE_10 + cueva. Charmander visible en B1F. |
| 3 | `REWARD_READY` | Charmander capturado/rescatado. Chico reacciona; sigue hasta ROUTE_10. |
| 4 | `COMPLETED` | Recompensa entregada. Chico se queda en ROUTE_10 (dialogo final). |

Ruta A (el jugador ya tiene un Charmander): el encuentro de B1F es un rescate,
no una captura → `charmander_found`. Ruta B: batalla salvaje scripted L12 →
captura → `charmander_found`.

---

## 2. Diseño de gameplay (sin pathfinding)

El chico **no calcula rutas**: retraza las celdas que el jugador acaba de
dejar. Como el jugador ya caminó por ahí, la ruta siempre es válida (truco de
`PikachuFollower.lua`).

- En cada paso del jugador (`world.stepped`) el chico camina una celda hacia la
  posición del jugador hace `desfase` pasos.
- `passable = true` → nunca bloquea (puedes caminar sobre él).
- Cambio de mapa → `map.entered` re-spawnea (objeto estático + toggle).
- Si se queda a >6 celdas (bici/surf/warp) → teletransporte detrás.

---

## 3. Hallazgos (verificados en el motor)

| hallazgo | fuente |
|----------|--------|
| `world.stepped` existe; payload `{ mapId, x, y, tile, tod }` | `src/world/OverworldController.lua:3486` |
| `scriptMove` = movimiento en background (cola `scriptMoves`, anima por frames, no bloquea al jugador) | `OverworldController.lua:4352` |
| `updateScriptMoves` procesa la cola cada frame (fase 1 retira terminados, fase 2 arranca) | `OverworldController.lua:4375` |
| `passable` es real: `Collision.occupied` lo salta | `src/world/Collision.lua:22` |
| `NPC.new` NO copia `passable` del def → se setea en la instancia | `src/world/NPC.lua:23` |
| `NPC` soporta `stepFrames` y `hopStep` (follower rápido) | `NPC.lua:54-64` |
| `mod.world` real: `spawnNpc`, `npc(...)→Handle{scriptMove,marchInPlace,face,position}`, `toggleObject`, `queueScript` | `src/world/WorldAPI.lua:167,206,187,222,127` |
| `queueScript` **no** corre si ya hay un script (`"a script is already running"`) | `WorldAPI.lua:225` |
| `addRuntimeObject` mete en `Game.data.maps[].objects` (persiste en data, requiere remove) | `OverworldController.lua` |
| El único follower del motor es el de Pikachu (Yellow), hardcodeado (INDEX 99, sprite PIKACHU) | `src/world/PikachuFollower.lua` |
| `mod.find(id)` devuelve `{ id, version, exports }` — **sin** `options` | `src/mods/Loader.lua:728-734` |
| Túnel oscuro sin Flash: `darkMaps = { ROCK_TUNNEL_1F, ROCK_TUNNEL_B1F }`, se aclara con Flash (requiere medalla Boulder) | `data/generated/field.lua:1081-1089`, `OverworldController.lua:316,361` |
| Gate post-SS Anne | `EVENT_SS_ANNE_LEFT = 1506` (`data/save_convert/data/event_flags.lua`) |

---

## 4. Follower del chico (implementación)

Objeto estático en cada mapa, `hidden = true` por defecto, controlado con
toggles (`mod.world:toggleObject` — mismo patrón que squirtle/bulbasaur).

```lua
-- pseudo
FOLLOWER_MAPS = { "ROUTE_10", "ROCK_TUNNEL_1F", "ROCK_TUNNEL_B1F" }
KID_NAME = "STARTER_STORIES_CHARMANDER_KID"

-- map.entered: visibilidad según stage
if stage in {1,2,3} and FOLLOWER_MAPS[payload.mapId] then
    world:toggleObject(payload.mapId, KID_NAME, true)
else
    world:toggleObject(payload.mapId, KID_NAME, false)
end

-- world.stepped (solo stage == 2)
local h = world:npc(payload.mapId, KID_NAME)
h.npc.passable = true            -- una vez
-- cola de celdas recientes del jugador (tamaño = offset + 2)
local offset = wildsCount() + 1  -- ver sección 5
local target = trail[#trail - offset]
if distancia(h, target) > 6 then
    snap(h, target)              -- anti-atascamiento
elseif not h.npc.moving and not h.npc.marching then
    h:scriptMove(dirHacia(target), 1)   -- background, no bloquea
end
```

El chico también es **talkable** durante el viaje (línea idle en la cueva).

---

## 5. Integración con Wilds of Kanto (cola al final, sin interferir)

Wilds of Kanto = `overworld_wild_spawns` (manifest `id`, priority 80; vanilla-plus
es priority 100 → carga después y puede detectarlo).

Cómo se lee el número de trailers **sin tocar internals de Wilds**:

- Wilds espeja su opción en el save: `game.save.pokepcFollowerCount` y
  `game.save.pokepcControlMode` (`lib/follower/settings.lua:241-245`).
- vanilla-plus lee `mod.world.game.save.pokepcFollowerCount` (0-6, clamp en
  `settings.lua:19-28`). Si `nil` → 0.
- `desfase = pokepcFollowerCount + 1` → el chico se encola **detrás de todos
  los followers** (la última de la última).
- Detección para texto/hint: `mod.find("overworld_wild_spawns")`.
- **Nunca escribe** claves de Wilds → cero interferencia.

Limitación honesta: el encolado es por **desfase de celdas**, no por posición
exacta de cada trailer. Suficiente para el objetivo.

---

## 6. Implementación por fases

### Fase A — Infraestructura
1. `quests/charmander.lua` nuevo, con la sección `0. estado` y comandos
   custom `charmander:set_stage / check_stage / set_found / check_found`
   (patrón bulbasaur).
2. `main.lua`: `loadQuest("quests/charmander.lua")` (después de state.lua).
3. Contrato al final del archivo:
   ```lua
   mod.quests.register("charmander", {
       stage = function() return getState(STAGE_KEY, 0) end,
       completed = function() return getState(STAGE_KEY, 0) >= 4 end,
   })
   ```

### Fase B — Objetos (patches de mapa)
| mapa | index | name | función |
|------|------:|------|---------|
| `ROUTE_10` | 90 | `STARTER_STORIES_CHARMANDER_KID` | El chico (hidden, `text = TEXT_CHARMANDER_KID_*`) |
| `ROCK_TUNNEL_1F` | 90 | `STARTER_STORIES_CHARMANDER_KID` | Chico follower |
| `ROCK_TUNNEL_B1F` | 90 | `STARTER_STORIES_CHARMANDER_KID` | Chico follower |
| `ROCK_TUNNEL_B1F` | 91 | `STARTER_STORIES_CHARMANDER_WILD` | Charmander salvaje L12 (hidden hasta stage 2) |

> Regla: los índices 90/91 están libres (vanilla usa 1-13 en esos mapas), pero
> **deben verificarse y registrarse en `INDEX_DE_OBJETOS.md`** antes de implementar.

### Fase C — Textos (EN + ES vía `game.ready`)
- `_CharmanderKidIntro`, `_CharmanderKidFollow` (idle cueva),
  `_CharmanderKidFound` (reacción post-captura), `_CharmanderKidRewardA/B`,
  `_CharmanderKidDone`, `_CharmanderEncounter*`, hint de follower.

### Fase D — Scripts de mapa
- `ROUTE_10` `talk`: intro (stage 1→2), recompensa (stage 3→4), final (stage 4).
- `ROCK_TUNNEL_1F`/`B1F` `talk` (chico idle).
- `ROCK_TUNNEL_B1F`: `onStep`/`talk` del Charmander → batalla salvaje scripted
  (mismo mecanismo que bulbasaur/squirtle, MANUAL sección 14) → `set_found`.
- `map_scripts` `onEnter` de los 3 mapas: toggles de visibilidad del chico.

### Fase E — Follower (sección 4) + hook de captura
- `mod.events:on("pokemon.caught")`: species `CHARMANDER` durante stage 2 →
  `charmander_found = true`, stage 3.
- Ruta A: en el encuentro, si `check_party CHARMANDER` → rescate (sin batalla),
  `set_found`.

### Fase F — Recompensa
- Ruta B: el Charmander ya quedó en el equipo al capturarlo + objeto agradecido.
- Ruta A: objeto de agradecimiento + reunión.
- Hint: "Si usas el mod de followers, pon a tu Charmander en tu equipo para
  que te acompañe por Kanto."

### Fase G — Docs
- Actualizar `INDEX_DE_OBJETOS.md` (sección 1: 4 filas nuevas; sección 3:
  `charmander_stage`, `charmander_found`).
- Actualizar `MANUAL_DE_MISIONES.md` (sección 19: fila `charmander` completed ≥ 4).
- Validación de sintaxis (luaparser, como en las otras quests).

---

## 7. Riesgos y mitigaciones

| riesgo | mitigación |
|--------|------------|
| Wilds spawns wilds visibles dentro del túnel y hookea catching | El encuentro usa `start_battle wild` a nivel motor (independiente de Wilds). Probar convivencia en B1F. |
| Túnel oscuro sin Flash (`darkMaps`) | Quest post-SS-Anne (probable Flash/medalla Boulder). Alternativa: acercar el encuentro a la entrada. |
| `scriptMove` no chequea colisión | Solo se retrazan celdas del jugador → siempre válidas. |
| Offset de cola aproximado vs. posición real de trailers | Aceptado para v1 ("la última de la última"). |
| Re-entrada a un mapa → el chico vuelve a su celda patch (pierde posición en el mismo mapa) | Aceptable: en mapa nuevo aparece en su posición de patch. |
| Bici/Surf → el chico no sigue el ritmo | `passable` + teletransporte >6 celdas. |
| Índices de objetos (90/91) | Verificar contra vanilla y registrar en INDEX doc. |
| `talk` del chico durante FOLLOWING pausa al jugador | Aceptable (runner foreground), línea corta. |

---

## 8. Fuentes y referencias

### Motor (Gen1Recomp)
- `src/world/WorldAPI.lua` — `mod.world` completo (spawnNpc 167, Handle 184-204, npc 206, toggleObject 127, queueScript 222, current 78).
- `src/world/OverworldController.lua` — scriptMove 4352, marchInPlace 4363, updateScriptMoves 4375, `world.stepped` emit 3486, isDarkMap 99, dark set 316/361.
- `src/world/Collision.lua` — `occupied` 20-30 (`passable` 22).
- `src/world/NPC.lua` — `NPC.new` 23 (no copia passable), `stepFrames`/`hopStep` 54-64.
- `src/world/PikachuFollower.lua` — el follower de Yellow (patrón: INDEX 99, trail, fast follow, snap >6).
- `src/mods/Loader.lua` — `mod.find` 728-734 (`{id, version, exports}`), `mod.world` materialize 765-777.
- `src/mods/Schemas.lua` — registries y API de mods.
- `data/generated/maps.lua` — ROCK_TUNNEL_1F 8966, ROCK_TUNNEL_B1F 9136, ROUTE_10 9421 (vanilla usa índices 1-13 en esos mapas).
- `data/generated/field.lua` — `darkMaps` 1081-1089 (flashBadge BOULDERBADGE).
- `src/save_convert/data/event_flags.lua` — `EVENT_SS_ANNE_LEFT = 1506`.
- `src/render/PaletteFX.lua` — `DARK_BGP` 740.

### Mod de Kanto (Wilds of Kanto v2.0.0)
- `mods/Wilds.of.Kanto.v2.0.0/overworld-spawn-mod-main/manifest.json` — `id = "overworld_wild_spawns"`, priority 80, permisos `engine_internals`.
- `mods/Wilds.of.Kanto.v2.0.0/overworld-spawn-mod-main/main.lua` — `Follower.new` (líneas 90-96), `_G._wildsSpriteService` 95.
- `mods/Wilds.of.Kanto.v2.0.0/overworld-spawn-mod-main/lib/follower/init.lua` — arquitectura del core (selection/persistence/control/trailers/talk).
- `mods/Wilds.of.Kanto.v2.0.0/overworld-spawn-mod-main/lib/follower/selection.lua` — `getActiveFollowerMon` 72, `save.followerPartyIndex` 133.
- `mods/Wilds.of.Kanto.v2.0.0/overworld-spawn-mod-main/lib/follower/settings.lua` — `followerCount` 73, `engineMode` 85, `clampCount` 19, `alignSave` 241-245 (**espejo `game.save.pokepcControlMode` / `pokepcFollowerCount`**), opciones `follow_control` / `trainer_trail` / `follower_count`.
- `mods/Wilds.of.Kanto.v2.0.0/overworld-spawn-mod-main/lib/follower/control_engine.lua` — modos `follow | pokemon | lead_trainer | pack` y trailers.
- `mods/Wilds.of.Kanto.v2.0.0/overworld-spawn-mod-main/lib/follower/{lifecycle,sprite_service,interaction}.lua` — ciclo de vida, sprites, talk.

### Nuestro proyecto
- `mods/vanilla-plus/main.lua` — loader de quests (state.lua primero).
- `mods/vanilla-plus/quests/state.lua` — QuestConnector (`mod.quests`).
- `mods/vanilla-plus/quests/INDEX_DE_OBJETOS.md` — registro de índices por mapa.
- `mods/vanilla-plus/quests/MANUAL_DE_MISIONES.md` — secciones 19/20 (conector e índice).
