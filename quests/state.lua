return function(mod)
    -- =========================================================================
    -- QuestConnector: registro central de estado de misiones.
    --
    -- NO guarda estado por sí mismo. Cada quest sigue escribiendo en mod.save
    -- con sus propias keys; aquí solo se REGISTRA una lectura (stage/completed)
    -- para que cualquier quest u orquestador futuro pueda preguntar:
    --
    --     mod.quests.registered("squirtle")  -> true si existe el contrato
    --     mod.quests.stage("squirtle")        -> número de etapa (o nil)
    --     mod.quests.completed("squirtle")    -> true/false
    --     mod.quests.active("squirtle")       -> true si ya arrancó (stage > 0)
    --
    -- REGLA DE ORO: una quest NUNCA asume que otra existe. Si necesita el
    -- estado de otra, pregunta por mod.quests y comprueba registered() antes
    -- de actuar. Ver INDEX_DE_OBJETOS.md para los índices por mapa.
    -- =========================================================================

    local registry = {}

    local function isRegistered(id)
        return registry[id] ~= nil
    end

    local api = {
        register = function(id, contract)
            if type(id) ~= "string" or type(contract) ~= "table" then
                error("mod.quests.register: se espera (string id, tabla contrato)", 2)
            end
            if isRegistered(id) then
                error("mod.quests.register: la quest '" .. id .. "' ya está registrada", 2)
            end
            if type(contract.stage) ~= "function" then
                error("mod.quests.register: la quest '" .. id .. "' debe exponer stage()", 2)
            end
            registry[id] = contract
            if mod.log then
                mod.log:info(("    ok: quest contract registered: %s"):format(id))
            end
        end,

        registered = isRegistered,

        stage = function(id)
            local q = registry[id]
            if not q then return nil end
            local s = q.stage()
            return s and tonumber(s) or nil
        end,

        completed = function(id)
            local q = registry[id]
            if not q or type(q.completed) ~= "function" then return false end
            return q.completed() and true or false
        end,

        active = function(id)
            local s = api.stage(id)
            return s ~= nil and s > 0
        end,
    }

    mod.quests = api
    mod.log:info("==> quest system: QuestConnector instalado (mod.quests)")
end
