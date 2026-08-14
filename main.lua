return function(mod)
    local compile = loadstring or load

    local function loadQuest(relative)
        mod.log:info(("==> loading %s"):format(relative))

        local source, readErr = mod:read(relative)
        if not source then
            mod.log:error(("cannot read %s: %s"):format(relative, tostring(readErr)))
            error(("cannot read quest file %s: %s"):format(relative, tostring(readErr)), 0)
        end

        local chunk, compileErr = compile(source, "@" .. mod.path .. "/" .. relative)
        if not chunk then
            mod.log:error(("cannot compile %s: %s"):format(relative, tostring(compileErr)))
            error(("cannot compile quest file %s: %s"):format(relative, tostring(compileErr)), 0)
        end

        local ok, result = pcall(chunk)
        if not ok then
            mod.log:error(("runtime error in %s: %s"):format(relative, tostring(result)))
            error(("quest file %s failed to load: %s"):format(relative, tostring(result)), 0)
        end

        if type(result) == "function" then
            local ok2, err2 = pcall(result, mod)
            if not ok2 then
                mod.log:error(("error executing %s: %s"):format(relative, tostring(err2)))
                error(("quest %s entry failed: %s"):format(relative, tostring(err2)), 0)
            end
            mod.log:info(("    ok: %s executed"):format(relative))
        else
            mod.log:info(("    ok: %s compiled (no entry function)"):format(relative))
        end
    end

    -- QuestConnector: debe cargarse ANTES que cualquier quest
    loadQuest("quests/state.lua")

    -- Quest 1: Running Shoes (mision original de vanilla-plus)
    loadQuest("quests/running_shoes.lua")

    -- Quest 2: The Lost Bulbasaur / El Bulbasaur Perdido
    loadQuest("quests/bulbasaur.lua")

    -- Quest 3: The Problematic Squirtle / El Squirtle Problematico
    loadQuest("quests/squirtle.lua")

    -- Quest 4: The Scared Kid / El Chico Asustado (Charmander)
    loadQuest("quests/charmander.lua")

    -- Independent NPC + Charmander followers for the quest.
    loadQuest("quests/charmander_follower.lua")

    mod.log:info("==> vanilla-plus: all quests loaded")
end
