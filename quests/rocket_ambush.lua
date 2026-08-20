return function(mod)

    -- =========================================================================
    -- EMBOSCADAS DE TEAM ROCKET (post-finale de Lavender, TODAS las rutas)
    --
    -- JENNY lo advierte en el finale ("They may ambush you on the road").
    -- Tras completar la misión de Lavender, reclutas ROCKET pueden aparecer en
    -- CUALQUIER ruta de Kanto: colocación 100% dinámica vía mod.world:spawnNpc
    -- (tile libre aleatorio al ENTRAR al mapa; cada visita puede estar en un
    -- sitio distinto, igual que los spawns visibles de Wilds of Kanto).
    --
    -- VENTANA NARRATIVA (no permanente): activa desde el finale de Lavender
    -- hasta que Team Rocket se disuelve al vencer a GIOVANNI en el Gimnasio de
    -- Viridian (8ª medalla). Después ya no hay emboscadas: vuelves a capturar
    -- POKéMON tranquilo. Mientras dure el "acecho":
    --   * visible y evitable: solo te intercepta si pasas ENFRENTE de él a
    --     <= 2 celdas (línea de visión); rodéalo por la espalda/lateral y
    --     pasas de largo.
    --   * probabilidad de aparición: PRIMERA vez siempre (SPAWN_CHANCE); en
    --     revisitas de una ruta ya despejada, prob. de reaparecer (REVISIT_CHANCE).
    --   * 1 por ruta (máximo una derrota por encuentro; vencerlo lo retira).
    --   * nivel escalado por MEDALLAS y por el promedio del equipo (reto justo).
    --   * recompensas ALEATORIAS y variadas (Poke Balls, pociones, revives,
    --     etc.): recluta 3 ítems / capitán 5 ítems; el "capitán" (CAPTAIN_CHANCE)
    --     además cura a tu equipo antes del combate. Cada ítem se muestra con
    --     su propio aviso de recogida ("¡Red recibió POKE BALL!") y su jingle.
    --   * 5 PLANTILLAS de POKéMON (parties) diferentes por nivel: cada emboscada
    --     elige una al azar, así nunca peleas contra el mismo equipo dos veces.
    -- =========================================================================

    local function getState(key, default)
        return mod.save:get("mod:" .. key, default)
    end

    local function setState(key, value)
        mod.save:set("mod:" .. key, value)
    end

    local function beaten(key)
        return getState(tostring(key), false) and true or false
    end

    local function setBeaten(key)
        setState(tostring(key), true)
    end

    -- Gate: el finale de Lavender (escena de JENNY) ya ocurrió.
    local function lavenderFinaleDone()
        return beaten("lavender_finale_done")
    end

    -- Corte narrativo: la última misión de Team Rocket es el Gimnasio de
    -- Viridian (GIOVANNI). Al vencerlo (8ª medalla) la organización se disuelve
    -- y las emboscadas en las rutas terminan para siempre: vuelves a capturar
    -- POKéMON tranquilo. Mientras tanto, la ventana de "acecho" está activa.
    local BADGE_IDS = {
        "BOULDERBADGE", "CASCADEBADGE", "THUNDERBADGE", "RAINBOWBADGE",
        "SOULBADGE", "MARSHBADGE", "VOLCANOBADGE", "EARTHBADGE",
    }

    local function rocketDisbanded(game)
        local inv = game and game.save and game.save.inventory or {}
        local badges = 0
        for _, id in ipairs(BADGE_IDS) do
            if inv[id] then badges = badges + 1 end
        end
        return badges >= 8
    end

    local GRUNT_MUSIC = "Music_MeetMaleTrainer"

    -- Probabilidad de aparición al entrar a una ruta:
    --   * PRIMERA vez (ruta nunca despejada): siempre aparece (SPAWN_CHANCE = 1).
    --   * REVISITA (ruta ya despejada): probabilidad de que reaparezca otro
    --     grunt (farming de recompensas dentro de la ventana narrativa).
    local SPAWN_CHANCE = 1.0
    local REVISIT_CHANCE = 0.45
    -- Probabilidad de que el grunt sea un "capitán" (cura + mejor loot).
    local CAPTAIN_CHANCE = 0.18

    -- Todas las rutas de Kanto (se excluyen la Cycling Road 16/17/18, de
    -- bici forzada, y las rutas acuáticas 19/20/21). Regístrate onStep por
    -- mapa en el LOAD (la lista es estable en gen1).
    local ROUTE_MAPS = {
        "ROUTE_1", "ROUTE_2", "ROUTE_3", "ROUTE_4", "ROUTE_5", "ROUTE_6",
        "ROUTE_7", "ROUTE_8", "ROUTE_9", "ROUTE_10", "ROUTE_11", "ROUTE_12",
        "ROUTE_13", "ROUTE_14", "ROUTE_15", "ROUTE_22", "ROUTE_23", "ROUTE_24",
        "ROUTE_25",
    }

    local ROUTE_SET = {}
    for _, mapId in ipairs(ROUTE_MAPS) do
        ROUTE_SET[mapId] = true
    end

    -- Recompensas variadas/aleatorias: cada "slot" tira de un pool con pesos.
    -- Recluta: 3 ítems de un pool modesto. Capitán: 5 ítems de un pool mejor.
    local REGULAR_POOL = {
        { item = "POKE_BALL",    weight = 35 },
        { item = "POTION",       weight = 25 },
        { item = "SUPER_POTION", weight = 18 },
        { item = "FULL_HEAL",    weight = 12 },
        { item = "REVIVE",       weight = 10 },
    }

    local CAPTAIN_POOL = {
        { item = "GREAT_BALL",   weight = 28 },
        { item = "HYPER_POTION", weight = 22 },
        { item = "POKE_BALL",    weight = 16 },
        { item = "REVIVE",       weight = 14 },
        { item = "SUPER_POTION", weight = 12 },
        { item = "ELIXER",       weight = 8 },
    }

    local function rollReward(pool)
        local total = 0
        for _, entry in ipairs(pool) do total = total + entry.weight end
        local r = math.random() * total
        local acc = 0
        for _, entry in ipairs(pool) do
            acc = acc + entry.weight
            if r <= acc then return entry.item end
        end
        return pool[#pool].item
    end

    local function rollRewards(cfg)
        local out = {}
        for _ = 1, cfg.itemCount do
            out[#out + 1] = rollReward(cfg.pool)
        end
        return out
    end

    local REGULAR_CFG = {
        intro = "_RocketAmbushIntro",
        won = "_RocketAmbushWon",
        heal = false,
        itemCount = 3,
        pool = REGULAR_POOL,
    }

    local CAPTAIN_CFG = {
        intro = "_RocketCaptainIntro",
        won = "_RocketCaptainWon",
        heal = true,
        itemCount = 5,
        pool = CAPTAIN_POOL,
    }

    local function routeKey(mapId)
        return "rocket_ambush_" .. mapId .. "_beat"
    end

    -- Grunts vivos en esta sesión, por mapa: spawned[mapId] = { npcId, captain }.
    local spawned = {}

    local function clearGrunt(mapId)
        local entry = spawned[mapId]
        if not entry then return end
        spawned[mapId] = nil
        if mod.world then
            pcall(mod.world.removeNpc, mod.world, entry.npcId)
        end
    end

    -- =========================================================================
    -- 1. ENTRENADORES POR NIVEL (escala por medallas + promedio del equipo)
    -- =========================================================================

    local TIER_TRAINERS = {
        "STARTER_STORIES_ROCKET_AMBUSH_T1",
        "STARTER_STORIES_ROCKET_AMBUSH_T2",
        "STARTER_STORIES_ROCKET_AMBUSH_T3",
        "STARTER_STORIES_ROCKET_AMBUSH_T4",
        "STARTER_STORIES_ROCKET_AMBUSH_T5",
    }

    -- 5 plantillas (parties) DIFERENTES por nivel: cada emboscada elige una
    -- al azar, así el combate varía (nada de pelear siempre contra el mismo
    -- equipo). Niveles ~ fijos por rango; el escalado fino lo decide el tier.
    local TIER_PARTIES = {
        -- T1 (objetivo <= 21): reclutas bisoños
        {
            { { level = 22, species = "RATTATA" }, { level = 23, species = "ZUBAT" } },
            { { level = 22, species = "EKANS" },   { level = 23, species = "MEOWTH" } },
            { { level = 23, species = "GRIMER" },  { level = 22, species = "KOFFING" } },
            { { level = 23, species = "MACHOP" },  { level = 22, species = "DROWZEE" } },
            { { level = 21, species = "ZUBAT" }, { level = 22, species = "RATTATA" }, { level = 23, species = "EKANS" } },
        },
        -- T2 (objetivo 22-25)
        {
            { { level = 26, species = "EKANS" },     { level = 27, species = "KOFFING" } },
            { { level = 26, species = "MEOWTH" },    { level = 27, species = "GRIMER" } },
            { { level = 25, species = "DROWZEE" }, { level = 26, species = "MACHOP" }, { level = 27, species = "ZUBAT" } },
            { { level = 26, species = "SANDSHREW" }, { level = 27, species = "VOLTORB" } },
            { { level = 25, species = "RATTATA" }, { level = 26, species = "RATICATE" }, { level = 27, species = "EKANS" } },
        },
        -- T3 (objetivo 26-29)
        {
            { { level = 30, species = "GRIMER" },   { level = 31, species = "ZUBAT" },   { level = 32, species = "MACHOP" } },
            { { level = 30, species = "KOFFING" },  { level = 31, species = "EKANS" },    { level = 32, species = "MEOWTH" } },
            { { level = 30, species = "VOLTORB" },  { level = 31, species = "DROWZEE" },  { level = 32, species = "GRIMER" } },
            { { level = 30, species = "SANDSHREW" }, { level = 31, species = "MACHOP" },  { level = 32, species = "ARBOK" } },
            { { level = 30, species = "RATICATE" }, { level = 31, species = "GOLBAT" },   { level = 32, species = "PERSIAN" } },
        },
        -- T4 (objetivo 30-33): equipo consolidado
        {
            { { level = 34, species = "SANDSHREW" }, { level = 35, species = "KOFFING" }, { level = 36, species = "ARBOK" } },
            { { level = 34, species = "MEOWTH" },    { level = 35, species = "GRIMER" },  { level = 36, species = "MACHOKE" } },
            { { level = 34, species = "VOLTORB" },   { level = 35, species = "DROWZEE" }, { level = 36, species = "GOLBAT" } },
            { { level = 34, species = "RATICATE" },  { level = 35, species = "MUK" },     { level = 36, species = "HYPNO" } },
            { { level = 34, species = "NIDORINA" },  { level = 35, species = "WEEZING" }, { level = 36, species = "PERSIAN" } },
        },
        -- T5 (objetivo >= 34): los matones de GIOVANNI
        {
            { { level = 38, species = "RHYHORN" },   { level = 39, species = "PERSIAN" }, { level = 40, species = "NIDOQUEEN" } },
            { { level = 38, species = "MACHOKE" },   { level = 39, species = "GOLBAT" },  { level = 40, species = "ARBOK" } },
            { { level = 38, species = "DROWZEE" },   { level = 39, species = "ELECTRODE" }, { level = 40, species = "MUK" } },
            { { level = 38, species = "NIDOKING" },  { level = 39, species = "WEEZING" }, { level = 40, species = "RHYDON" } },
            { { level = 38, species = "HITMONCHAN" }, { level = 39, species = "HYPNO" },  { level = 40, species = "NIDOQUEEN" } },
        },
    }

    for i, parties in ipairs(TIER_PARTIES) do
        mod.content.trainers:register(TIER_TRAINERS[i], {
            id = TIER_TRAINERS[i],
            name = "Rocket",
            basePic = "OPP_ROCKET",
            baseMoney = 36,
            parties = parties,
        })
    end

    -- Las plantillas disponibles para un trainer id (para tirar al azar).
    local function tierParties(trainerId)
        for i, id in ipairs(TIER_TRAINERS) do
            if id == trainerId then return TIER_PARTIES[i] end
        end
        return TIER_PARTIES[1]
    end

    -- Nivel objetivo: piso por medallas (16 + 3*badges) pero nunca por debajo
    -- del promedio del equipo + 2, así escala también con tus POKéMON.
    local function targetLevel(game)
        local party = game and game.save and game.save.party or {}
        local sum, n = 0, 0
        for _, mon in ipairs(party) do
            if mon and mon.level then
                sum = sum + mon.level
                n = n + 1
            end
        end
        local avg = n > 0 and math.floor(sum / n) or 20
        local inv = game and game.save and game.save.inventory or {}
        local badges = 0
        for _, id in ipairs(BADGE_IDS) do
            if inv[id] then badges = badges + 1 end
        end
        local floor = 16 + badges * 3
        return math.max(floor, avg + 2)
    end

    local function tierTrainerId(game)
        local t = targetLevel(game)
        if t <= 21 then return TIER_TRAINERS[1] end
        if t <= 25 then return TIER_TRAINERS[2] end
        if t <= 29 then return TIER_TRAINERS[3] end
        if t <= 33 then return TIER_TRAINERS[4] end
        return TIER_TRAINERS[5]
    end

    -- =========================================================================
    -- 2. TEXTOS (EN al cargar; ES en game.ready si recomp-spanish está activo)
    -- =========================================================================

    mod.content.text:register("TEXT_STARTER_STORIES_ROCKET_AMBUSH",
        "You messed with the\nwrong team, kid.")
    mod.content.text:register("_RocketAmbushIntro",
        "So YOU'RE the one\nwho wrecked our\nLAVENDER base!\vYou're not walking\npast this one!")
    mod.content.text:register("_RocketAmbushWon",
        "Grr... fine.\vTake these and\ndon't come back\nto LAVENDER!")
    mod.content.text:register("_RocketCaptainIntro",
        "The one who\nhumiliated our\nbase...\vI won't let that\nslide.\vGet your team ready.\vI want a fair fight.")
    mod.content.text:register("_RocketCaptainWon",
        "Impressive.\vTake these and\ngo--before my\nbuddies show up!")
    mod.content.text:register("_RocketItemReceived",
        "{PLAYER} received\n{RAM:wStringBuffer}!")

    mod.events:on("game.ready", function(ev)
        local game = ev and ev.game
        local mods = game and game.mods and game.mods.mods
        local spanish = mods and mods["recomp-spanish"]
        if not (spanish and spanish.enabled) then return end
        local text = game.data and game.data.text
        if not text then return end

        text["TEXT_STARTER_STORIES_ROCKET_AMBUSH"] =
            "Te metiste con el\nequipo equivocado,\ncriatura."
        text._RocketAmbushIntro =
            "¡Con que TÚ eres el\nque arruinó nuestra\nbase en LAVANDA!\v¡No vas a pasar\npor aquí!"
        text._RocketAmbushWon =
            "Grr... está bien.\vToma esto y no\nvuelvas a LAVANDA."
        text._RocketCaptainIntro =
            "El que humilló\nnuestra base...\vNo lo dejaré\npasar.\vPrepara tu equipo.\vQuiero un combate\njusto."
        text._RocketCaptainWon =
            "Impresionante.\vToma esto y vete--\vantes de que lleguen\nlos demás."
        text._RocketItemReceived =
            "¡{PLAYER} recibió\n{RAM:wStringBuffer}!"
    end)

    -- =========================================================================
    -- 3. COMANDOS CUSTOM
    -- =========================================================================

    mod.content.commands:register("rocket_ambush:set_beat", function(ctx, mapId)
        setBeaten(routeKey(mapId))
    end)

    mod.content.commands:register("rocket_ambush:clear", function(ctx)
        local ow = ctx.overworld
        local mapId = ow and ow.map and ow.map.id
        if mapId and ROUTE_SET[mapId] then clearGrunt(mapId) end
    end)

    -- =========================================================================
    -- 4. COLOCACIÓN DINÁMICA (spawnNpc en tile libre aleatorio)
    -- =========================================================================

    -- Escanea mapOverview: '.' = caminable, '+' = warp, '~' = agua, ' ' = bloq.
    -- Devuelve un tile caminable a 3-10 celdas del jugador, sin NPCs encima.
    local function pickFreeTile(px, py)
        local overview = mod.world:mapOverview()
        if not overview or not overview.rows then return nil end
        local rows = overview.rows
        local candidates = {}
        local function collect(minD, maxD)
            for y = 0, #rows - 1 do
                local row = rows[y + 1]
                for x = 0, #row - 1 do
                    if row:sub(x + 1, x + 1) == "." then
                        local d = math.max(math.abs(x - px), math.abs(y - py))
                        if d >= minD and d <= maxD then
                            candidates[#candidates + 1] = { x = x, y = y }
                        end
                    end
                end
            end
        end
        collect(3, 10)
        if #candidates == 0 then collect(2, 14) end
        if #candidates == 0 then return nil end

        local ow = mod.world:overworld()
        local free = {}
        for _, c in ipairs(candidates) do
            if not ow:npcAtCell(c.x, c.y)
               and not (c.x == px and c.y == py) then
                free[#free + 1] = c
            end
        end
        if #free == 0 then return nil end
        return free[math.random(#free)]
    end

    -- Facing aleatorio al spawn: el grunt "vigila" un lado de la ruta. Solo
    -- embosca si te le acercas de FRENTE (línea de visión); puedes colarte
    -- por la espalda o el lateral.
    local FACINGS = { "UP", "DOWN", "LEFT", "RIGHT" }

    local function spawnGrunt(mapId, px, py)
        local tile = pickFreeTile(px, py)
        if not tile then
            mod.log:info("rocket_ambush: no free tile on %s", mapId)
            return
        end
        local captain = math.random() <= CAPTAIN_CHANCE
        local trainerId = tierTrainerId(mod.world.game)
        -- Plantilla al azar (para el combate por hablar vanilla también varíe).
        local partyIndex = math.random(#tierParties(trainerId))
        local npcId = mod.world:spawnNpc(mapId, {
            name = "STARTER_STORIES_ROCKET_AMBUSH_" .. mapId,
            text = "TEXT_STARTER_STORIES_ROCKET_AMBUSH",
            sprite = "SPRITE_ROCKET",
            x = tile.x,
            y = tile.y,
            movement = "STAY",
            range = FACINGS[math.random(#FACINGS)],
            trainerClass = trainerId,
            trainerParty = partyIndex,
        })
        if npcId then
            spawned[mapId] = { npcId = npcId, captain = captain }
            mod.log:info("rocket_ambush: %s grunt at (%d,%d) trainer=%s party=%d captain=%s",
                         mapId, tile.x, tile.y, trainerId, partyIndex, tostring(captain))
        end
    end

    mod.events:on("map.entered", function(ev)
        if not mod.world then return end
        local mapId = ev and ev.mapId
        if not (mapId and ROUTE_SET[mapId]) then return end
        if not lavenderFinaleDone() then
            mod.log:info("rocket_ambush: %s sin spawn (finale de Lavender pendiente)", mapId)
            return
        end
        -- Team Rocket disuelto (GIOVANNI vencido): se acabaron las emboscadas.
        if rocketDisbanded(mod.world.game) then
            clearGrunt(mapId)
            mod.log:info("rocket_ambush: %s sin spawn (Team Rocket disuelto)", mapId)
            return
        end
        local cleared = beaten(routeKey(mapId))
        -- Primera vez en la ruta: el grunt SIEMPRE aparece. Revisita a una
        -- ruta ya despejada: solo reaparece con probabilidad (farming de
        -- recompensas mientras dure la ventana narrativa).
        if cleared then
            if math.random() > REVISIT_CHANCE then return end
        end

        -- Reubicación dinámica: cada vez que entras, el grunt puede estar en
        -- un sitio distinto.
        clearGrunt(mapId)
        if math.random() > SPAWN_CHANCE then return end

        local pos = mod.world:current()
        if not pos or pos.mapId ~= mapId then return end
        spawnGrunt(mapId, pos.x, pos.y)
    end)

    -- =========================================================================
    -- 5. EMBOSCADA (onStep, patrón runGruntAmbush de lavender)
    -- =========================================================================

    local function indexOfNpcId(npcId)
        local idx = npcId and npcId:match("_(%d+)$")
        return idx and tonumber(idx) or nil
    end

    local function ambushOnStep(game, ow, x, y, mapId)
        if ow.runner:isRunning() then return false end
        -- Team Rocket disuelto: retira cualquier grunt que quede en la ruta.
        if rocketDisbanded(game) then
            clearGrunt(mapId)
            return false
        end

        local entry = spawned[mapId]
        if not entry then return false end
        if ow.map.id ~= mapId then return false end

        local npcId = entry.npcId

        -- Si ya se le venció por talk (ruta vanilla del entrenador), limpia.
        if game.save.defeatedTrainers and game.save.defeatedTrainers[npcId] then
            setBeaten(routeKey(mapId))
            clearGrunt(mapId)
            return false
        end

        local handle = mod.world:npc(ow.map.id, npcId)
        if not handle or not handle.npc then return false end
        if handle.npc.moving then return false end

        local gx, gy = handle:position()
        local dx = x - gx
        local dy = y - gy
        -- Línea de visión del grunt (como un trainer vanilla): solo te
        -- intercepta si estás ENFRENTE de su facing, a max 2 celdas. Si lo
        -- rodeas por la espalda o el lateral, pasas de largo sin combate.
        local dir = handle.npc.facing
        local dist
        if dir == "up" or dir == "down" then
            if dx ~= 0 then return false end
            dist = dy * (dir == "down" and 1 or -1)
        else
            if dy ~= 0 then return false end
            dist = dx * (dir == "right" and 1 or -1)
        end
        if dist < 1 or dist > 2 then return false end

        -- Embestida de 1 paso hacia ti (dist-1). Solo avanza si el tile está
        -- libre: nada de caminar "raro" a través de árboles o sobre ti.
        local walkDir = dir
        local walkSteps = dist - 1
        if walkSteps > 0 then
            local vec = dir == "up" and { 0, -1 }
                or dir == "down" and { 0, 1 }
                or dir == "left" and { -1, 0 }
                or { 1, 0 }
            local tx = gx + vec[1] * walkSteps
            local ty = gy + vec[2] * walkSteps
            if not ow.map:isWalkableCell(tx, ty)
               or (tx == x and ty == y) then
                walkSteps = 0
            end
        end

        -- El jugador se gira hacia el grunt (facing opuesto al suyo).
        ow.player.facing = dir == "up" and "down"
            or dir == "down" and "up"
            or dir == "left" and "right"
            or "left"

        local cfg = entry.captain and CAPTAIN_CFG or REGULAR_CFG
        local trainerId = tierTrainerId(game)
        -- Plantilla al azar entre las 5 del nivel: nunca el mismo equipo.
        local partyIndex = math.random(#tierParties(trainerId))
        local rows = {
            { "stop_music" },
            { "play_music", GRUNT_MUSIC },
            { "emote", "player", "shock", 30 },
            { "wait", 20 },
            { "move_npc", indexOfNpcId(npcId), walkDir, walkSteps },
            { "face_player" },
            { "show_text", cfg.intro },
        }
        -- El "capitán" te cura antes del combate (combate justo).
        if cfg.heal then
            rows[#rows + 1] = { "heal_party" }
        end
        rows[#rows + 1] = { "start_battle", "trainer", trainerId, partyIndex }
        rows[#rows + 1] = { "check_battle_result", "win" }
        rows[#rows + 1] = { "jump_if_false", "end_ambush" }
        rows[#rows + 1] = { "show_text", cfg.won }
        -- Limpieza ANTES del reparto de ítems: si la mochila está llena,
        -- give_item corta el guion (math.huge), así el grunt ya quedó
        -- retirado y la música de la ruta restaurada.
        rows[#rows + 1] = { "rocket_ambush:set_beat", mapId }
        rows[#rows + 1] = { "rocket_ambush:clear" }
        rows[#rows + 1] = { "play_default_music" }
        -- Recompensas variadas: cada slot tira de un pool con pesos y se
        -- muestra su aviso de recogida ("Red received POKE BALL!") con jingle.
        for _, item in ipairs(rollRewards(cfg)) do
            rows[#rows + 1] = { "give_item", item, 1, "_RocketItemReceived" }
        end
        rows[#rows + 1] = { "label", "end_ambush" }

        ow.runner:run(rows, { npc = handle.npc })
        return true
    end

    for _, mapId in ipairs(ROUTE_MAPS) do
        mod.content.map_scripts:register(mapId, {
            onStep = function(game, ow, x, y)
                return ambushOnStep(game, ow, x, y, mapId)
            end,
        })
    end

end