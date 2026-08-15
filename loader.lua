local SOURCE_URL = "https://raw.githubusercontent.com/donniehuamani-max/Ragnarok-Hub/main/main.lua"

local function ResolveCompiler()
    if type(loadstring) == "function" then
        return loadstring
    end
    if type(load) == "function" then
        return load
    end
    return nil
end

local function FetchSource()
    local success, result = pcall(function()
        if type(game.HttpGet) == "function" then
            return game:HttpGet(SOURCE_URL)
        end
        local service = game:GetService("HttpService")
        return service:GetAsync(SOURCE_URL)
    end)
    if not success then
        return nil, tostring(result)
    end
    if type(result) ~= "string" or #result == 0 then
        return nil, "empty-source"
    end
    return result
end

local function Execute()
    local compiler = ResolveCompiler()
    if not compiler then
        error("Ragnarok executor loader: loadstring/load unavailable")
    end
    local source, fetchError = FetchSource()
    if not source then
        error("Ragnarok executor loader: source fetch failed: " .. tostring(fetchError))
    end
    local compiled, compileError = compiler(source)
    if type(compiled) ~= "function" then
        error("Ragnarok executor loader: compilation failed: " .. tostring(compileError))
    end
    local success, result = pcall(compiled)
    if not success then
        error("Ragnarok executor loader: execution failed: " .. tostring(result))
    end
    return result
end

return Execute()
