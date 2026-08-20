return function(mod)

    -- =========================================================================
    -- 0. ESTADO DE LA MISIÓN
    --
    -- squirtle_stage:
    --   0 = NOT_STARTED
    --   1 = STARTED
    --   2 = CHASING
    --   3 = CAUGHT
    --   4 = COMPLETED
    --
    -- Rivales:
    --   squirtle_rival1_beat
    --   squirtle_rival2_beat
    --   squirtle_rival3_beat
    --   squirtle_rival4_beat
    --
    -- Guardian:
    --   squirtle_guardian_beat
    -- =========================================================================

    local STAGE_KEY = "squirtle_stage"

    local function getState(key, default)
        return mod.save:get(key, default)
    end

    local function setState(key, value)
        mod.save:set(key, value)
    end

    local function rivalKey(key)
        return "squirtle_" .. tostring(key)
    end

    local function rivalBeaten(key)
        return getState(rivalKey(key), false) and true or false
    end

    local function setRivalBeaten(key)
        setState(rivalKey(key), true)
    end

    -- =========================================================================
    -- 1. COMANDOS CUSTOM
    -- =========================================================================

    mod.content.commands:register("squirtle:set_stage", function(ctx, value)
        setState(STAGE_KEY, tonumber(value) or 0)
    end)

    mod.content.commands:register("squirtle:check_stage", function(ctx, value)
        ctx.lastCheck =
            getState(STAGE_KEY, 0) == (tonumber(value) or -1)
    end)

    mod.content.commands:register("squirtle:set_rival", function(ctx, key)
        setRivalBeaten(key)
    end)

    mod.content.commands:register("squirtle:check_rival", function(ctx, key)
        ctx.lastCheck = rivalBeaten(key)
    end)

    -- Combate del guardián: STARMIE salvaje que no puede capturarse
    -- (noCatch), para que muestre el sprite del Pokémon en pantalla.
    -- Mismo patrón de Commands.start_battle: pushBattle (con su wipe
    -- de transición) + runner:yield, y onFinish que deja el resultado
    -- en ctx.lastBattleResult / ctx.lastCheck.
    mod.content.commands:register("squirtle:guardian_battle", function(ctx)
        local BattleState = require("src.battle.BattleState")
        local runner = ctx.runner
        local battle = BattleState.newWild(ctx.game, "STARMIE", 19)
        battle.noCatch = true
        battle.onFinish = function(result)
            ctx.lastBattleResult = result
            ctx.lastCheck = result == "win"
            if ctx.overworld then
                if result == "win" then
                    ctx.afterScript = ctx.afterScript or {}
                    table.insert(ctx.afterScript, function()
                        ctx.overworld:afterBattle(result, battle)
                    end)
                else
                    ctx.overworld:afterBattle(result, battle)
                end
            end
            runner:resume()
        end
        if ctx.overworld and ctx.overworld.pushBattle then
            ctx.overworld:pushBattle(battle)
        else
            ctx.game.stack:push(battle)
        end
        runner:yield()
    end)

    -- =========================================================================
    -- 2. REGLA DEL STARTER
    --
    -- Red / Blue:
    --   - Debe haber recibido un starter.
    --   - Si eligió Squirtle, la misión queda excluida.
    --
    -- Yellow:
    --   - EVENT_GOT_STARTER permite continuar.
    --   - No existe EVENT_CHOSE_SQUIRTLE para excluir la misión.
    --
    -- IMPORTANTE:
    --   No usamos Misty, una medalla ni EVENT_BEAT_MISTY como requisito.
    --   La misión se descubre naturalmente al llegar a Ciudad Celeste.
    -- =========================================================================

    local function hasStarter(game)
        local flags = game and game.save and game.save.flags

        return not not (
            flags
            and flags.EVENT_GOT_STARTER
        )
    end

    local function choseSquirtle(game)
        local flags = game and game.save and game.save.flags

        return not not (
            flags
            and flags.EVENT_CHOSE_SQUIRTLE
        )
    end

    local function questEligible(game)
        if not hasStarter(game) then
            return false
        end

        if choseSquirtle(game) then
            return false
        end

        return true
    end

    -- =========================================================================
    -- 3. SPRITE PERSONALIZADO DE SQUIRTLE
    -- =========================================================================

    mod.content.sprites:register("SPRITE_FOLLOWER_SQUIRTLE", {
        id = "SPRITE_FOLLOWER_SQUIRTLE",
        image = mod.assets:path(
            "assets/poke_followers/follower_007.png"
        ),
        frames = 6,
        walker = true,
        trueColor = true,
    })

    mod.content.sprites:register("SPRITE_FOLLOWER_STARMIE", {
    id = "SPRITE_FOLLOWER_STARMIE",
    image = mod.assets:path(
        "assets/poke_followers/follower_121.png"
    ),
    frames = 6,
    walker = true,
    trueColor = true,
})
    -- =========================================================================
    -- 4. ENTRENADORES
    -- =========================================================================

    mod.content.trainers:register("STARTER_STORIES_SQUIRTLE_RIVAL1", {
        id = "STARTER_STORIES_SQUIRTLE_RIVAL1",
        name = "Derek",
        basePic = "OPP_YOUNGSTER",
        baseMoney = 30,

        parties = {
            {
                { level = 15, species = "RATTATA" },
                { level = 15, species = "EKANS" },
                { level = 16, species = "ODDISH" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_SQUIRTLE_RIVAL2", {
        id = "STARTER_STORIES_SQUIRTLE_RIVAL2",
        name = "Milo",
        basePic = "OPP_BUG_CATCHER",
        baseMoney = 30,

        parties = {
            {
                { level = 15, species = "CATERPIE" },
                { level = 15, species = "METAPOD" },
                { level = 17, species = "BUTTERFREE" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_SQUIRTLE_RIVAL3", {
        id = "STARTER_STORIES_SQUIRTLE_RIVAL3",
        name = "Bruno",
        basePic = "OPP_HIKER",
        baseMoney = 35,

        parties = {
            {
                { level = 16, species = "GEODUDE" },
                { level = 16, species = "MACHOP" },
                { level = 17, species = "GEODUDE" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_SQUIRTLE_RIVAL4", {
        id = "STARTER_STORIES_SQUIRTLE_RIVAL4",
        name = "Caleb",
        basePic = "OPP_FISHER",
        baseMoney = 40,

        parties = {
            {
                { level = 16, species = "GOLDEEN" },
                { level = 17, species = "POLIWAG" },
                { level = 18, species = "HORSEA" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_SQUIRTLE_GUARDIAN", {
        id = "STARTER_STORIES_SQUIRTLE_GUARDIAN",
        name = "Starmie",
        basePic = "OPP_SWIMMER",
        baseMoney = 0,

        parties = {
            {
                { level = 19, species = "STARMIE" },
            },
        },
    })

    -- =========================================================================
    -- 5. TEXTOS BASE
    --
    -- BASE = INGLÉS
    -- ESPAÑOL = game.ready cuando recomp-spanish está activo.
    --
    -- Se usan cajas cortas y varios saltos de línea para evitar texto corrido.
    -- =========================================================================

    mod.content.text:register(
        "_SquirtleStart1",
        "SQUIRTLE!\n" ..
        "Wait!"
    )

    mod.content.text:register(
        "_SquirtleOfficer1",
        "Officer Reyes: That SQUIRTLE again!"
    )

    mod.content.text:register(
        "_SquirtleOfficer2",
        "Officer Marín: It's been causing\n" ..
        "trouble for days."
    )

    mod.content.text:register(
        "_SquirtleOfficer3",
        "Officer Reyes: It keeps running\n" ..
        "away whenever we approach."
    )

    mod.content.text:register(
        "_SquirtleOfficer4",
        "Officer Marín: If you see it,\n" ..
        "try to stop it!"
    )

    mod.content.text:register(
        "_SquirtleOfficerWaiting",
        "Officer Reyes: That SQUIRTLE ran off again.\n" ..
        "It usually heads north, toward ROUTE 24."
    )

    mod.content.text:register(
        "_SquirtleOfficerDone",
        "Officer Marín: So that little one was\n" ..
        "not the troublemaker after all.\n" ..
        "Thank you for helping it."
    )

    mod.content.text:register(
        "_SquirtleRival1Talk",
        "Derek: So you're after that SQUIRTLE?\n" ..
        "I saw it first!\n" ..
        "Let's battle!"
    )

    mod.content.text:register(
        "_SquirtleRival1Won",
        "Derek: What?!\n" ..
        "You actually beat me..."
    )

    mod.content.text:register(
        "_SquirtleRival2Talk",
        "Milo: Have you seen that SQUIRTLE?\n" ..
        "I won't let you catch it first!"
    )

    mod.content.text:register(
        "_SquirtleRival2Won",
        "Milo: Ouch!\n" ..
        "Okay, you win..."
    )

    mod.content.text:register(
        "_SquirtleRival3Talk",
        "Bruno: Who made you the hero\n" ..
        "of CERULEAN CITY?\n" ..
        "You'll have to get past me!"
    )

    mod.content.text:register(
        "_SquirtleRival3Won",
        "Bruno: Hah... you're stronger\n" ..
        "than you look."
    )

    mod.content.text:register(
        "_SquirtleRival4Talk",
        "Caleb: You made it this far...\n" ..
        "Not bad.\n" ..
        "But SQUIRTLE is mine."
    )

    mod.content.text:register(
        "_SquirtleRival4Won",
        "Caleb: I see...\n" ..
        "You're not giving up."
    )

    mod.content.text:register(
        "_SquirtleFrightened",
        "SQUIRTLE looks frightened.\n" ..
        "It doesn't seem to trust\n" ..
        "anyone."
    )

    mod.content.text:register(
        "_SquirtleGuardianIntro",
        "SQUIRTLE is cornered!\n" ..
        "STARMIE moves in front of it."
    )

    mod.content.text:register(
        "_SquirtleGuardianWon",
        "STARMIE can no longer protect\n" ..
        "SQUIRTLE."
    )

    mod.content.text:register(
        "_SquirtleCaught",
        "SQUIRTLE was caught!"
    )

    mod.content.text:register(
        "_SquirtleEscort1",
        "Officer Reyes:\n" ..
        "Jenny asked us\n" ..
        "to come along.\v" ..
        "That SQUIRTLE is\n" ..
        "in good hands now."
    )

    mod.content.text:register(
        "_SquirtleEscort2",
        "Officer Marín:\n" ..
        "We escorted her\n" ..
        "from the city.\v" ..
        "Take good care\n" ..
        "of the little one."
    )

    mod.content.text:register(
        "_SquirtleJenny1",
        "Jenny: We found something strange\n" ..
        "about this SQUIRTLE."
    )

    mod.content.text:register(
        "_SquirtleJenny2",
        "Jenny: It wasn't causing trouble\n" ..
        "on purpose."
    )

    mod.content.text:register(
        "_SquirtleJenny3",
        "Jenny: TEAM ROCKET had been\n" ..
        "forcing it to help them."
    )

    mod.content.text:register(
        "_SquirtleJenny4",
        "Jenny: They chased it whenever\n" ..
        "it tried to escape."
    )

    mod.content.text:register(
        "_SquirtleJenny5",
        "Jenny: No wonder it was so afraid\n" ..
        "of people..."
    )

    mod.content.text:register(
        "_SquirtleJenny6",
        "Jenny: We'll investigate what\n" ..
        "happened."
    )

    mod.content.text:register(
        "_SquirtleJenny7",
        "Jenny: For now, take good care\n" ..
        "of that little SQUIRTLE."
    )

    mod.content.text:register(
        "_SquirtleJennyRepeat",
        "We must\n" ..
        "investigate all\n" ..
        "of this very\n" ..
        "carefully."
    )

    -- =========================================================================
    -- 6. ESPAÑOL EN RUNTIME
    -- =========================================================================

    mod.events:on("game.ready", function(ev)

        local game = ev and ev.game
        local mods = game and game.mods and game.mods.mods
        local spanish = mods and mods["recomp-spanish"]

        if not (spanish and spanish.enabled) then
            return
        end

        local text = game.data and game.data.text

        if not text then
            return
        end

        text._SquirtleStart1 =
            "¡SQUIRTLE!\n" ..
            "¡Espera!"

        text._SquirtleOfficer1 =
            "Oficial Reyes: ¡Ese SQUIRTLE otra vez!"

        text._SquirtleOfficer2 =
            "Oficial Marín: Lleva varios días\n" ..
            "causando problemas."

        text._SquirtleOfficer3 =
            "Oficial Reyes: Siempre huye\n" ..
            "cuando intentamos acercarnos."

        text._SquirtleOfficer4 =
            "Oficial Marín: Si lo ves,\n" ..
            "¡intenta detenerlo!"

        text._SquirtleOfficerWaiting =
            "Oficial Reyes: Ese SQUIRTLE volvió a escapar.\n" ..
            "Suele ir hacia el norte, hacia la RUTA 24."

        text._SquirtleOfficerDone =
            "Oficial Marín: Así que ese pequeño no era\n" ..
            "el que causaba los problemas.\n" ..
            "Gracias por ayudarlo."

        text._SquirtleRival1Talk =
            "Derek: ¿Así que buscas a ese SQUIRTLE?\n" ..
            "¡Yo lo vi primero!\n" ..
            "¡A combatir!"

        text._SquirtleRival1Won =
            "Derek: ¿Qué?\n" ..
            "De verdad me derrotaste..."

        text._SquirtleRival2Talk =
            "Milo: ¿Has visto a ese SQUIRTLE?\n" ..
            "¡No dejaré que lo captures primero!"

        text._SquirtleRival2Won =
            "Milo: ¡Auch!\n" ..
            "Vale, tú ganas..."

        text._SquirtleRival3Talk =
            "Bruno: ¿Quién te nombró héroe\n" ..
            "de CIUDAD CELESTE?\n" ..
            "¡Tendrás que pasar sobre mí!"

        text._SquirtleRival3Won =
            "Bruno: Je... eres más fuerte\n" ..
            "de lo que pareces."

        text._SquirtleRival4Talk =
            "Caleb: Has llegado hasta aquí...\n" ..
            "No está mal.\n" ..
            "Pero SQUIRTLE es mío."

        text._SquirtleRival4Won =
            "Caleb: Ya veo...\n" ..
            "No vas a rendirte."

        text._SquirtleFrightened =
            "SQUIRTLE parece asustado.\n" ..
            "No parece confiar\n" ..
            "en nadie."

        text._SquirtleGuardianIntro =
            "¡SQUIRTLE está acorralado!\n" ..
            "STARMIE se coloca delante de él."

        text._SquirtleGuardianWon =
            "STARMIE ya no puede proteger\n" ..
            "a SQUIRTLE."

        text._SquirtleCaught =
            "¡SQUIRTLE ha sido capturado!"

        text._SquirtleEscort1 =
            "Reyes: Jenny nos\n" ..
            "pidió venir con\n" ..
            "ella.\v" ..
            "Ese SQUIRTLE\n" ..
            "está a salvo."

        text._SquirtleEscort2 =
            "Marín: La trajimos\n" ..
            "desde la ciudad.\v" ..
            "Cuida bien\n" ..
            "de él."

        text._SquirtleJenny1 =
            "Jenny: Descubrimos algo extraño\n" ..
            "sobre este SQUIRTLE."

        text._SquirtleJenny2 =
            "Jenny: No estaba causando problemas\n" ..
            "a propósito."

        text._SquirtleJenny3 =
            "Jenny: El TEAM ROCKET lo estaba\n" ..
            "obligando a ayudarlos."

        text._SquirtleJenny4 =
            "Jenny: Lo perseguían cada vez\n" ..
            "que intentaba escapar."

        text._SquirtleJenny5 =
            "Jenny: No me extraña que estuviera\n" ..
            "tan asustado de la gente..."

        text._SquirtleJenny6 =
            "Jenny: Investigaremos lo ocurrido."

        text._SquirtleJenny7 =
            "Jenny: Por ahora, cuida bien\n" ..
            "de ese pequeño SQUIRTLE."

        text._SquirtleJennyRepeat =
            "Debemos\n" ..
            "investigar muy\n" ..
            "bien todo esto."
    end)

    -- =========================================================================
    -- 7. OBJETOS DE CIUDAD CELESTE
    --
    -- Índices deliberadamente propios de este mod.
    -- Si alguno coincide con otro parche del mapa, debe ajustarse.
    -- =========================================================================

    mod.content.maps:patch("CERULEAN_CITY", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_SQUIRTLE",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE",
                    sprite = "SPRITE_FOLLOWER_SQUIRTLE",
                    x = 25,
                    y = 11,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },

                {
                    index = 91,
                    name = "STARTER_STORIES_SQUIRTLE_OFFICER1",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_OFFICER1",
                    sprite = "SPRITE_GUARD",
                    x = 23,
                    y = 12,
                    movement = "STAY",
                    range = "RIGHT",
                    hidden = true,
                },

                {
                    index = 92,
                    name = "STARTER_STORIES_SQUIRTLE_OFFICER2",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_OFFICER2",
                    sprite = "SPRITE_GUARD",
                    x = 22,
                    y = 12,
                    movement = "STAY",
                    range = "RIGHT",
                    hidden = true,
                },
            },
        },
    })

    -- =========================================================================
    -- 8. OBJETOS DE RUTA 24
    -- =========================================================================

    mod.content.maps:patch("ROUTE_24", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_SQUIRTLE_RIVAL1",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_RIVAL1",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 11,
                    y = 9,
                    movement = "STAY",
                    range = "LEFT",
                    hidden = true,
                },
            },
        },
    })

    -- =========================================================================
    -- 9. OBJETOS DE RUTA 25
    -- =========================================================================

    mod.content.maps:patch("ROUTE_25", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_SQUIRTLE_RIVAL2",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_RIVAL2",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 3,
                    y = 9,
                    movement = "STAY",
                    range = "RIGHT",
                    hidden = true,
                },

                {
                    index = 91,
                    name = "STARTER_STORIES_SQUIRTLE_WILD",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_WILD",
                    sprite = "SPRITE_FOLLOWER_SQUIRTLE",
                    x = 20,
                    y = 4,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },

                {
                    index = 92,
                    name = "STARTER_STORIES_SQUIRTLE_RIVAL3",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_RIVAL3",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 33,
                    y = 6,
                    movement = "STAY",
                    range = "LEFT",
                    hidden = true,
                },

                {
                    index = 93,
                    name = "STARTER_STORIES_SQUIRTLE_RIVAL4",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_RIVAL4",
                    sprite = "SPRITE_FISHER",
                    x = 41,
                    y = 6,
                    movement = "STAY",
                    range = "LEFT",
                    hidden = true,
                },

                {
                    index = 94,
                    name = "STARTER_STORIES_SQUIRTLE_GUARDIAN",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_GUARDIAN",
                    sprite = "SPRITE_FOLLOWER_STARMIE",
                    x = 53,
                    y = 4,
                    movement = "STAY",
                    range = "LEFT",
                    hidden = true,
                },

                {
                    index = 95,
                    name = "STARTER_STORIES_SQUIRTLE_FINAL",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_FINAL",
                    sprite = "SPRITE_FOLLOWER_SQUIRTLE",
                    x = 54,
                    y = 4,
                    movement = "STAY",
                    range = "LEFT",
                    hidden = true,
                },

                {
                    index = 96,
                    name = "STARTER_STORIES_SQUIRTLE_JENNY",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_JENNY",
                    sprite = "SPRITE_GUARD",
                    x = 44,
                    y = 5,
                    movement = "STAY",
                    range = "UP",
                    hidden = true,
                },

                {
                    index = 97,
                    name = "STARTER_STORIES_SQUIRTLE_ESCORT1",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_ESCORT1",
                    sprite = "SPRITE_GUARD",
                    x = 44,
                    y = 6,
                    movement = "STAY",
                    range = "UP",
                    hidden = true,
                },

                {
                    index = 98,
                    name = "STARTER_STORIES_SQUIRTLE_ESCORT2",
                    text = "TEXT_STARTER_STORIES_SQUIRTLE_ESCORT2",
                    sprite = "SPRITE_GUARD",
                    x = 44,
                    y = 7,
                    movement = "STAY",
                    range = "UP",
                    hidden = true,
                },
            },
        },
    })

    -- =========================================================================
    -- 10. CIUDAD CELESTE �- INICIO
    -- =========================================================================

    mod.content.map_scripts:register("CERULEAN_CITY", {

        onEnter = function(game, ow)

            if getState(STAGE_KEY, 0) ~= 0 then
                return
            end

            if not questEligible(game) then
                return
            end

            ow:queueScript({
                {
                    "show_object",
                    "CERULEAN_CITY",
                    "STARTER_STORIES_SQUIRTLE",
                },
            })
        end,

        onStep = function(game, ow, x, y)

            if ow.runner:isRunning() then
                return false
            end

            if getState(STAGE_KEY, 0) ~= 0 then
                return false
            end

            if not questEligible(game) then
                return false
            end

            -- Trigger más lejano: rango 2 alrededor de Squirtle (25,11).
            -- No hace falta pararse al lado; basta acercarse
            -- un par de cuadros.
            local dx = math.abs(x - 25)
            local dy = math.abs(y - 11)

            if dx > 2 or dy > 2 then
                return false
            end

            local playerBelow = (y > 11)

            local introRows = {
                { "stop_music" },

                { "emote",
                    "player",
                    "shock",
                    30
                },

                { "face_player" },

                { "play_cry",
                    "SQUIRTLE"
                },

                { "show_text",
                    "_SquirtleStart1"
                },
            }

            -- Squirtle sale un paso hacia el frente (hacia el jugador)
            -- y luego huye corriendo hacia arriba (Ruta 24).
            if not playerBelow then
                table.insert(introRows, {
                    "move_npc",
                    90,
                    "down",
                    3
                })
            end
            
            table.insert(introRows, {
                    "move_npc",
                    90,
                    "left",
                    2
                })
            

            table.insert(introRows, {
                "move_npc",
                90,
                "up",
                4
            })

            table.insert(introRows, {
                "hide_object",
                "CERULEAN_CITY",
                "STARTER_STORIES_SQUIRTLE"
            })

            table.insert(introRows, {
                "show_object",
                "CERULEAN_CITY",
                "STARTER_STORIES_SQUIRTLE_OFFICER1"
            })

            table.insert(introRows, {
                "show_object",
                "CERULEAN_CITY",
                "STARTER_STORIES_SQUIRTLE_OFFICER2"
            })

            -- Oficiales con recorrido visible: nacen lejos (sur, hacia la
            -- ciudad) y corren hacia delante hasta situarse dos celdas
            -- delante del jugador.  Coordenadas fijas para no depender de
            -- la posición relativa del jugador (evita el crash previo).
            table.insert(introRows, {
                "place_npc",
                91,
                24,
                15,
                "up"
            })

            table.insert(introRows, {
                "place_npc",
                92,
                25,
                15,
                "up"
            })

            table.insert(introRows, {
                "move_npc",
                91,
                "up",
                2
            })

            table.insert(introRows, {
                "move_npc",
                92,
                "up",
                2
            })

            table.insert(introRows, {
                "face_player"
            })

            table.insert(introRows, {
                "show_text",
                "_SquirtleOfficer1"
            })

            table.insert(introRows, {
                "show_text",
                "_SquirtleOfficer2"
            })

            table.insert(introRows, {
                "show_text",
                "_SquirtleOfficer3"
            })

            table.insert(introRows, {
                "show_text",
                "_SquirtleOfficer4"
            })

            table.insert(introRows, {
                "squirtle:set_stage",
                2
            })

            table.insert(introRows, {
                "play_default_music"
            })

            ow:queueScript(introRows)

            return true
        end,

        talk = {

            TEXT_STARTER_STORIES_SQUIRTLE_OFFICER1 = {
                { "face_player" },

                { "squirtle:check_stage", 4 },
                { "jump_if_true", "done" },

                { "squirtle:check_stage", 2 },
                { "jump_if_true", "waiting" },

                { "squirtle:check_stage", 3 },
                { "jump_if_true", "waiting" },

                { "show_text", "_SquirtleOfficer1" },
                { "show_text", "_SquirtleOfficer3" },
                { "jump", "end" },

                { "label", "waiting" },
                { "show_text", "_SquirtleOfficerWaiting" },
                { "jump", "end" },

                { "label", "done" },
                { "show_text", "_SquirtleOfficerDone" },
                { "label", "end" },
            },

            TEXT_STARTER_STORIES_SQUIRTLE_OFFICER2 = {
                { "face_player" },

                { "squirtle:check_stage", 4 },
                { "jump_if_true", "done" },

                { "squirtle:check_stage", 2 },
                { "jump_if_true", "waiting" },

                { "squirtle:check_stage", 3 },
                { "jump_if_true", "waiting" },

                { "show_text", "_SquirtleOfficer2" },
                { "show_text", "_SquirtleOfficer4" },
                { "jump", "end" },

                { "label", "waiting" },
                { "show_text", "_SquirtleOfficerWaiting" },
                { "jump", "end" },

                { "label", "done" },
                { "show_text", "_SquirtleOfficerDone" },
                { "label", "end" },
            },

            TEXT_STARTER_STORIES_SQUIRTLE = {
                { "face_player" },
                { "show_text", "_SquirtleStart1" },
            },
        },
    })

    -- =========================================================================
    -- 11. RUTA 24 �- PERSEGUIDOR #1
    -- =========================================================================

    mod.content.map_scripts:register("ROUTE_24", {

        onEnter = function(game, ow)

            if getState(STAGE_KEY, 0) ~= 2 then
                return
            end

            if not rivalBeaten("rival1_beat") then
                ow:queueScript({
                    {
                        "show_object",
                        "ROUTE_24",
                        "STARTER_STORIES_SQUIRTLE_RIVAL1",
                    },
                })
            end
        end,

        onStep = function(game, ow, x, y)

            if ow.runner:isRunning() then
                return false
            end

            if getState(STAGE_KEY, 0) ~= 2 then
                return false
            end

            if rivalBeaten("rival1_beat") then
                return false
            end

            -- Trigger por zona alrededor del rival (X11 Y9): dispara de frente
            -- y también al pasar a un lado.
            local dx11 = x - 11
            local dy9 = y - 9

            if math.abs(dx11) > 2 or math.abs(dy9) > 2 then
                return false
            end

            local npc = ow:npcByIndex(90)

            if not npc or npc.moving then
                return false
            end

            -- FIX: el rival camina hacia el jugador por el eje dominante,
            -- quedando una celda de distancia.  move_npc no usa BFS ni
            -- coordenadas relativas, así nunca cuelga como move_npc_to.
            local walkDir
            local walkSteps

            if math.abs(dx11) >= math.abs(dy9) then
                walkDir = dx11 > 0 and "right" or "left"
                walkSteps = math.max(0, math.abs(dx11) - 1)
            else
                walkDir = dy9 > 0 and "down" or "up"
                walkSteps = math.max(0, math.abs(dy9) - 1)
            end

            -- El player mira hacia el rival (eje dominante), sin volteo
            -- forzado: si el rival camina hacia abajo, el rival queda
            -- delante y el player debe mirar hacia arriba.
            ow.player.facing = walkDir == "right" and "left"
                or walkDir == "left" and "right"
                or walkDir == "down" and "up"
                or "down"

            ow.runner:run({
                { "stop_music" },

                { "play_music",
                    "Music_MeetMaleTrainer"
                },

                { "emote",
                    "player",
                    "shock",
                    30
                },

                { "wait",
                    20
                },

                { "move_npc",
                    90,
                    walkDir,
                    walkSteps
                },

                { "face_player" },

                { "show_text",
                    "_SquirtleRival1Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_SQUIRTLE_RIVAL1",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false",
                    "end"
                },

                { "show_text",
                    "_SquirtleRival1Won"
                },

                { "squirtle:set_rival",
                    "rival1_beat"
                },

                { "hide_object",
                    "ROUTE_24",
                    "STARTER_STORIES_SQUIRTLE_RIVAL1"
                },

                { "play_default_music" },

                { "label",
                    "end"
                },
            }, {
                npc = npc
            })

            return true
        end,

        talk = {

            TEXT_STARTER_STORIES_SQUIRTLE_RIVAL1 = {
                { "face_player" },

                { "show_text",
                    "_SquirtleRival1Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_SQUIRTLE_RIVAL1",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false",
                    "end"
                },

                { "show_text",
                    "_SquirtleRival1Won"
                },

                { "squirtle:set_rival",
                    "rival1_beat"
                },

                { "hide_object",
                    "ROUTE_24",
                    "STARTER_STORIES_SQUIRTLE_RIVAL1"
                },

                { "label", "end" },
            },
        },
    })

    -- =========================================================================
    -- 12. RUTA 25 �- PERSEGUIDORES Y SQUIRTLE
    -- =========================================================================

    mod.content.map_scripts:register("ROUTE_25", {

        onEnter = function(game, ow)

            local stage = getState(STAGE_KEY, 0)

            -- Self-heal: versiones previas marcaban stage 3 al atrapar al
            -- Squirtle y solo pasaban a 4 al terminar la cinemática de Jenny;
            -- si se guardaba/salía a mitad, la quest quedaba sin salida.
            -- Ahora el completado (stage 4) se fija en el catch y stage 3 solo
            -- puede venir de un save antiguo: se completa en la primera entrada.
            if stage == 3 then
                setState(STAGE_KEY, 4)
                stage = 4
            end

            if stage ~= 2 and stage ~= 4 then
                return
            end

            local rows = {}

            if stage == 2 then

                if not rivalBeaten("rival2_beat") then
                    table.insert(rows, {
                        "show_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_RIVAL2"
                    })
                end

                table.insert(rows, {
                    "show_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_WILD"
                })

                if not rivalBeaten("rival3_beat") then
                    table.insert(rows, {
                        "show_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_RIVAL3"
                    })
                end

                if not rivalBeaten("rival4_beat") then
                    table.insert(rows, {
                        "show_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_RIVAL4"
                    })
                end

                -- M1: el guardián no debe resucitar al reentrar tras ser
                -- vencido (mismo patrón que los rivales).
                if not rivalBeaten("guardian_beat") then
                    table.insert(rows, {
                        "show_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_GUARDIAN"
                    })
                end

                table.insert(rows, {
                    "show_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_FINAL"
                })

            elseif stage == 4 then

                -- Completada: la oficial se queda en la zona, pero no quedan
                -- ni el guardián ni el Squirtle final visibles (limpia también
                -- el caso borde del respaldo pokemon.caught).
                table.insert(rows, {
                    "hide_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_GUARDIAN"
                })

                table.insert(rows, {
                    "hide_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_FINAL"
                })

                table.insert(rows, {
                    "show_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_JENNY"
                })

            end

            ow:queueScript(rows)
        end,

        onStep = function(game, ow, x, y)

            if ow.runner:isRunning() then
                return false
            end

            if getState(STAGE_KEY, 0) ~= 2 then
                return false
            end

            -- -------------------------------------------------------------
            -- Helper para los cuatro perseguidores.
            -- -------------------------------------------------------------

            -- Trigger por zona alrededor de cada rival: dispara de frente
            -- y también al pasar a un lado (radio 2, como el de STARMIE).
            local function zoneTrigger(rx, ry)
                return math.abs(x - rx) <= 2 and math.abs(y - ry) <= 2
            end

            local function checkAmbush(
                sightCondition,
                rivalIndex,
                rx,
                ry,
                trainerId,
                objectName,
                rivalFlag,
                textIntro,
                textWin,
                standStill
            )

                if not sightCondition then
                    return false
                end

                if rivalBeaten(rivalFlag) then
                    return false
                end

                local npc = ow:npcByIndex(rivalIndex)

                if not npc or npc.moving then
                    return false
                end

                -- El rival camina hacia el jugador por el eje dominante,
                -- quedando una celda de distancia.  move_npc con pasos
                -- fijos no depende de coordenadas relativas ni usa BFS,
                -- así no puede cuelgar.
                -- Si standStill es true, el rival permanece parado en su
                -- sitio (solo se voltea) como MILO, que debe verse fijo.
                local walkDir
                local walkSteps

                if not standStill then

                    local dx = x - rx
                    local dy = y - ry

                    if math.abs(dx) >= math.abs(dy) then
                        walkDir = dx > 0 and "right" or "left"
                        walkSteps = math.max(0, math.abs(dx) - 1)
                    else
                        walkDir = dy > 0 and "down" or "up"
                        walkSteps = math.max(0, math.abs(dy) - 1)
                    end

                    ow.player.facing = walkDir == "right" and "left"
                        or walkDir == "left" and "right"
                        or walkDir == "down" and "up"
                        or "down"
                end

                local rows = {
                    { "stop_music" },

                    { "play_music",
                        "Music_MeetMaleTrainer"
                    },
                }

                if not standStill then

                    table.insert(rows, { "emote", "player", "shock", 30 })
                    table.insert(rows, { "wait", 20 })
                    table.insert(rows, {
                        "move_npc",
                        rivalIndex,
                        walkDir,
                        walkSteps
                    })

                end

                table.insert(rows, { "face_player" })

                table.insert(rows, { "show_text", textIntro })

                table.insert(rows, {
                    "start_battle",
                    "trainer",
                    trainerId,
                    1
                })

                table.insert(rows, { "check_battle_result", "win" })

                table.insert(rows, { "jump_if_false", "end_ambush" })

                table.insert(rows, { "show_text", textWin })

                table.insert(rows, { "squirtle:set_rival", rivalFlag })

                table.insert(rows, {
                    "hide_object",
                    "ROUTE_25",
                    objectName
                })

                table.insert(rows, { "play_default_music" })

                table.insert(rows, { "label", "end_ambush" })

                ow.runner:run(rows, {
                    npc = npc
                })

                return true
            end

            -- -------------------------------------------------------------
            -- MILO �- X3 Y9
            -- -------------------------------------------------------------

            if checkAmbush(
                zoneTrigger(3, 9),
                90,
                3,
                9,
                "STARTER_STORIES_SQUIRTLE_RIVAL2",
                "STARTER_STORIES_SQUIRTLE_RIVAL2",
                "rival2_beat",
                "_SquirtleRival2Talk",
                "_SquirtleRival2Won",
                true
            ) then
                return true
            end

            -- -------------------------------------------------------------
            -- SQUIRTLE �- X20 Y4
            --
            -- Segundo encuentro durante la persecución.
            -- Si el jugador llega antes de los perseguidores, solamente
            -- muestra que Squirtle está asustado y vuelve a huir.
            -- -------------------------------------------------------------

            -- Trigger por zona alrededor de Squirtle (X20 Y4): igual que el de
            -- STARMIE, basta acercarse hasta dos celdas para que salga huyendo.
            local squirtleDx = math.abs(x - 20)
            local squirtleDy = math.abs(y - 4)

            if squirtleDx <= 2 and squirtleDy <= 2
                and getState(STAGE_KEY, 0) == 2
            then

                local squirtle = ow:npcByIndex(91)

                if squirtle and not squirtle.moving then

                    -- Squirtle huye en dirección opuesta al jugador,
                    -- por el eje dominante.
                    local fleeDir

                    if squirtleDx >= squirtleDy then
                        fleeDir = x > 20 and "left" or "right"
                    elseif y > 4 then
                        fleeDir = "up"
                    else
                        fleeDir = "down"
                    end

                    ow.player.facing = "down"

                    ow.runner:run({
                        { "stop_music" },

                        { "play_cry",
                            "SQUIRTLE"
                        },

                        { "emote",
                            "player",
                            "shock",
                            30
                        },

                        { "show_text",
                            "_SquirtleFrightened"
                        },

                        { "move_npc",
                            91,
                            fleeDir,
                            3
                        },

                        { "hide_object",
                            "ROUTE_25",
                            "STARTER_STORIES_SQUIRTLE_WILD"
                        },

                        { "play_default_music" },
                    }, {
                        npc = squirtle
                    })

                    return true
                end
            end

            -- -------------------------------------------------------------
            -- BRUNO �- X33 Y6
            -- -------------------------------------------------------------

            if checkAmbush(
                zoneTrigger(33, 6),
                92,
                33,
                6,
                "STARTER_STORIES_SQUIRTLE_RIVAL3",
                "STARTER_STORIES_SQUIRTLE_RIVAL3",
                "rival3_beat",
                "_SquirtleRival3Talk",
                "_SquirtleRival3Won"
            ) then
                return true
            end

            -- -------------------------------------------------------------
            -- CALEB �- X41 Y6
            -- -------------------------------------------------------------

            if checkAmbush(
                zoneTrigger(41, 6),
                93,
                41,
                6,
                "STARTER_STORIES_SQUIRTLE_RIVAL4",
                "STARTER_STORIES_SQUIRTLE_RIVAL4",
                "rival4_beat",
                "_SquirtleRival4Talk",
                "_SquirtleRival4Won"
            ) then
                return true
            end

            -- -------------------------------------------------------------
            -- ENCUENTRO FINAL: SQUIRTLE + STARMIE
            --
            -- X54 Y4.
            -- El guardián debe ser derrotado antes de permitir la captura.
            -- -------------------------------------------------------------

            -- Trigger por zona alrededor del final (X54 Y4): basta acercarse
            -- hasta dos celdas del SQUIRTLE acorralado para que STARMIE
            -- salga a protegerlo.
            local finalDx = math.abs(x - 54)
            local finalDy = math.abs(y - 4)

            -- Tramo compartido: batalla silvestre del SQUIRTLE acorralado y,
            -- si es capturado, la secuencia con Jenny.  Si el jugador lo
            -- derrota o huye, el SQUIRTLE no desaparece (el label salta al
            -- final sin ocultarlo), así se puede volver a enfrentar.
            local function buildFinalSquirtleFlow()
                return {
                    { "play_cry",
                        "SQUIRTLE"
                    },

                    { "start_battle",
                        "wild",
                        "SQUIRTLE",
                        18
                    },

                    { "check_battle_result",
                        "caught"
                    },

                    { "jump_if_false",
                        "after_squirtle"
                    },

                    { "hide_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_FINAL"
                    },

                    { "squirtle:set_stage",
                        4
                    },

                    { "show_text",
                        "_SquirtleCaught"
                    },

                    -- Jenny viene desde el pasillo sur (X54 Y10) hacia el
                    -- norte, acompañada de dos oficiales.  Es la jefa:
                    -- avanza UN PASO más que los escoltas (hasta Y4, la
                    -- celda del SQUIRTLE).  Los escoltas quedan en Y6/Y7.
                    -- INDICES  PATCH OBJECTS:
                    --   96 = JENNY, 97 = ESCORT1, 98 = ESCORT2
                    { "show_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_JENNY"
                    },

                    { "show_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_ESCORT1"
                    },

                    { "show_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_ESCORT2"
                    },

                    { "move_npc",
                        96,
                        "right",
                        6
                    },

                    { "move_npc",
                        97,
                        "right",
                        6
                    },

                    { "move_npc",
                        98,
                        "right",
                        6
                    },

                    -- Los tres se voltean hacia la DERECHA (este).  El
                    -- runner no tiene ctx.npc propio aquí, así que giramos
                    -- explícitamente a cada uno.
                    { "face_object",
                        96,
                        "right"
                    },

                    { "face_object",
                        97,
                        "right"
                    },

                    { "face_object",
                        98,
                        "right"
                    },

                    { "show_text",
                        "_SquirtleJenny1"
                    },

                    { "show_text",
                        "_SquirtleJenny2"
                    },

                    { "show_text",
                        "_SquirtleJenny3"
                    },

                    { "show_text",
                        "_SquirtleJenny4"
                    },

                    { "show_text",
                        "_SquirtleJenny5"
                    },

                    { "show_text",
                        "_SquirtleJenny6"
                    },

                    { "show_text",
                        "_SquirtleJenny7"
                    },

                    -- Los escoltas regresan por el pasillo sur por donde
                    -- vinieron y se van.  La oficial JENNY se queda en su
                    -- puesto (Y4), de cara a la derecha.
                    { "move_npc",
                        97,
                        "left",
                        4
                    },

                    { "move_npc",
                        98,
                        "left",
                        4
                    },

                    { "move_npc",
                        97,
                        "down",
                        5
                    },

                    { "move_npc",
                        98,
                        "down",
                        5
                    },

                    { "hide_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_ESCORT1"
                    },

                    { "hide_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_ESCORT2"
                    },

                    { "squirtle:set_stage",
                        4
                    },

                    { "play_default_music" },

                    { "label",
                        "after_squirtle"
                    },
                }
            end

            -- -------------------------------------------------------------
            -- Camino 1: el guardián aún no ha sido vencido.
            -- Encuentro completo (STARMIE primero, SQUIRTLE después).
            -- -------------------------------------------------------------

            local function buildGuardianFlow()
                local flow = {
                    { "stop_music" },

                    { "play_cry",
                        "SQUIRTLE"
                    },

                    { "show_text",
                        "_SquirtleGuardianIntro"
                    },

                    { "squirtle:guardian_battle" },

                    { "check_battle_result",
                        "win"
                    },

                    { "jump_if_false",
                        "end_final"
                    },

                    { "show_text",
                        "_SquirtleGuardianWon"
                    },

                    { "squirtle:set_rival",
                        "guardian_beat"
                    },

                    { "hide_object",
                        "ROUTE_25",
                        "STARTER_STORIES_SQUIRTLE_GUARDIAN"
                    },
                }

                -- Si el guardián cae, el SQUIRTLE se encadena en esta
                -- misma visita (el jugador ya está acorralado).
                local squirtleFlow = buildFinalSquirtleFlow()

                for _, cmd in ipairs(squirtleFlow) do
                    table.insert(flow, cmd)
                end

                table.insert(flow, { "label", "end_final" })

                return flow
            end

            if finalDx <= 2 and finalDy <= 2
                and not rivalBeaten("guardian_beat")
            then

                local guardian = ow:npcByIndex(94)
                local finalSquirtle = ow:npcByIndex(95)

                if guardian and finalSquirtle
                    and not guardian.moving
                    and not finalSquirtle.moving
                then

                    ow.runner:run(
                        buildGuardianFlow(),
                        {
                            npc = guardian
                        }
                    )

                    return true
                end
            end

            -- -------------------------------------------------------------
            -- Camino 2: el guardián ya fue vencido pero SQUIRTLE escapó.
            -- Se puede volver a enfrentar; no se oculta al derrotarlo.
            -- -------------------------------------------------------------

            if finalDx <= 2 and finalDy <= 2
                and rivalBeaten("guardian_beat")
            then

                local finalSquirtle = ow:npcByIndex(95)

                if finalSquirtle
                    and getState(STAGE_KEY, 0) == 2
                    and not finalSquirtle.moving
                then

                    local flow = buildFinalSquirtleFlow()
                    table.insert(flow, 1, { "stop_music" })

                    ow.runner:run(flow, {
                        npc = finalSquirtle
                    })

                    return true
                end
            end

            return false
        end,

        talk = {

            TEXT_STARTER_STORIES_SQUIRTLE_RIVAL2 = {
                { "face_player" },

                { "show_text",
                    "_SquirtleRival2Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_SQUIRTLE_RIVAL2",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false",
                    "end"
                },

                { "show_text",
                    "_SquirtleRival2Won"
                },

                { "squirtle:set_rival",
                    "rival2_beat"
                },

                { "hide_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_RIVAL2"
                },

                { "label", "end" },
            },

            TEXT_STARTER_STORIES_SQUIRTLE_RIVAL3 = {
                { "face_player" },

                { "show_text",
                    "_SquirtleRival3Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_SQUIRTLE_RIVAL3",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false",
                    "end"
                },

                { "show_text",
                    "_SquirtleRival3Won"
                },

                { "squirtle:set_rival",
                    "rival3_beat"
                },

                { "hide_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_RIVAL3"
                },

                { "label", "end" },
            },

            TEXT_STARTER_STORIES_SQUIRTLE_RIVAL4 = {
                { "face_player" },

                { "show_text",
                    "_SquirtleRival4Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_SQUIRTLE_RIVAL4",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false", "end" },

                { "show_text",
                    "_SquirtleRival4Won"
                },

                { "squirtle:set_rival",
                    "rival4_beat"
                },

                { "hide_object",
                    "ROUTE_25",
                    "STARTER_STORIES_SQUIRTLE_RIVAL4"
                },

                { "label", "end" },
            },

            TEXT_STARTER_STORIES_SQUIRTLE_WILD = {

                { "face_player" },

                { "play_cry",
                    "SQUIRTLE"
                },

                { "show_text",
                    "_SquirtleFrightened"
                },
            },

            TEXT_STARTER_STORIES_SQUIRTLE_GUARDIAN = {},

            TEXT_STARTER_STORIES_SQUIRTLE_FINAL = {},

            TEXT_STARTER_STORIES_SQUIRTLE_JENNY = {
                { "face_player" },

                { "show_text", "_SquirtleJennyRepeat" },
            },

            TEXT_STARTER_STORIES_SQUIRTLE_ESCORT1 = {
                { "face_player" },

                { "show_text", "_SquirtleEscort1" },
            },

            TEXT_STARTER_STORIES_SQUIRTLE_ESCORT2 = {
                { "face_player" },

                { "show_text", "_SquirtleEscort2" },
            },
        },
    })

    -- =========================================================================
    -- 13. EVENTO pokemon.caught
    --
    -- Respaldo del estado CAUGHT.
    -- No entrega Squirtle y no modifica el Pokémon capturado.
    -- =========================================================================

    mod.events:on("pokemon.caught", function(e)

        if not e then
            return
        end

        if e.species ~= "SQUIRTLE" then
            return
        end

        if getState(STAGE_KEY, 0) ~= 2 then
            return
        end

        setState(STAGE_KEY, 4)
    end)

    -- =========================================================================
    -- 14. QUEST SYSTEM
    -- =========================================================================

    mod.events:on("game.ready", function(payload)

        local game = payload and payload.game or payload

        if not game then
            return
        end

        local journal = mod.find("quest_system")

        if not (
            journal
            and journal.exports
            and journal.exports.register
        ) then
            return
        end

        pcall(
            journal.exports.register,
            {
                id = "starter_stories_squirtle",

                title = "The Problematic Squirtle",

                source = "Starter Stories",

                sort = 160,

                description =
                    "A frightened Squirtle is causing trouble " ..
                    "around Cerulean City. Find out what is happening.",

                objective = function()

                    local currentStage =
                        getState(STAGE_KEY, 0)

                    if currentStage == 1 then
                        return "Follow the trail of Squirtle."
                    end

                    if currentStage == 2 then
                        return "Chase Squirtle along Routes 24 and 25."
                    end

                    if currentStage == 3 then
                        return "Find out what happened to Squirtle."
                    end

                    if currentStage == 4 then
                        return "Mission complete. Take good care of Squirtle!"
                    end

                    return "Find the Squirtle causing trouble in Cerulean City."
                end,

                location = function()

                    local currentStage =
                        getState(STAGE_KEY, 0)

                    if currentStage == 2 then
                        return "Routes 24 and 25"
                    end

                    if currentStage >= 3 then
                        return "Route 25"
                    end

                    return "Cerulean City"
                end,

                reward =
                    "Wild Squirtle, Level 18",

                progress = function()

                    local currentStage =
                        getState(STAGE_KEY, 0)

                    return {
                        current = currentStage,
                        total = 4
                    }
                end,
            }
        )
    end)

    -- Contrato para el orquestador (QuestConnector)
    mod.quests.register("squirtle", {
        stage = function()
            return getState(STAGE_KEY, 0)
        end,
        completed = function()
            return getState(STAGE_KEY, 0) >= 4
        end,
    })

end
