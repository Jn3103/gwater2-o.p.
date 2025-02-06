AddCSLuaFile()

if SERVER then return end

local default = {
    ["CUST/Master Reset"]=true,
    ["CUST/Author"]=author
}

local function SimpleMain(out, data, prefix)
    for dname, data in pairs(data) do
        if dname == "Prefix" or dname == "Recursive" then continue end
        local name = string.match(dname, "%d+-(.+)")
        local id = name:lower():Replace(" ", "_")
        local param = gwater2.parameters[id]
        if param ~= gwater2.defaults[id] then
            local prefixed = prefix .. "/" .. name
            if IsColor(param) then
                out[prefixed] = {param.r, param.g, param.b, param.a}
            else
                out[prefixed] = param
            end
        end
    end
    return out
end

local function AdvancedMain(out, data, prefix, filter)
    for dname, data in pairs(data) do
        if dname == "Prefix" or dname == "Recursive" then continue end
        local name = string.match(dname, "%d+-(.+)")
        local id = name:lower():Replace(" ", "_")
        local param = gwater2.parameters[id]
        if filter[prefix][name] then
            local prefixed = prefix .. "/" .. name
            if IsColor(param) then
                out[prefixed] = {param.r, param.g, param.b, param.a}
            else
                out[prefixed] = param
            end
        end
    end
    return out
end

local function AllMain(out, data, prefix, value)
    for dname, data in pairs(data) do
        if dname == "Prefix" or dname == "Recursive" then continue end
        local name = string.match(dname, "%d+-(.+)")
        out[name] = value
    end
end

local function main(addons)
    local api = {}

    function api.Simple(name, author)
        local addonsp = {}
        for i, v in pairs(addons.private.addons) do
            addonsp[i] = v.info.name
        end
        local preset = {
            ["CUST/Addons"]=addonsp;
            ["CUST/Master Reset"]=true,
            ["CUST/Author"]=author or LocalPlayer():GetName()
        }
        for cat, data in pairs(gwater2.__PARAMS__) do
            if !data.Prefix then continue end
            local prefix = data.Prefix

            -- idfk and idgaf
            if data.Recursive then
                for name, ddata in pairs(data) do
                    if name == "Prefix" or name == "Recursive" then continue end
                    SimpleMain(preset, ddata, prefix)
                end
            else
                SimpleMain(preset, data, prefix)
            end
        end
        return preset
    end

    function api.Advanced(name, author, reset, filter)
        local addonsp = {}
        for i, v in pairs(addons.private.addons) do
            addonsp[i] = v.info.name
        end
        local preset = {
            ["CUST/Addons"]=addonsp,
            ["CUST/Master Reset"]=reset or false,
            ["CUST/Author"]=author or LocalPlayer():GetName()
        }
        for cat, data in pairs(gwater2.__PARAMS__) do
            if !data.Prefix then continue end
            local prefix = data.Prefix

            -- idfk and idgaf
            if data.Recursive then
                for name, ddata in pairs(data) do
                    if name == "Prefix" or name == "Recursive" then continue end
                    AdvancedMain(preset, ddata, prefix, filter)
                end
            else
                AdvancedMain(preset, data, prefix, filter)
            end
        end
        return preset
    end

    function api.All()
        local out = {}
        for cat, data in pairs(gwater2.__PARAMS__) do
            if !data.Prefix then continue end
            local prefix = data.Prefix
            local prdata = {}
            out[prefix] = prdata

            -- idfk and idgaf
            if data.Recursive then
                for name, ddata in pairs(data) do
                    if name == "Prefix" or name == "Recursive" then continue end
                    AllMain(prdata, ddata, prefix, true)
                end
            else
                AllMain(prdata, data, prefix, true)
            end
        end
        for i, addon in pairs(addons.private.addons) do
            if table.IsEmpty(addon.parameters) then continue end
            local ptable = {}
            out[addon.prefix] = ptable
            for id, param in pairs(addon.parameters) do
                ptable[id] = true
            end
        end
        return out
    end

    function api.Categorys()
        local out = {}
        for cat, data in pairs(gwater2.__PARAMS__) do
            if !data.Prefix then continue end
            out[data.Prefix] = {}
        end
        for i, addon in pairs(addons.private.addons) do
            if table.Empty(addon.parameters) then continue end
            out[addon.prefix] = {}
        end
        return out
    end

    function api.Load(preset)
        if preset["CUST/Master Reset"] then
            for name, _ in pairs(gwater2.parameters) do
                gwater2.ChangeParameter(name, gwater2.defaults[name], true)
                gwater2.addons.util.set_gwater_parameter(name, gwater2.defaults[name], true)
            end
        end

        for param, value in pairs(preset) do
            local cat = param:Split("/")[1]
            if !(cat == "PHYS" or cat == "INTC" or cat == "VISL") then continue end
            local name = param:Split("/")[2]
            local id = name:lower():Replace(" ", "_")
            if IsColor(gwater2.defaults[id]) then
                gwater2.ChangeParameter(id, Color(unpack(value)), true)
                gwater2.addons.util.set_gwater_parameter(id, Color(unpack(value)), true)
            else
                gwater2.ChangeParameter(id, value, true)
                gwater2.addons.util.set_gwater_parameter(id, value, true)
            end
        end
    end

    function api.Check(preset)
        if !preset["CUST/Addons"] then return true end
        -- TODO: terrifying code (atleast i think so)
        for i, v in preset["CUST/Addons"] do
            local s = false
            for j, w in addons.private.addons do
                if w.info.name == v then
                    s = true
                    break
                end
            end
            if !s then return false end
        end
    end

    return api
end

return main