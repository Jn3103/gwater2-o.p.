AddCSLuaFile()

if SERVER or not gwater2 then return end

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

local function tab(tabs, params)
    local tab = vgui.Create("DPanel", tabs)
	tab.Paint = nil
	tabs:AddSheet("Online Presets", tab, "icon16/basket.png").Tab.realname = "op" -- _util.get_localised("Presets.title")
	tab = tab:Add("DScrollPanel")
	tab:Dock(FILL)
	--tab.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255)) end
	styling.define_scrollbar(tab:GetVBar())

	// local _ = tab:Add("DLabel") _:SetText(" ") _:SetFont("GWater2Title") _:Dock(TOP) _:SizeToContents()
	// function _:Paint(w, h)
	// 	draw.DrawText("Online Presets", "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	// 	draw.DrawText("Online Presets", "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	// end

    if cookie.GetString("OnlinePresetsToken") == nil then
        local unloggedinpanels = {}

        local title = tab:Add("DLabel") title:SetText("Welcome to Online Presets! ") title:SetFont("GWater2Title") title:SizeToContents() title:SetText("")
        unloggedinpanels[#unloggedinpanels + 1] = title
	    function title:Paint(w, h)
            title:SetPos(tab:GetWide() / 2 - title:GetWide() / 2, tab:GetTall() / 4 - title:GetTall())
	    	draw.DrawText("Welcome to Online Presets!", "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	    	draw.DrawText("Welcome to Online Presets!", "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	    end

        local expl = tab:Add("DLabel") expl:SetText("Online Presets!!!!\nPretty self-explanatory: They are Online Presets\nJust upload it for everyone to see!") expl:SetFont("GWater2Text") expl:SetContentAlignment(8) expl:SizeToContents() expl:SetText("")
        unloggedinpanels[#unloggedinpanels + 1] = expl
	    function expl:Paint(w, h)
            expl:SetPos(tab:GetWide() / 2 - expl:GetWide() / 2, tab:GetTall() / 4 + expl:GetTall() / 5)
	    	draw.DrawText("Online Presets!!!!\nPretty self-explanatory: They are Online Presets\nJust upload it for everyone to see!", "GWater2Text", expl:GetWide() / 2, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER) -- _util.get_localised("Presets.titletext")
	    end

        local copylog = tab:Add("DButton") copylog:SetText("Copy Login Link") copylog:SizeToContents()
        copylog:SetSize(copylog:GetWide() + 5, copylog:GetTall() + 5)
        unloggedinpanels[#unloggedinpanels + 1] = copylog
	    function copylog:AnimationThink()
            copylog:SetPos(tab:GetWide() / 2 - copylog:GetWide() / 2, tab:GetTall() / 2.3 + copylog:GetTall() / 2)
	    end
        function copylog:Paint(w, h) 
            button_paint(w, h, copylog)
        end
        function copylog:DoClick()
            SetClipboardText("https://discord.com/oauth2/authorize?client_id=1310620734812327936&response_type=code&redirect_uri=http%3A%2F%2Fgw2-online.com%2Flogin&scope=identify")
            copylog:SetText("Copied!")
        end
    end
end

return tab