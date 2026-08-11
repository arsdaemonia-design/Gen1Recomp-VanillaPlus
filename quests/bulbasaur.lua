return function(mod)

    -- =========================================================================
    -- 0. ESTADO DE LA MISIÓN
    --
    -- bulbasaur_stage:
    --   0 = NOT_STARTED
    --   1 = STARTED
    --   2 = CAUGHT
    --   3 = COMPLETED
    --
    -- Rivales:
    --   bulba_rival1_beat
    --   bulba_rival2_beat
    --   bulba_rival3_beat
    --   bulba_rival_final_beat
    -- =========================================================================

    local STAGE_KEY = "bulbasaur_stage"

    local function getState(key, default)
        return mod.save:get(key, default)
    end

    local function setState(key, value)
        mod.save:set(key, value)
    end

    local function rivalKey(key)
        return "bulba_" .. tostring(key)
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

    mod.content.commands:register("bulbasaur:set_stage", function(ctx, value)
        setState(STAGE_KEY, tonumber(value) or 0)
    end)

    mod.content.commands:register("bulbasaur:check_stage", function(ctx, value)
        ctx.lastCheck =
            getState(STAGE_KEY, 0) == (tonumber(value) or -1)
    end)

    mod.content.commands:register("bulbasaur:set_rival", function(ctx, key)
        setRivalBeaten(key)
    end)

    mod.content.commands:register("bulbasaur:check_rival", function(ctx, key)
        ctx.lastCheck = rivalBeaten(key)
    end)

    -- =========================================================================
    -- 2. CONDICIONES DE PROGRESIÓN VANILLA
    --
    -- Para iniciar la misión:
    --
    --   - El jugador debe tener BOULDERBADGE.
    --   - Debe haber recibido un starter.
    --   - No debe haber elegido Bulbasaur.
    --
    -- BOULDERBADGE es preferible a EVENT_BEAT_BROCK para esta condición
    -- porque representa el estado persistente de progresión y funciona
    -- correctamente en partidas donde el mod se instala posteriormente.
    -- =========================================================================

    local function hasBoulderBadge(game)
        local save = game and game.save
        local inventory = save and save.inventory or {}

        return (inventory["BOULDERBADGE"] or 0) > 0
    end

    local function hasStarter(game)
        local flags = game and game.save and game.save.flags

        return not not (
            flags
            and flags.EVENT_GOT_STARTER
        )
    end

    local function choseBulbasaur(game)
        local flags = game and game.save and game.save.flags

        return not not (
            flags
            and flags.EVENT_CHOSE_BULBASAUR
        )
    end

    -- =========================================================================
    -- 3. SPRITE PERSONALIZADO DE BULBASAUR
    --
    -- No modificamos la definición global de BULBASAUR.
    -- =========================================================================

    mod.content.sprites:register("SPRITE_FOLLOWER_BULBASAUR", {
        id = "SPRITE_FOLLOWER_BULBASAUR",
        image = mod.assets:path(
            "assets/poke_followers/follower_001.png"
        ),
        frames = 6,
        walker = true,
        trueColor = true,
    })

    -- =========================================================================
    -- 4. ENTRENADORES RIVALES
    -- =========================================================================

    mod.content.trainers:register("STARTER_STORIES_BULBA_RIVAL1", {
        id = "STARTER_STORIES_BULBA_RIVAL1",
        name = "Liam",
        basePic = "OPP_BUG_CATCHER",
        baseMoney = 15,

        parties = {
            {
                { level = 11, species = "WEEDLE" },
                { level = 11, species = "CATERPIE" },
                { level = 12, species = "KAKUNA" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_BULBA_RIVAL2", {
        id = "STARTER_STORIES_BULBA_RIVAL2",
        name = "Lorenzo",
        basePic = "OPP_BUG_CATCHER",
        baseMoney = 15,

        parties = {
            {
                { level = 11, species = "CATERPIE" },
                { level = 12, species = "METAPOD" },
                { level = 12, species = "KAKUNA" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_BULBA_RIVAL3", {
        id = "STARTER_STORIES_BULBA_RIVAL3",
        name = "Oliver",
        basePic = "OPP_YOUNGSTER",
        baseMoney = 15,

        parties = {
            {
                { level = 11, species = "RATTATA" },
                { level = 12, species = "ZUBAT" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_BULBA_FINAL_RIVAL", {
        id = "STARTER_STORIES_BULBA_FINAL_RIVAL",
        name = "Nico",
        basePic = "OPP_YOUNGSTER",
        baseMoney = 20,

        parties = {
            {
                { level = 12, species = "NIDORAN_M" },
                { level = 12, species = "RATTATA" },
                { level = 13, species = "SPEAROW" },
            },
        },
    })

    -- =========================================================================
    -- 5. TEXTOS BASE
    --
    -- BASE = INGLÉS
    -- ESPAÑOL = game.ready cuando recomp-spanish está activo.
    -- =========================================================================

    mod.content.text:register(
        "_BulbaPewterHint",
        "Have you seen a girl looking for her BULBASAUR?\n" ..
        "She looked really worried."
    )

    mod.content.text:register(
        "_BulbaOwnerIntro1",
        "Wait!"
    )

    mod.content.text:register(
        "_BulbaOwnerIntro2",
        "Oh, I was so foolish! I lost my BULBASAUR...\n" ..
        "I tried to train it, but I was way too hard on it."
    )

    mod.content.text:register(
        "_BulbaOwnerIntro3",
        "It got scared and ran away!\n" ..
        "I think it fled south, into the VIRIDIAN FOREST."
    )

    mod.content.text:register(
        "_BulbaOwnerIntro4",
        "If you find him... please, help him."
    )

    mod.content.text:register(
        "_BulbaOwnerWaiting",
        "Please look for him in the VIRIDIAN FOREST!\n" ..
        "He must be so scared..."
    )

    mod.content.text:register(
        "_BulbaOwnerCaught",
        "Is that BULBASAUR with you?!\n" ..
        "Oh... he looks so happy by your side...\n\n" ..
        "Maybe I am not the trainer he needs.\n" ..
        "Please... keep him!"
    )

    mod.content.text:register(
        "_BulbaOwnerDone",
        "I'll look for a POKéMON that fits my style better.\n" ..
        "Thank you so much!"
    )

    mod.content.text:register(
        "_BulbaRival1Talk",
        "Liam: Are you looking for that BULBASAUR?\n" ..
        "I saw him first! Let's battle!"
    )

    mod.content.text:register(
        "_BulbaRival1Won",
        "Liam: Awww, you're too strong!\n" ..
        "It went further north..."
    )

    mod.content.text:register(
        "_BulbaRival2Talk",
        "Lorenzo: Don't even think about stealing\n" ..
        "my friend's BULBASAUR!"
    )

    mod.content.text:register(
        "_BulbaRival2Won",
        "Lorenzo: Ouch! Okay, okay, you win!\n" ..
        "He's hidden near the northeastern clear."
    )

    mod.content.text:register(
        "_BulbaRival3Talk",
        "Oliver: Hey, have you seen a frightened little POKéMON?\n" ..
        "I think it went that way, but Nico is tracking it too."
    )

    mod.content.text:register(
        "_BulbaRival3Won",
        "Oliver: Ouch!\n" ..
        "I think it went that way, but Nico is tracking it too."
    )

    mod.content.text:register(
        "_BulbaFinalTalk",
        "Nico: Hey! Back off!\n" ..
        "This rare POKéMON is mine!"
    )

    mod.content.text:register(
        "_BulbaFinalWon",
        "Nico: No way! I'm out of here!"
    )

    mod.content.text:register(
        "_BulbaWildScared",
        "BULBASAUR is hiding behind a bush.\n" ..
        "It looks too scared to approach while that trainer is around."
    )

    mod.content.text:register(
        "_BulbaWildCalm",
        "BULBASAUR looks calmed down now..."
    )

    mod.content.text:register(
        "_BulbaWildDefeated",
        "BULBASAUR was defeated!\n" ..
        "It fled deeper into the forest..."
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

        text._BulbaPewterHint =
            "¿Has visto a una chica buscando a su BULBASAUR?\n" ..
            "Parecía bastante preocupada."

        text._BulbaOwnerIntro1 =
            "¡Espera!"

        text._BulbaOwnerIntro2 =
            "¡Ay, soy una tonta! Perdí a mi BULBASAUR...\n" ..
            "Intenté entrenarlo, pero fui demasiado dura con él."

        text._BulbaOwnerIntro3 =
            "¡Se asustó y salió corriendo!\n" ..
            "Creo que huyó hacia el sur, hacia el BOSQUE VERDE."

        text._BulbaOwnerIntro4 =
            "Si lo encuentras... por favor, ayúdalo."

        text._BulbaOwnerWaiting =
            "¡Por favor, búscalo en el BOSQUE VERDE!\n" ..
            "¡Debe estar tan asustado!..."

        text._BulbaOwnerCaught =
            "¡¿Ese BULBASAUR está contigo?!\n" ..
            "Oh... se ve tan feliz a tu lado...\n\n" ..
            "Quizá yo no soy la entrenadora que necesita.\n" ..
            "Por favor... ¡quédate con él!"

        text._BulbaOwnerDone =
            "Buscaré un POKéMON que se adapte mejor a mi estilo.\n" ..
            "¡Muchas gracias!"

        text._BulbaRival1Talk =
            "Liam: ¿Estás buscando a ese BULBASAUR?\n" ..
            "¡Yo lo vi primero! ¡A combatir!"

        text._BulbaRival1Won =
            "Liam: ¡Ugh, eres muy fuerte!\n" ..
            "Cruzó hacia el norte..."

        text._BulbaRival2Talk =
            "Lorenzo: Ni se te ocurra robar\n" ..
            "el BULBASAUR de mi amiga."

        text._BulbaRival2Won =
            "Lorenzo: ¡Auch! ¡Vale, vale, ganas!\n" ..
            "Está escondido cerca del claro del noreste."

        text._BulbaRival3Talk =
            "Oliver: Oye, ¿no has visto a un POKéMON asustadito?\n" ..
            "Creo que fue por ahí, pero Nico lo está siguiendo."

        text._BulbaRival3Won =
            "Oliver: ¡Auch!\n" ..
            "Creo que fue por ahí, pero Nico lo está siguiendo."

        text._BulbaFinalTalk =
            "Nico: ¡Oye! ¡Aléjate!\n" ..
            "¡Este POKéMON raro es mío!"

        text._BulbaFinalWon =
            "Nico: ¡No puede ser! ¡Me largo de aquí!"

        text._BulbaWildScared =
            "BULBASAUR está escondido detrás de un arbusto.\n" ..
            "Parece demasiado asustado para acercarse mientras ese entrenador siga aquí."

        text._BulbaWildCalm =
            "BULBASAUR parece más tranquilo ahora..."

        text._BulbaWildDefeated =
            "¡BULBASAUR ha sido derrotado!\n" ..
            "Huyó hacia lo más profundo del bosque..."
    end)

    -- =========================================================================
    -- 7. OBJETOS DE MAPA
    --
    -- Todos permanecen estáticos y ocultos.
    -- No cambiamos a runtime spawning porque aquí no hace falta.
    -- =========================================================================

    mod.content.maps:patch("PEWTER_CITY", {
        objects = {
            __append = {
                {
                    index = 95,
                    name = "STARTER_STORIES_BULBA_PEWTER_LASSIE",
                    text = "TEXT_STARTER_STORIES_BULBA_PEWTER_LASSIE",
                    sprite = "SPRITE_COOLTRAINER_F",
                    x = 16,
                    y = 20,
                    movement = "STAY",
                    range = "DOWN",
                },
            },
        },
    })

    mod.content.maps:patch("ROUTE_3", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_BULBA_OWNER",
                    text = "TEXT_STARTER_STORIES_BULBA_OWNER_WAITING",
                    sprite = "SPRITE_COOLTRAINER_F",
                    x = 14,
                    y = 9,
                    movement = "STAY",
                    range = "LEFT",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("VIRIDIAN_FOREST", {
        objects = {
            __append = {

                {
                    index = 51,
                    name = "STARTER_STORIES_BULBA_RIVAL1",
                    text = "TEXT_STARTER_STORIES_BULBA_RIVAL1",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 5,
                    y = 23,
                    movement = "STAY",
                    range = "RIGHT",
                    hidden = true,
                },

                {
                    index = 52,
                    name = "STARTER_STORIES_BULBA_RIVAL2",
                    text = "TEXT_STARTER_STORIES_BULBA_RIVAL2",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 6,
                    y = 15,
                    movement = "STAY",
                    range = "RIGHT",
                    hidden = true,
                },

                {
                    index = 53,
                    name = "STARTER_STORIES_BULBA_RIVAL3",
                    text = "TEXT_STARTER_STORIES_BULBA_RIVAL3",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 14,
                    y = 17,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },

                {
                    index = 54,
                    name = "STARTER_STORIES_BULBA_WILD",
                    text = "TEXT_STARTER_STORIES_BULBA_WILD",
                    sprite = "SPRITE_FOLLOWER_BULBASAUR",
                    x = 32,
                    y = 1,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },

                {
                    index = 55,
                    name = "STARTER_STORIES_BULBA_RIVAL_FINAL",
                    text = "TEXT_STARTER_STORIES_BULBA_RIVAL_FINAL",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 31,
                    y = 2,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },

            },
        },
    })

    -- =========================================================================
    -- 8. PEWTER CITY
    -- =========================================================================

    mod.content.map_scripts:register("PEWTER_CITY", {

        talk = {

            TEXT_STARTER_STORIES_BULBA_PEWTER_LASSIE = {
                { "show_text", "_BulbaPewterHint" },
            },

        },
    })

    -- =========================================================================
    -- 9. ROUTE 3
    --
    -- Trigger de la misión:
    --
    --   X = 9
    --   Y = 8..12
    --
    -- Se conserva deliberadamente toda la franja vertical.
    -- =========================================================================

    mod.content.map_scripts:register("ROUTE_3", {

        onStep = function(game, ow, x, y)

            -- Nunca iniciar otra escena mientras el runner está ocupado.
            if ow.runner:isRunning() then
                return false
            end

            -- -------------------------------------------------------------
            -- Franja de activación
            -- -------------------------------------------------------------

            if x ~= 9 then
                return false
            end

            if y < 8 or y > 12 then
                return false
            end

            -- -------------------------------------------------------------
            -- Quest ya iniciada/completada
            -- -------------------------------------------------------------

            if getState(STAGE_KEY, 0) ~= 0 then
                return false
            end

            -- -------------------------------------------------------------
            -- Requisitos de progresión
            -- -------------------------------------------------------------

            if not hasBoulderBadge(game) then
                return false
            end

            if not hasStarter(game) then
                return false
            end

            if choseBulbasaur(game) then
                return false
            end

            -- -------------------------------------------------------------
            -- Activamos la escena
            -- -------------------------------------------------------------

            ow:queueScript({

                { "stop_music" },

                { "play_music",
                    "Music_MeetFemaleTrainer"
                },

                { "show_object",
                    "ROUTE_3",
                    "STARTER_STORIES_BULBA_OWNER"
                },

                -- La dueña aparece ligeramente a la derecha del jugador.
                { "place_npc",
                    90,
                    15,
                    y,
                    "left"
                },

                { "emote",
                    "player",
                    "shock",
                    30
                },

                { "move_npc_to",
                    90,
                    10,
                    y
                },

                { "face_player" },

                { "show_text",
                    "_BulbaOwnerIntro1"
                },

                { "show_text",
                    "_BulbaOwnerIntro2"
                },

                { "show_text",
                    "_BulbaOwnerIntro3"
                },

                { "show_text",
                    "_BulbaOwnerIntro4"
                },

                { "bulbasaur:set_stage",
                    1
                },

                { "play_default_music" },

                { "label",
                    "end"
                },
            })

            return true
        end,

        -- ---------------------------------------------------------------------
        -- TALK DE LA DUEÑA
        -- ---------------------------------------------------------------------

        talk = {

            TEXT_STARTER_STORIES_BULBA_OWNER_WAITING = {

                -- -------------------------------------------------------------
                -- COMPLETADA
                -- -------------------------------------------------------------

                { "bulbasaur:check_stage", 3 },
                { "jump_if_true", "done" },

                -- -------------------------------------------------------------
                -- BULBASAUR CAPTURADO
                -- -------------------------------------------------------------

                { "bulbasaur:check_stage", 2 },
                { "jump_if_true", "caught" },

                -- -------------------------------------------------------------
                -- MISIÓN EN CURSO
                -- -------------------------------------------------------------

                { "show_text",
                    "_BulbaOwnerWaiting"
                },

                { "jump",
                    "end"
                },

                -- -------------------------------------------------------------
                -- REGRESÓ CON BULBASAUR
                -- -------------------------------------------------------------

                { "label",
                    "caught"
                },

                { "show_text",
                    "_BulbaOwnerCaught"
                },

                { "show_text",
                    "_BulbaOwnerDone"
                },

                -- No usamos una variable y inexistente aquí.
                -- La dueña simplemente sale caminando y desaparece.
                { "move_npc",
                    90,
                    "right",
                    5
                },

                { "hide_object",
                    "ROUTE_3",
                    "STARTER_STORIES_BULBA_OWNER"
                },

                { "bulbasaur:set_stage",
                    3
                },

                { "jump",
                    "end"
                },

                -- -------------------------------------------------------------
                -- YA COMPLETADA
                -- -------------------------------------------------------------

                { "label",
                    "done"
                },

                { "show_text",
                    "_BulbaOwnerDone"
                },

                { "label",
                    "end"
                },
            },
        },
    })

    -- =========================================================================
    -- 10. VIRIDIAN FOREST
    -- =========================================================================

    mod.content.map_scripts:register("VIRIDIAN_FOREST", {

        -- ---------------------------------------------------------------------
        -- ENTRADA AL BOSQUE
        --
        -- Muestra únicamente los rivales que todavía no han sido derrotados.
        -- ---------------------------------------------------------------------

        onEnter = function(game, ow)

            if getState(STAGE_KEY, 0) ~= 1 then
                return
            end

            local rows = {}

            local function showIfNotBeat(objectName, key)

                table.insert(rows, {
                    "bulbasaur:check_rival",
                    key
                })

                table.insert(rows, {
                    "jump_if_true",
                    "skip_" .. key
                })

                table.insert(rows, {
                    "show_object",
                    "VIRIDIAN_FOREST",
                    objectName
                })

                table.insert(rows, {
                    "label",
                    "skip_" .. key
                })
            end

            showIfNotBeat(
                "STARTER_STORIES_BULBA_RIVAL1",
                "rival1_beat"
            )

            showIfNotBeat(
                "STARTER_STORIES_BULBA_RIVAL2",
                "rival2_beat"
            )

            showIfNotBeat(
                "STARTER_STORIES_BULBA_RIVAL3",
                "rival3_beat"
            )

            -- Bulbasaur siempre está presente mientras la misión está activa.
            table.insert(rows, {
                "show_object",
                "VIRIDIAN_FOREST",
                "STARTER_STORIES_BULBA_WILD"
            })

            ow:queueScript(rows)
        end,

        -- ---------------------------------------------------------------------
        -- ON STEP
        -- ---------------------------------------------------------------------

        onStep = function(game, ow, x, y)

            -- -------------------------------------------------------------
            -- Nunca lanzar otra escena mientras el runner está ocupado.
            -- -------------------------------------------------------------

            if ow.runner:isRunning() then
                return false
            end

            -- -------------------------------------------------------------
            -- NICO — EMBOSCADA FINAL
            --
            -- Bulbasaur está en:
            --   X=32, Y=1
            --
            -- Cubrimos las cuatro celdas adyacentes.
            -- -------------------------------------------------------------

            local isAdjacentToBulba =
                (x == 31 and y == 1)
                or
                (x == 33 and y == 1)
                or
                (x == 32 and y == 0)
                or
                (x == 32 and y == 2)

            if
                isAdjacentToBulba
                and getState(STAGE_KEY, 0) == 1
                and not rivalBeaten("rival_final_beat")
            then

                ow:queueScript({

                    { "stop_music" },

                    { "play_music",
                        "Music_MeetMaleTrainer"
                    },

                    { "show_object",
                        "VIRIDIAN_FOREST",
                        "STARTER_STORIES_BULBA_RIVAL_FINAL"
                    },

                    { "place_npc",
                        55,
                        30,
                        2,
                        "right"
                    },

                    { "emote",
                        "player",
                        "shock",
                        30
                    },

                    { "wait",
                        15
                    },

                    { "move_npc_to",
                        55,
                        x,
                        y
                    },

                    { "face_player" },

                    { "show_text",
                        "_BulbaFinalTalk"
                    },

                    { "start_battle",
                        "trainer",
                        "STARTER_STORIES_BULBA_FINAL_RIVAL",
                        1
                    },

                    { "check_battle_result",
                        "win"
                    },

                    { "jump_if_false",
                        "end"
                    },

                    { "show_text",
                        "_BulbaFinalWon"
                    },

                    { "bulbasaur:set_rival",
                        "rival_final_beat"
                    },

                    { "hide_object",
                        "VIRIDIAN_FOREST",
                        "STARTER_STORIES_BULBA_RIVAL_FINAL"
                    },

                    { "play_default_music" },

                    { "label",
                        "end"
                    },
                })

                return true
            end

            -- -------------------------------------------------------------
            -- Los tres rivales secundarios
            -- -------------------------------------------------------------

            if getState(STAGE_KEY, 0) ~= 1 then
                return false
            end

            -- -------------------------------------------------------------
            -- Helper de emboscadas
            --
            -- trainerId:
            --   ID del entrenador usado por start_battle.
            --
            -- objectName:
            --   nombre exacto del objeto del mapa usado por hide_object.
            --
            -- Se mantienen separados deliberadamente.
            -- -------------------------------------------------------------

            local function checkSightAndAmbush(
                sightCondition,
                rivalIndex,
                trainerId,
                objectName,
                rivalFlag,
                faceDir,
                walkDir,
                walkSteps,
                textIntro,
                textWin
            )

                if not sightCondition then
                    return false
                end

                if rivalBeaten(rivalFlag) then
                    return false
                end

                local npc = ow:npcByIndex(rivalIndex)

                if not npc then
                    return false
                end

                if npc.moving then
                    return false
                end

                ow.player.facing = faceDir

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
                        30
                    },

                    { "move_npc",
                        rivalIndex,
                        walkDir,
                        walkSteps
                    },

                    { "face_player" },

                    { "show_text",
                        textIntro
                    },

                    { "start_battle",
                        "trainer",
                        trainerId,
                        1
                    },

                    { "check_battle_result",
                        "win"
                    },

                    { "jump_if_false",
                        "end_ambush"
                    },

                    { "show_text",
                        textWin
                    },

                    { "bulbasaur:set_rival",
                        rivalFlag
                    },

                    -- FIX:
                    -- usamos objectName, no trainerId.
                    { "hide_object",
                        "VIRIDIAN_FOREST",
                        objectName
                    },

                    { "play_default_music" },

                    { "label",
                        "end_ambush"
                    },

                }, {
                    npc = npc
                })

                return true
            end

            -- -------------------------------------------------------------
            -- LIAM
            -- X=5, Y=23
            -- -------------------------------------------------------------

            if checkSightAndAmbush(
                (y == 23 and x > 5 and x <= 9),
                51,
                "STARTER_STORIES_BULBA_RIVAL1",
                "STARTER_STORIES_BULBA_RIVAL1",
                "rival1_beat",
                "left",
                "right",
                x - 5 - 1,
                "_BulbaRival1Talk",
                "_BulbaRival1Won"
            ) then
                return true
            end

            -- -------------------------------------------------------------
            -- LORENZO
            -- X=6, Y=15
            -- -------------------------------------------------------------

            if checkSightAndAmbush(
                (y == 15 and x > 6 and x <= 10),
                52,
                "STARTER_STORIES_BULBA_RIVAL2",
                "STARTER_STORIES_BULBA_RIVAL2",
                "rival2_beat",
                "left",
                "right",
                x - 6 - 1,
                "_BulbaRival2Talk",
                "_BulbaRival2Won"
            ) then
                return true
            end

            -- -------------------------------------------------------------
            -- OLIVER
            -- X=14, Y=17
            -- -------------------------------------------------------------

            if checkSightAndAmbush(
                (x == 14 and y > 17 and y <= 21),
                53,
                "STARTER_STORIES_BULBA_RIVAL3",
                "STARTER_STORIES_BULBA_RIVAL3",
                "rival3_beat",
                "up",
                "down",
                y - 17 - 1,
                "_BulbaRival3Talk",
                "_BulbaRival3Won"
            ) then
                return true
            end

            return false
        end,

        -- ---------------------------------------------------------------------
        -- TALKS
        -- ---------------------------------------------------------------------

        talk = {

            -- ================================================================
            -- LIAM
            -- ================================================================

            TEXT_STARTER_STORIES_BULBA_RIVAL1 = {

                { "face_player" },

                { "show_text",
                    "_BulbaRival1Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_BULBA_RIVAL1",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false",
                    "end"
                },

                { "show_text",
                    "_BulbaRival1Won"
                },

                { "bulbasaur:set_rival",
                    "rival1_beat"
                },

                { "hide_object",
                    "VIRIDIAN_FOREST",
                    "STARTER_STORIES_BULBA_RIVAL1"
                },

                { "label",
                    "end"
                },
            },

            -- ================================================================
            -- LORENZO
            -- ================================================================

            TEXT_STARTER_STORIES_BULBA_RIVAL2 = {

                { "face_player" },

                { "show_text",
                    "_BulbaRival2Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_BULBA_RIVAL2",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false",
                    "end"
                },

                { "show_text",
                    "_BulbaRival2Won"
                },

                { "bulbasaur:set_rival",
                    "rival2_beat"
                },

                { "hide_object",
                    "VIRIDIAN_FOREST",
                    "STARTER_STORIES_BULBA_RIVAL2"
                },

                { "label",
                    "end"
                },
            },

            -- ================================================================
            -- OLIVER
            -- ================================================================

            TEXT_STARTER_STORIES_BULBA_RIVAL3 = {

                { "face_player" },

                { "show_text",
                    "_BulbaRival3Talk"
                },

                { "start_battle",
                    "trainer",
                    "STARTER_STORIES_BULBA_RIVAL3",
                    1
                },

                { "check_battle_result",
                    "win"
                },

                { "jump_if_false",
                    "end"
                },

                { "show_text",
                    "_BulbaRival3Won"
                },

                { "bulbasaur:set_rival",
                    "rival3_beat"
                },

                { "hide_object",
                    "VIRIDIAN_FOREST",
                    "STARTER_STORIES_BULBA_RIVAL3"
                },

                { "label",
                    "end"
                },
            },

            -- ================================================================
            -- NICO
            --
            -- Nico no necesita un talk normal porque la escena se dispara
            -- mediante onStep al acercarse a Bulbasaur.
            -- ================================================================

            TEXT_STARTER_STORIES_BULBA_RIVAL_FINAL = {},

            -- ================================================================
            -- BULBASAUR
            --
            -- IMPORTANTE:
            --
            -- El jugador puede llegar directamente hasta Bulbasaur desde
            -- cualquier dirección.
            --
            -- Pero si Nico todavía no ha sido derrotado, Bulbasaur NO combate.
            --
            -- Esto evita que el jugador pueda saltarse la emboscada final.
            -- ================================================================

            TEXT_STARTER_STORIES_BULBA_WILD = {

                -- ------------------------------------------------------------
                -- ¿NICO YA FUE DERROTADO?
                -- ------------------------------------------------------------

                { "bulbasaur:check_rival",
                    "rival_final_beat"
                },

                { "jump_if_true",
                    "ready"
                },

                -- ------------------------------------------------------------
                -- NICO SIGUE ACTIVO
                -- ------------------------------------------------------------

                { "face_player" },

                { "play_cry",
                    "BULBASAUR"
                },

                { "show_text",
                    "_BulbaWildScared"
                },

                { "jump",
                    "end"
                },

                -- ------------------------------------------------------------
                -- NICO DERROTADO
                -- ------------------------------------------------------------

                { "label",
                    "ready"
                },

                { "face_player" },

                { "play_cry",
                    "BULBASAUR"
                },

                { "show_text",
                    "_BulbaWildCalm"
                },

                -- ------------------------------------------------------------
                -- BATALLA SALVAJE REAL
                --
                -- NO setup_moves.
                -- NO teardown_moves.
                -- NO mutación de game.data.pokemon.
                -- ------------------------------------------------------------

                { "start_battle",
                    "wild",
                    "BULBASAUR",
                    12
                },

                -- ------------------------------------------------------------
                -- Si fue capturado → stage 2.
                -- ------------------------------------------------------------

                { "check_battle_result",
                    "caught"
                },

                { "jump_if_true",
                    "captured"
                },

                -- ------------------------------------------------------------
                -- Si fue derrotado pero NO capturado:
                -- no completamos la misión.
                --
                -- El stage sigue en 1.
                -- Al volver a entrar al bosque, Bulbasaur reaparece.
                -- ------------------------------------------------------------

                { "check_battle_result",
                    "win"
                },

                { "jump_if_true",
                    "defeated"
                },

                -- Run / lose / cualquier otro resultado.
                { "jump",
                    "end"
                },

                -- ------------------------------------------------------------
                -- BULBASAUR CAPTURADO
                -- ------------------------------------------------------------

                { "label",
                    "captured"
                },

                { "hide_object",
                    "VIRIDIAN_FOREST",
                    "STARTER_STORIES_BULBA_WILD"
                },

                { "bulbasaur:set_stage",
                    2
                },

                { "jump",
                    "end"
                },

                -- ------------------------------------------------------------
                -- BULBASAUR DERROTADO SIN CAPTURA
                -- ------------------------------------------------------------

                { "label",
                    "defeated"
                },

                { "show_text",
                    "_BulbaWildDefeated"
                },

                { "hide_object",
                    "VIRIDIAN_FOREST",
                    "STARTER_STORIES_BULBA_WILD"
                },

                -- Stage permanece en 1.
                -- Se podrá volver a encontrar al entrar nuevamente al bosque.

                { "jump",
                    "end"
                },

                { "label",
                    "end"
                },
            },
        },
    })

    -- =========================================================================
    -- 11. EVENTO pokemon.caught
    --
    -- Es respaldo del estado CAUGHT.
    --
    -- No entrega Bulbasaur.
    -- No modifica sus movimientos.
    -- Solo sincroniza nuestra quest después de una captura real.
    -- =========================================================================

    mod.events:on("pokemon.caught", function(e)

        if not e then
            return
        end

        if e.species ~= "BULBASAUR" then
            return
        end

        if getState(STAGE_KEY, 0) ~= 1 then
            return
        end

        setState(STAGE_KEY, 2)
    end)

    -- =========================================================================
    -- 12. QUEST SYSTEM
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
                id = "starter_stories_bulbasaur",

                title = "The Lost Bulbasaur",

                source = "Starter Stories",

                sort = 150,

                description =
                    "A worried Lass lost her Bulbasaur in Viridian Forest. " ..
                    "Find it and let it choose its trainer.",

                objective = function()

                    local currentStage =
                        getState(STAGE_KEY, 0)

                    if currentStage == 1 then
                        return "Find Bulbasaur in Viridian Forest."
                    end

                    if currentStage == 2 then
                        return "Return to the Lass on Route 3."
                    end

                    if currentStage == 3 then
                        return "Mission complete. Take good care of Bulbasaur!"
                    end

                    return "Find the worried Lass on Route 3."
                end,

                location = function()

                    local currentStage =
                        getState(STAGE_KEY, 0)

                    if currentStage == 1 then
                        return "Viridian Forest"
                    end

                    return "Route 3"
                end,

                reward =
                    "Wild Bulbasaur, Level 12",

                progress = function()

                    local currentStage =
                        getState(STAGE_KEY, 0)

                    return {
                        current = currentStage,
                        total = 3
                    }
                end,
            }
        )
    end)

end