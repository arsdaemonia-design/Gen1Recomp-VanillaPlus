return function(mod)
    -- Independent story followers for the Charmander quest.  This module
    -- does not import or call Wilds of Kanto.
    local STAGE_KEY = "mod:charmander_stage"
    local FOLLOWER_MAPS = {
        ROCK_TUNNEL_1F = true,
        ROCK_TUNNEL_B1F = true,
    }
    local KID_NAME = "STARTER_STORIES_CHARMANDER_KID"
    local CHAR_NAME = "STARTER_STORIES_CHARMANDER_FOLLOWER"

    local trail = {}
    local currentMap = nil
    local lastX, lastY = nil, nil
    local cachedKid, cachedChar = nil, nil

    local BACK = {
        up = { 0, 1 }, down = { 0, -1 },
        left = { 1, 0 }, right = { -1, 0 },
    }

    local function stage()
        return tonumber(mod.save:get(STAGE_KEY, 0)) or 0
    end

    local function hasCharmander(game)
        for _, mon in ipairs((game and game.save and game.save.party) or {}) do
            if mon.species == "CHARMANDER"
                or mon.species == "CHARMELEON"
                or mon.species == "CHARIZARD" then
                return true
            end
        end
        return false
    end

    local function activeWorld()
        return mod.world and mod.world:overworld()
    end

    local function wildsOwnsPokemonFollower(game)
        local exports = game and game.mods and game.mods.exports
        local api = exports and exports.overworld_wild_spawns
        if type(api) ~= "table" or type(api.getActiveFollowerMon) ~= "function" then
            return false
        end
        local ok, active = pcall(api.getActiveFollowerMon, game, false)
        return ok and active ~= nil
    end

    local function put(npc, x, y, facing)
        if not npc then return end
        npc.cellX, npc.cellY = x, y
        npc.px, npc.py = x * 16, y * 16
        npc.targetX, npc.targetY = nil, nil
        npc.progress = 0
        npc.moving = false
        npc.marching = false
        if facing then npc.facing = facing end
        npc.passable = true
    end

    local function behind(ow, distance)
        local p = ow.player
        local d = BACK[p.facing] or BACK.down
        local x = p.cellX + d[1] * distance
        local y = p.cellY + d[2] * distance
        local w = ow.map.width or 9999
        local h = ow.map.height or 9999
        return math.max(0, math.min(w - 1, x)),
            math.max(0, math.min(h - 1, y))
    end

    local function ensureCharmander(ow)
        local handle = mod.world:npc(ow.map.id, CHAR_NAME)
        if handle then return handle end
        local x, y = behind(ow, 2)
        local id = mod.world:spawnNpc(ow.map.id, {
            name = CHAR_NAME,
            sprite = "SPRITE_FOLLOWER_CHARMANDER",
            x = x,
            y = y,
            movement = "STAY",
            range = "DOWN",
            hidden = false,
        })
        if not id then return nil end
        return mod.world:npc(ow.map.id, CHAR_NAME)
    end

    local function targetAt(offset)
        local index = #trail - offset
        if index < 1 then index = 1 end
        return trail[index]
    end

    local function moveToward(handle, target, ow)
        if not (handle and target and handle.npc) then return end
        local npc = handle.npc
        npc.passable = true
        if npc.moving then return end
        local x, y = npc.cellX, npc.cellY
        local dx, dy = target.x - x, target.y - y
        if math.max(math.abs(dx), math.abs(dy)) > 6 then
            put(npc, target.x, target.y)
            return
        end
        if dx == 0 and dy == 0 then return end
        local dir
        if math.abs(dx) >= math.abs(dy) then
            dir = dx > 0 and "right" or "left"
        else
            dir = dy > 0 and "down" or "up"
        end
        npc.facing = dir
        npc.targetX = target.x
        npc.targetY = target.y
        npc.moving = true
        npc.progress = 0
        
        if ow and ow.player then
            local p = ow.player
            local stepLen = p.stepFramesCur or p.stepFrames or 16
            local far = math.abs(dx) + math.abs(dy)
            if far > 1 then
                stepLen = math.max(1, math.floor(stepLen / 2))
            end
            npc.stepFrames = stepLen
        end
        
        if ow and ow.map and ow.entities then
            npc:update(ow.map, ow.entities)
        end
    end

    local function syncFollowers(game, mapId)
        local ow = activeWorld()
        if not (ow and ow.map and ow.map.id == mapId) then return end
        if stage() ~= 4 or not hasCharmander(game) then return end

        local kid = cachedKid
        if not (kid and kid.npc and kid.npc.cellX) then
            kid = mod.world:npc(mapId, KID_NAME)
        end
        -- The map script may still be finishing its show_object command on
        -- the first map-enter event.  Do not spawn anything until the static
        -- story NPC is actually live.
        if not kid then return end

        local char = cachedChar
        if not (char and char.npc and char.npc.cellX) then
            char = ensureCharmander(ow)
        end
        if not char then return end
        cachedKid, cachedChar = kid, char
        kid.npc.passable = true

        local offsetChar = wildsOwnsPokemonFollower(game) and 2 or 1
        local offsetKid = offsetChar + 1

        local cx, cy = behind(ow, offsetChar)
        local kx, ky = behind(ow, offsetKid)
        
        if char then put(char.npc, cx, cy) end
        put(kid.npc, kx, ky)
        
        trail = {}
        for i = offsetKid, 1, -1 do
            local tx, ty = behind(ow, i)
            table.insert(trail, { x = tx, y = ty })
        end
        table.insert(trail, { x = ow.player.cellX, y = ow.player.cellY })

        currentMap = mapId
    end

    mod.events:on("map.entered", function(ev)
        local game = mod.world and mod.world.game
        local mapId = ev and ev.mapId
        
        -- Always clear caches on map enter to prevent stale handles after a save/load or reload
        currentMap, trail = nil, {}
        cachedKid, cachedChar = nil, nil

        if not (game and FOLLOWER_MAPS[mapId] and stage() == 4
            and hasCharmander(game)) then
            return
        end

        -- The map script owns visibility; this keeps the story NPC present
        -- while following and lets its normal talk entry remain available.
        -- Prevent infinite recursion: toggleObject triggers setMap which triggers map.entered
        local save = game.save
        local toggles = save and save.objectToggles and save.objectToggles[mapId]
        if not (toggles and toggles[KID_NAME] == true) then
            mod.world:toggleObject(mapId, KID_NAME, true)
        end
        -- Wait for the map script's show_object and the first committed step.
        -- Spawning during map.entered is a transitional-state hazard.
    end)

    -- Per-frame follower drive.  Uses the engine's input.step hook instead of
    -- wrapping OverworldController.update so Wilds of Kanto's reinstall --
    -- which unconditionally restores the engine functions to their vanilla
    -- originals (restoreOverworldUpdateWrap) -- can never orphan this logic.
    -- Hooks chain by owner and are torn down with the mod on reload/unload.
    mod.hooks:wrap("input.step", function(next_, game, dt)
        next_(game, dt)

        local ow = game and game.overworld
        local mapId = ow and ow.map and ow.map.id
        if not (game and mapId and FOLLOWER_MAPS[mapId]
            and stage() == 4 and hasCharmander(game)) then return end
        if not (ow.isOverworld and ow.player) then return end
        if ow.runner and ow.runner:isRunning() then return end

        local p = ow.player
        local destX = p.targetX or p.cellX
        local destY = p.targetY or p.cellY

        if currentMap ~= mapId or not trail or #trail == 0 then
            syncFollowers(game, mapId)
            return
        end

        local currentTarget = trail[#trail]
        if destX ~= currentTarget.x or destY ~= currentTarget.y then
            table.insert(trail, { x = destX, y = destY })
            while #trail > 12 do table.remove(trail, 1) end
        end

        local kid = cachedKid or mod.world:npc(mapId, KID_NAME)
        local char = cachedChar or mod.world:npc(mapId, CHAR_NAME)

        -- If Wilds of Kanto has a follower, push our followers back by 1 so they trail behind it
        local offsetChar = wildsOwnsPokemonFollower(game) and 2 or 1
        local offsetKid = offsetChar + 1

        moveToward(char, targetAt(offsetChar), ow)
        moveToward(kid, targetAt(offsetKid), ow)
    end)
end
