AddCSLuaFile()

if SERVER then return end

local _util = include("menu/gwater2_util.lua")
local styling = include("menu/gwater2_styling.lua")

-- reused code, hope thats fine?
local lang = GetConVar("gmod_language"):GetString()
local function load_language_addon_specific(lang, locale_folder, locale_prefix)
	local strings = file.Read(locale_folder .. locale_prefix .. lang .. ".txt", "THIRDPARTY")
	if not strings then return false end
	--[[
	matches strings like this:
		"KEY"=[[
		VALUE
		]]
	--]]
	for k, v in string.gmatch(strings, '"(.-)"=%[%[%s*(.-)%s*%]%]') do 
		language.Add(k, v) 
	end
	return true
end

local function p(self, ...) end -- short for placeholder, dont know if it can be inefficient

local private = {}
private.addons = {}
private.tabs = {}

local public = {}
local hooks = {
    "MenuStartLoad",
    "MenuOpen",
    "MenuClose",
    "TabChanged"
}

public.util = _util
public.styling = include("menu/gwater2_styling.lua")
public.available_hooks = hooks
public.addon_infos = {}
public.parameters = {}


local create_slider
local create_check
local create_color
do -- parameter creations, copied and modified to work better in a addon context. wrapped in a do end statement for code readability reasons
    local function reset(param, slider)
		slider:SetValue(param.default)	
        param.value = param.default
		_util.emit_sound("reset")
    end

    local function is_hovered_any(panel)
        if panel:IsHovered() then return true end
        for k,v in pairs(panel:GetChildren()) do
            if v.IsEditing and v:IsEditing() then
                return true
            end
            if v.IsDown and v:IsDown() then
                return true
            end
            if is_hovered_any(v) then
                return true
            end
        end
        return false
    end
    public.util.is_hovered_any = is_hovered_any

    local function panel_paint(self, w, h)
        if gwater2.cursor_busy ~= self and gwater2.cursor_busy ~= nil and IsValid(gwater2.cursor_busy) then return end
        local hovered = is_hovered_any(self)
        local tab = self.tab
        local label = self.label
        if hovered and not self.washovered then
            self.default_help_text = tab.help_text:GetText()
            self.washovered = true
            gwater2.cursor_busy = self
            tab.help_text:SetText(_util.get_localised(self.parameter_locale_name..".desc"))
            _util.emit_sound("rollover")
            label:SetColor(label.fancycolor_hovered or Color(187, 245, 255))
        elseif not hovered and self.washovered then
            self.washovered = false
            gwater2.cursor_busy = nil
            if tab.help_text:GetText() == _util.get_localised(self.parameter_locale_name..".desc") then
                tab.help_text:SetText(self.default_help_text)
            end
            label:SetColor(label.fancycolor or Color(255, 255, 255))
        end
    end

    create_slider = function(sliderp, tab)
        local panel = tab:Add("DPanel")
        panel.tab = tab
        panel.parameter_locale_name = sliderp.name
        panel.Paint = nil
        panel.param = sliderp
        
        local slider = panel:Add("DNumSlider")
        function slider.Scratch:GetTextValue()
            local decimals = self:GetDecimals()
            if decimals == 0 then
                return string.format("%i", self:GetFloatValue())
            end
            if decimals < 0 then
                return string.format("%i", math.floor(self:GetFloatValue() / 10^decimals) * 10^decimals)
            end
    
            return string.format("%." .. decimals .. "f", self:GetFloatValue())
        end
        slider:SetDecimals(sliderp.decimals)
        panel.slider = slider
        slider:SetMinMax(sliderp.min, sliderp.max)
        slider:SetValue(sliderp.default)
        slider:SetText("")
    
        local label = slider.Label
        panel.label = label
        label:SetFont("GWater2Text")
        label:SetText(_util.get_localised(sliderp.name))
        label:SizeToContents()
        label:SetWidth(label:GetSize() * 1.1)
        label:SetColor(Color(255, 255, 255))
    
        function slider:OnValueChanged(val)
            sliderp.value = math.Round(val, parameter.decimals)
            sliderp:OnChange(panel)
        end
    
        local button = panel:Add("DImageButton")
        panel.button = button
        button:Dock(RIGHT)
        button:SetImage("icon16/arrow_refresh.png")
        button:SizeToContents()
        button:SetKeepAspect(true)
        button:SetStretchToFit(false)
        button.Paint = nil
    
        slider:Dock(FILL)
        slider:DockMargin(0, 0, 0, 0)
    
        -- not sure why this is required. for some reason just makes it work
        slider.PerformLayout = empty
        
        slider.TextArea:SizeToContents()
    
        function button:DoClick()
            reset(sliderp, slider)
            sliderp:OnReset(panel)
        end
        function slider:OnValueChanged(val)
            sliderp.value = math.Round(val, sliderp.decimals)
            sliderp:OnChange(panel)
        end
        panel.Paint = panel_paint
    
        function slider.Slider.Knob:Paint(w, h)
            surface.SetDrawColor(0, 0, 0, 125)
            surface.DrawRect(w/4, 0, w/2, h)
        
            if panel.washovered then
                surface.SetDrawColor(panel.label.fancycolor_hovered or Color(187, 245, 255))
            else
                surface.SetDrawColor(panel.label.fancycolor or Color(255, 255, 255))
            end
            surface.DrawOutlinedRect(w/4, 0, w/2, h)
        end
    
        panel:SetTall(panel:GetTall()+2)
        sliderp:Init(panel)
        return panel
    end

    make_parameter_check = function(checkp, tab)
        local panel = tab:Add("DPanel")
        panel.tab = tab
        panel.Paint = nil
        panel:Dock(TOP)
        local label = panel:Add("DLabel")
        panel.label = label
        label:SetText(get_localised(checkp.name))
        label:SetColor(Color(255, 255, 255))
        label:SetFont("GWater2Text")
        label:Dock(LEFT)
        label:SetMouseInputEnabled(true)
        label:SizeToContents()
    
        local check = panel:Add("DCheckBoxLabel")
        panel.check = check
        check:Dock(FILL)
        check:DockMargin(5, 0, 5, 0)
        check:SetText("")
        check:SetChecked(check.default)
        local button = panel:Add("DImageButton")
        panel.button = button
        button:Dock(RIGHT)
        button:SetImage("icon16/arrow_refresh.png")
        button:SizeToContents()
        button:SetKeepAspect(true)
        button:SetStretchToFit(false)
        button.Paint = nil
        function button:DoClick()
            check:SetChecked(check.default)
            checkp:OnReset(panel)
        end
        function check:OnChange(val)
            checkp.value = val
            checkp:OnChange(panel)
        end
        panel.Paint = panel_paint
        function check.Button:Paint(w, h)
            surface.SetDrawColor(0, 0, 0, 125)
            surface.DrawRect(0, 0, w, h)
    
            if panel.washovered then
                surface.SetDrawColor(panel.label.fancycolor_hovered or Color(187, 245, 255))
            else
                surface.SetDrawColor(panel.label.fancycolor or Color(255, 255, 255))
            end
        
            if self:GetChecked() then
                surface.DrawRect(3, 3, w-6, h-6)
            end
    
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    
        if not gwater2.parameters[parameter_id] then
            gwater2.parameters[parameter_id] = check:GetChecked()
            gwater2.defaults[parameter_id] = check:GetChecked()
        end
    
        panel:SetTall(panel:GetTall()+5)
    
        return panel
    end
end



function private.GenerateTabs(where, tabs)
    for i, v in pairs(private.tabs) do
        if v.order ~= where then continue end
        local tab = vgui.Create("DPanel", tabs)
        tabs:AddSheet(_util.get_localised(v.name), tab, v.icon).Tab.realname = v.name
        tab.Paint = nil
        tab = tab:Add("DScrollPanel")
        tab.help_text = tabs.help_text
        tab:Dock(FILL)
        styling.define_scrollbar(tab:GetVBar())

        v.func(tab, gwater2.parameters)
    end
end

function public.parameters.slider(name, min, max, decimals, default)
    local param = {}
    param.name = name
    param.min = min
    param.max = max
    param.decimals = decimals
    param.default = default
    param.value = default
    param.text = {}
    local txcol = param.text
    txcol.default = nil 
    txcol.hovered = nil

    param.Init = p
    param.OnChange = p
    param.OnReset = p
    function param:Generate(tab)
        return create_slider(self, tab)
    end
    return param
end

function public.parameters.check(name, default)
    local param = {}
    param.name = name
    param.default = default
    param.value = default

    param.Init = p
    param.OnChange = p
    param.OnReset = p
    function param:Generate(tab)
        return create_check(self, tab)
    end
    return param
end

function public.definition(icon, name, description, locale_folder, locale_prefix)
    if locale_folder then
        load_language_addon_specific("en", locale_folder, locale_prefix) -- fallback, but again
        load_language_addon_specific(lang, locale_folder, locale_prefix)
    end
    local def = {}
    def.info = {
        icon = icon,
        name = name,
        description = description
    }
    def.mounted = false
    def.parameters = {}
    def.id = nil
    public.addon_infos[#public.addon_infos + 1] = def.info



    def.hooks = {}
    local h = def.hooks

    function def:AddParameter(param)
        self.parameters[#self.parameters + 1] = param
    end

    function def:CreateTab(order, icon, name, func)
        local tabo = {}
        tabo.name = name
        tabo.icon = icon
        tabo.order = order
        tabo.func = func
        tabo.addon = self
        private.tabs[#private.tabs + 1] = tabo
        return tabo
    end

    function def:Mount()
        if self.mounted then return end
        self.mounted = true
        self.id = #private.addons + 1
        private.addons[self.id] = self
        print(string.format("[GWATER2] Addon %s mounted successfully!", self.info.name))
    end

    function def:Demount()
        if !self.mounted then return end
        self.mounted = false
        table.remove(private.addons, self.id)
        self.id = nil
        print(string.format("[GWATER2] Addon %s demounted successfully!", self.info.name))
    end
    return def
end



local addons = {
    public = public,
    private = private
}

return addons