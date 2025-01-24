AddCSLuaFile()

if SERVER or not gwater2 then return end

-- cookie.Delete("gw2_online_presets_token")

local existing_pps = {}

local styling = include("menu/gwater2_styling.lua")
local _util = include("menu/gwater2_util.lua")

local function button_paint(w, h, self)
    if self:IsHovered() and not self.washovered then
        self.washovered = true
        _util.emit_sound("rollover")
    elseif not self:IsHovered() and self.washovered then
        self.washovered = false
    end
    if self:IsHovered() and not self:IsDown() then
        self:SetColor(Color(0, 127, 255, 255))
    elseif self:IsDown() then
        self:SetColor(Color(63, 190, 255, 255))
    else
        self:SetColor(Color(255, 255, 255))
    end
    styling.draw_main_background(0, 0, w, h)
end

local function preset_panel(tab, data, likes, dislikes, featured)
    
end

local function loadpresets(tab)
    HTTP({
        method = "POST",
        url = "http://www.jthings.xyz/gw2-onlinepresets/gmod/oauth2/verify",
        parameters = {
            sid = LocalPlayer():SteamID64(),
            code = code
        },
        failed = function(reason)
            ErrorNoHaltWithStack(reason)
        end,
        success = function(code, body, headers)
            if code ~= 200 then
                ErrorNoHaltWithStack(body)
                return
            end
            cookie.Set("gw2_online_presets_token", body)
            for i, v in pairs(unloggedinpanels) do
                v:Remove()
            end
            generate_non_login_tab(tab)
        end
    })
end

local function hastoken()
    return cookie.GetString("gw2_online_presets_token", NULL) ~= NULL
end

local function gettoken()
    return cookie.GetString("gw2_online_presets_token", NULL)
end

local function generate_non_login_tab(tab)
    if !tab:IsValid() then return end
    local refresh = tab:Add("DButton")
    refresh:SetText("Refresh")
    refresh:SizeToContents()
    refresh:SetWide(65)
    refresh:SetSize(refresh:GetWide() + 5, refresh:GetTall() + 5)
    refresh:SetImage("icon16/arrow_refresh.png")
    function refresh:AnimationThink()
        self:SetPos(tab:GetWide() - self:GetWide() - 15, 15)
    end
    function refresh:Paint(w, h)
        button_paint(w, h, self)
    end
end

local function login(code, tab, unloggedinpanels)
    HTTP({
        method = "POST",
        url = "http://www.jthings.xyz/gw2-onlinepresets/gmod/oauth2/verify",
        parameters = {
            sid = LocalPlayer():SteamID64(),
            code = code
        },
        failed = function(reason)
            ErrorNoHaltWithStack(reason)
        end,
        success = function(code, body, headers)
            if code ~= 200 then
                ErrorNoHaltWithStack(body)
                return
            end
            cookie.Set("gw2_online_presets_token", body)
            for i, v in pairs(unloggedinpanels) do
                v:Remove()
            end
            generate_non_login_tab(tab)
        end
    })
end

local function tab(tabs, params)
    local tab = vgui.Create("DPanel", tabs)
	tab.Paint = nil
	tabs:AddSheet("Online Presets", tab, "icon16/basket.png").Tab.realname = "op" -- _util.get_localised("Presets.title")
	tab = tab:Add("DScrollPanel")
	tab:Dock(FILL)
	--tab.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255)) end
	styling.define_scrollbar(tab:GetVBar())

	-- local _ = tab:Add("DLabel") _:SetText(" ") _:SetFont("GWater2Title") _:Dock(TOP) _:SizeToContents()
	-- function _:Paint(w, h)
	-- 	draw.DrawText("Online Presets", "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	-- 	draw.DrawText("Online Presets", "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	-- end

    if !hastoken() then
        local unloggedinpanels = {}

        local title = tab:Add("DLabel") title:SetText("Welcome to Online Presets! ") title:SetFont("GWater2Title") title:SizeToContents() title:SetText("")
        unloggedinpanels[#unloggedinpanels + 1] = title
	    function title:Paint(w, h)
            title:SetPos(tab:GetWide() / 2 - title:GetWide() / 2, tab:GetTall() / 4 - title:GetTall())
	    	draw.DrawText("Welcome to Online Presets!", "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	    	draw.DrawText("Welcome to Online Presets!", "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	    end

        local expl = tab:Add("DLabel") expl:SetText("Online Presets!!!!\nPretty self-explanatory: They are Online Presets\nJust upload it for everyone to see!\n\nPlop in the code you got from the site below and hit enter:") expl:SetFont("GWater2Text") expl:SetContentAlignment(8) expl:SizeToContents() expl:SetText("")
        unloggedinpanels[#unloggedinpanels + 1] = expl
	    function expl:Paint(w, h)
            expl:SetPos(tab:GetWide() / 2 - expl:GetWide() / 2, tab:GetTall() / 4 + expl:GetTall() / 5)
	    	draw.DrawText("Online Presets!!!!\nPretty self-explanatory: They are Online Presets\nJust upload it for everyone to see!\n\nPlop in the code you got from the site below and hit enter:", "GWater2Text", expl:GetWide() / 2, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER) -- _util.get_localised("Presets.titletext")
	    end

        local copylog = tab:Add("DButton") copylog:SetText("Copy Login Link") copylog:SizeToContents()
        copylog:SetSize(copylog:GetWide() + 5, copylog:GetTall() + 5)
        unloggedinpanels[#unloggedinpanels + 1] = copylog
	    function copylog:AnimationThink()
            copylog:SetPos(tab:GetWide() / 2 - copylog:GetWide() / 2, tab:GetTall() / 2.36 + copylog:GetTall() / 2)
	    end
        function copylog:Paint(w, h) 
            button_paint(w, h, copylog)
        end
        function copylog:DoClick()
            SetClipboardText("https://discord.com/oauth2/authorize?client_id=1310620734812327936&response_type=code&redirect_uri=http%3A%2F%2Fwww.jthings.xyz%2Fgw2-onlinepresets%2Flogin&scope=identify")
            copylog:SetText("Copied!")
            timer.Simple(0.5, function()
                copylog:SetText("Copy Login Link")
            end)
        end

        


        local codeentry = tab:Add("DTextEntry")
        codeentry:SetFont("GWater2Text")
        codeentry:SetValue("")

        unloggedinpanels[#unloggedinpanels + 1] = codeentry

        function codeentry:Paint(w, h)
            styling.draw_main_background(0, 0, w, h)

            local text = self:GetText()
            local real = self:GetText()

            local textcolor = Color(255, 255, 255)

            if text ~= real then self:SetText(text) self:InvalidateLayout(true) end
		    if not self:HasFocus() then
                textcolor.r = textcolor.r - 32
                textcolor.g = textcolor.g - 32
                textcolor.b = textcolor.b - 32
            end
            self:DrawTextEntryText(textcolor, self:GetHighlightColor(), self:GetCursorColor())
		    if text ~= real then self:SetText(real) end
        end

        function codeentry:AnimationThink()
            codeentry:SetWide(tab:GetWide())
            codeentry:SetPos(tab:GetWide() / 2 - codeentry:GetWide() / 2, tab:GetTall() / 1.85 + codeentry:GetTall() / 2)
	    end

        function codeentry:OnEnter(text)
            login(text, tab, unloggedinpanels)
        end
    else
        generate_non_login_tab(tab)
    end
end

return tab