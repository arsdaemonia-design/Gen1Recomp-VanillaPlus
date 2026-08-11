return function(mod)
    local compile = loadstring or load

    local function loadQuest(relative)
        local source, readErr = mod:read(relative)
        if not source then
            error(("cannot read quest file %s: %s"):format(relative, tostring(readErr)), 0)
        end
        local chunk, compileErr = compile(source, "@" .. mod.path .. "/" .. relative)
        if not chunk then
            error(("cannot compile quest file %s: %s"):format(relative, tostring(compileErr)), 0)
        end
        local ok, result = pcall(chunk)
        if not ok then
            error(("quest file %s failed to load: %s"):format(relative, tostring(result)), 0)
        end
        if type(result) == "function" then result(mod) end
    end

    -- Quest 1: Running Shoes (mision original de vanilla-plus)
    loadQuest("quests/running_shoes.lua")

    -- Quest 2: The Lost Bulbasaur / El Bulbasaur Perdido
    loadQuest("quests/bulbasaur.lua")
end