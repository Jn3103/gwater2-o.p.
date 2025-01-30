-- miniature file responsible for gwater2hooker
if SERVER then return end

local hooks = {}

local function call()
    for i, v in pairs(hooks) do
        pcall(v)
    end
end

hook.Add("gw2_INTERNAL_call", "call", call)


gwater2hooker = {
    Hook = function(func, id)
        hooks[id] = func
    end
}