return function(mod)

    -- =========================================================================
    -- 0. ESTADO DE LA MISIÓN
    --
    -- charmander_stage:
    --   0 = misión no iniciada
    --   1 = chico encontrado y diálogo iniciado (usado transitoriamente o por consistencia)
    --   2 = chico listo para acompañar al jugador (esperando Charmander)
    --   3 = Charmander requerido encontrado o confirmado (capturado en B1F)
    --   4 = chico acompañando al jugador (follower activo lógicamente)
    --   5 = misión completada
    -- =========================================================================

    local STAGE_KEY = "charmander_stage"
    local ROUTE_KEY = "charmander_route"
    local FOUND_KEY = "charmander_found"
    local FAREWELL_KEY = "charmander_farewell"
    local COMPLETED_KEY = "charmander_completed"
    local LIGHT_OWNED_KEY = "charmander_light_owned"
    local LIGHT_PREVIOUS_KEY = "charmander_light_previous"
    local RADIAL_KEY = "charmander_radial_light"
    local CUSTOM_LIGHT_ENABLED = true
    local lightMapApplied = nil

    local AMBUSHES = {
        { map = "ROCK_TUNNEL_B1F", x = 17, y = 9,  index = 92, species = "ZUBAT",   level = 17, key = "charmander_ambush_1", name = "CHARMANDER_AMBUSH_1" },
        { map = "ROCK_TUNNEL_B1F", x = 13, y = 17, index = 93, species = "GEODUDE", level = 17, key = "charmander_ambush_2", name = "CHARMANDER_AMBUSH_2" },
        { map = "ROCK_TUNNEL_B1F", x = 9,  y = 26, index = 94, species = "MACHOP",  level = 18, key = "charmander_ambush_3", name = "CHARMANDER_AMBUSH_3" },
        { map = "ROCK_TUNNEL_B1F", x = 3,  y = 14, index = 95, species = "GRAVELER",level = 18, key = "charmander_ambush_4", name = "CHARMANDER_AMBUSH_4" },
        { map = "ROCK_TUNNEL_1F",  x = 16, y = 26, index = 92, species = "ZUBAT",   level = 17, key = "charmander_ambush_5", name = "CHARMANDER_AMBUSH_5" },
        { map = "ROCK_TUNNEL_1F",  x = 31, y = 28, index = 93, species = "ONIX",    level = 19, key = "charmander_ambush_6", name = "CHARMANDER_AMBUSH_6" },
    }

    local AMBUSH_LINES = {
        "That PokÃ©mon seemed drawn to the flame of your Charmander.",
        "Careful! The cave PokÃ©mon are watching us.",
        "It looks like your Charmander made a new friend... or a rival!",
    }

    local function getState(key, default)
        return mod.save:get("mod:" .. key, default)
    end

    local function setState(key, value)
        mod.save:set("mod:" .. key, value)
    end

    -- =========================================================================
    -- 1. DETECCIÓN DEL STARTER Y LÍNEA EVOLUTIVA
    -- =========================================================================

    local function choseCharmander(game)
        local flags = game and game.save and game.save.flags
        return not not (flags and flags.EVENT_CHOSE_CHARMANDER)
    end

    local function hasStarter(game)
        local flags = game and game.save and game.save.flags
        return not not (flags and flags.EVENT_GOT_STARTER)
    end

    local function hasCharmanderLine(game)
        local party = game and game.save and game.save.party or {}
        for _, mon in ipairs(party) do
            if mon.species == "CHARMANDER" or mon.species == "CHARMELEON" or mon.species == "CHARIZARD" then
                return true
            end
        end

        return false
    end


    local function isCave(mapId)
        return mapId and (mapId:match("^ROCK_TUNNEL")
            or mapId:match("^MT_MOON")
            or mapId:match("^CERULEAN_CAVE")
            or mapId:match("^DIGLETTS_CAVE")
            or mapId:match("^SEAFOAM_ISLANDS")
            or mapId:match("^VICTORY_ROAD"))
    end

    local function isCharmanderCave(mapId)
        return mapId == "ROCK_TUNNEL_1F" or mapId == "ROCK_TUNNEL_B1F"
    end

    local function shouldCharmanderLight(game)
        -- Solo ilumina la cueva si hay un Charmander (o evolución) EN LA PARTY
        -- activa. Fijarlo en la caja / soltarlo apaga la luz y detiene las
        -- emboscadas (consistente con el follower). Sin caché por stage: la
        -- party puede cambiar sin que cambie el stage.
        local stage = getState(STAGE_KEY, 0)
        return stage >= 3 and stage < 5 and hasCharmanderLine(game)
    end



    local lightShader
    local function getLightShader()
        if not lightShader then
            lightShader = love.graphics.newShader([[
                extern vec2 lightPos;
                extern float lightRadius;
                extern vec4 darknessColor;

                vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
                    float dist = distance(screen_coords, lightPos);
                    float intensity = smoothstep(lightRadius * 0.35, lightRadius, dist);
                    return vec4(darknessColor.rgb, darknessColor.a * intensity);
                }
            ]])
        end
        return lightShader
    end

    local OverworldController = require("src.world.OverworldController")
    if OverworldController._vanillaPlusSetMapWrap then
        OverworldController.setMap = OverworldController._vanillaPlusOriginalSetMap
    end
    local old_setMap = OverworldController.setMap
    OverworldController._vanillaPlusOriginalSetMap = old_setMap
    OverworldController.setMap = function(self, mapId, x, y, facing, opts)
        local game = mod.world and mod.world.game
        local override = false
        -- Auto-light the cave when entering if Charmander is following.
        -- We do this by temporarily spoofing flashLit during the setMap call
        -- so the engine builds the map fully bright, but we restore it immediately
        -- so Flash remains available in Pikachu's menu.
        if game and CUSTOM_LIGHT_ENABLED and isCharmanderCave(mapId) and shouldCharmanderLight(game) then
            if not game.save.flashLit then
                override = true
                game.save.flashLit = true
            end
        end

        old_setMap(self, mapId, x, y, facing, opts)

        if override then
            game.save.flashLit = false
            -- old_setMap will have called self:setDark(false) because flashLit was true,
            -- which sets self.dark = false. We must set it back to true so the 
            -- native PartyMenu still allows the use of the Flash item!
            self.dark = true
        end
    end
    OverworldController._vanillaPlusSetMapWrap = true

    if OverworldController._vanillaPlusDrawWorldWrap then
        OverworldController.drawWorld = OverworldController._vanillaPlusOriginalDrawWorld
    end
    local old_drawWorld = OverworldController.drawWorld
    OverworldController._vanillaPlusOriginalDrawWorld = old_drawWorld
    OverworldController.drawWorld = function(self)
        local game = mod.world and mod.world.game
        local spoofed_dark = false

        if game and CUSTOM_LIGHT_ENABLED and isCharmanderCave(self.map and self.map.id) and shouldCharmanderLight(game) then
            -- Si la cueva está oscurecida naturalmente (self.dark), pero Charmander
            -- debe iluminarla, engañamos a drawWorld para que la dibuje brillante.
            if not game.save.flashLit and self.dark then
                self.dark = false
                spoofed_dark = true
            end
        end

        old_drawWorld(self)

        if spoofed_dark then
            self.dark = true
        end
    end
    OverworldController._vanillaPlusDrawWorldWrap = true

    local function drawCharmanderLight(game, viewport)
        if not CUSTOM_LIGHT_ENABLED then return end
        local ow = game and game.overworld
        if not (ow and ow.isOverworld and ow.map and ow.player) then return end
        
        if not (isCharmanderCave(ow.map.id) and shouldCharmanderLight(game)) then
            return
        end

        -- Si el jugador activó el Destello (Flash) manualmente, game.save.flashLit será true.
        -- En ese caso, la máscara desaparece completamente.
        if game.save.flashLit then
            return
        end

        -- El overworld sigue debajo de batallas y menus, pero la linterna no
        -- debe pintarse encima de esos estados.
        local top = game.stack and game.stack:top()
        -- render.hud runs after the complete composite. Menu states do not all
        -- declare isOpaque, so comparing the active state directly is the
        -- reliable guard: only the live overworld may receive the cave mask.
        if top and top ~= ow then return end

        local g = love.graphics
        local ox = (viewport and viewport.gameX) or 0
        local oy = (viewport and viewport.gameY) or 0
        local cam = ow.camera
        if not cam then return end

        -- The HUD hook runs after Renderer:endFrame, while the overworld was
        -- rendered with the world canvas (which may be larger than the 160x144
        -- UI canvas during zoom-out). Reuse the renderer's world dimensions and
        -- scale so the light uses the same transform as the player sprite.
        local renderer = game.renderer
        local worldW, worldH = renderer:worldViewSize()
        local screenW, screenH = love.graphics.getDimensions()
        local scale = (viewport and viewport.scale) or 1
        local dpiX = (viewport and viewport.dpiX) or 1
        local dpiY = (viewport and viewport.dpiY) or 1
        local sx, sy = scale / dpiX, scale / dpiY
        local worldOx = (screenW - worldW * scale) / (2 * dpiX)
        local worldOy = (screenH - worldH * scale) / (2 * dpiY)
        local cx = worldOx + (ow.player.px - cam.x + 8) * sx
        local cy = worldOy + (ow.player.py - cam.y + 8) * sy
        -- A 6.75-cell radius covers the player, the kid and Charmander,
        -- with a small amount of breathing room around the group.
        local radius = 16.75 * 16 * math.min(sx, sy)
        local shader = getLightShader()
        g.push("all")
        g.setShader(shader)
        shader:send("lightPos", {cx, cy})
        shader:send("lightRadius", radius)
        shader:send("darknessColor", {0, 0, 0, 0.95})
        local screenW, screenH = love.graphics.getDimensions()
        g.rectangle("fill", 0, 0, screenW, screenH)
        g.pop()

    end

    -- =========================================================================
    -- 2. COMANDOS CUSTOM
    -- =========================================================================

    mod.content.commands:register("charmander:set_stage", function(ctx, value)
        local stage = tonumber(value) or 0
        setState(STAGE_KEY, stage)
    end)

    mod.content.commands:register("charmander:check_stage", function(ctx, value)
        if getState(STAGE_KEY, 0) == (tonumber(value) or -1) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    mod.content.commands:register("charmander:set_route", function(ctx, value)
        setState(ROUTE_KEY, tostring(value))
    end)

    mod.content.commands:register("charmander:check_route", function(ctx, value)
        if getState(ROUTE_KEY, "") == tostring(value) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    mod.content.commands:register("charmander:set_found", function(ctx, value)
        setState(FOUND_KEY, value == "true" or value == true)
    end)

    mod.content.commands:register("charmander:check_found", function(ctx)
        if getState(FOUND_KEY, false) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    mod.content.commands:register("charmander:check_chose_charmander", function(ctx)
        if choseCharmander(ctx.game) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    mod.content.commands:register("charmander:check_has_charmander_line", function(ctx)
        if hasCharmanderLine(ctx.game) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    mod.content.commands:register("charmander:check_has_starter", function(ctx)
        if hasStarter(ctx.game) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    mod.content.commands:register("charmander:check_ambush", function(ctx, key)
        ctx.lastCheck = getState(tostring(key), false) and true or false
    end)


    mod.content.commands:register("charmander:set_ambush", function(ctx, key)
        setState(tostring(key), true)
    end)

    -- Marca temporal de "disturbado": tras luchar contra una emboscada sin
    -- atraparla, no vuelve a abalanzarse en la misma visita (evita el bucle
    -- inmediato tras el reload de batalla).  Se limpia al cambiar de mapa.
    mod.content.commands:register("charmander:set_disturbed", function(ctx, key)
        setState(tostring(key) .. "_disturbed", true)
    end)

    -- Coloca al chico frente al jugador (hacia la franja de salida) y al
    -- sprite de Charmander a su lado para la escena de despedida. Usa el NPC
    -- runtime del follower (o lo crea) para no depender del índice dinámico.
    local CHARMANDER_FOLLOWER_NAME = "STARTER_STORIES_CHARMANDER_FOLLOWER"
    mod.content.commands:register("charmander:farewell_setup", function(ctx)
        local ow = ctx.overworld
        if not (ow and ow.map and ow.map.id == "ROCK_TUNNEL_1F" and ow.player) then return end
        local fx = ow.player.cellX
        local fy = math.min(ow.player.cellY + 1, ow.map.heightCells - 1)
        local kid = ow:npcByIndex(90)
        if kid then
            kid.cellX, kid.cellY = fx, fy
            kid.px, kid.py = fx * 16, fy * 16
            kid.targetX, kid.targetY = nil, nil
            kid.moving = false
            kid.facing = "up"
        end
        local char = mod.world:npc("ROCK_TUNNEL_1F", CHARMANDER_FOLLOWER_NAME)
        if not char then
            mod.world:spawnNpc("ROCK_TUNNEL_1F", {
                name = CHARMANDER_FOLLOWER_NAME,
                sprite = "SPRITE_FOLLOWER_CHARMANDER",
                x = fx + 1,
                y = fy,
                movement = "STAY",
                range = "DOWN",
                hidden = false,
            })
            char = mod.world:npc("ROCK_TUNNEL_1F", CHARMANDER_FOLLOWER_NAME)
        end
        if char then
            char.npc.passable = true
            char.npc.cellX, char.npc.cellY = math.min(fx + 1, ow.map.widthCells - 1), fy
            char.npc.px, char.npc.py = char.npc.cellX * 16, char.npc.cellY * 16
            char.npc.targetX, char.npc.targetY = nil, nil
            char.npc.moving = false
            char.npc.facing = "up"
        end
    end)

    -- Retira el Charmander runtime de la escena al terminar la despedida
    -- (el follower deja de actualizarlo con stage 5).
    mod.content.commands:register("charmander:farewell_cleanup", function(ctx)
        local ow = ctx.overworld
        local mapId = ow and ow.map and ow.map.id
        if not mapId then return end
        local char = mod.world:npc(mapId, CHARMANDER_FOLLOWER_NAME)
        if char then
            mod.world:removeNpc(char.id)
        end
    end)

    -- =========================================================================
    -- 3. SPRITE DE CHARMANDER
    -- =========================================================================

    mod.content.sprites:register("SPRITE_FOLLOWER_CHARMANDER", {
        id = "SPRITE_FOLLOWER_CHARMANDER",
        image = mod.assets:path("assets/poke_followers/follower_004.png"),
        frames = 6,
        walker = true,
        trueColor = true,
    })

    -- Sprites de los Pokemon que aparecen en los ambush.  El pack ya incluye
    -- las 151 crias (follower_###.png, donde ### es el numero de Pokedex).
    local function registerFollowerSprite(id, path)
        mod.content.sprites:register(id, {
            id = id,
            image = mod.assets:path(path),
            frames = 6,
            walker = true,
            trueColor = true,
        })
    end

    registerFollowerSprite("SPRITE_FOLLOWER_ZUBAT", "assets/poke_followers/follower_041.png")
    registerFollowerSprite("SPRITE_FOLLOWER_GEODUDE", "assets/poke_followers/follower_074.png")
    registerFollowerSprite("SPRITE_FOLLOWER_MACHOP", "assets/poke_followers/follower_066.png")
    registerFollowerSprite("SPRITE_FOLLOWER_GRAVELER", "assets/poke_followers/follower_075.png")
    registerFollowerSprite("SPRITE_FOLLOWER_ONIX", "assets/poke_followers/follower_095.png")

    -- =========================================================================
    -- 4. TEXTOS BASE (INGLÉS)
    -- =========================================================================

    -- Textos Ruta A
    mod.content.text:register("_CharKidIntroA1", "Um... excuse me...\vI really need to\ncross the ROCK\nTUNNEL, but...\fIt's so dark inside!\nNone of my POKéMON\ncan light the way.")
    mod.content.text:register("_CharKidIntroA2", "Oh, I see! You have\na POKéMON from the\nCHARMANDER line.\vDo you think you\ncould cross with\nme?")
    mod.content.text:register("_CharKidAWait", "Please put it in\nyour party so we\ncan see in the dark!")
    mod.content.text:register("_CharKidAJoin", "Thank you so much!\nWith your POKéMON,\nwe'll be fine.\vLet's go!")

    mod.content.text:register("_CharKidDeclined", "Oh... I understand.\\nI'll wait here.")

    -- Textos Ruta B
    mod.content.text:register("_CharKidIntroB1", "Um... excuse me...\vI really need to\ncross the ROCK\nTUNNEL, but...\fIt's so dark inside!\nNone of my POKéMON\ncan light the way.")
    mod.content.text:register("_CharKidIntroB2", "I saw a CHARMANDER\ngo into the cave\nearlier.\vIt was probably\nlooking for shelter\nfrom the cold.\fMaybe that POKéMON\ncould help us...\vCould you go check?")
    mod.content.text:register("_CharKidBWait", "Please find that\nCHARMANDER in the\ncave!\vI'll wait right\nhere.")
    mod.content.text:register("_CharKidBFound", "You caught that\nCHARMANDER!\vNow we have some\nlight to cross the\ntunnel.\vLet's go together!")

    -- Textos comunes
    mod.content.text:register("_CharKidFollowing", "It's not so scary\nwhen you're not\nalone!")

    mod.content.text:register("_CharKidAmbush1", AMBUSH_LINES[1])
    mod.content.text:register("_CharKidAmbush2", AMBUSH_LINES[2])
    mod.content.text:register("_CharKidAmbush3", AMBUSH_LINES[3])
    for i = 1, #AMBUSHES do
        mod.content.text:register("TEXT_CHARMANDER_AMBUSH_" .. i, "...")
    end

    -- Textos Charmander salvaje
    mod.content.text:register("_CharWildEncounter", "CHARMANDER looks\nlost and cold in\nthe dark tunnel...")

    -- Textos de la despedida (Fase F): trigger en la franja de la salida sur
    mod.content.text:register("_CharKidFarewell1", "This is where\nwe part ways.\vThe way out of the\ntunnel is right\nover there.\vThank you for\nescorting me here!")
    mod.content.text:register("_CharKidFarewell2", "I'm not scared\nanymore.\vMy CHARMANDER will\nstay by your side\nnow.\vYou two have grown\nso close!")
    mod.content.text:register("_CharKidFarewell3", "I'll take this as\na memento.\vTake care of\nmy CHARMANDER.\vGood luck on your\njourney!")

    -- =========================================================================
    -- 5. TRADUCCIÓN AL ESPAÑOL (RUNTIME)
    -- =========================================================================

    mod.events:on("game.ready", function(ev)
        local game = ev and ev.game
        local mods = game and game.mods and game.mods.mods
        local spanish = mods and mods["recomp-spanish"]

        if not (spanish and spanish.enabled) then
            return
        end

        local text = game.data and game.data.text
        if not text then return end

        text._CharKidAmbush1 = "Ese Pokemon parecia atraido\npor la llama de tu Charmander."
        text._CharKidAmbush2 = "Cuidado! Los Pokemon\nde la cueva nos observan."
        text._CharKidAmbush3 = "Parece que tu Charmander\nse gano un amigo... o rival!"

        text._CharKidIntroA1 = "Emm... disculpa...\vNecesito cruzar el\nTÚNEL ROCA, pero...\f¡Está muy oscuro!\nNinguno de mis\nPOKéMON brilla."
        text._CharKidIntroA2 = "¡Ah, ya veo! Tienes\nun POKéMON de la\nlínea de CHARMANDER.\v¿Crees que podrías\ncruzar conmigo?"
        text._CharKidAWait = "¡Por favor ponlo en\ntu equipo para que\npodamos ver algo!"
        text._CharKidAJoin = "¡Muchas gracias!\nCon tu POKéMON,\nestaremos bien.\v¡Vamos!"

        text._CharKidIntroB1 = "Emm... disculpa...\vNecesito cruzar el\nTÚNEL ROCA, pero...\f¡Está muy oscuro!\nNinguno de mis\nPOKéMON brilla."
        text._CharKidIntroB2 = "Vi un CHARMANDER\nentrar a la cueva\nhace un rato.\vSeguro buscaba\nrefugio del frío.\fQuizá ese POKéMON\nnos pueda ayudar...\v¿Podrías ir a ver?"
        text._CharKidBWait = "¡Por favor busca a\nese CHARMANDER en\nla cueva!\vYo esperaré justo\naquí."
        text._CharKidBFound = "¡Atrapaste a ese\nCHARMANDER!\vAhora tenemos luz\npara cruzar el\ntúnel.\v¡Vamos juntos!"

        text._CharKidFollowing = "¡No da tanto miedo\ncuando no estás\nsolo!"
        text._CharWildEncounter = "CHARMANDER parece\nperdido y con frío\nen el túnel oscuro..."
        text._CharKidFarewell1 = "Este es el final\nde nuestro camino.\vLa salida de la\ncueva está allí.\f¡Gracias por\ncaminar conmigo!"
        text._CharKidFarewell2 = "Ya no tengo miedo.\vMi CHARMANDER\nquerrá quedarse\na tu lado.\fHan hecho muy\nbuena pareja!"
        text._CharKidFarewell3 = "Lo guardaré como\nrecuerdo.\vCuida bien de mi\nCHARMANDER.\f¡Buena suerte en\ntu viaje!"
    end)

    local function ambushRows(mapId, visible)
        local rows = {}
        for _, ambush in ipairs(AMBUSHES) do
            if ambush.map == mapId then
                local done = getState(ambush.key, false)
                rows[#rows + 1] = {
                    visible and not done and "show_object" or "hide_object",
                    mapId,
                    "CHARMANDER_AMBUSH_" .. tostring(ambush.key:match("%d+")),
                }
            end
        end
        return rows
    end

        -- Rango (distancia Manhattan) desde el que una emboscada te ve y se lanza.
    local AMBUSH_RANGE = 4

    -- Celda a la que abalanzarse: la vecina del jugador mas cercana al punto
    -- de origen de la emboscada (andable y desocupada). Si ninguna sirve, se
    -- apunta a la celda del propio jugador (bfsPath la trata como exenta).
    local function lungeTarget(ow, ambush, npc, px, py)
        local candidates = { { 0, 1 }, { 0, -1 }, { -1, 0 }, { 1, 0 } }
        local bestX, bestY, bestDist
        for _, d in ipairs(candidates) do
            local nx, ny = px + d[1], py + d[2]
            if ow.map:inBounds(nx, ny) and ow.map:isWalkableCell(nx, ny) then
                local occupied = false
                for _, e in ipairs(ow.entities or {}) do
                    if e ~= npc and e.cellX == nx and e.cellY == ny then
                        occupied = true
                        break
                    end
                end
                if not occupied then
                    local dist = math.abs(nx - ambush.x) + math.abs(ny - ambush.y)
                    if not bestX or dist < bestDist then
                        bestX, bestY, bestDist = nx, ny, dist
                    end
                end
            end
        end
        if bestX then return bestX, bestY end
        return px, py
    end

    -- Las emboscadas te ven dentro de AMBUSH_RANGE y se abalanzan sobre ti:
    -- "!" de sorpresa, grito, carrera hasta tu lado y batalla salvaje. Si no
    -- las atrapas quedan "disturbadas" (no re-aggro en la misma visita).
    local function tryAmbush(game, ow, mapId, x, y)
        if getState(STAGE_KEY, 0) ~= 4 or ow.runner:isRunning()
            or not hasCharmanderLine(game) then
            return false
        end
        local bestI, bestAmbush, bestDist
        for i, ambush in ipairs(AMBUSHES) do
            if ambush.map == mapId
                and not getState(ambush.key, false)
                and not getState(ambush.key .. "_disturbed", false) then
                local dist = math.abs(x - ambush.x) + math.abs(y - ambush.y)
                if dist <= AMBUSH_RANGE and (not bestI or dist < bestDist) then
                    bestI, bestAmbush, bestDist = i, ambush, dist
                end
            end
        end
        if not bestI then return false end

        local ambush = bestAmbush
        local objectName = ambush.name
        local dialogueId = "_CharKidAmbush" .. tostring(((bestI - 1) % 3) + 1)
        local npc = ow:npcByIndex(ambush.index)
        local tx, ty = lungeTarget(ow, ambush, npc, x, y)

        local started = ow:queueScript({
            { "emote", ambush.index, "shock" },
            { "play_cry", ambush.species },
            { "move_npc_to", ambush.index, tx, ty },
            { "start_battle", "wild", ambush.species, ambush.level },
            { "check_battle_result", "caught" },
            { "jump_if_false", "not_caught" },
            { "charmander:set_ambush", ambush.key },
            { "hide_object", mapId, objectName },
            { "show_text", dialogueId },
            { "jump", "end" },
            { "label", "not_caught" },
            { "charmander:set_disturbed", ambush.key },
            { "label", "end" },
        })
        return started and true or false
    end

    -- Al cambiar de mapa (salida real, no reload en sitio) se rearman las
    -- emboscadas disturbadas para la proxima visita a la cueva.
    mod.events:on("map.exited", function(ev)
        if not ev or ev.mapId == ev.toMapId then return end
        for _, ambush in ipairs(AMBUSHES) do
            setState(ambush.key .. "_disturbed", false)
        end
    end)

    -- Fase F — cinemática de despedida del chico.
    -- Trigger: franja de la salida sur de ROCK_TUNNEL_1F (x≈15, y≥31),
    -- justo antes de la escalera hacia ROUTE_10. Solo con stage 4 y una vez.
    local function tryFarewell(game, ow, x, y)
        if getState(STAGE_KEY, 0) ~= 4 then return false end
        if not hasCharmanderLine(game) then return false end
        if getState(FAREWELL_KEY, false) then return false end
        if x < 14 or x > 16 or y < 31 or y > 35 then return false end
        if ow.runner:isRunning() then return false end

        setState(FAREWELL_KEY, true)
        ow:queueScript({
            { "face_player_dir", "down" },
            { "charmander:farewell_setup" },
            { "face_object", 90, "up" },
            { "show_text", "_CharKidFarewell1" },
            { "play_cry", "CHARMANDER" },
            { "show_text", "_CharKidFarewell2" },
            { "emote", 90, "happy" },
            { "show_text", "_CharKidFarewell3" },
            { "move_npc", 90, "down", 2 },
            { "charmander:farewell_cleanup" },
            { "charmander:set_stage", 5 },
            { "hide_object", "ROCK_TUNNEL_1F", "STARTER_STORIES_CHARMANDER_KID" },
            { "give_item", "RARE_CANDY", 1 },
        })
        return true
    end

    -- =========================================================================
    -- 6. OBJETOS DE MAPA
    -- =========================================================================

    mod.content.maps:patch("ROUTE_10", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_CHARMANDER_KID",
                    text = "TEXT_STARTER_STORIES_CHARMANDER_KID",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 2,
                    y = 21,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("ROCK_TUNNEL_1F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_CHARMANDER_KID",
                    text = "TEXT_STARTER_STORIES_CHARMANDER_KID",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 16,
                    y = 3,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
                { index = 92, name = "CHARMANDER_AMBUSH_5", text = "TEXT_CHARMANDER_AMBUSH_5", sprite = "SPRITE_FOLLOWER_ZUBAT", x = 16, y = 26, movement = "STAY", range = "DOWN", hidden = true },
                { index = 93, name = "CHARMANDER_AMBUSH_6", text = "TEXT_CHARMANDER_AMBUSH_6", sprite = "SPRITE_FOLLOWER_ONIX", x = 31, y = 28, movement = "STAY", range = "DOWN", hidden = true },
            },
        },
    })

    mod.content.maps:patch("ROCK_TUNNEL_B1F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_CHARMANDER_KID",
                    text = "TEXT_STARTER_STORIES_CHARMANDER_KID",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 11,
                    y = 14,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
                {
                    index = 91,
                    name = "STARTER_STORIES_CHARMANDER_WILD",
                    text = "TEXT_STARTER_STORIES_CHARMANDER_WILD",
                    sprite = "SPRITE_FOLLOWER_CHARMANDER",
                    x = 37,
                    y = 2,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
                { index = 92, name = "CHARMANDER_AMBUSH_1", text = "TEXT_CHARMANDER_AMBUSH_1", sprite = "SPRITE_FOLLOWER_ZUBAT", x = 17, y = 9, movement = "STAY", range = "DOWN", hidden = true },
                { index = 93, name = "CHARMANDER_AMBUSH_2", text = "TEXT_CHARMANDER_AMBUSH_2", sprite = "SPRITE_FOLLOWER_GEODUDE", x = 13, y = 17, movement = "STAY", range = "DOWN", hidden = true },
                { index = 94, name = "CHARMANDER_AMBUSH_3", text = "TEXT_CHARMANDER_AMBUSH_3", sprite = "SPRITE_FOLLOWER_MACHOP", x = 9, y = 26, movement = "STAY", range = "DOWN", hidden = true },
                { index = 95, name = "CHARMANDER_AMBUSH_4", text = "TEXT_CHARMANDER_AMBUSH_4", sprite = "SPRITE_FOLLOWER_GRAVELER", x = 3, y = 14, movement = "STAY", range = "DOWN", hidden = true },
            },
        },
    })

    -- =========================================================================
    -- 7. SCRIPTS DE MAPA
    -- =========================================================================

    mod.content.map_scripts:register("ROUTE_10", {
        talk = {
            TEXT_STARTER_STORIES_CHARMANDER_KID = {
                { "charmander:check_stage", 4 },
                { "jump_if_true", "following" },

                { "charmander:check_stage", 3 },
                { "jump_if_true", "found_b" },

                { "charmander:check_stage", 2 },
                { "jump_if_true", "waiting" },

                { "charmander:check_stage", 1 },
                { "jump_if_true", "waiting" },

                -- Etapa 0: Inicio de la quest
                { "charmander:check_has_starter" },
                { "jump_if_false", "not_started_yet" },

                { "charmander:check_chose_charmander" },
                { "jump_if_true", "route_a_intro" },
                { "jump", "route_b_intro" },

                { "label", "route_a_intro" },
                { "show_text", "_CharKidIntroA1" },
                { "ask", "_CharKidIntroA2" },
                { "jump_if_false", "declined" },
                { "charmander:set_stage", 2 },
                { "charmander:set_route", "starter" },
                { "jump", "check_a_ready" },

                { "label", "route_b_intro" },
                { "show_text", "_CharKidIntroB1" },
                { "ask", "_CharKidIntroB2" },
                { "jump_if_false", "declined" },
                { "charmander:set_stage", 2 },
                { "charmander:set_route", "captured" },
                { "jump", "end" },

                { "label", "waiting" },
                { "charmander:check_route", "starter" },
                { "jump_if_true", "check_a_ready" },
                { "show_text", "_CharKidBWait" },
                { "jump", "end" },

                { "label", "check_a_ready" },
                { "charmander:check_has_charmander_line" },
                { "jump_if_true", "ready_a" },
                { "show_text", "_CharKidAWait" },
                { "jump", "end" },

                { "label", "ready_a" },
                { "show_text", "_CharKidAJoin" },
                { "charmander:set_stage", 4 },
                { "jump", "end" },

                { "label", "found_b" },
                { "show_text", "_CharKidBFound" },
                { "charmander:set_stage", 4 },
                { "jump", "end" },

                { "label", "following" },
                { "show_text", "_CharKidFollowing" },
                { "jump", "end" },

                { "label", "declined" },
                { "show_text", "_CharKidDeclined" },
                { "jump", "end" },

                { "label", "not_started_yet" },
                { "label", "end" },
            },
        },
        onEnter = function(game, ow)
            local stage = getState(STAGE_KEY, 0)
            -- La primera visita tambien debe mostrar al chico: la etapa 0
            -- es precisamente el punto donde puede iniciar la mision.
            -- Desaparece de Route 10 cuando empieza a acompanarnos.
            if stage < 4 then
                ow:queueScript({
                    { "show_object", "ROUTE_10", "STARTER_STORIES_CHARMANDER_KID" },
                })
            else
                ow:queueScript({
                    { "hide_object", "ROUTE_10", "STARTER_STORIES_CHARMANDER_KID" },
                })
            end
        end,
    })

    mod.content.map_scripts:register("ROCK_TUNNEL_1F", {
        talk = {
            TEXT_STARTER_STORIES_CHARMANDER_KID = {
                { "show_text", "_CharKidFollowing" },
            },
        },
        onEnter = function(game, ow)
            local stage = getState(STAGE_KEY, 0)
            local ambushRowsForMap = ambushRows("ROCK_TUNNEL_1F", stage == 4)
            if stage < 4 or stage >= 5 then
                ambushRowsForMap[#ambushRowsForMap + 1] = { "hide_object", "ROCK_TUNNEL_1F", "STARTER_STORIES_CHARMANDER_KID" }
            end
            ow:queueScript(ambushRowsForMap)
        end,
        onStep = function(game, ow, x, y)
            if tryFarewell(game, ow, x, y) then
                return true
            end
            return tryAmbush(game, ow, "ROCK_TUNNEL_1F", x, y)
        end,
    })

    mod.hooks:wrap("render.hud", function(next_, game, viewport)
        next_(game, viewport)
        drawCharmanderLight(game, viewport)
    end)

    mod.content.map_scripts:register("ROCK_TUNNEL_B1F", {
        talk = {
            TEXT_STARTER_STORIES_CHARMANDER_KID = {
                { "show_text", "_CharKidFollowing" },
            },
            TEXT_STARTER_STORIES_CHARMANDER_WILD = {
                -- El salvaje no debe interactuar por talk, solo onStep
            },
        },
        onEnter = function(game, ow)
            local stage = getState(STAGE_KEY, 0)
            local route = getState(ROUTE_KEY, "")
            local ambushRowsForMap = ambushRows("ROCK_TUNNEL_B1F", stage == 4)

            if stage < 4 or stage >= 5 then
                ambushRowsForMap[#ambushRowsForMap + 1] = { "hide_object", "ROCK_TUNNEL_B1F", "STARTER_STORIES_CHARMANDER_KID" }
            end

            if stage == 2 and route == "captured" and not getState(FOUND_KEY, false) then
                ambushRowsForMap[#ambushRowsForMap + 1] = { "show_object", "ROCK_TUNNEL_B1F", "STARTER_STORIES_CHARMANDER_WILD" }
            else
                ambushRowsForMap[#ambushRowsForMap + 1] = { "hide_object", "ROCK_TUNNEL_B1F", "STARTER_STORIES_CHARMANDER_WILD" }
            end
            ow:queueScript(ambushRowsForMap)
        end,

        onStep = function(game, ow, x, y)
            if ow.runner:isRunning() then
                return false
            end

            local stage = getState(STAGE_KEY, 0)
            local route = getState(ROUTE_KEY, "")

            if tryAmbush(game, ow, "ROCK_TUNNEL_B1F", x, y) then
                return true
            end

            -- El objeto se muestra una sola vez al entrar al mapa. Aquí solo
            -- se evalúa el disparador de proximidad para no llenar la cola de
            -- scripts con show_object en cada paso del jugador.
            if stage == 2 and route == "captured" and not getState(FOUND_KEY, false) then

                if x >= 36 and x <= 38 and y >= 1 and y <= 3 then
                    local wildNpc = ow:npcByIndex(91)
                    local wx, wy = lungeTarget(ow, { x = 37, y = 2 }, wildNpc, x, y)
                    local started = ow:queueScript({
                        { "stop_music" },
                        { "play_music", "Music_MeetFemaleTrainer" },
                        { "emote", 91, "shock" },
                        { "play_cry", "CHARMANDER" },
                        { "move_npc_to", 91, wx, wy },
                        { "show_text", "_CharWildEncounter" },
                        { "start_battle", "wild", "CHARMANDER", 12 },
                        { "check_battle_result", "caught" },
                        { "jump_if_false", "not_caught" },

                        { "charmander:set_found", "true" },
                        { "charmander:set_stage", 3 },
                        { "hide_object", "ROCK_TUNNEL_B1F", "STARTER_STORIES_CHARMANDER_WILD" },
                        { "play_default_music" },
                        { "jump", "end" },

                        { "label", "not_caught" },
                        { "play_default_music" },
                        { "label", "end" },
                    })
                    return started and true or false
                end
            end
            return false
        end,
    })

    -- =========================================================================
    -- 8. EVENTO pokemon.caught (respaldo de seguridad)
    --
    -- Si el jugador captura un CHARMANDER por cualquier vía mientras la
    -- ruta B espera la captura, la misión avanza igual que el script.
    -- =========================================================================

    mod.events:on("pokemon.caught", function(e)
        if not e then return end
        if e.species ~= "CHARMANDER" then return end
        if getState(STAGE_KEY, 0) ~= 2 then return end
        if getState(ROUTE_KEY, "") ~= "captured" then return end
        if getState(FOUND_KEY, false) then return end

        setState(FOUND_KEY, true)
        setState(STAGE_KEY, 3)
    end)

    -- =========================================================================
    -- 9. QUEST SYSTEM (diario)
    -- =========================================================================

    mod.events:on("game.ready", function(payload)
        local game = payload and payload.game or payload
        if not game then return end

        local journal = mod.find("quest_system")
        if not (journal and journal.exports and journal.exports.register) then
            return
        end

        pcall(journal.exports.register, {
            id = "starter_stories_charmander",
            title = "The Scared Kid",
            source = "Starter Stories",
            sort = 170,
            description =
                "A kid is too scared to cross the dark Rock Tunnel. " ..
                "Help him find a way through.",
            objective = function()
                local currentStage = getState(STAGE_KEY, 0)
                if currentStage >= 5 then
                    return "Mission complete. You crossed the tunnel with the kid!"
                end
                if currentStage == 2 then
                    if getState(ROUTE_KEY, "") == "captured" then
                        return "Find the Charmander hiding in Rock Tunnel B1F."
                    end
                    return "Keep a Charmander in your party to light the way."
                end
                if currentStage >= 3 then
                    return "Escort the kid through Rock Tunnel."
                end
                return "Talk to the kid outside Rock Tunnel."
            end,
            location = function()
                local currentStage = getState(STAGE_KEY, 0)
                if currentStage >= 3 then
                    return "Rock Tunnel"
                end
                return "Route 10"
            end,
            reward = "Rare Candy",
            progress = function()
                return {
                    current = getState(STAGE_KEY, 0),
                    total = 5,
                }
            end,
        })
    end)

    -- =========================================================================
    -- 10. QUEST CONNECTOR
    -- =========================================================================

    if mod.quests and mod.quests.register then
        mod.quests.register("charmander", {
            stage = function()
                return getState(STAGE_KEY, 0)
            end,
            completed = function()
                return getState(STAGE_KEY, 0) >= 5
            end,
        })
    end

end
