AddCSLuaFile()

gwater2 = nil

if SERVER then 
	include("gwater2_net.lua")
	include("gwater2_interactions.lua")

	AddCSLuaFile("gwater2_interactions.lua")
	AddCSLuaFile("gwater2_net.lua")
	AddCSLuaFile("gwater2_shaders.lua")
	AddCSLuaFile("gwater2_net.lua")
	return
end

require((BRANCH == "x86-64" or BRANCH == "chromium" ) and "gwater2" or "gwater2_main")	-- carrying
local in_water = include("gwater2_interactions.lua")

-- GetMeshConvexes but for client
local function unfucked_get_mesh(ent, raw)
	-- Physics object exists
	local phys = ent:GetPhysicsObject()
	if phys:IsValid() then return (raw and phys:GetMesh() or phys:GetMeshConvexes()) end

	local model = ent:GetModel()
	local is_ragdoll = util.IsValidRagdoll(model)
	local convexes

	if !is_ragdoll or raw then
		local cs_ent = ents.CreateClientProp(model)
		local phys = cs_ent:GetPhysicsObject()
		convexes = phys:IsValid() and (raw and phys:GetMesh() or phys:GetMeshConvexes())
		cs_ent:Remove()
	else 
		-- no joke this is the hackiest shit ive ever done. 
		-- for whatever reason the metrocop and ONLY the metrocop model has this problem
		-- when creating a clientside ragdoll of the metrocop entity it will sometimes break all pistol and stunstick animations
		-- I have no idea why this happens.
		if model == "models/police.mdl" then model = "models/combine_soldier.mdl" end

		local cs_ent = ClientsideRagdoll(model)
		convexes = {}
		for i = 0, cs_ent:GetPhysicsObjectCount() - 1 do
			table.insert(convexes, cs_ent:GetPhysicsObjectNum(i):GetMesh())
		end
		cs_ent:Remove()
	end

	return convexes
end

-- adds entity to FlexSolver
local function add_prop(ent)
	if !IsValid(ent) then return end
	
	local ent_index = ent:EntIndex()
	gwater2.solver:RemoveCollider(ent_index) -- incase source decides to reuse the same entity index

	if !ent:IsSolid() or ent:IsWeapon() or !ent:GetModel() then return end

	local convexes = unfucked_get_mesh(ent)
	if !convexes then return end

	ent.GWATER2_IS_RAGDOLL = util.IsValidRagdoll(ent:GetModel())
	
	if #convexes < 16 then	-- too many convexes to be worth calculating
		for k, v in ipairs(convexes) do
			if #v <= 64 * 3 then	-- hardcoded limits.. No more than 64 planes per convex as it is a FleX limitation
				gwater2.solver:AddConvexCollider(ent_index, v, ent:GetPos(), ent:GetAngles())
			else
				gwater2.solver:AddConcaveCollider(ent_index, v, ent:GetPos(), ent:GetAngles())
			end
		end
	else
		gwater2.solver:AddConcaveCollider(ent_index, unfucked_get_mesh(ent, true), ent:GetPos(), ent:GetAngles())
	end

end

local function get_map_vertices()
	local all_vertices = {}
	for _, brush in ipairs(game.GetWorld():GetBrushSurfaces()) do
		local vertices = brush:GetVertices()
		for i = 3, #vertices do
			all_vertices[#all_vertices + 1] = vertices[1]
			all_vertices[#all_vertices + 1] = vertices[i - 1]
			all_vertices[#all_vertices + 1] = vertices[i]
		end
	end

	return all_vertices
end

-- collisions will lerp from positions they were at a long time ago if no particles have been initialized for a while
local no_lerp = false

gwater2 = {
	solver = FlexSolver(100000),
	renderer = FlexRenderer(),
	cloth_pos = Vector(),
	parameters = {},
	defaults = {},
	update_colliders = function(index, id, rep)
		if id == 0 then return end	-- skip, entity is world

		local ent = Entity(id)
		if !IsValid(ent) then 
			gwater2.solver:RemoveCollider(id)
		else 
			if !ent.GWATER2_IS_RAGDOLL then

				-- custom physics objects may be networked and initialized after the entity was created
				if ent.GWATER2_PHYSOBJ or ent:GetPhysicsObjectCount() != 0 then
					local phys = ent:GetPhysicsObject()	-- slightly expensive operation

					if !IsValid(ent.GWATER2_PHYSOBJ) or ent.GWATER2_PHYSOBJ != phys then	-- we know physics object was recreated with a PhysicsInit* function
						add_prop(ent)	-- internally cleans up entity colliders
						ent.GWATER2_PHYSOBJ = phys
					end
				end

				gwater2.solver:SetColliderPos(index, ent:GetPos(), no_lerp)
				gwater2.solver:SetColliderAng(index, ent:GetAngles(), no_lerp)
				gwater2.solver:SetColliderEnabled(index, ent:GetCollisionGroup() != COLLISION_GROUP_WORLD and bit.band(ent:GetSolidFlags(), FSOLID_NOT_SOLID) == 0)
			else
				-- horrible code for proper ragdoll collision. Still breaks half the time. Fuck source
				local bone_index = ent:TranslatePhysBoneToBone(rep)
				local pos, ang = ent:GetBonePosition(bone_index)
				if !pos or pos == ent:GetPos() then 	-- wtf?
					local bone = ent:GetBoneMatrix(bone_index)
					if bone then
						pos = bone:GetTranslation()
						ang = bone:GetAngles()
					else
						pos = ent:GetPos()
						ang = ent:GetAngles()
					end
				end
				gwater2.solver:SetColliderPos(index, pos, no_lerp)
				gwater2.solver:SetColliderAng(index, ang, no_lerp)
				
				if in_water(ent) then 
					gwater2.solver:SetColliderEnabled(index, false) 
					return 
				end

				local should_collide = ent:GetCollisionGroup() != COLLISION_GROUP_WORLD and bit.band(ent:GetSolidFlags(), FSOLID_NOT_SOLID) == 0
				if ent:IsPlayer() then
					gwater2.solver:SetColliderEnabled(index, should_collide and ent:GetNW2Bool("GWATER2_COLLISION", true))
				else
					gwater2.solver:SetColliderEnabled(index, should_collide)
				end
			end
		end
	end,

	reset_solver = function(err)
		xpcall(function()
			gwater2.solver:AddMapCollider(0, game.GetMap())
		end, function(e)
			gwater2.solver:AddConcaveCollider(0, get_map_vertices(), Vector(), Angle(0))
			if !err then
				ErrorNoHaltWithStack("[GWater2]: Map BSP structure is unsupported. Reverting to brushes. Collision WILL have holes!")
			end
		end)

		for k, ent in ipairs(ents.GetAll()) do
			add_prop(ent)
		end

		gwater2.solver:InitBounds(Vector(-16384, -16384, -16384), Vector(16384, 16384, 16384))	-- source bounds
	end,
	
	-- defined on server in gwater2_net.lua
	quick_matrix = function(pos, ang, scale)
		local mat = Matrix()
		if pos then mat:SetTranslation(pos) end
		if ang then mat:SetAngles(ang) end
		if scale then mat:SetScale(Vector(1, 1, 1) * scale) end
		return mat
	end
}

-- setup external default values
gwater2.parameters.color = Color(209, 237, 255, 25)
gwater2.parameters.color_value_multiplier = 1
gwater2.defaults = table.Copy(gwater2.parameters)

-- setup percentage values (used in menu)
gwater2["surface_tension"] = gwater2.solver:GetParameter("surface_tension") * gwater2.solver:GetParameter("radius")^4	-- dont ask me why its a power of 4
gwater2["fluid_rest_distance"] = gwater2.solver:GetParameter("fluid_rest_distance") / gwater2.solver:GetParameter("radius")
gwater2["solid_rest_distance"] = gwater2.solver:GetParameter("solid_rest_distance") / gwater2.solver:GetParameter("radius")
gwater2["collision_distance"] = gwater2.solver:GetParameter("collision_distance") / gwater2.solver:GetParameter("radius")
gwater2["cohesion"] = gwater2.solver:GetParameter("cohesion") * gwater2.solver:GetParameter("radius") * 0.1	-- cohesion scales by radius, for some reason..
gwater2["blur_passes"] = 3
-- reaction force specific
gwater2["force_multiplier"] = 0.01
gwater2["force_buoyancy"] = 0
gwater2["force_dampening"] = 0
gwater2["player_interaction"] = true

include("gwater2_shaders.lua")
include("gwater2_net.lua")
include("gwater2_menu.lua")

local limit_fps = 1 / 60
local function gwater_tick2()
	local lp = LocalPlayer()
	if !IsValid(lp) then return end

	if gwater2.solver:GetActiveParticles() <= 0 then 
		no_lerp = true
	else
		gwater2.solver:ApplyContacts(limit_fps * gwater2["force_multiplier"], 3, gwater2["force_buoyancy"], gwater2["force_dampening"])
		gwater2.solver:IterateColliders(gwater2.update_colliders)

		if no_lerp then 
			no_lerp = false
		end
	end
	
	local particles_in_radius = gwater2.solver:GetParticlesInRadius(lp:GetPos() + lp:OBBCenter(), gwater2.solver:GetParameter("fluid_rest_distance") * 3)
	GWATER2_QuickHackRemoveMeASAP(	-- TODO: REMOVE THIS HACKY SHIT!!!!!!!!!!!!!
		lp:EntIndex(), 
		particles_in_radius
	)

	lp.GWATER2_CONTACTS = particles_in_radius

	--[[
		for whatever reason if you drain particles before adding them it will cause 
		a problem where particles will swap velocities and positions randomly.

		im 5 hours in trying to figure out what flawed logic in my code is causing this to happen, and
		to be honest I do not have enough time or patience to figure out the underlying issue.. so for now we're
		gonna have to deal with some mee++
	]]
		
	hook.Run("gwater2_tick_particles")
	hook.Run("gwater2_tick_drains")

	gwater2.solver:Tick(limit_fps, 0)
end

timer.Create("gwater2_tick", limit_fps, 0, gwater_tick2)

-- for development when you run init code again, so that solver gets initialised properly
if game.GetWorld() ~= nil then
	gwater2.reset_solver()
else 
	hook.Add("InitPostEntity", "gwater2_addprop", gwater2.reset_solver)
end
hook.Add("OnEntityCreated", "gwater2_addprop", function(ent) timer.Simple(0, function() add_prop(ent) end) end)	// timer.0 so data values are setup correctly

-- gravgun support
local can_fire = false
local last_fire = 0
hook.Add("gwater2_tick_drains", "gwater2_gravgun_grab", function()
	local lp = LocalPlayer()
	local gravgun = lp:GetActiveWeapon()
	if !IsValid(gravgun) or lp:GetActiveWeapon():GetClass() ~= "weapon_physcannon" then 
		can_fire = false
		return 
	end

	-- right click (hold)
	if lp:KeyDown(IN_ATTACK2) then
		gwater2.solver:AddForceField(lp:EyePos() + lp:GetAimVector() * 170, 150, -200, 0, true)
	end

	-- left click (punt)
	if can_fire and last_fire ~= gravgun:GetNextPrimaryFire() then
		last_fire = gravgun:GetNextPrimaryFire()
		gwater2.solver:AddForceField(lp:EyePos(), 320, 200, 1, false)
	else
		last_fire = gravgun:GetNextPrimaryFire()
		can_fire = true
	end
end)
