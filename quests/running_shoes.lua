return function(mod)
    -- =========================================================================
    -- ESTADO CENTRALIZADO (mod.save) — desacoplado del progreso vanilla
    -- stage: 0=no_empezada | 1=escena_vista | 2=ladrón_derrotado | 3=completada
    -- =========================================================================
    local STAGE_KEY = "mod:running_shoes_stage"

    local function stage()
        return mod.save:get(STAGE_KEY, 0)
    end

    local function setStage(value)
        mod.save:set(STAGE_KEY, value)
    end

    -- Comandos custom para leer/escribir estado dentro de MapScripts
    mod.content.commands:register("running_shoes:check_stage", function(ctx, value)
        ctx.lastCheck = stage() == (tonumber(value) or -1)
    end)
    mod.content.commands:register("running_shoes:set_stage", function(ctx, value)
        setStage(tonumber(value) or 0)
    end)

    -- =========================================================================
    -- 1. ITEMS
    -- =========================================================================
    mod.content.items:register("RUNNING_SHOES_STOLEN", {
        id = "RUNNING_SHOES_STOLEN",
        name = "Stolen Running Shoes",
        price = 0,
        keyItem = true,
        tossable = false,
    })

    mod.content.items:register("RUNNING_SHOES", {
        id = "RUNNING_SHOES",
        name = "Running Shoes",
        price = 0,
        keyItem = true,
        tossable = false,
    })

    -- =========================================================================
    -- 2. TRAINER
    -- =========================================================================
    mod.content.trainers:register("RUNNING_SHOES_THIEF", {
        id = "RUNNING_SHOES_THIEF",
        name = "Thief",
        basePic = "OPP_SUPER_NERD",
        baseMoney = 180,
        parties = {
            {
                { species = "RATTATA", level = 8 },
                { species = "ZUBAT",   level = 9 },
            },
        },
    })

    -- =========================================================================
    -- 3. TEXTOS — Base en inglés, override a español si detecta recomp-spanish
    -- =========================================================================
    mod.content.text:register("_RunningShoesSceneIntro",
        "Help! That thief took something from me and ran toward Route 2.")
    mod.content.text:register("_RunningShoesSceneDetails",
        "They were a special pair of shoes. Catch him, recover them, and bring them back here.")
    mod.content.text:register("_RunningShoesAskHelp",
        "Will you help us recover the shoes?")
    mod.content.text:register("_RunningShoesDeclined",
        "I understand. Come back if you change your mind.")
    mod.content.text:register("_RunningShoesVictimWaiting",
        "The victim will wait here until you recover the shoes.")
    mod.content.text:register("_RunningShoesVictimMissing",
        "The thief still has my shoes. He must be somewhere on Route 2!")
    mod.content.text:register("_RunningShoesThiefIntro",
        "Stay out of this! These shoes are mine now.")
    mod.content.text:register("_RunningShoesBattleLost",
        "The thief got away with the item. Try again.")
    mod.content.text:register("_RunningShoesBattleWon",
        "You win! Here, you recovered the stolen item.")
    mod.content.text:register("_RunningShoesAlreadyDefeated",
        "All right, you beat me. Enjoy them.")
    mod.content.text:register("_RunningShoesVictimReward",
        "You recovered my shoes! Keep this pair as a thank-you.\nHold B while walking to run faster.")
    mod.content.text:register("_RunningShoesCompleted",
        "Thank you for your help. I can get back to work now.")

    -- Inyección de español en runtime (mutación directa, bypass del freeze)
    mod.events:on("game.ready", function(ev)
        local game = ev and ev.game
        local mods = game and game.mods and game.mods.mods
        local spanish = mods and mods["recomp-spanish"]
        if not (spanish and spanish.enabled) then return end

        local text = game.data and game.data.text
        if not text then return end

        text._RunningShoesSceneIntro   = "¡Ayuda! Un sujeto robó algo y escapó hacia la Ruta 2."
        text._RunningShoesSceneDetails = "Era un par de zapatillas especiales. Si lo alcanzas, recupera el objeto y tráelo aquí."
        text._RunningShoesAskHelp      = "¿Quieres ayudar a recuperar las zapatillas?"
        text._RunningShoesDeclined     = "Entiendo. Vuelve cuando quieras ayudarnos."
        text._RunningShoesVictimWaiting= "La víctima esperará aquí hasta que recuperes las zapatillas."
        text._RunningShoesVictimMissing= "El ladrón todavía tiene mis zapatillas. ¡Debe estar en la Ruta 2!"
        text._RunningShoesThiefIntro   = "¡No te metas! Estas zapatillas son mías ahora."
        text._RunningShoesBattleLost   = "El ladrón escapó con el objeto. Inténtalo de nuevo."
        text._RunningShoesBattleWon    = "¡Ganaste! Toma, recuperaste el objeto robado."
        text._RunningShoesAlreadyDefeated = "Está bien, me venciste, disfrútalas."
        text._RunningShoesVictimReward = "¡Recuperaste mis zapatillas! Pero ya he comprado otras. Quédate con este par. Mantén B mientras caminas para correr más rápido."
        text._RunningShoesCompleted    = "Gracias por tu ayuda. Ahora puedo volver a trabajar."

        if game.data.items then
            if game.data.items.RUNNING_SHOES_STOLEN then
                game.data.items.RUNNING_SHOES_STOLEN.name = "Zapatillas robadas"
            end
            if game.data.items.RUNNING_SHOES then
                game.data.items.RUNNING_SHOES.name = "Zapatillas para correr"
            end
        end
        if game.data.trainers and game.data.trainers.RUNNING_SHOES_THIEF then
            game.data.trainers.RUNNING_SHOES_THIEF.name = "Ladrón"
        end
    end)

    -- =========================================================================
    -- 4. MAP PATCHES (NPCs)
    -- =========================================================================
    mod.content.maps:patch("VIRIDIAN_MART", {
        objects = {
            __append = {
                {
                    index = 4,
                    name = "RUNNING_SHOES_VICTIM",
                    sprite = "SPRITE_YOUNGSTER",
                    movement = "STAY",
                    range = "UP",
                    x = 6,
                    y = 5,
                    hidden = true,
                    text = "TEXT_RUNNING_SHOES_VICTIM",
                },
            },
        },
    })

    mod.content.maps:patch("ROUTE_2", {
        objects = {
            __append = {
                {
                    index = 3,
                    name = "RUNNING_SHOES_THIEF_NPC",
                    sprite = "SPRITE_SUPER_NERD",
                    movement = "STAY",
                    range = "LEFT",
                    x = 3,
                    y = 60,
                    hidden = true,
                    text = "TEXT_RUNNING_SHOES_THIEF",
                },
            },
        },
    })

    -- =========================================================================
    -- 5. MAP SCRIPTS — TENDER DE VIRIDIAN MART (trigger retrocompatible)
    -- =========================================================================
    mod.content.map_scripts:register("VIRIDIAN_MART", {
        talk = {
            TEXT_VIRIDIANMART_CLERK = {
                -- A) Si ya completó la misión → tienda normal
                { "running_shoes:check_stage", 3 },
                { "jump_if_true", "vanilla_shop" },

                -- B) Si ya tiene la recompensa en el inventario → tienda normal
                { "check_item", "RUNNING_SHOES" },
                { "jump_if_true", "vanilla_shop" },

                -- C) Si la escena ya se inició → tienda normal (la víctima maneja el resto)
                { "running_shoes:check_stage", 1 },
                { "jump_if_true", "vanilla_shop" },

                -- D) FLUJO VANILLA DEL PARCEL (solo para partidas nuevas que aún no lo tienen)
                { "check_flag", "EVENT_GOT_OAKS_PARCEL" },
                { "jump_if_true", "start_shoes_scene" },

                -- Si no tiene el paquete de Oak y ya tiene starter → flujo vanilla
                { "check_flag", "EVENT_GOT_STARTER" },
                { "jump_if_false", "vanilla_shop" },

                { "show_text", "TEXT_VIRIDIANMART_CLERK" },
                { "give_item", "OAKS_PARCEL", 1 },
                { "set_flag", "EVENT_GOT_OAKS_PARCEL" },
                { "jump", "end" },

                -- E) INICIO DE LA ESCENA DE ZAPATILLAS (retrocompatible)
                { "label", "start_shoes_scene" },
                { "running_shoes:set_stage", 1 },
                { "show_object", "VIRIDIAN_MART", "RUNNING_SHOES_VICTIM" },
                { "show_object", "ROUTE_2", "RUNNING_SHOES_THIEF_NPC" },
                { "place_npc", 4, 3, 7, "up" },
                { "move_npc", 4, "up", 3 },
                { "face_object", 4, "left" },
                { "face_player_dir", "right" },
                { "show_text", "_RunningShoesSceneIntro" },
                { "show_text", "_RunningShoesSceneDetails" },
                { "ask", "_RunningShoesAskHelp" },
                { "jump_if_false", "declined" },
                { "show_text", "_RunningShoesVictimWaiting" },
                { "jump", "vanilla_shop" },

                { "label", "declined" },
                { "show_text", "_RunningShoesDeclined" },
                { "jump", "vanilla_shop" },

                { "label", "vanilla_shop" },
                { "open_mart", "TEXT_VIRIDIANMART_CLERK" },
                { "label", "end" },
            },

            -- =========================================================================
            -- 6. VÍCTIMA: entrega y recompensa
            -- =========================================================================
            TEXT_RUNNING_SHOES_VICTIM = {
                { "running_shoes:check_stage", 3 },
                { "jump_if_true", "completed" },

                { "check_item", "RUNNING_SHOES_STOLEN" },
                { "jump_if_false", "missing" },

                { "show_text", "_RunningShoesVictimReward" },
                -- Limpia copias antiguas por si acaso
                { "take_item", "RUNNING_SHOES_STOLEN", 99 },
                { "give_item", "RUNNING_SHOES", 1 },
                { "running_shoes:set_stage", 3 },
                { "show_text", "_RunningShoesCompleted" },
                { "jump", "end" },

                { "label", "missing" },
                { "show_text", "_RunningShoesVictimMissing" },
                { "jump", "end" },

                { "label", "completed" },
                { "show_text", "_RunningShoesCompleted" },
                { "label", "end" },
            },
        },
    })

    -- =========================================================================
    -- 7. LADRÓN EN ROUTE 2
    -- =========================================================================
    mod.content.map_scripts:register("ROUTE_2", {
        talk = {
            TEXT_RUNNING_SHOES_THIEF = {
                -- Si ya tiene la recompensa o el objeto robado → ya derrotado
                { "check_item", "RUNNING_SHOES" },
                { "jump_if_true", "already_defeated" },
                { "check_item", "RUNNING_SHOES_STOLEN" },
                { "jump_if_true", "already_defeated" },
                { "running_shoes:check_stage", 2 },
                { "jump_if_true", "already_defeated" },

                { "show_text", "_RunningShoesThiefIntro" },
                { "start_battle", "trainer", "RUNNING_SHOES_THIEF", 1 },

                -- Protección obligatoria: solo marca victoria si ganó
                { "jump_if_false", "battle_failed" },
                { "running_shoes:set_stage", 2 },
                { "give_item", "RUNNING_SHOES_STOLEN", 1 },
                { "show_text", "_RunningShoesBattleWon" },
                { "jump", "end" },

                { "label", "battle_failed" },
                { "show_text", "_RunningShoesBattleLost" },
                { "jump", "end" },

                { "label", "already_defeated" },
                { "show_text", "_RunningShoesAlreadyDefeated" },
                { "label", "end" },
            },
        },
    })

    -- =========================================================================
    -- 8. HOOK DE VELOCIDAD (lee de mod.save, no de flags sueltas)
    -- =========================================================================
    mod.hooks:wrap("movement.speed", function(next, frames, ctx)
        if ctx.onBike or ctx.surfing then
            return next(frames, ctx)
        end

        local holdingB = ctx.input
            and ctx.input.isDown
            and ctx.input:isDown("b")

        if stage() >= 3 and holdingB then
            return math.max(1, math.floor(frames / 2))
        end

        return next(frames, ctx)
    end)
end