AddCSLuaFile()

if SERVER or not gwater2 then return end

local styling = include("menu/gwater2_styling.lua")
local _util = include("menu/gwater2_util.lua")

local function tab(tabs, params)
    local tab = vgui.Create("DPanel", tabs)
	tab.Paint = nil
	tabs:AddSheet("Online Presets", tab, "icon16/basket.png").Tab.realname = "op" -- _util.get_localised("Presets.title")
	tab = tab:Add("DScrollPanel")
	tab:Dock(FILL)
	--tab.Paint = function(s, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255)) end
	styling.define_scrollbar(tab:GetVBar())

	local _ = tab:Add("DLabel") _:SetText(" ") _:SetFont("GWater2Title") _:Dock(TOP) _:SizeToContents()
	function _:Paint(w, h)
		draw.DrawText("Online Presets", "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
		draw.DrawText("Online Presets", "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT) -- _util.get_localised("Presets.titletext")
	end
end

return tab