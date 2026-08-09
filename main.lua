return function(mod)
    -- 1. Contenido
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

    mod.content.trainers:register("RUNNING_SHOES_THIEF", {
        id = "RUNNING_SHOES_THIEF",
        name = "Ladrón",
        basePic = "OPP_SUPER_NERD",
        baseMoney = 180,
        parties = {
            {
                { species = "RATTATA", level = 8 },
                { species = "ZUBAT", level = 9 },
            },
        },
    })

    -- 2. Texto authored por el mod
    mod.content.text:register("_RunningShoesSceneIntro",
        "¡Ayuda! Ese sujeto tomó algo de la tienda y escapó hacia la Ruta 2.")
    mod.content.text:register("_RunningShoesSceneDetails",
        "Era un par de zapatillas especiales. Si lo alcanzas, recupera el objeto y tráelo aquí.")
    mod.content.text:register("_RunningShoesAskHelp",
        "¿Quieres ayudar a recuperar las zapatillas?")
    mod.content.text:register("_RunningShoesDeclined",
        "Entiendo. Vuelve cuando quieras ayudarnos.")
    mod.content.text:register("_RunningShoesVictimWaiting",
        "La víctima esperará aquí hasta que recuperes las zapatillas.")
    mod.content.text:register("_RunningShoesVictimMissing",
        "El ladrón todavía tiene mis zapatillas. ¡Debe estar en la Ruta 2!")
    mod.content.text:register("_RunningShoesThiefIntro",
        "¡No te metas! Estas zapatillas son mías ahora.")
    mod.content.text:register("_RunningShoesBattleLost",
        "El ladrón escapó con el objeto. Inténtalo de nuevo.")
    mod.content.text:register("_RunningShoesBattleWon",
        "¡Ganaste! Toma, recuperaste el objeto robado.")
    mod.content.text:register("_RunningShoesAlreadyDefeated",
        "El ladrón ya no tiene nada que robar.")
    mod.content.text:register("_RunningShoesVictimReward",
        "¡Recuperaste mis zapatillas! Quédate con este par como agradecimiento.")
    mod.content.text:register("_RunningShoesCompleted",
        "Gracias por tu ayuda. Ahora puedo volver a trabajar.")

    -- English is the mod's source language. The existing registrations above
    -- are kept for compatibility; these overrides are the authoritative
    -- English strings used by the quest.
    local englishText = {
        _RunningShoesSceneIntro = "Help! That thief took something from me and ran toward Route 2.",
        _RunningShoesSceneDetails = "They were a special pair of shoes. Catch him, recover them, and bring them back here.",
        _RunningShoesAskHelp = "Will you help us recover the shoes?",
        _RunningShoesDeclined = "I understand. Come back if you change your mind.",
        _RunningShoesVictimWaiting = "The victim will wait here until you recover the shoes.",
        _RunningShoesVictimMissing = "The thief still has my shoes. He must be somewhere on Route 2!",
        _RunningShoesThiefIntro = "Stay out of this! These shoes are mine now.",
        _RunningShoesBattleLost = "The thief got away with the item. Try again.",
        _RunningShoesBattleWon = "You win! Here, you recovered the stolen item.",
        _RunningShoesAlreadyDefeated = "All right, you beat me. Enjoy them.",
        _RunningShoesVictimReward = "You recovered my shoes! Keep this pair as a thank-you. Hold B while walking to run faster.",
        _RunningShoesCompleted = "Thank you for your help. I can get back to work now.",
    }
    for id, value in pairs(englishText) do
        mod.content.text:override(id, value)
    end
    mod.content.trainers:patch("RUNNING_SHOES_THIEF", { name = "Thief" })

    -- If the Spanish content mod is enabled, replace only this quest's
    -- authored text after the game data has been merged.
    mod.events:on("game.ready", function(ev)
        local game = ev and ev.game
        local mods = game and game.mods and game.mods.mods
        local spanish = mods and mods["recomp-spanish"]
        if not (spanish and spanish.enabled) then return end

        local text = game.data and game.data.text
        if not text then return end
        text._RunningShoesSceneIntro = "¡Ayuda! Un sujeto robó algo y escapó hacia la Ruta 2."
        text._RunningShoesSceneDetails = "Era un par de zapatillas especiales. Si lo alcanzas, recupera el objeto y tráelo aquí."
        text._RunningShoesAskHelp = "¿Quieres ayudar a recuperar las zapatillas?"
        text._RunningShoesDeclined = "Entiendo. Vuelve cuando quieras ayudarnos."
        text._RunningShoesVictimWaiting = "La víctima esperará aquí hasta que recuperes las zapatillas."
        text._RunningShoesVictimMissing = "El ladrón todavía tiene mis zapatillas. ¡Debe estar en la Ruta 2!"
        text._RunningShoesThiefIntro = "¡No te metas! Estas zapatillas son mías ahora."
        text._RunningShoesBattleLost = "El ladrón escapó con el objeto. Inténtalo de nuevo."
        text._RunningShoesBattleWon = "¡Ganaste! Toma, recuperaste el objeto robado."
        text._RunningShoesAlreadyDefeated = "Está bien, me venciste, disfrútalas."
        text._RunningShoesVictimReward = "¡Recuperaste mis zapatillas! Pero ya he comprado otras. Quédate con este par. Mantén B mientras caminas para correr más rápido."
        text._RunningShoesCompleted = "Gracias por tu ayuda. Ahora puedo volver a trabajar."
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

    -- 3. Objetos de mapa
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

    -- 4. Dependiente: conserva primero el flujo vanilla del Parcel
    mod.content.map_scripts:register("VIRIDIAN_MART", {
        talk = {
            TEXT_VIRIDIANMART_CLERK = {
                -- El item final es la fuente de verdad mas robusta: si el
                -- jugador ya tiene RUNNING_SHOES, el tendero vuelve siempre
                -- a su flujo normal, aunque una partida antigua no conserve
                -- correctamente la flag mod:*.
                { "check_item", "RUNNING_SHOES" },
                { "jump_if_true", "vanilla_shop" },
                -- El estado de la mision tiene prioridad sobre el flujo
                -- vanilla del Parcel. Asi el tendero no reinicia la escena
                -- si la partida no trae exactamente la misma flag vanilla.
                { "check_flag", "MOD_RUNNING_SHOES_completed" },
                { "jump_if_true", "vanilla_shop" },
                -- Estado separado: la escena de entrada solo puede ejecutarse

                { "check_flag", "MOD_RUNNING_SHOES_scene_started" },
                { "jump_if_true", "vanilla_shop" },
                { "check_flag", "MOD_RUNNING_SHOES_quest_started" },
                { "jump_if_true", "vanilla_shop" },
                { "check_flag", "EVENT_OAK_GOT_PARCEL" },
                { "jump_if_false", "vanilla_parcel" },

                -- Reservar el estado antes de cualquier movimiento o texto.
                { "set_flag", "MOD_RUNNING_SHOES_scene_started" },
                { "set_flag", "MOD_RUNNING_SHOES_quest_started" },
                { "show_object", "VIRIDIAN_MART", "RUNNING_SHOES_VICTIM" },
                { "show_object", "ROUTE_2", "RUNNING_SHOES_THIEF_NPC" },
                { "place_npc", 4, 3, 7, "up" },
                { "move_npc", 4, "up", 3 },
                { "face_object", 4, "left" },
                { "face_player_dir", "right" },
                -- Desde este punto el tendero queda desbloqueado: el niño
                -- ya entro en escena aunque el jugador rechace la ayuda.
                { "show_text", "_RunningShoesSceneIntro" },
                { "show_text", "_RunningShoesSceneDetails" },
                { "ask", "_RunningShoesAskHelp" },
                { "jump_if_false", "declined" },
                { "show_text", "_RunningShoesVictimWaiting" },
                { "jump", "vanilla_shop" },

                { "label", "declined" },
                { "show_text", "_RunningShoesDeclined" },
                { "jump", "vanilla_shop" },

                { "label", "vanilla_parcel" },
                { "check_flag", "EVENT_GOT_OAKS_PARCEL" },
                { "jump_if_true", "parcel_waiting" },
                { "check_flag", "EVENT_GOT_STARTER" },
                { "jump_if_false", "vanilla_shop" },
                { "show_text", "TEXT_VIRIDIANMART_CLERK" },
                { "give_item", "OAKS_PARCEL", 1 },
                { "set_flag", "EVENT_GOT_OAKS_PARCEL" },
                { "jump", "end" },

                { "label", "parcel_waiting" },
                { "show_text", "TEXT_VIRIDIANMART_CLERK" },
                { "jump", "end" },

                { "label", "vanilla_shop" },
                { "show_text", "TEXT_VIRIDIANMART_CLERK" },
                { "open_mart", "TEXT_VIRIDIANMART_CLERK" },
                { "label", "end" },
            },

            -- 5. Víctima: recibe el objeto y entrega la recompensa
            TEXT_RUNNING_SHOES_VICTIM = {
                { "check_flag", "MOD_RUNNING_SHOES_completed" },
                { "jump_if_true", "completed" },
                { "check_item", "RUNNING_SHOES_STOLEN" },
                { "jump_if_false", "missing" },
                { "show_text", "_RunningShoesVictimReward" },
                -- Limpia tambien copias antiguas creadas por la version con
                -- bug; la mision solo debe consumir esa recompensa una vez.
                { "take_item", "RUNNING_SHOES_STOLEN", 99 },
                { "give_item", "RUNNING_SHOES", 1 },
                { "set_flag", "MOD_RUNNING_SHOES_completed" },
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

    -- 6. Ladrón en otro mapa
    mod.content.map_scripts:register("ROUTE_2", {
        talk = {
            TEXT_RUNNING_SHOES_THIEF = {
                -- La recompensa fisica tambien bloquea el combate. Esto evita
                -- duplicados incluso si se habla otra vez antes de entregarla.
                { "check_item", "RUNNING_SHOES" },
                { "jump_if_true", "already_defeated" },
                { "check_item", "RUNNING_SHOES_STOLEN" },
                { "jump_if_true", "already_defeated" },
                { "check_flag", "MOD_RUNNING_SHOES_thief_defeated" },
                { "jump_if_true", "already_defeated" },
                { "show_text", "_RunningShoesThiefIntro" },
                { "start_battle", "trainer", "RUNNING_SHOES_THIEF", 1 },

                -- Es obligatorio proteger la recompensa con este salto.
                { "jump_if_false", "battle_failed" },
                { "set_flag", "MOD_RUNNING_SHOES_thief_defeated" },
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

    -- 7. Hook de velocidad
    mod.hooks:wrap("movement.speed", function(next, frames, ctx)
        if ctx.onBike or ctx.surfing then
            return next(frames, ctx)
        end

        local flags = ctx.save and ctx.save.flags or {}
        local unlocked = flags["MOD_RUNNING_SHOES_completed"]
        local holdingB = ctx.input
            and ctx.input.isDown
            and ctx.input:isDown("b")

        if unlocked and holdingB then
            local runSpeed = 2
            return math.max(1, math.floor(frames / runSpeed))
        end

        return next(frames, ctx)
    end)
end
