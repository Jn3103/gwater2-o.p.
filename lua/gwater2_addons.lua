AddCSLuaFile()

if SERVER then return end

local _util = include("menu/gwater2_util.lua")
local styling = include("menu/gwater2_styling.lua")

local private = {}
local public = {}
local hooks = {
    "MenuStartLoad",
    "MenuOpen",
    "MenuClose",
    "InitParams",
    "TabChanged"
}

do -- basic tables, functions and more tables
    private.addons = {}
    private.tabs = {}
    public.util = _util
    function public.util.create_category(tab, txt)
        local pan = tab:Add("Panel")
        pan:Dock(TOP)
        pan.help_text = tab.help_text
        function pan:Paint(w, h) styling.draw_main_background(0, 0, w, h) end
        pan.label = _util.make_title_label(pan, txt)
        function pan:Finish()
            local ttall = self:GetTall()+5
            for _, i in pairs(self:GetChildren()) do
                ttall = ttall + i:GetTall()
            end
        
            ttall = ttall - 20
            self:SetTall(ttall)
            self:Dock(TOP)
            self:InvalidateChildren()
            self:DockMargin(5, 5, 5, 5)
            self:DockPadding(5, 5, 5, 5)
        end
        return pan
    end
    public.styling = styling
    public.available_hooks = hooks
    public.parameters = {}
    public.locale = {}
end

local ccall
do -- locale and ccall (checked call, checks if func exists before calling it)
    -- reused code
    local lang = GetConVar("gmod_language"):GetString()
    local function load_language(lang, locale_prefix, ftype)
    	local strings = file.Read(locale_prefix .. lang .. ftype, "THIRDPARTY")
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

    function public.locale:Load(locale_prefix, ftype)
        if !load_language(lang, locale_prefix, "." .. (ftype or "txt")) then
            load_language("en", locale_prefix, "." .. (ftype or "txt"))
        end
    end

    ccall = function(func, ...) -- run a function if it exists, made to replace p
        if !func then return end
        func(...)
    end
end

local create_slider
local create_check
local create_color
do -- parameter creations, copied and modified to work better in a addon context. wrapped in a do end statement for code collapsability reasons
    local function emit_overrides(name, param)
        if param.sounds.mute[name] then
            return
        end
        if param.sounds.overrides[name] then 
            surface.PlaySound(param.sounds.overrides[name])
            return
        end
        _util.emit_sound(name)
    end

    local function reset(param)
        param:Set(param.default)
		emit_overrides("reset", param)
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
            emit_overrides("rollover", self.param)
            label:SetColor(self.param.text.hovered or Color(187, 245, 255))
        elseif not hovered and self.washovered then
            self.washovered = false
            gwater2.cursor_busy = nil
            if tab.help_text:GetText() == _util.get_localised(self.parameter_locale_name..".desc") then
                tab.help_text:SetText(self.default_help_text)
            end
            label:SetColor(self.param.text.default or Color(255, 255, 255))
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
        slider:SetValue(sliderp.value)
        slider:SetText("")
    
        local label = slider.Label
        panel.label = label
        label:SetFont("GWater2Text")
        label:SetText(_util.get_localised(sliderp.name))
        label:SizeToContents()
        label:SetWidth(label:GetSize() * 1.1)
        label:SetColor(Color(255, 255, 255))
    
        function slider:OnValueChanged(val)
            if self.block then return end
            sliderp.value = math.Round(val, sliderp.decimals)
            ccall(sliderp.OnChange, sliderp, panel)
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
            ccall(sliderp.OnReset, sliderp, panel)
        end
        panel.Paint = panel_paint
    
        function slider.Slider.Knob:Paint(w, h)
            surface.SetDrawColor(0, 0, 0, 125)
            surface.DrawRect(w/4, 0, w/2, h)
        
            if panel.washovered then
                surface.SetDrawColor(sliderp.text.hovered or Color(187, 245, 255))
            else
                surface.SetDrawColor(sliderp.text.default or Color(255, 255, 255))
            end
            surface.DrawOutlinedRect(w/4, 0, w/2, h)
        end
    
        panel:SetTall(panel:GetTall()+2)
        function panel:Think()
            ccall(sliderp.OnThink, sliderp, panel)
        end
        ccall(sliderp.Init, sliderp, panel)
        return panel
    end

    create_check = function(checkp, tab)
        local panel = tab:Add("DPanel")
        panel.tab = tab
        panel.parameter_locale_name = checkp.name
        panel.Paint = nil
        panel.param = checkp
        local label = panel:Add("DLabel")
        panel.label = label
        label:SetText(_util.get_localised(checkp.name))
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
        check:SetChecked(checkp.value)
        local button = panel:Add("DImageButton")
        panel.button = button
        button:Dock(RIGHT)
        button:SetImage("icon16/arrow_refresh.png")
        button:SizeToContents()
        button:SetKeepAspect(true)
        button:SetStretchToFit(false)
        button.Paint = nil
        function button:DoClick()
            check:SetChecked(checkp.default)
            checkp.value = checkp.default
            emit_overrides("reset", checkp)
            ccall(checkp.OnReset, checkp, panel)
        end
        function check:OnChange(val)
            if self.block then return end
            checkp.value = val
            emit_overrides("toggle", checkp)
            ccall(checkp.OnChange, checkp, panel)
        end
        panel.Paint = panel_paint
        function check.Button:Paint(w, h)
            surface.SetDrawColor(0, 0, 0, 125)
            surface.DrawRect(0, 0, w, h)
    
            if panel.washovered then
                surface.SetDrawColor(checkp.text.hovered or Color(187, 245, 255))
            else
                surface.SetDrawColor(checkp.text.default or Color(255, 255, 255))
            end
        
            if self:GetChecked() then
                surface.DrawRect(3, 3, w-6, h-6)
            end
    
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    
        panel:SetTall(panel:GetTall()+5)

        function panel:Think()
            ccall(checkp.OnThink, checkp, self)
        end

        return panel
    end

    local function COLOR_FixHex(hexstring, nooriginal)
        local original = hexstring
        if hexstring[1] == "#" then hexstring = string.sub(hexstring, 2) end
        if #hexstring ~= 6 and #hexstring ~= 8 then
            hexstring = hexstring..string.rep("0", 6-#hexstring)
            if #hexstring > 6 then
                hexstring = hexstring..string.rep("0", 8-#hexstring)
            end
        end
        if not nooriginal and original[1] == "#" then hexstring = "#"..original end
        return hexstring
    end
    local function COLOR_ToHex(self)
        return (self.a == 255 and string.format("%02X%02X%02X", self.r, self.g, self.b) or
                string.format("%02X%02X%02X%02X", self.r, self.g, self.b, self.a))
    end
    local function COLOR_FromHex(hexstring)
        hexstring = COLOR_FixHex(hexstring, true)
        local r, g, b, a = tonumber(string.sub(hexstring, 1, 2), 16) or 0,
                           tonumber(string.sub(hexstring, 3, 4), 16) or 0,
                           tonumber(string.sub(hexstring, 5, 6), 16) or 0, 255
        if #hexstring == 8 then
            a = tonumber(string.sub(hexstring, 7, 8), 16) or 255
        end
        return Color(math.Round(r), math.Round(g), math.Round(b), math.Round(a))
    end

    public.util.FixHex = COLOR_FixHex
    public.util.ToHex = COLOR_ToHex
    public.util.FromHex = COLOR_FromHex

    create_color = function(colorp, tab)
        local panel = tab:Add("DPanel")
        panel.tab = tab
        panel.parameter_locale_name = colorp.name
        panel.Paint = nil
        panel.param = colorp
        panel:SetTall(150)
    
        local label = panel:Add("DLabel")
        panel.label = label
        label:SetText(_util.get_localised(colorp.name))
        label:SetColor(Color(255, 255, 255))
        label:SetFont("GWater2Text")
        label:Dock(LEFT)
        label:SetMouseInputEnabled(true)
        label:SizeToContents()
    
        local mixer = panel:Add("DColorMixer")
        panel.mixer = mixer
        mixer:Dock(FILL)
        mixer:DockPadding(5, 0, 5, 0)
        mixer:SetPalette(false)
        mixer:SetLabel()
        mixer:SetAlphaBar(true)
        mixer:SetWangs(true)
        mixer.Hex = mixer.WangsPanel:Add("DTextEntry")
        mixer.Hex:Dock(BOTTOM)
        mixer.Hex:SetFont("GWater2TextSmall")
        mixer.WangsPanel:SetWide(mixer.WangsPanel:GetWide() + 24)
        local draw = false
        function mixer.Hex:OnChange()
            if draw then return end
            local hex = self:GetValue()
            colorp:Set(COLOR_FromHex(hex))
        end
        function mixer.Hex:Paint(w, h)
            draw = true
            styling.draw_main_background(0, 0, w, h)
    
            local text = self:GetText()
            local real = self:GetText()
    
            local textcolor = Color(255, 255, 255)
    
            if text:Trim() == "" then
                text = "##"..COLOR_ToHex(mixer:GetColor())
                if not self:HasFocus() then
                    real = text
                    draw = false
                    self:SetValue(real)
                    draw = true
                else
                    textcolor = Color(127, 127, 127)
                end
            end
    
            if text ~= real then self:SetValue(text) self:InvalidateLayout(true) end
            if not self:HasFocus() then
                textcolor.r = textcolor.r - 32
                textcolor.g = textcolor.g - 32
                textcolor.b = textcolor.b - 32
            end
            self:DrawTextEntryText(textcolor, self:GetHighlightColor(), self:GetCursorColor())
            if text ~= real then self:SetValue(real) end
            draw = false
        end
    
        for _,wang in ipairs({mixer.txtR, mixer.txtG, mixer.txtB, mixer.txtA}) do
            wang:SetTextColor(Color(
                (_ == 1 or _ == 4) and 255 or 63,
                (_ == 2 or _ == 4) and 255 or 63,
                (_ == 3 or _ == 4) and 255 or 63
            ))
            function wang:Paint(w, h)
                styling.draw_main_background(0, 0, w, h)
                self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
            end
        end
        mixer:SetColor(colorp.value) 
    
        local button = panel:Add("DImageButton")
        panel.button = button
        button:Dock(RIGHT)
        button:SetImage("icon16/arrow_refresh.png")
        button:SizeToContents()
        button:SetKeepAspect(true)
        button:SetStretchToFit(false)
        button.Paint = nil
        function button:DoClick()
            emit_overrides("reset", colorp)
            colorp:Set(colorp.default)
            ccall(colorp.OnReset, colorp, panel)
        end
    
        panel:SizeToContents()
    
        -- TODO: find something to reset editing to false when user stops editing color
        function mixer:ValueChanged(val)
            if self.block then return end
            val = Color(val.r, val.g, val.b, val.a)

            self.Hex:SetValue("##"..COLOR_ToHex(val))
            colorp.value = val
            ccall(colorp.OnChange, colorp, panel)
        end
        panel.Paint = panel_paint
    
        panel:SetTall(panel:GetTall()+5)
    
        ccall(colorp.Init, colorp, panel)

        function panel:Think()
            ccall(colorp.OnThink, colorp, self)
        end

        return panel
    end
end

do -- parameter structs
    local function baseParameter(name, default, value)
        local param = {}
        param.name = name
        param.default = default
        param.value = value or default

        param.panel = nil

        -- text color
        param.text = {}
        local txcol = param.text
        txcol.default = nil 
        txcol.hovered = nil

        -- sounds
        param.sounds = {}
        local sounds = param.sounds
        sounds.mute = {
            rollover = false,
            reset = false
        }
        function sounds:MuteAll()
            for i, v in pairs(self.mute) do
                self.mute[i] = true
            end
        end
        function sounds:UnmuteAll()
            for i, v in pairs(self.mute) do
                self.mute[i] = false
            end
        end
        sounds.overrides = {
            rollover = nil,
            reset = nil
        }

        -- hooks
        param.Init = nil
        param.OnChange = nil
        param.OnReset = nil
        param.OnThink = nil
        return param
    end

    public.parameters.baseParameter = baseParameter

    function public.parameters.slider(name, min, max, default, decimals, value)
        local param = baseParameter(name, default, value)
        param.min = min
        param.max = max
        param.decimals = decimals

        function param:Generate(tab)
            self.panel = create_slider(self, tab)
            return self.panel
        end

        function param:Set(val)
            if self.panel then
                self.panel.slider:SetValue(val)
            end
            self.value = val
        end

        function param:Get()
            return self.value
        end
        return param
    end

    function public.parameters.color(name, default, value)
        local param = baseParameter(name, default, value)

        function param:Generate(tab)
            self.panel = create_color(self, tab)
            return self.panel
        end

        function param:Set(val)
            if self.panel then
                self.panel.mixer:SetColor(val)
            end
            self.value = val
        end

        function param:Get()
            return self.value
        end
        return param
    end

    function public.parameters.check(name, default, value)
        local param = baseParameter(name, default, value)

        local sounds = param.sounds
        sounds.mute.toggle = false 
        sounds.overrides.toggle = nil

        function param:Generate(tab)
            self.panel = create_check(self, tab)
            return self.panel
        end

        function param:Set(val)
            if self.panel then
                self.panel.check:SetValue(val)
            end
            self.value = val
        end

        function param:Get()
            return self.value
        end
        return param
    end
end

function public.definition(icon, name, description)
    local def = {}
    def.info = {
        icon = icon,
        name = name,
        description = description
    }
    def.mounted = false
    def.parameters = {}
    def.id = nil



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
    end

    function def:Mount()
        if self.mounted then return end
        self.mounted = true
        self.id = #private.addons + 1
        private.addons[self.id] = self
        print(string.format("[GWATER2] Addon %s mounted successfully!", self.info.name))
    end

    function def:IsMounted()
        return self.mounted
    end

    function def:Dismount()
        if !self.mounted then return end
        self.mounted = false
        table.remove(private.addons, self.id)
        self.id = nil
        print(string.format("[GWATER2] Addon %s dismounted successfully!", self.info.name))
    end
    return def
end

do -- private functions only shared with menu
    function private.GenerateTabs(where, tabs)
        for i, v in pairs(private.tabs) do
            if v.order ~= where or !v.addon:IsMounted() then continue end
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


    function private.CallOnAddons(funcname, ...)
        for i, v in pairs(private.addons) do
            ccall(v[funcname], v, ...)
        end
    end
end

local addons = {
    public = public,
    private = private
}

return addons