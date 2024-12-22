AddCSLuaFile()

if SERVER or not gwater2 then return end

gwater2.cursor_busy = nil

local localed_cache = {}
-- TODO: this is horrible.
local function get_localised(loc, a,b,c,d,e)
	a,b,c,d,e = a or "", b or "", c or "", d or "", e or ""
	if localed_cache[loc..a..b..c..d..e] then return localed_cache[loc..a..b..c..d..e] end
	localed_cache[loc..a..b..c..d..e] = language.GetPhrase("gwater2.menu."..loc):gsub("^%s+", ""):format(a,b,c,d,e)
	return localed_cache[loc..a..b..c..d..e]
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

local function set_gwater_parameter(option, val)
	-- print(option, val)
	local param = gwater2.options.initialised[option]

	assert(param, "Parameter does not exist: "..option)

	gwater2.parameters[option] = val

	local out = nil
	if param[1].func then
		out = param[1].func(val, param)

		if out == true then return end
	end

	if IsValid(param[2]) and not param[2].editing then
		param[2].block = true
		if param[1].type ~= "color" then 
      		param[2]:SetValue(val)
		else 
      		param[2]:SetColor(val)
		end
		param[2].block = false
		param[2].editing = false -- editing gets set to true, reset it back
	end

	if out == false then return end

	if gwater2[option] then
		gwater2[option] = val
		local radius = gwater2.solver:GetParameter("radius")
		if option == "surface_tension" then	-- hack hack hack! this parameter scales based on radius
			local r1 = val / radius^4	-- cant think of a name for this variable rn
			local r2 = val / math.min(radius * 1.3, 15)^4
			gwater2.solver:SetParameter(option, r1)
			gwater2.options.solver:SetParameter(option, r2)
		elseif option == "fluid_rest_distance" or option == "collision_distance" or option == "solid_rest_distance" then -- hack hack hack! this parameter scales based on radius
			local r1 = val * radius
			local r2 = val * math.min(radius * 1.3, 15)
			gwater2.solver:SetParameter(option, r1)
			gwater2.options.solver:SetParameter(option, r2)
		elseif option == "cohesion" then	-- also scales by radius
			local r1 = math.min(val / radius * 10, 1)
			local r2 = math.min(val / (radius * 1.3) * 10, 1)
			gwater2.solver:SetParameter(option, r1)
			gwater2.options.solver:SetParameter(option, r2)
		end
		return
	end

	gwater2.solver:SetParameter(option, val)

	if option == "gravity" then val = -val end	-- hack hack hack! y coordinate is considered down in screenspace!
	if option == "radius" then 					-- hack hack hack! radius needs to edit multiple parameters!
		gwater2.solver:SetParameter("surface_tension", gwater2["surface_tension"] / val^4)	-- literally no idea why this is a power of 4
		gwater2.solver:SetParameter("fluid_rest_distance", val * gwater2["fluid_rest_distance"])
		gwater2.solver:SetParameter("solid_rest_distance", val * gwater2["solid_rest_distance"])
		gwater2.solver:SetParameter("collision_distance", val * gwater2["collision_distance"])
		gwater2.solver:SetParameter("cohesion", math.min(gwater2["cohesion"] / val * 10, 1))
		
		if val > 15 then val = 15 end	-- explody
		val = val * 1.3
		gwater2.options.solver:SetParameter("surface_tension", gwater2["surface_tension"] / val^4)
		gwater2.options.solver:SetParameter("fluid_rest_distance", val * gwater2["fluid_rest_distance"])
		gwater2.options.solver:SetParameter("solid_rest_distance", val * gwater2["solid_rest_distance"])
		gwater2.options.solver:SetParameter("collision_distance", val * gwater2["collision_distance"])
		gwater2.options.solver:SetParameter("cohesion", math.min(gwater2["cohesion"] / val * 10, 1))
	end

	if option ~= "diffuse_threshold" and option ~= "dynamic_friction" then -- hack hack hack! fluid preview doesn't use diffuse particles
		gwater2.options.solver:SetParameter(option, val)
	end
end

local function make_title_label(tab, txt)
	local label = tab:Add("DLabel")
	label:SetText(txt)
	label:SetColor(Color(187, 245, 255))
	label:SetFont("GWater2Title")
	label:Dock(TOP)
	label:SetMouseInputEnabled(true)
	label:SizeToContents()
	local defhelptext = nil

	return label
end
local function make_parameter_scratch(tab, locale_parameter_name, parameter_name, parameter)
	local panel = tab:Add("DPanel")
	function panel:Paint() end
	panel:Dock(TOP)
	local label = panel:Add("DLabel")
	label:SetText(get_localised(locale_parameter_name))
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Param")
	label:SetMouseInputEnabled(true)
	label:SizeToContents()
	local slider = panel:Add("DNumSlider")
	slider:SetMinMax(parameter.min, parameter.max)

	local parameter_id = string.lower(parameter_name):gsub(" ", "_")

	pcall(function()
		local parameter_name = parameter_id
		slider:SetValue(gwater2[parameter_name] or gwater2.solver:GetParameter(parameter_name))
	end) -- if we can't get parameter, let's hope .setup() does that for us
	slider:SetDecimals(parameter.decimals)
	local button = panel:Add("DButton")
	button:SetText("")
	button:SetImage("icon16/arrow_refresh.png")
	button:SetWide(button:GetTall())
	button.Paint = nil
	panel.label = label
	panel.slider = slider
	panel.button = button
	label:Dock(LEFT)
	button:Dock(RIGHT)

	slider:SetText("")
	slider:Dock(FILL)

	-- HACKHACKHACK!!! Docking information is not set properly until after all elements are loaded
	-- I want the weird arrow editor on the text part of the slider, so we need to move and resize the slider after
	-- ..all of the docking information is loaded
	slider.Paint = function(w, h)
		local pos_x, pos_y = slider:GetPos()
		local size_x, size_y = slider:GetSize()
		
		slider:Dock(NODOCK)
		slider:SetPos(pos_x - size_x / 1.45, pos_y)	-- magic numbers. blame DNumSlider for this shit
		slider:SetSize(size_x * 1.7, size_y)

		slider.Paint = nil
	end
	
	--slider.Label:Hide()

	slider.TextArea:SizeToContents()
	if parameter.setup then parameter.setup(slider) end
	gwater2.options.initialised[parameter_id] = {parameter, slider}
	function button:DoClick()
		slider:SetValue(gwater2.defaults[parameter_id])
		if gwater2.options.read_config().sounds then surface.PlaySound("gwater2/menu/reset.wav", 75, 100, 1, CHAN_STATIC) end
	end
	function slider.Slider.Knob:DoClick()
		gwater2.ChangeParameter(parameter_id, math.Round(slider:GetValue(), parameter.decimals), true)
		slider.editing = false
	end
	function slider:OnValueChanged(val)
		slider.editing = true
		if slider.block then return end
		if val ~= math.Round(val, parameter.decimals) then
			self:SetValue(math.Round(val, parameter.decimals))
			return
		end

		gwater2.parameters[parameter_id] = val
		gwater2.ChangeParameter(parameter_id, val, false)
		--set_gwater_parameter(parameter_id, val, nil, true)
	end
	local defhelptext = nil
	function panel:Paint()
		if gwater2.cursor_busy ~= panel and gwater2.cursor_busy ~= nil and IsValid(gwater2.cursor_busy) then return end
		local hovered = is_hovered_any(panel)
		if hovered and not panel.washovered then
			defhelptext = tab.help_text:GetText()
			panel.washovered = true
			gwater2.cursor_busy = panel
			tab.help_text:SetText(get_localised(locale_parameter_name..".desc"))
			if gwater2.options.read_config().sounds then  surface.PlaySound("gwater2/menu/rollover.wav", 75, 100, 1, CHAN_STATIC) end
			label:SetColor(label.fancycolor_hovered or Color(187, 245, 255))
		elseif not hovered and panel.washovered then
			panel.washovered = false
			gwater2.cursor_busy = nil
			if tab.help_text:GetText() == get_localised(locale_parameter_name..".desc") then
				tab.help_text:SetText(defhelptext)
			end
			label:SetColor(label.fancycolor or Color(255, 255, 255))
		end
	end
	if not gwater2.parameters[parameter_id] then
		gwater2.parameters[parameter_id] = slider:GetValue()
		gwater2.defaults[parameter_id] = slider:GetValue()
	end
	panel:SetTall(panel:GetTall()+2)
	return panel
end

local function make_parameter_color(tab, locale_parameter_name, parameter_name, parameter)
	local panel = tab:Add("DPanel")
	function panel:Paint() end
	panel:Dock(TOP)
	local label = panel:Add("DLabel")
	label:SetText(get_localised(locale_parameter_name))
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Param")
	label:Dock(LEFT)
	label:SetMouseInputEnabled(true)
	label:SizeToContents()

	local parameter_id = string.lower(parameter_name):gsub(" ", "_")

	local mixer = panel:Add("DColorMixer")
	mixer:Dock(FILL)
	mixer:DockPadding(5, 0, 5, 0)
	panel:SetTall(150)
	mixer:SetPalette(false)
	mixer:SetLabel()
	mixer:SetAlphaBar(true)
	mixer:SetWangs(true)
	mixer:SetColor(gwater2.parameters[parameter_id]) 
	local button = panel:Add("DButton")
	button:Dock(RIGHT)
	button:SetText("")
	button:SetImage("icon16/arrow_refresh.png")
	button:SetWide(button:GetTall())
	button.Paint = nil
	panel:SizeToContents()
	panel.button = button
	panel.mixer = mixer
	panel.label = label

	if parameter.setup then parameter.setup(mixer) end
	gwater2.options.initialised[parameter_id] = {parameter, mixer}
	function button:DoClick()
		mixer:SetColor(Color(gwater2.defaults[parameter_id]:Unpack()))
		if gwater2.options.read_config().sounds then surface.PlaySound("gwater2/menu/reset.wav", 75, 100, 1, CHAN_STATIC) end
	end
	function mixer:ValueChanged(val)
		--mixer.editing = true
		-- TODO: find something to reset editing to false when user stops editing color
		if mixer.block then return end
		val = Color(val.r, val.g, val.b, val.a)

		gwater2.parameters[parameter_id] = val
		gwater2.ChangeParameter(parameter_id, val, true) -- TODO: ^
	end

	local defhelptext = nil
	function panel:Paint()
		if gwater2.cursor_busy ~= panel and gwater2.cursor_busy ~= nil and IsValid(gwater2.cursor_busy) then return end
		local hovered = is_hovered_any(panel)
		if hovered and not panel.washovered then
			defhelptext = tab.help_text:GetText()
			panel.washovered = true
			gwater2.cursor_busy = panel
			tab.help_text:SetText(get_localised(locale_parameter_name..".desc"))
			if gwater2.options.read_config().sounds then surface.PlaySound("gwater2/menu/rollover.wav", 75, 100, 1, CHAN_STATIC) end
			label:SetColor(Color(187, 245, 255))
		elseif not hovered and panel.washovered then
			panel.washovered = false
			gwater2.cursor_busy = nil
			if tab.help_text:GetText() == get_localised(locale_parameter_name..".desc") then
				tab.help_text:SetText(defhelptext)
			end
			label:SetColor(Color(255, 255, 255))
		end
	end
	panel:SetTall(panel:GetTall()+5)
	if not gwater2.parameters[parameter_id] then

		gwater2.parameters[parameter_id] = mixer:GetValue()
		gwater2.defaults[parameter_id] = mixer:GetValue()
	end
	return panel
end
local function make_parameter_check(tab, locale_parameter_name, parameter_name, parameter)
	local panel = tab:Add("DPanel")
	function panel:Paint() end
	panel:Dock(TOP)
	local label = panel:Add("DLabel")
	label:SetText(get_localised(locale_parameter_name))
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Param")
	label:Dock(LEFT)
	label:SetMouseInputEnabled(true)
	label:SizeToContents()
	local check = panel:Add("DCheckBoxLabel")
	local button = panel:Add("DButton")
	button:Dock(RIGHT)
	check:Dock(FILL)
	check:DockMargin(5, 0, 5, 0)
	check:SetText("")
	button:SetText("")
	button:SetImage("icon16/arrow_refresh.png")
	button:SetWide(button:GetTall())

	local parameter_id = string.lower(parameter_name):gsub(" ", "_")

	button.Paint = nil
	panel.label = label
	panel.check = check
	panel.button = button
	if parameter.setup then parameter.setup(check) end
	gwater2.options.initialised[parameter_id] = {parameter, check}
	function button:DoClick()
		check:SetValue(gwater2.defaults[parameter_id])
		if gwater2.options.read_config().sounds then surface.PlaySound("gwater2/menu/reset.wav", 75, 100, 1, CHAN_STATIC) end
	end
	function check:OnChange(val)
		if check.block then return end
		if gwater2.options.read_config().sounds then surface.PlaySound("gwater2/menu/toggle.wav", 75, 100, 1, CHAN_STATIC) end

		gwater2.parameters[parameter_id] = val
		gwater2.ChangeParameter(parameter_id, val, true) -- all checkbox edits are final
		--if parameter.func then if parameter.func(val) then return end end
		--set_gwater_parameter(parameter_id, val)
	end
	local defhelptext = nil
	function panel:Paint()
		if gwater2.cursor_busy ~= panel and gwater2.cursor_busy ~= nil and IsValid(gwater2.cursor_busy) then return end
		local hovered = is_hovered_any(panel)
		if hovered and not panel.washovered then
			defhelptext = tab.help_text:GetText()
			panel.washovered = true
			gwater2.cursor_busy = panel
			tab.help_text:SetText(get_localised(locale_parameter_name..".desc"))
			if gwater2.options.read_config().sounds then surface.PlaySound("gwater2/menu/rollover.wav", 75, 100, 1, CHAN_STATIC) end
			label:SetColor(label.fancycolor_hovered or Color(187, 245, 255))
		elseif not hovered and panel.washovered then
			panel.washovered = false
			gwater2.cursor_busy = nil
			if tab.help_text:GetText() == get_localised(locale_parameter_name..".desc") then
				tab.help_text:SetText(defhelptext)
			end
			label:SetColor(label.fancycolor or Color(255, 255, 255))
		end
	end
	panel:SetTall(panel:GetTall()+5)
	if not gwater2.parameters[parameter_id] then
		gwater2.parameters[parameter_id] = check:GetChecked()
		gwater2.defaults[parameter_id] = check:GetChecked()
	end
	return panel
end

return {
	make_title_label=make_title_label,
	make_parameter_check=make_parameter_check,
	make_parameter_color=make_parameter_color,
	make_parameter_scratch=make_parameter_scratch,
	set_gwater_parameter=set_gwater_parameter,
	get_localised=get_localised
}