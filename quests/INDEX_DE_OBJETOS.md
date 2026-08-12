# Índice de Objetos y Recursos por Mapa

**Vanilla Plus — Starter Stories**

Documento de referencia para **no pisar** lo que ya existe. Antes de parchear un
mapa, registrar un comando, un texto o una key de estado, consulta este documento.

> **REGLA DE ORO (de `state.lua`)**: una quest **nunca asume que otra existe**.
> Si necesita el estado de otra, pregunta por `mod.quests` (y comprueba
> `registered()`) — nunca leas las keys internas de otra quest en `mod.save`.

---

## 1. Índices de objetos por mapa

Cada fila es un objeto **agregado** (`__append`) por una quest. Un `index`
solo debe usarse **una vez por mapa**. Si el mapa no aparece aquí, eres libre
de usarlo, pero agrega tu fila.

### CERULEAN_CITY — (quest: squirtle)
| index | name | sprite | función |
|------:|------|--------|---------|
| 90 | `STARTER_STORIES_SQUIRTLE` | — | El squirtle problema |
| 91 | `STARTER_STORIES_SQUIRTLE_OFFICER1` | — | Oficial (escena final) |
| 92 | `STARTER_STORIES_SQUIRTLE_OFFICER2` | — | Oficial (escena final) |

### ROUTE_24 — (quest: squirtle)
| index | name | sprite | función |
|------:|------|--------|---------|
| 90 | `STARTER_STORIES_SQUIRTLE_RIVAL1` | — | Emboscador de la caza |

### ROUTE_25 — (quest: squirtle)
| index | name | sprite | función |
|------:|------|--------|---------|
| 90 | `STARTER_STORIES_SQUIRTLE_RIVAL2` | — | Emboscador 2 |
| 91 | `STARTER_STORIES_SQUIRTLE_WILD` | — | Squirtle salvaje objetivo |
| 92 | `STARTER_STORIES_SQUIRTLE_RIVAL3` | — | Emboscador 3 |
| 93 | `STARTER_STORIES_SQUIRTLE_RIVAL4` | — | Emboscador 4 |
| 94 | `STARTER_STORIES_SQUIRTLE_GUARDIAN` | — | Rival final (batalla) |
| 95 | `STARTER_STORIES_SQUIRTLE_FINAL` | — | Rival vencido (parado) |
| 96 | `STARTER_STORIES_SQUIRTLE_JENNY` | — | Jenny (oficial) |
| 97 | `STARTER_STORIES_SQUIRTLE_ESCORT1` | — | Escolta 1 |
| 98 | `STARTER_STORIES_SQUIRTLE_ESCORT2` | — | Escolta 2 |

### ROUTE_3 — (quest: bulbasaur)
| index | name | sprite | función |
|------:|------|--------|---------|
| 90 | `STARTER_STORIES_BULBA_OWNER` | — | La chica (Lass) dueña del bulbasaur |

### PEWTER_CITY — (quest: bulbasaur)
| index | name | sprite | función |
|------:|------|--------|---------|
| 95 | `STARTER_STORIES_BULBA_PEWTER_LASSIE` | — | Pista de la Lass en Pewter |

### VIRIDIAN_FOREST — (quest: bulbasaur)
| index | name | sprite | función |
|------:|------|--------|---------|
| 51 | `STARTER_STORIES_BULBA_RIVAL1` | — | Emboscador 1 |
| 52 | `STARTER_STORIES_BULBA_RIVAL2` | — | Emboscador 2 |
| 53 | `STARTER_STORIES_BULBA_RIVAL3` | — | Emboscador 3 |
| 54 | `STARTER_STORIES_BULBA_WILD` | — | Bulbasaur salvaje objetivo |
| 55 | `STARTER_STORIES_BULBA_RIVAL_FINAL` | — | Rival final |

### VIRIDIAN_MART — (quest: running_shoes)
| index | name | sprite | función |
|------:|------|--------|---------|
| 4 | `RUNNING_SHOES_VICTIM` | `SPRITE_YOUNGSTER` | Víctima del robo |

### ROUTE_2 — (quest: running_shoes)
| index | name | sprite | función |
|------:|------|--------|---------|
| 3 | `RUNNING_SHOES_THIEF_NPC` | `SPRITE_SUPER_NERD` | El ladrón |

---

## 2. Convención de nombres

- **Objetos**: `STARTER_STORIES_<MISION>_<ROL>` (ej. `STARTER_STORIES_SQUIRTLE_RIVAL1`).
  La quest de running_shoes usa `RUNNING_SHOES_*` por ser anterior a la convención.
- **Textos**: prefijo propio de misión (`_Squirtle*`, `_Bulba*`, `_RunningShoes*`).
- **Comandos custom**: `<mision>:*` — ya registrados:

| comando | quest |
|---------|-------|
| `squirtle:set_stage` / `squirtle:check_stage` | squirtle |
| `squirtle:set_rival` / `squirtle:check_rival` | squirtle |
| `bulbasaur:set_stage` / `bulbasaur:check_stage` | bulbasaur |
| `bulbasaur:set_rival` / `bulbasaur:check_rival` | bulbasaur |
| `running_shoes:set_stage` / `running_shoes:check_stage` | running_shoes |

- **IDs** (items/trainers/pokémon): prefijo de misión (`RUNNING_SHOES_*`,
  `STARTER_STORIES_*`).

---

## 3. Keys de estado en `mod.save` (no colisionar)

| key | quest | valores |
|-----|-------|---------|
| `mod:running_shoes_stage` | running_shoes | 0 no_empezada · 1 escena_vista · 2 ladrón_derrotado · 3 completada |
| `bulbasaur_stage` | bulbasaur | 0 not_started · 1 started · 2 caught · 3 completed |
| `bulba_rival1_beat` … `bulba_rival3_beat`, `bulba_rival_final_beat` | bulbasaur | true/false |
| `squirtle_stage` | squirtle | 0 not_started · 1 started · 2 chasing · 3 caught · 4 completed |
| `squirtle_rival1_beat` … `squirtle_rival4_beat` | squirtle | true/false |
| `squirtle_guardian_beat` | squirtle | true/false |

> Nunca escribir la key de otra quest. Para **leer** el estado de otra usa el
> contrato: `mod.quests.stage("squirtle")`, `mod.quests.completed("bulbasaur")`.

---

## 4. Checklist antes de agregar una quest nueva

1. ¿El mapa ya aparece en la sección 1? Si sí, elige índices libres y agrega tu fila.
2. ¿Tu comando custom colisiona con la tabla de la sección 2? Usa otro prefijo.
3. ¿Tu key de estado colisiona con la sección 3? Usa un prefijo de misión nuevo.
4. ¿Necesitas saber si otra quest terminó? Usa `mod.quests.completed(...)`.
5. Registra tu quest en `state.lua` vía `mod.quests.register(id, { stage, completed })`.
