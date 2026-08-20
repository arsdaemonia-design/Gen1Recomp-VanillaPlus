return function(mod)

    -- =========================================================================
    -- 0. ESTADO DE LA MISIÓN
    --
    -- lavender_stage:
    --   0 = NOT_STARTED
    --   1 = MEET (chico en Lavender; JENNY entra caminando y da la pista)
    --   2 = ROUTE_8 (grunts C/D en la Ruta 8)
    --   3 = HIDEOUT_SCOPE (Guarida Rocket vanilla + SILPH_SCOPE)
    --   4 = JENNY_REVEAL (vuelta a Lavender con Scope; Jenny revela la TORRE)
    --   5 = TOWER_ASCENT (grunts A/B/E en 1F-3F)
    --   6 = DARIA_MID (encuentro en 4F; se la llevan arriba)
    --   7 = TOWER_UPPER (grunt F en 5F, lore 6F, cima 7F con Rockets vanilla)
    --   8 = DARIA_DUEL (test de fuerza en 7F)
    --   9 = JOINED (completada, Daría civil)
    --
    -- Convención de flags: TODAS las keys de "vencido" se guardan ya con el
    -- prefijo lavender_ completo bajo el namespace "mod:" (beaten/setBeaten
    -- NO agregan prefijo; los scripts pasan la key completa). El bug previo:
    -- los ambushes escribían sin prefijo (mod:grunt_d_beat) mientras beaten()
    -- leía con prefijo (mod:lavender_grunt_d_beat) -> los grunts nunca se
    -- marcaban como vencidos y se re-spawneaban.
    -- =========================================================================

    local STAGE_KEY = "lavender_stage"

    local function getState(key, default)
        return mod.save:get("mod:" .. key, default)
    end

    local function setState(key, value)
        mod.save:set("mod:" .. key, value)
    end

    local function hasSilphScope(game)
        local inv = game and game.save and game.save.inventory
        return not not (inv and (inv.SILPH_SCOPE or 0) > 0)
    end

    -- Gate de arranque: secuela de charmander (stage >= 5 = completada).
    -- Nunca asume que la quest existe (regla de oro de state.lua).
    local function charmanderComplete()
        if not (mod.quests and mod.quests.registered) then return false end
        if not mod.quests.registered("charmander") then return false end
        local s = mod.quests.stage("charmander")
        return s and s >= 5 or false
    end

    -- Flags de "vencido" de la quest (patrón guardian_beat de squirtle).
    -- Las keys se guardan COMPLETAS con el prefijo lavender_ ya incluido.
    local function beaten(key)
        return getState(tostring(key), false) and true or false
    end

    local function setBeaten(key)
        setState(tostring(key), true)
    end

    -- =========================================================================
    -- 1. COMANDOS CUSTOM BASE
    -- =========================================================================

    mod.content.commands:register("lavender:set_stage", function(ctx, value)
        local stage = tonumber(value) or 0
        setState(STAGE_KEY, stage)
    end)

    mod.content.commands:register("lavender:check_stage", function(ctx, value)
        if getState(STAGE_KEY, 0) == (tonumber(value) or -1) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    -- Para rastrear qué Rockets / partes se han completado (guardian_beat pattern)
    mod.content.commands:register("lavender:set_found", function(ctx, key)
        setState(tostring(key), true)
    end)

    mod.content.commands:register("lavender:check_found", function(ctx, key)
        if getState(tostring(key), false) then
            ctx.lastCheck = true
        else
            ctx.lastCheck = false
        end
    end)

    mod.content.commands:register("lavender:check_charmander_done", function(ctx)
        ctx.lastCheck = charmanderComplete()
    end)

    -- =========================================================================
    -- 2. OBJETOS DE MAPA (FASE B)
    --
    -- Indices 90+ libres en todos estos mapas (vanilla usa 1-9). Los 3 Rockets
    -- de la cima (7F) son los vanilla (indices 1-3): no se agregan nuevos.
    -- Las coordenadas se verificaron walkable y sin choque con NPC vanilla
    -- (script walkability_final.py / walk_check*.py, 0 mismatches).
    -- =========================================================================

    mod.content.maps:patch("LAVENDER_TOWN", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_KID",
                    text = "TEXT_STARTER_STORIES_LAVENDER_KID",
                    sprite = "SPRITE_YOUNGSTER",
                    x = 11,
                    y = 11,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
                {
                    index = 91,
                    name = "STARTER_STORIES_LAVENDER_JENNY",
                    text = "TEXT_STARTER_STORIES_LAVENDER_JENNY",
                    sprite = "SPRITE_GUARD",
                    x = 13,
                    y = 12,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
                {
                    -- DARÍA ya libre: en la plaza, junto a su hermano (stage 9+).
                    index = 92,
                    name = "STARTER_STORIES_LAVENDER_DARIA_CIVIL",
                    text = "TEXT_STARTER_STORIES_LAVENDER_DARIA_CIVIL",
                    sprite = "SPRITE_LITTLE_GIRL",
                    x = 12,
                    y = 11,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("POKEMON_TOWER_1F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_GRUNT_B",
                    text = "TEXT_STARTER_STORIES_LAVENDER_GRUNT_B",
                    sprite = "SPRITE_ROCKET",
                    x = 16,
                    y = 10,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    -- GRUNT_A vivía en LAVENDER_TOWN en el flujo viejo; el usuario pidió que
    -- A y B aparezcan al volver a la TORRE (fase de ascenso). B guarda el 1F
    -- (16,10, junto a las escaleras en 18,9); A custodia el 2F (10,9), en el
    -- corredor central por el que el jugador cruza entre escaleras (18,9)->(3,9).
    mod.content.maps:patch("POKEMON_TOWER_2F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_GRUNT_A",
                    text = "TEXT_STARTER_STORIES_LAVENDER_GRUNT_A",
                    sprite = "SPRITE_ROCKET",
                    x = 10,
                    y = 9,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("ROUTE_8", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_GRUNT_C",
                    text = "TEXT_STARTER_STORIES_LAVENDER_GRUNT_C",
                    sprite = "SPRITE_ROCKET",
                    x = 25,
                    y = 10,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
                {
                    index = 91,
                    name = "STARTER_STORIES_LAVENDER_GRUNT_D",
                    text = "TEXT_STARTER_STORIES_LAVENDER_GRUNT_D",
                    sprite = "SPRITE_ROCKET",
                    x = 44,
                    y = 10,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("POKEMON_TOWER_3F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_GRUNT_E",
                    text = "TEXT_STARTER_STORIES_LAVENDER_GRUNT_E",
                    sprite = "SPRITE_ROCKET",
                    x = 8,
                    y = 12,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("POKEMON_TOWER_4F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_DARIA",
                    text = "TEXT_STARTER_STORIES_LAVENDER_DARIA",
                    sprite = "SPRITE_ROCKET",
                    x = 7,
                    y = 14,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("POKEMON_TOWER_5F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_GRUNT_F",
                    text = "TEXT_STARTER_STORIES_LAVENDER_GRUNT_F",
                    sprite = "SPRITE_ROCKET",
                    x = 10,
                    y = 12,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    mod.content.maps:patch("POKEMON_TOWER_7F", {
        objects = {
            __append = {
                {
                    index = 90,
                    name = "STARTER_STORIES_LAVENDER_DARIA",
                    text = "TEXT_STARTER_STORIES_LAVENDER_DARIA",
                    sprite = "SPRITE_ROCKET",
                    x = 11,
                    y = 5,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
                {
                    index = 91,
                    name = "STARTER_STORIES_LAVENDER_DARIA_CIVIL",
                    text = "TEXT_STARTER_STORIES_LAVENDER_DARIA_CIVIL",
                    sprite = "SPRITE_LITTLE_GIRL",
                    x = 11,
                    y = 6,
                    movement = "STAY",
                    range = "DOWN",
                    hidden = true,
                },
            },
        },
    })

    -- =========================================================================
    -- 2.5 ENTRENADORES (FASE D)
    --
    -- Grunts Rocket (1v1, patron squirtle: parties fijas). Daría usa
    -- OPP_COOLTRAINER_F: es una entrenadora fuerte reclutada a la fuerza.
    -- =========================================================================

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_GRUNT_A", {
        id = "STARTER_STORIES_LAVENDER_GRUNT_A",
        name = "Rocket",
        basePic = "OPP_ROCKET",
        baseMoney = 30,
        parties = {
            {
                { level = 18, species = "RATTATA" },
                { level = 20, species = "ZUBAT" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_GRUNT_B", {
        id = "STARTER_STORIES_LAVENDER_GRUNT_B",
        name = "Rocket",
        basePic = "OPP_ROCKET",
        baseMoney = 30,
        parties = {
            {
                { level = 19, species = "EKANS" },
                { level = 21, species = "KOFFING" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_GRUNT_C", {
        id = "STARTER_STORIES_LAVENDER_GRUNT_C",
        name = "Rocket",
        basePic = "OPP_ROCKET",
        baseMoney = 30,
        parties = {
            {
                { level = 20, species = "GRIMER" },
                { level = 22, species = "ZUBAT" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_GRUNT_D", {
        id = "STARTER_STORIES_LAVENDER_GRUNT_D",
        name = "Rocket",
        basePic = "OPP_ROCKET",
        baseMoney = 30,
        parties = {
            {
                { level = 21, species = "SANDSHREW" },
                { level = 23, species = "MACHOP" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_GRUNT_E", {
        id = "STARTER_STORIES_LAVENDER_GRUNT_E",
        name = "Rocket",
        basePic = "OPP_ROCKET",
        baseMoney = 30,
        parties = {
            {
                { level = 22, species = "KOFFING" },
                { level = 23, species = "RATTATA" },
                { level = 24, species = "ZUBAT" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_GRUNT_F", {
        id = "STARTER_STORIES_LAVENDER_GRUNT_F",
        name = "Rocket",
        basePic = "OPP_ROCKET",
        baseMoney = 30,
        parties = {
            {
                { level = 23, species = "GRIMER" },
                { level = 24, species = "EKANS" },
                { level = 25, species = "MACHOP" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_DARIA_MID", {
        id = "STARTER_STORIES_LAVENDER_DARIA_MID",
        name = "DARIA",
        basePic = "OPP_COOLTRAINER_F",
        baseMoney = 40,
        parties = {
            {
                { level = 25, species = "PONYTA" },
                { level = 26, species = "RHYHORN" },
                { level = 27, species = "ARBOK" },
            },
        },
    })

    mod.content.trainers:register("STARTER_STORIES_LAVENDER_DARIA_FINAL", {
        id = "STARTER_STORIES_LAVENDER_DARIA_FINAL",
        name = "DARIA",
        basePic = "OPP_COOLTRAINER_F",
        baseMoney = 50,
        parties = {
            {
                { level = 28, species = "PERSIAN" },
                { level = 29, species = "NIDOQUEEN" },
                { level = 30, species = "ALAKAZAM" },
            },
        },
    })

    -- =========================================================================
    -- 3. TEXTOS (FASE C)
    --
    -- EN se registra al cargar; ES se sobreescribe en game.ready si el mod
    -- recomp-spanish está activo (patrón charmander).
    -- =========================================================================

    -- Textos-identificador de objetos (ruta de talk / línea por defecto)
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_KID", "DARIA... my\nsister.\vThey took her.")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_JENNY", "Officer JENNY on\nthe ROCKET case.")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_GRUNT_A", "Team Rocket holds\nthis street!")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_GRUNT_B", "Nobody walks past\nus!")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_GRUNT_C", "You are not going\nto CELADON!")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_GRUNT_D", "Route 8 is Rockets\nland!")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_GRUNT_E", "The TOWER is our\nstronghold!")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_GRUNT_F", "Nobody climbs past\nhere!")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_DARIA", "...You actually\ncame looking\nfor me?")
    mod.content.text:register("TEXT_STARTER_STORIES_LAVENDER_DARIA_CIVIL", "DARIA is safe\nnow. Thank you!")

    -- Etapa 1: MEET (chico en Lavender; Jenny entra caminando)
    mod.content.text:register("_LavendarKidIntro",
        "Hey, it's you!\vMy sister DARIA\nwas taken by\vTEAM ROCKET.\fThey grab strong\nTRAINERS by force.\vShe is the best\nout there.")
    mod.content.text:register("_LavendarJennyRoute8",
        "Officer JENNY!\vYou always turn\nup where ROCKET\nis.\vYour sister?\nTaken by force.\fWe are sweeping\nROUTE 8.\vGrunts block the\nroad to CELADON.\vClear them--I will\ncover you!")

    -- Etapa 2: Ruta 8 (grunts C/D)
    mod.content.text:register("_LavendarKidSearching",
        "ROCKETS closed the\nroad to CELADON!\vPlease clear\nROUTE 8--\vJENNY is waiting!")
    mod.content.text:register("_LavendarGruntCIntro", "The road to\nCELADON is closed\nfor you!")
    mod.content.text:register("_LavendarGruntDIntro", "Second line of\ndefense! Roar!")

    -- Etapa 3-4: señuelo en Azulona (Guarida Rocket) y revelación de Jenny
    mod.content.text:register("_LavendarHideoutClue",
        "The hideout was a\ndead end--DARIA\nwas never there.\vA scrap of paper:\v\"DARIA moved.\nTOWER now.\"")
    mod.content.text:register("_LavendarKidWait",
        "The hideout is a\nwild goose chase...\vbut please--find\nout the truth\nabout DARIA!")
    mod.content.text:register("_LavendarScopeReminder",
        "The ROCKET Hideout\nin CELADON hides\nthe SILPH SCOPE.\vWithout it, the\nTOWER's ghosts bar\nthe way.\vGo get it!")
    mod.content.text:register("_LavendarJennyReveal",
        "I dug deeper.\vYour friend is in\nPOKeMON TOWER.\vWith your SILPH\nSCOPE, ghosts no\nlonger bar the way.\fClimb on--I will\ncover you.")

    -- Etapa 5-8: ascenso (grunts de torre + lore Marowak)
    mod.content.text:register("_LavendarKidTower",
        "The TOWER...\vthey are hiding\nher up there!\vPlease save my\nsister!")
    mod.content.text:register("_LavendarGruntAIntro",
        "Looking for a\ntrainer named\nDARIA?!\vNo one rescues\nher!")
    mod.content.text:register("_LavendarGruntBIntro",
        "This is as far as\nyou go!\vTeam Rocket rules\nthe TOWER!")
    mod.content.text:register("_LavendarGruntEIntro", "Third floor is ours!\nTurn back!")
    mod.content.text:register("_LavendarGruntFIntro",
        "The ghost floor\ndoes not scare\nus--it scares you!")
    mod.content.text:register("_LavendarGhostMarowak",
        "A Channeler grieves:\vROCKET cut down a\nCUBONE's mother\nhere.\fRestless soul\nshadows floor 6.")
    mod.content.text:register("_LavendarJennyIntro",
        "Officer JENNY here.\vI am covering the\nTOWER--keep going,\vI am right behind\nyou.")

    -- Etapa 6: duelo medio con Daría (4F)
    mod.content.text:register("_LavendarDariaMidIntro",
        "DARIA!\v...So you really\ncame.\fBeat me and you\nwill see where\nthey drag me.")
    mod.content.text:register("_LavendarDariaMidWon",
        "...Impressive.\vBut ROCKET does not\nlet go that easy.\vThey are shoving me\nUPSTAIRS.\vCome finish it.")
    mod.content.text:register("_LavendarDariaTaken",
        "Two ROCKETS grab\nDARIA and drag her\nupstairs.\v\"Let me go!...\vI will be waiting\nabove.\"")

    -- Etapa 7: cima 7F (nota conectada a Mr. Fuji)
    mod.content.text:register("_LavendarTopRocketNote",
        "JENNY eyes the three\nbeaten grunts.\v\"She is working\nwith them...\vbut something tells\nme it's not on\nher own accord.\"")

    -- Etapa 8: duelo final de Daría (desahogo tras liberarse)
    mod.content.text:register("_LavendarDariaDuelIntro",
        "Thank you--for\ncoming for me.\vROCKET kept us\nlocked up here.\vThanks to you,\nI can be free.\fBut I am furious.\vBefore we leave,\nlet me calm down\na bit.\fA battle--what\ndo you say?")
    mod.content.text:register("_LavendarDariaDuelPre",
        "New partner battle.\nReady... go!")
    mod.content.text:register("_LavendarDariaDuelWon",
        "Phew... that did\nme good.\vI feel like\nmyself again.\fThank you--for\nreal this time.\vI am choosing to\nwalk with you.\fLet's go, partner.")

    -- Etapa 9: unido / recompensa / cierre
    mod.content.text:register("_LavendarJoined",
        "DARIA sheds the\nROCKET coat.\vShe smiles.\v\"I am free now.\fThank you--my\nplace is with you.\fBy my own choice.\"")
    mod.content.text:register("_LavendarJennyReward",
        "As promised, our\npayment.\vHere--an ELIXER.\fIt restores your\nparty's PP.\vGood luck out\nthere.")
    mod.content.text:register("_LavendarKidThanks",
        "You saved DARIA!\vThank you, thank\nyou so much!")
    mod.content.text:register("_LavendarFinale",
        "Thank you, {PLAYER}!\vWe still need to\ninvestigate TEAM\nROCKET further.\vJust be careful--\vthey won't be happy\nabout this.\fThey may ambush\nyou on the road.")
    mod.content.text:register("_LavendarDone",
        "The kid hugs his\nsister.\vJENNY smiles--they\nhave their own\nroads now.\fDARIA walks by your\nside.\v\"See you, partner.\"")

    -- Resultados de combate de grunts + guias menores
    mod.content.text:register("_LavendarGruntAWon",
        "Grr... that was\njust the first\nline of defense!")
    mod.content.text:register("_LavendarGruntBWon",
        "Inside the TOWER\ntoo?! Fine...\vgo on, climb.")
    mod.content.text:register("_LavendarGruntCWon",
        "Route 8 slips...\vbut the hideout\nawards you!")
    mod.content.text:register("_LavendarGruntDWon",
        "Second line\nbroken...\vgo ahead.")
    mod.content.text:register("_LavendarGruntEWon",
        "You climb well...\vthe higher grunts\nare worse!")
    mod.content.text:register("_LavendarGruntFWon",
        "The ghosts did\nnot stop you...\vgood luck above.")

    -- =========================================================================
    -- 4. TRADUCCIÓN AL ESPAÑOL (RUNTIME)
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

        text["TEXT_STARTER_STORIES_LAVENDER_KID"] = "DARÍA... mi\nhermana.\vSe la llevaron."
        text["TEXT_STARTER_STORIES_LAVENDER_JENNY"] = "Oficial JENNY en\nel caso ROCKET."
        text["TEXT_STARTER_STORIES_LAVENDER_GRUNT_A"] = "¡Team Rocket es\ndueño de esta calle!"
        text["TEXT_STARTER_STORIES_LAVENDER_GRUNT_B"] = "¡Nadie pasa\nfrente a nosotros!"
        text["TEXT_STARTER_STORIES_LAVENDER_GRUNT_C"] = "¡No irás a\nCIUDAD AZULONA!"
        text["TEXT_STARTER_STORIES_LAVENDER_GRUNT_D"] = "¡La Ruta 8 es\nterritorio Rocket!"
        text["TEXT_STARTER_STORIES_LAVENDER_GRUNT_E"] = "¡La TORRE es\nnuestra fortaleza!"
        text["TEXT_STARTER_STORIES_LAVENDER_GRUNT_F"] = "¡Nadie sube más\nallá de aquí!"
        text["TEXT_STARTER_STORIES_LAVENDER_DARIA"] = "...¿De verdad\nviniste a\nbuscarme?"
        text["TEXT_STARTER_STORIES_LAVENDER_DARIA_CIVIL"] = "DARÍA ya está a\nsalvo. ¡Gracias!"

        text._LavendarKidIntro =
            "¡Hey, eres tú!\vSecuestraron a mi\nhermana DARÍA.\vTEAM ROCKET recluta\nentrenadores fuertes\na la fuerza.\vElla es la mejor\nde todos."
        text._LavendarJennyRoute8 =
            "¡Oficial JENNY!\vSiempre apareces\ndonde está el\nEQUIPO ROCKET.\v¿Secuestraron a tu\nhermana?\fEstamos rastreando\nla RUTA 8--\vlos reclutas bloquean\nel camino a\nCIUDAD AZULONA.\vDerrótalos--yo te\ncubro."

        text._LavendarKidSearching =
            "¡Los ROCKETS cerraron\nel camino a\nCIUDAD AZULONA!\vPor favor, despeja\nla RUTA 8--\v¡JENNY te espera!"
        text._LavendarGruntCIntro = "¡El camino a\nCIUDAD AZULONA\nestá cerrado para ti!"
        text._LavendarGruntDIntro = "¡Segunda línea de\ndefensa! ¡Yujuu!"

        text._LavendarHideoutClue =
            "La guarida fue un\ncallejón sin salida--\vDARÍA nunca estuvo\nallí.\vUna nota:\v\"Se llevaron a\nDARÍA. A la TORRE.\""
        text._LavendarKidWait =
            "La guarida es una\npista falsa...\vpero por favor--\vdescubre la verdad\nsobre DARÍA!"
        text._LavendarScopeReminder =
            "El VISOR SILPH\nestá en la guarida\nROCKET de CELADON.\vLos fantasmas de\nla TORRE te\nbloquean sin él.\v¡Ve a buscarlo!"
        text._LavendarJennyReveal =
            "Investigué a fondo.\vTu amiga está en\nla TORRE POKéMON.\vCon tu VISOR SILPH\nlos fantasmas ya no\nte detienen--\vsube, yo te cubro\nla espalda."

        text._LavendarKidTower =
            "La TORRE...\v¡la esconden allá\narriba!\v¡Salva a mi\nhermana, por favor!"
        text._LavendarGruntAIntro = "¿Buscas a una\nentrenadora\nllamada DARÍA?!\v¡Nadie la va a\nrescatar!"
        text._LavendarGruntBIntro =
            "¡Hasta aquí\nllegaste!\v¡Team Rocket manda\nen la TORRE!"
        text._LavendarGruntEIntro = "¡El tercer piso es\nnuestro! ¡Retrocede!"
        text._LavendarGruntFIntro =
            "¡El piso fantasma\nno nos asusta!\v¡A ti te espanta!"
        text._LavendarGhostMarowak =
            "Una Sacerdotisa\ngime:\vROCKET abatió a la\nmadre de un CUBONE\naquí.\fEl alma inquieta\nsombra el piso 6."
        text._LavendarJennyIntro =
            "Oficial JENNY aquí.\vEstoy cubriendo la\nTORRE--sigue subiendo,\vte cubro la espalda."

        text._LavendarDariaMidIntro =
            "¡DARÍA!\v...Así que viniste\nde verdad.\fVénceme y verás a\ndónde me arrastran."
        text._LavendarDariaMidWon =
            "...Impresionante.\vPero ROCKET no\nsuelta así nomás.\vMe llevan HACIA\nARRIBA.\vVen a terminar esto."
        text._LavendarDariaTaken =
            "Dos ROCKETS sujetan\na DARÍA y la\narrastran arriba.\v\"¡Suéltame!...\vTe espero\nallá arriba.\""

        text._LavendarTopRocketNote =
            "JENNY observa a los\ntres reclutas\nvencidos.\v\"Está trabajando\ncon ellos...\vpero algo me dice\nque no es por su\npropia cuenta.\""

        text._LavendarDariaDuelIntro =
            "¡Gracias por venir\npor mí!\vROCKET nos tuvo\nencerrados aquí.\vGracias a ti,\nya puedo ser libre.\fPero estoy furiosa.\vAntes de irnos,\nquiero calmarme\nun poco.\f¿Un combate...\vqué opinas?"
        text._LavendarDariaDuelPre = "Combate de nuevos\naliados. ¡Listos...\nya!"
        text._LavendarDariaDuelWon =
            "Uf... eso me\nhizo bien.\vYa me siento yo\nmisma otra vez.\fGracias--de\nverdad esta vez.\vEs mi decisión\ncaminar contigo.\fVamos, compañero."

        text._LavendarJoined =
            "DARÍA se quita el\nabrigo de ROCKET.\vSonríe.\v\"Ahora soy libre.\fGracias--mi\nlugar está contigo.\fPor mi propia\ndecisión.\""
        text._LavendarJennyReward =
            "Como prometí,\nnuestra paga.\vTen--un ELIXER.\fRecupera PP de tu\nequipo.\vBuena suerte ahí\nafuera."
        text._LavendarKidThanks =
            "¡Salvaste a DARÍA!\v¡Gracias, muchísimas\ngracias!"
        text._LavendarFinale =
            "¡Gracias, {PLAYER}!\vAún tenemos que\ninvestigar más al\nEQUIPO ROCKET.\vSolo ten cuidado--\vseguro no estarán\nnada contentos.\fPueden tenderte\nuna emboscada."
        text._LavendarDone =
            "El chico abraza a\nsu hermana.\fJENNY sonríe--cada\nquien sigue su\ncamino.\fDARÍA camina a tu\nlado.\v\"Te veo, compañero.\""

        text._LavendarGruntAWon =
            "Grr... esa era\nsolo la primera\nlínea de defensa!"
        text._LavendarGruntBWon =
            "¿Dentro de la\nTORRE también?!\vBien... sube, pues."
        text._LavendarGruntCWon =
            "La RUTA 8 se\nescurre...\vpero el escondite\nte recompensa!"
        text._LavendarGruntDWon =
            "Segunda línea\nrota...\vadelante."
        text._LavendarGruntEWon =
            "Subes bien...\vlos grunts de\narriba son peores!"
        text._LavendarGruntFWon =
            "Los fantasmas no\nte detuvieron...\vbuena suerte\nallá arriba."
    end)

    -- =========================================================================
    -- 5. SCRIPTS DE MAPA (FASE D+E)
    --
    -- Composición (MapScripts.lua): onEnter all-run (nuestro corre junto al
    -- vanilla), onStep first-truthy-consume (devolvemos false salvo que
    -- lancemos un encuentro), talk por TEXT constant (keys propias, sin
    -- pisar vanilla). La visibilidad se resuelve SIEMPRE en onEnter (patrón
    -- charmander); los encuentros de grunts usan onStep (patrón squirtle:
    -- runGruntAmbush) y talk como vía secundaria.
    --
    -- Flujo nuevo (aprobado por el usuario):
    --   kid + JENNY (entra caminando) -> Ruta 8 (grunts C/D) -> fase "mystery
    --   scope" (Guarida vanilla + SILPH_SCOPE) -> JENNY revela la TORRE ->
    --   grunts de la torre A/B/E (1F-3F) -> DARIA en 4F -> subida a la cima
    --   (grunt F en 5F, lore 6F, Rockets vanilla + Mr. Fuji en 7F) -> duelo
    --   final -> Daría civil. Los grunts A/B viven en la TORRE (decisión del
    --   usuario), ya no en Lavender.
    -- =========================================================================

    local GRUNT_MUSIC = "Music_MeetMaleTrainer"
    local DARIA_MUSIC = "Music_MeetFemaleTrainer"

    -- Avance de etapa: los 2 grunts de la Ruta 8 (C y D) vencidos -> stage 3
    local function afterRoute8Grunts()
        if getState(STAGE_KEY, 0) == 2
            and beaten("lavender_grunt_c_beat")
            and beaten("lavender_grunt_d_beat") then
            setState(STAGE_KEY, 3)
        end
    end

    -- Avance de etapa: los 3 grunts de la subida baja (A, B, E) vencidos
    -- -> stage 6 (DARIA_MID). El onEnter de 4F es el fallback anti-soft-lock
    -- (llegar a 4F también avanza).
    local function afterLowerGrunts()
        if getState(STAGE_KEY, 0) == 5
            and beaten("lavender_grunt_a_beat")
            and beaten("lavender_grunt_b_beat")
            and beaten("lavender_grunt_e_beat") then
            setState(STAGE_KEY, 6)
        end
    end

    -- Encuentro de grunt tipo squirtle: si estás a <= 2 celdas, el grunt se
    -- abalanza (play_music + emote + move_npc por el eje dominante), batalla
    -- trainer, y al ganar marca beaten + se oculta. Devuelve true si lo
    -- disparó (consume el step); false si no. cfg.key va con el prefijo
    -- lavender_ COMPLETO (fix del bug de prefijo).
    local function runGruntAmbush(game, ow, x, y, cfg)
        if ow.runner:isRunning() then return false end
        if beaten(cfg.key) then return false end
        local dx = math.abs(x - cfg.x)
        local dy = math.abs(y - cfg.y)
        if dx > 2 or dy > 2 then return false end

        local npc = ow:npcByIndex(cfg.index)
        if not npc or npc.moving then return false end

        local walkDir
        local walkSteps
        if dx >= dy then
            walkDir = dx > 0 and "right" or "left"
            walkSteps = math.max(0, dx - 1)
        else
            walkDir = dy > 0 and "down" or "up"
            walkSteps = math.max(0, dy - 1)
        end

        ow.player.facing = walkDir == "right" and "left"
            or walkDir == "left" and "right"
            or walkDir == "down" and "up"
            or "down"

        local rows = {
            { "stop_music" },
            { "play_music", GRUNT_MUSIC },
            { "emote", "player", "shock", 30 },
            { "wait", 20 },
            { "move_npc", cfg.index, walkDir, walkSteps },
            { "face_player" },
            { "show_text", cfg.intro },
            { "start_battle", "trainer", cfg.trainer, 1 },
            { "check_battle_result", "win" },
            { "jump_if_false", "end_ambush" },
            { "show_text", cfg.won },
            { "lavender:set_found", cfg.key },
            { "hide_object", cfg.map, cfg.object },
            { "play_default_music" },
            { "label", "end_ambush" },
        }
        ow.runner:run(rows, { npc = npc })
        return true
    end

    -- Daría en 4F (stage 6): te intercepta, primer duelo. Al ganar "se la
    -- llevan" (stage 7) y desaparece.
    local function runDariaMidAmbush(game, ow, x, y)
        if ow.runner:isRunning() then return false end
        if getState(STAGE_KEY, 0) ~= 6 then return false end
        if beaten("lavender_daria_mid_beat") then return false end
        local dx = math.abs(x - 7)
        local dy = math.abs(y - 14)
        if dx > 2 or dy > 2 then return false end

        local npc = ow:npcByIndex(90)
        if not npc or npc.moving then return false end

        local walkDir
        local walkSteps
        if dx >= dy then
            walkDir = dx > 0 and "right" or "left"
            walkSteps = math.max(0, dx - 1)
        else
            walkDir = dy > 0 and "down" or "up"
            walkSteps = math.max(0, dy - 1)
        end

        ow.player.facing = walkDir == "right" and "left"
            or walkDir == "left" and "right"
            or walkDir == "down" and "up"
            or "down"

        local rows = {
            { "stop_music" },
            { "play_music", DARIA_MUSIC },
            { "emote", "player", "shock", 30 },
            { "wait", 20 },
            { "move_npc", 90, walkDir, walkSteps },
            { "face_player" },
            { "show_text", "_LavendarDariaMidIntro" },
            { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_DARIA_MID", 1 },
            { "check_battle_result", "win" },
            { "jump_if_false", "end_ambush" },
            { "show_text", "_LavendarDariaMidWon" },
            { "show_text", "_LavendarDariaTaken" },
            { "lavender:set_found", "lavender_daria_mid_beat" },
            { "lavender:set_stage", 7 },
            { "hide_object", "POKEMON_TOWER_4F", "STARTER_STORIES_LAVENDER_DARIA" },
            { "play_default_music" },
            { "label", "end_ambush" },
        }
        ow.runner:run(rows, { npc = npc })
        return true
    end

    -- Dirección (y pasos) para que un NPC en (ox,oy) se acerque al jugador
    -- en (px,py), por el eje dominante (mismo criterio que runGruntAmbush).
    local function stepToward(px, py, ox, oy)
        local dx = px - ox
        local dy = py - oy
        local adx = math.abs(dx)
        local ady = math.abs(dy)
        if adx >= ady then
            return (dx > 0 and "right" or "left"), math.max(0, adx - 1)
        end
        return (dy > 0 and "down" or "up"), math.max(0, ady - 1)
    end

    -- Dirección en la que un NPC en (ox,oy) debe mirar hacia el jugador.
    local function faceToward(px, py, ox, oy)
        local dx = px - ox
        local dy = py - oy
        if math.abs(dx) >= math.abs(dy) then
            return dx > 0 and "right" or "left"
        end
        return dy > 0 and "down" or "up"
    end

    -- ---------------------------------------------------------------------
    -- LAVENDER_TOWN: kid (stage 1+), Jenny (stage 2+), heal tras combates,
    -- gateo de arranque (charmander) y de vuelta con Scope (stage 3+scope->4).
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("LAVENDER_TOWN", {
        onEnter = function(game, ow)
            if getState(STAGE_KEY, 0) == 0 and charmanderComplete() then
                setState(STAGE_KEY, 1)
            end
            local stage = getState(STAGE_KEY, 0)
            if (stage == 3 or stage == 4) and hasSilphScope(game) then
                setState(STAGE_KEY, 4)
                stage = 4
            end
            afterRoute8Grunts()
            stage = getState(STAGE_KEY, 0)

            local rows = {}
            -- Tras el finale, JENNY, el morrito y DARÍA se van: no vuelven a
            -- aparecer en la plaza (ya no estorban).
            local finaleDone = beaten("lavender_finale_done")
            if stage >= 1 and not finaleDone then
                rows[#rows + 1] = { "show_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_KID" }
            else
                rows[#rows + 1] = { "hide_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_KID" }
            end
            -- Jenny entra caminando durante la intro (stage 1 -> 2); a partir
            -- de stage 2 ya es visible de forma permanente.
            if stage >= 2 and not finaleDone then
                rows[#rows + 1] = { "show_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_JENNY" }
            else
                rows[#rows + 1] = { "hide_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_JENNY" }
            end
            -- DARÍA libre en la plaza (stage 9+), junto a su hermano.
            if stage >= 9 and not finaleDone then
                rows[#rows + 1] = { "show_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_DARIA_CIVIL" }
            else
                rows[#rows + 1] = { "hide_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_DARIA_CIVIL" }
            end
            -- Jenny cura al equipo cuando ya hubo combates (stage >= 2)
            if stage >= 2 then
                rows[#rows + 1] = { "heal_party" }
            end
            ow:queueScript(rows)
        end,
        -- Escena de revelación automática: cuando el jugador vuelve a Lavender
        -- con el SILPH_SCOPE y ya derrotó a los dos grunts de la Ruta 8 (stage
        -- 4 = JENNY_REVEAL), JENNY y el morrito se acercan a hablarle en vez
        -- de esperar a que el jugador los busque. Se dispara una sola vez
        -- (flag lavender_jenny_reveal_done); el talk sigue como vía secundaria.
        onStep = function(game, ow, x, y)
            if ow.runner:isRunning() then return false end
            local stage = getState(STAGE_KEY, 0)
            local jenny = ow:npcByIndex(91)

            -- ------------------------------------------------------------
            -- Escena de revelación (stage 4): al volver con el SILPH_SCOPE
            -- y con los 2 grunts de la Ruta 8 vencidos, JENNY y el morrito
            -- se acercan a hablarle al jugador. Una sola vez por quest.
            -- ------------------------------------------------------------
            if stage == 4 then
                if not hasSilphScope(game) then return false end
                if not (beaten("lavender_grunt_c_beat") and beaten("lavender_grunt_d_beat")) then
                    return false
                end
                if beaten("lavender_jenny_reveal_done") then return false end

                -- Solo cerca del kid/JENNY (centro del pueblo, radio 3 celdas),
                -- para no interrumpir la entrada por otros bordes.
                local dx = math.abs(x - 12)
                local dy = math.abs(y - 12)
                if dx > 3 or dy > 3 then return false end

                if not jenny or jenny.moving then return false end

                setBeaten("lavender_jenny_reveal_done")

                local jDir, jSteps = stepToward(x, y, 13, 12)
                local kDir, kSteps = stepToward(x, y, 11, 11)

                ow.player.facing = jDir == "right" and "left"
                    or jDir == "left" and "right"
                    or jDir == "down" and "up"
                    or "down"

                ow.runner:run({
                    { "stop_music" },
                    { "play_music", DARIA_MUSIC },
                    { "emote", "player", "shock", 30 },
                    { "wait", 20 },
                    -- JENNY se acerca al jugador...
                    { "move_npc", 91, jDir, jSteps },
                    { "face_object", 91, faceToward(x, y, 13, 12) },
                    -- ...y el morrito también.
                    { "move_npc", 90, kDir, kSteps },
                    { "face_object", 90, faceToward(x, y, 11, 11) },
                    { "show_text", "_LavendarHideoutClue" },
                    { "show_text", "_LavendarJennyReveal" },
                    { "lavender:set_stage", 5 },
                    { "play_default_music" },
                }, { npc = jenny })
                return true
            end

            -- ------------------------------------------------------------
            -- Escena final (stage 9): con Daría liberada Y Mr. Fuji rescatado
            -- (ambas misiones), al volver a Lavender JENNY y el morrito se
            -- acercan: JENNY paga el ELIXER y ambos cierran la aventura.
            -- ------------------------------------------------------------
            if stage >= 9 then
                if beaten("lavender_finale_done") then return false end
                if not (game.save.flags and game.save.flags.EVENT_RESCUED_MR_FUJI) then
                    return false
                end

                -- Solo cerca del kid/JENNY (centro del pueblo, radio 3 celdas).
                local dx = math.abs(x - 12)
                local dy = math.abs(y - 12)
                if dx > 3 or dy > 3 then return false end

                if not jenny or jenny.moving then return false end

                setBeaten("lavender_finale_done")

                local jDir, jSteps = stepToward(x, y, 13, 12)
                local kDir, kSteps = stepToward(x, y, 11, 11)

                ow.player.facing = jDir == "right" and "left"
                    or jDir == "left" and "right"
                    or jDir == "down" and "up"
                    or "down"

                local rows = {
                    { "stop_music" },
                    { "play_music", DARIA_MUSIC },
                    { "emote", "player", "happy", 30 },
                    { "wait", 20 },
                    -- JENNY se acerca al jugador...
                    { "move_npc", 91, jDir, jSteps },
                    { "face_object", 91, faceToward(x, y, 13, 12) },
                    -- ...y el morrito también.
                    { "move_npc", 90, kDir, kSteps },
                    { "face_object", 90, faceToward(x, y, 11, 11) },
                }
                -- JENNY agradece al jugador y advierte de la represalia de
                -- ROCKET (gancho para las emboscadas), y paga el ELIXER.
                rows[#rows + 1] = { "show_text", "_LavendarFinale" }
                if not beaten("lavender_elixer_given") then
                    rows[#rows + 1] = { "show_text", "_LavendarJennyReward" }
                    rows[#rows + 1] = { "give_item", "ELIXER", 1, false }
                    rows[#rows + 1] = { "lavender:set_found", "lavender_elixer_given" }
                end
                rows[#rows + 1] = { "show_text", "_LavendarKidThanks" }
                rows[#rows + 1] = { "show_text", "_LavendarDone" }
                -- Al cerrar la misión, JENNY y el morrito se van (el pueblo
                -- recupera la calma) y DARÍA sigue al jugador: ya no estorban
                -- en la plaza. hide_object persiste vía flag de visibilidad.
                rows[#rows + 1] = { "wait", 30 }
                rows[#rows + 1] = { "move_npc", 90, "down", 2 }
                rows[#rows + 1] = { "move_npc", 91, "down", 2 }
                rows[#rows + 1] = { "hide_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_KID" }
                rows[#rows + 1] = { "hide_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_JENNY" }
                rows[#rows + 1] = { "hide_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_DARIA_CIVIL" }
                rows[#rows + 1] = { "play_default_music" }

                ow.runner:run(rows, { npc = jenny })
                return true
            end

            return false
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_KID = {
                { "face_player" },
                { "lavender:check_charmander_done" },
                { "jump_if_false", "end_talk" },
                { "lavender:check_stage", 1 },
                { "jump_if_true", "intro" },
                { "lavender:check_stage", 2 },
                { "jump_if_true", "route8" },
                { "lavender:check_stage", 3 },
                { "jump_if_true", "wait" },
                { "lavender:check_stage", 4 },
                { "jump_if_true", "wait" },
                { "lavender:check_stage", 9 },
                { "jump_if_true", "thanks" },
                { "show_text", "_LavendarKidTower" },
                { "jump", "end_talk" },

                { "label", "intro" },
                { "show_text", "_LavendarKidIntro" },
                -- Jenny entra caminando desde el norte (columna x13, bajan de
                -- (13,8) a (13,12)) y se gira hacia el jugador.
                { "show_object", "LAVENDER_TOWN", "STARTER_STORIES_LAVENDER_JENNY" },
                { "place_npc", 91, 13, 8, "down" },
                { "move_npc", 91, "down", 4 },
                { "face_object", 91, "left" },
                { "show_text", "_LavendarJennyRoute8" },
                { "lavender:set_stage", 2 },
                { "jump", "end_talk" },

                { "label", "route8" },
                { "show_text", "_LavendarKidSearching" },
                { "jump", "end_talk" },

                { "label", "wait" },
                { "show_text", "_LavendarKidWait" },
                { "jump", "end_talk" },

                { "label", "thanks" },
                { "show_text", "_LavendarKidThanks" },
                { "jump", "end_talk" },

                { "label", "end_talk" },
            },
            TEXT_STARTER_STORIES_LAVENDER_JENNY = {
                { "face_player" },
                { "lavender:check_stage", 2 },
                { "jump_if_true", "route8" },
                { "lavender:check_stage", 3 },
                { "jump_if_true", "scope" },
                { "lavender:check_stage", 4 },
                { "jump_if_true", "scope" },
                { "lavender:check_stage", 9 },
                { "jump_if_true", "reward" },
                { "show_text", "_LavendarJennyIntro" },
                { "jump", "end_talk" },

                { "label", "route8" },
                { "show_text", "_LavendarJennyRoute8" },
                { "jump", "end_talk" },

                { "label", "scope" },
                { "check_item", "SILPH_SCOPE" },
                { "jump_if_true", "reveal" },
                { "show_text", "_LavendarScopeReminder" },
                { "jump", "end_talk" },

                { "label", "reveal" },
                { "show_text", "_LavendarHideoutClue" },
                { "show_text", "_LavendarJennyReveal" },
                { "lavender:set_stage", 5 },
                { "jump", "end_talk" },

                { "label", "reward" },
                { "lavender:check_found", "lavender_elixer_given" },
                { "jump_if_true", "reward_done" },
                { "show_text", "_LavendarJennyReward" },
                { "give_item", "ELIXER", 1, false },
                { "lavender:set_found", "lavender_elixer_given" },
                { "jump", "end_talk" },

                { "label", "reward_done" },
                { "show_text", "_LavendarDone" },
                { "jump", "end_talk" },

                { "label", "end_talk" },
            },
        },
    })

    -- ---------------------------------------------------------------------
    -- POKEMON_TOWER_1F: GRUNT_B (stage 5+), junto a las escaleras a 2F.
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("POKEMON_TOWER_1F", {
        onEnter = function(game, ow)
            afterLowerGrunts()
            local stage = getState(STAGE_KEY, 0)
            local rows = {}
            if stage >= 5 and not beaten("lavender_grunt_b_beat") then
                rows[#rows + 1] = { "show_object", "POKEMON_TOWER_1F", "STARTER_STORIES_LAVENDER_GRUNT_B" }
            else
                rows[#rows + 1] = { "hide_object", "POKEMON_TOWER_1F", "STARTER_STORIES_LAVENDER_GRUNT_B" }
            end
            ow:queueScript(rows)
        end,
        onStep = function(game, ow, x, y)
            afterLowerGrunts()
            if getState(STAGE_KEY, 0) < 5 then return false end
            return runGruntAmbush(game, ow, x, y, {
                index = 90, x = 16, y = 10,
                key = "lavender_grunt_b_beat",
                map = "POKEMON_TOWER_1F",
                object = "STARTER_STORIES_LAVENDER_GRUNT_B",
                trainer = "STARTER_STORIES_LAVENDER_GRUNT_B",
                intro = "_LavendarGruntBIntro",
                won = "_LavendarGruntBWon",
            })
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_GRUNT_B = {
                { "face_player" },
                { "lavender:check_found", "lavender_grunt_b_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarGruntBIntro" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_GRUNT_B", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarGruntBWon" },
                { "lavender:set_found", "lavender_grunt_b_beat" },
                { "hide_object", "POKEMON_TOWER_1F", "STARTER_STORIES_LAVENDER_GRUNT_B" },
                { "label", "end_talk" },
            },
        },
    })

    -- ---------------------------------------------------------------------
    -- POKEMON_TOWER_2F: GRUNT_A (stage 5+), en el corredor central.
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("POKEMON_TOWER_2F", {
        onEnter = function(game, ow)
            afterLowerGrunts()
            local stage = getState(STAGE_KEY, 0)
            local rows = {}
            if stage >= 5 and not beaten("lavender_grunt_a_beat") then
                rows[#rows + 1] = { "show_object", "POKEMON_TOWER_2F", "STARTER_STORIES_LAVENDER_GRUNT_A" }
            else
                rows[#rows + 1] = { "hide_object", "POKEMON_TOWER_2F", "STARTER_STORIES_LAVENDER_GRUNT_A" }
            end
            ow:queueScript(rows)
        end,
        onStep = function(game, ow, x, y)
            afterLowerGrunts()
            if getState(STAGE_KEY, 0) < 5 then return false end
            return runGruntAmbush(game, ow, x, y, {
                index = 90, x = 14, y = 7,
                key = "lavender_grunt_a_beat",
                map = "POKEMON_TOWER_2F",
                object = "STARTER_STORIES_LAVENDER_GRUNT_A",
                trainer = "STARTER_STORIES_LAVENDER_GRUNT_A",
                intro = "_LavendarGruntAIntro",
                won = "_LavendarGruntAWon",
            })
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_GRUNT_A = {
                { "face_player" },
                { "lavender:check_found", "lavender_grunt_a_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarGruntAIntro" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_GRUNT_A", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarGruntAWon" },
                { "lavender:set_found", "lavender_grunt_a_beat" },
                { "hide_object", "POKEMON_TOWER_2F", "STARTER_STORIES_LAVENDER_GRUNT_A" },
                { "label", "end_talk" },
            },
        },
    })

    -- ---------------------------------------------------------------------
    -- ROUTE_8 (ida a Azulona): grunts C/D visibles desde el stage 2. Ambos
    -- vencidos -> stage 3; llegar a la puerta oeste (x<=3) también avanza
    -- (anti-soft-lock si se evitan).
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("ROUTE_8", {
        onEnter = function(game, ow)
            afterRoute8Grunts()
            local stage = getState(STAGE_KEY, 0)
            local rows = {}
            if stage == 2 then
                if not beaten("lavender_grunt_d_beat") then
                    rows[#rows + 1] = { "show_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_D" }
                else
                    rows[#rows + 1] = { "hide_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_D" }
                end
                if not beaten("lavender_grunt_c_beat") then
                    rows[#rows + 1] = { "show_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_C" }
                else
                    rows[#rows + 1] = { "hide_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_C" }
                end
            else
                rows[#rows + 1] = { "hide_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_D" }
                rows[#rows + 1] = { "hide_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_C" }
            end
            ow:queueScript(rows)
        end,
        onStep = function(game, ow, x, y)
            afterRoute8Grunts()
            local stage = getState(STAGE_KEY, 0)
            if stage == 2 and x <= 3 then
                setState(STAGE_KEY, 3)
                stage = 3
            end
            if stage ~= 2 then return false end
            if not beaten("lavender_grunt_d_beat") then
                return runGruntAmbush(game, ow, x, y, {
                    index = 91, x = 44, y = 10,
                    key = "lavender_grunt_d_beat",
                    map = "ROUTE_8",
                    object = "STARTER_STORIES_LAVENDER_GRUNT_D",
                    trainer = "STARTER_STORIES_LAVENDER_GRUNT_D",
                    intro = "_LavendarGruntDIntro",
                    won = "_LavendarGruntDWon",
                })
            end
            if not beaten("lavender_grunt_c_beat") then
                return runGruntAmbush(game, ow, x, y, {
                    index = 90, x = 25, y = 10,
                    key = "lavender_grunt_c_beat",
                    map = "ROUTE_8",
                    object = "STARTER_STORIES_LAVENDER_GRUNT_C",
                    trainer = "STARTER_STORIES_LAVENDER_GRUNT_C",
                    intro = "_LavendarGruntCIntro",
                    won = "_LavendarGruntCWon",
                })
            end
            return false
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_GRUNT_D = {
                { "face_player" },
                { "lavender:check_found", "lavender_grunt_d_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarGruntDIntro" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_GRUNT_D", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarGruntDWon" },
                { "lavender:set_found", "lavender_grunt_d_beat" },
                { "hide_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_D" },
                { "label", "end_talk" },
            },
            TEXT_STARTER_STORIES_LAVENDER_GRUNT_C = {
                { "face_player" },
                { "lavender:check_found", "lavender_grunt_c_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarGruntCIntro" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_GRUNT_C", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarGruntCWon" },
                { "lavender:set_found", "lavender_grunt_c_beat" },
                { "hide_object", "ROUTE_8", "STARTER_STORIES_LAVENDER_GRUNT_C" },
                { "label", "end_talk" },
            },
        },
    })

    -- ---------------------------------------------------------------------
    -- POKEMON_TOWER_3F: GRUNT_E (stage 5+).
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("POKEMON_TOWER_3F", {
        onEnter = function(game, ow)
            afterLowerGrunts()
            local stage = getState(STAGE_KEY, 0)
            local rows = {}
            if stage >= 5 and not beaten("lavender_grunt_e_beat") then
                rows[#rows + 1] = { "show_object", "POKEMON_TOWER_3F", "STARTER_STORIES_LAVENDER_GRUNT_E" }
            else
                rows[#rows + 1] = { "hide_object", "POKEMON_TOWER_3F", "STARTER_STORIES_LAVENDER_GRUNT_E" }
            end
            ow:queueScript(rows)
        end,
        onStep = function(game, ow, x, y)
            afterLowerGrunts()
            if getState(STAGE_KEY, 0) < 5 then return false end
            return runGruntAmbush(game, ow, x, y, {
                index = 90, x = 8, y = 12,
                key = "lavender_grunt_e_beat",
                map = "POKEMON_TOWER_3F",
                object = "STARTER_STORIES_LAVENDER_GRUNT_E",
                trainer = "STARTER_STORIES_LAVENDER_GRUNT_E",
                intro = "_LavendarGruntEIntro",
                won = "_LavendarGruntEWon",
            })
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_GRUNT_E = {
                { "face_player" },
                { "lavender:check_found", "lavender_grunt_e_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarGruntEIntro" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_GRUNT_E", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarGruntEWon" },
                { "lavender:set_found", "lavender_grunt_e_beat" },
                { "hide_object", "POKEMON_TOWER_3F", "STARTER_STORIES_LAVENDER_GRUNT_E" },
                { "label", "end_talk" },
            },
        },
    })

    -- ---------------------------------------------------------------------
    -- POKEMON_TOWER_4F: DARÍA en piso medio (stage 6) -> primer duelo, "se
    -- la llevan" (stage 7). Llegar a 4F con stage 5 también avanza (fallback
    -- anti-soft-lock si se evita a algún grunt de los pisos 1-3).
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("POKEMON_TOWER_4F", {
        onEnter = function(game, ow)
            afterLowerGrunts()
            local stage = getState(STAGE_KEY, 0)
            if stage == 5 then
                setState(STAGE_KEY, 6)
                stage = 6
            end
            local rows = {}
            if stage == 6 and not beaten("lavender_daria_mid_beat") then
                rows[#rows + 1] = { "show_object", "POKEMON_TOWER_4F", "STARTER_STORIES_LAVENDER_DARIA" }
            else
                rows[#rows + 1] = { "hide_object", "POKEMON_TOWER_4F", "STARTER_STORIES_LAVENDER_DARIA" }
            end
            ow:queueScript(rows)
        end,
        onStep = function(game, ow, x, y)
            if getState(STAGE_KEY, 0) ~= 6 then return false end
            return runDariaMidAmbush(game, ow, x, y)
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_DARIA = {
                { "face_player" },
                { "lavender:check_stage", 6 },
                { "jump_if_false", "end_talk" },
                { "lavender:check_found", "lavender_daria_mid_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarDariaMidIntro" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_DARIA_MID", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarDariaMidWon" },
                { "show_text", "_LavendarDariaTaken" },
                { "lavender:set_found", "lavender_daria_mid_beat" },
                { "lavender:set_stage", 7 },
                { "hide_object", "POKEMON_TOWER_4F", "STARTER_STORIES_LAVENDER_DARIA" },
                { "label", "end_talk" },
            },
        },
    })

    -- ---------------------------------------------------------------------
    -- POKEMON_TOWER_5F: GRUNT_F (stage 7+). Llegar a 5F con stage 6 avanza a
    -- 7 (fallback anti-soft-lock: se superó el piso de DARÍA).
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("POKEMON_TOWER_5F", {
        onEnter = function(game, ow)
            local stage = getState(STAGE_KEY, 0)
            if stage == 6 then
                setState(STAGE_KEY, 7)
                stage = 7
            end
            local rows = {}
            if stage >= 7 and not beaten("lavender_grunt_f_beat") then
                rows[#rows + 1] = { "show_object", "POKEMON_TOWER_5F", "STARTER_STORIES_LAVENDER_GRUNT_F" }
            else
                rows[#rows + 1] = { "hide_object", "POKEMON_TOWER_5F", "STARTER_STORIES_LAVENDER_GRUNT_F" }
            end
            ow:queueScript(rows)
        end,
        onStep = function(game, ow, x, y)
            if getState(STAGE_KEY, 0) < 7 then return false end
            return runGruntAmbush(game, ow, x, y, {
                index = 90, x = 10, y = 12,
                key = "lavender_grunt_f_beat",
                map = "POKEMON_TOWER_5F",
                object = "STARTER_STORIES_LAVENDER_GRUNT_F",
                trainer = "STARTER_STORIES_LAVENDER_GRUNT_F",
                intro = "_LavendarGruntFIntro",
                won = "_LavendarGruntFWon",
            })
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_GRUNT_F = {
                { "face_player" },
                { "lavender:check_found", "lavender_grunt_f_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarGruntFIntro" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_GRUNT_F", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarGruntFWon" },
                { "lavender:set_found", "lavender_grunt_f_beat" },
                { "hide_object", "POKEMON_TOWER_5F", "STARTER_STORIES_LAVENDER_GRUNT_F" },
                { "label", "end_talk" },
            },
        },
    })

    -- ---------------------------------------------------------------------
    -- POKEMON_TOWER_6F: hook lore del Marowak (madre Cubone). NO consume el
    -- step: el onStep vanilla de (10,16) debe seguir disparando su batalla.
    -- Llegar a 6F con stage 6 avanza a 7 (fallback anti-soft-lock).
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("POKEMON_TOWER_6F", {
        onEnter = function(game, ow)
            if getState(STAGE_KEY, 0) == 6 then
                setState(STAGE_KEY, 7)
            end
        end,
        onStep = function(game, ow, x, y)
            if ow.runner:isRunning() then return false end
            if getState(STAGE_KEY, 0) < 7 then return false end
            if beaten("lavender_marowak_lore") then return false end
            if game.save.flags and game.save.flags.EVENT_BEAT_GHOST_MAROWAK then
                return false
            end
            if x == 10 and y == 16 then return false end
            if math.abs(x - 10) > 3 or math.abs(y - 16) > 3 then return false end
            setBeaten("lavender_marowak_lore")
            ow.runner:run({
                { "show_text", "_LavendarGhostMarowak" },
            })
            return false
        end,
    })

    -- ---------------------------------------------------------------------
    -- POKEMON_TOWER_7F: Daría con los Rockets vanilla de la cima (stage 7+),
    -- nota + duelo (stage 8) al vencerlos y rescatar a Mr. Fuji, sprite
    -- swap a DARIA_CIVIL (stage 9). Los 3 Rockets y Fuji quedan vanilla.
    --
    -- IMPORTANTE: el talk vanilla de Mr. Fuji warpea a su casa justo después
    -- de setear EVENT_RESCUED_MR_FUJI, así que el jugador NUNCA da otro paso
    -- en el 7F tras cumplir las 4 flags. La transición stage 7->8 NO puede
    -- depender de un onStep aquí: se evalúa en onEnter (al volver a subir al
    -- 7F ya están las flags) y el duelo final se dispara como emboscada
    -- (onStep, patrón grunt) al acercarse a Daría.
    -- ---------------------------------------------------------------------
    mod.content.map_scripts:register("POKEMON_TOWER_7F", {
        onEnter = function(game, ow)
            local stage = getState(STAGE_KEY, 0)
            if stage == 6 then
                setState(STAGE_KEY, 7)
                stage = 7
            end
            -- Transición 7->8: venció a los 3 Rockets vanilla y rescató a
            -- Fuji (el warp de Fuji saca del mapa, así que solo corre aquí,
            -- al re-entrar). Muestra la nota de JENNY una sola vez.
            local justAdvanced = false
            if (stage == 7 or stage == 8)
                and not beaten("lavender_top_note")
                and game.save.flags
                and game.save.flags.EVENT_BEAT_POKEMONTOWER_7_TRAINER_0
                and game.save.flags.EVENT_BEAT_POKEMONTOWER_7_TRAINER_1
                and game.save.flags.EVENT_BEAT_POKEMONTOWER_7_TRAINER_2
                and game.save.flags.EVENT_RESCUED_MR_FUJI then
                setBeaten("lavender_top_note")
                setState(STAGE_KEY, 8)
                stage = 8
                justAdvanced = true
            end
            local rows = {}
            if (stage == 7 or stage == 8) and not beaten("lavender_daria_final_beat") then
                rows[#rows + 1] = { "show_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA" }
            else
                rows[#rows + 1] = { "hide_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA" }
            end
            if stage >= 9 then
                rows[#rows + 1] = { "show_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA_CIVIL" }
            else
                rows[#rows + 1] = { "hide_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA_CIVIL" }
            end
            if justAdvanced then
                rows[#rows + 1] = { "show_text", "_LavendarTopRocketNote" }
            end
            ow:queueScript(rows)
        end,
        -- Emboscada del duelo final: en stage 7 (o 8 como fallback) al
        -- acercarse a Daría (11,5) te reta automáticamente, igual que los
        -- grunts. Ya NO espera a rescatar a Mr. Fuji: Daría se libera al
        -- llegar a la cima, y el rescate de Fuji queda para después (vanilla).
        onStep = function(game, ow, x, y)
            if ow.runner:isRunning() then return false end
            local stage = getState(STAGE_KEY, 0)
            if not (stage == 7 or stage == 8) then return false end
            if beaten("lavender_daria_final_beat") then return false end
            local dx = math.abs(x - 11)
            local dy = math.abs(y - 5)
            if dx > 2 or dy > 2 then return false end

            local daria = ow:npcByIndex(90)
            if not daria or daria.moving then return false end

            local walkDir
            local walkSteps
            if dx >= dy then
                walkDir = dx > 0 and "right" or "left"
                walkSteps = math.max(0, dx - 1)
            else
                walkDir = dy > 0 and "down" or "up"
                walkSteps = math.max(0, dy - 1)
            end

            ow.player.facing = walkDir == "right" and "left"
                or walkDir == "left" and "right"
                or walkDir == "down" and "up"
                or "down"

            local rows = {
                { "stop_music" },
                { "play_music", DARIA_MUSIC },
                { "emote", "player", "shock", 30 },
                { "wait", 20 },
                { "move_npc", 90, walkDir, walkSteps },
                { "face_player" },
                { "show_text", "_LavendarDariaDuelIntro" },
                { "show_text", "_LavendarDariaDuelPre" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_DARIA_FINAL", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_ambush" },
                { "show_text", "_LavendarDariaDuelWon" },
                { "show_text", "_LavendarJoined" },
                { "lavender:set_found", "lavender_daria_final_beat" },
                { "lavender:set_stage", 9 },
                { "hide_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA" },
                { "show_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA_CIVIL" },
                { "play_default_music" },
                { "label", "end_ambush" },
            }
            ow.runner:run(rows, { npc = daria })
            return true
        end,
        talk = {
            TEXT_STARTER_STORIES_LAVENDER_DARIA = {
                { "face_player" },
                { "lavender:check_stage", 8 },
                { "jump_if_false", "end_talk" },
                { "lavender:check_found", "lavender_daria_final_beat" },
                { "jump_if_true", "end_talk" },
                { "show_text", "_LavendarDariaDuelIntro" },
                { "show_text", "_LavendarDariaDuelPre" },
                { "start_battle", "trainer", "STARTER_STORIES_LAVENDER_DARIA_FINAL", 1 },
                { "check_battle_result", "win" },
                { "jump_if_false", "end_talk" },
                { "show_text", "_LavendarDariaDuelWon" },
                { "show_text", "_LavendarJoined" },
                { "lavender:set_found", "lavender_daria_final_beat" },
                { "lavender:set_stage", 9 },
                { "hide_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA" },
                { "show_object", "POKEMON_TOWER_7F", "STARTER_STORIES_LAVENDER_DARIA_CIVIL" },
                { "label", "end_talk" },
            },
            TEXT_STARTER_STORIES_LAVENDER_DARIA_CIVIL = {
                { "face_player" },
                { "show_text", "_LavendarDone" },
            },
        },
    })

    -- =========================================================================
    -- 6. REGISTRO DE LA MISIÓN
    -- =========================================================================

    -- Entrada en el journal del mod quest_system (patrón squirtle/charmander:
    -- bloqueada si el mod no existe, pcall-ensured).
    mod.events:on("game.ready", function(payload)
        local game = payload and payload.game or payload
        if not game then return end

        local journal = mod.find("quest_system")
        if not (journal and journal.exports and journal.exports.register) then
            return
        end

        pcall(journal.exports.register, {
            id = "starter_stories_lavender",
            title = "The Missing Trainer",
            source = "Starter Stories",
            sort = 180,
            description =
                "DARIA, a strong trainer, has vanished. Her brother " ..
                "says TEAM ROCKET took her. Follow the trail from " ..
                "Lavender Town.",
            objective = function()
                local s = getState(STAGE_KEY, 0)
                if s >= 9 then
                    return "Mission complete. DARIA is safe and trusts you!"
                end
                if s == 8 then
                    return "Face DARIA in a final battle at the top of the Pokemon Tower."
                end
                if s == 7 then
                    return "Reach the tower top: beat the three ROCKETS and rescue Mr. Fuji."
                end
                if s == 6 then
                    return "Find DARIA on the middle floors of the Pokemon Tower."
                end
                if s == 5 then
                    return "Climb the Pokemon Tower. Beat the ROCKETS on floors 1, 2 and 3."
                end
                if s == 4 then
                    return "Return to Lavender Town with the SILPH SCOPE."
                end
                if s == 3 then
                    return "Search the ROCKET Hideout in CELADON and get the SILPH SCOPE."
                end
                if s == 2 then
                    return "Clear the ROCKETS from ROUTE 8 to reach CELADON."
                end
                if s == 1 then
                    return "Talk to the kid in Lavender Town."
                end
                return "Find out what happened to the strong trainer DARIA."
            end,
            location = function()
                local s = getState(STAGE_KEY, 0)
                if s >= 5 then return "Pokemon Tower" end
                if s == 3 then return "Celadon City" end
                if s == 2 then return "Route 8" end
                return "Lavender Town"
            end,
            reward = "DARIA's trust and an ELIXER from JENNY",
            progress = function()
                return {
                    current = getState(STAGE_KEY, 0),
                    total = 9,
                }
            end,
        })
    end)

    if mod.quests and mod.quests.register then
        mod.quests.register("lavender", {
            stage = function()
                return getState(STAGE_KEY, 0)
            end,
            completed = function()
                return getState(STAGE_KEY, 0) >= 9
            end,
        })
    end

end
