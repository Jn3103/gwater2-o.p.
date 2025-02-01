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

-- code used to generate defaults

-- local parameters = {}
-- local param_map = {}

-- parameters.gravity = {}

-- parameters.gravity[0] = 0.0
-- parameters.gravity[1] = 0.0
-- parameters.gravity[2] = -15.24

-- parameters.wind = {}

-- parameters.wind[0] = 0.0
-- parameters.wind[1] = 0.0
-- parameters.wind[2] = 0.0

-- parameters.radius = 10
-- parameters.viscosity = 0.0
-- parameters.dynamicFriction = 0.5
-- parameters.staticFriction = 0.5
-- parameters.particleFriction = 0.0
-- parameters.freeSurfaceDrag = 0.0
-- parameters.drag = 0.0
-- parameters.lift = 0.0
-- parameters.numIterations = 3
-- parameters.fluidRestDistance = 6.5
-- parameters.solidRestDistance = 6.5

-- parameters.anisotropyScale = 1
-- parameters.anisotropyMin = 0.1
-- parameters.anisotropyMax = 0.5
-- parameters.smoothing = 1.0

-- parameters.dissipation = 0
-- parameters.damping = 0.0
-- parameters.particleCollisionMargin = 0
-- parameters.shapeCollisionMargin = 0
-- parameters.collisionDistance = 5 
-- parameters.sleepThreshold = 0.1
-- parameters.shockPropagation = 0.0
-- parameters.restitution = 0.0

-- parameters.maxSpeed = 1e5
-- parameters.maxAcceleration = 1e4
-- parameters.relaxationMode = 1
-- parameters.relaxationFactor = 0.25
-- parameters.solidPressure = 0.5
-- parameters.adhesion = 0.0
-- parameters.cohesion = 0.01
-- parameters.surfaceTension = 0.000001
-- parameters.vorticityConfinement = 0.0
-- parameters.buoyancy = 1.0

-- parameters.diffuseThreshold = 100
-- parameters.diffuseBuoyancy = 1
-- parameters.diffuseDrag = 0.8
-- parameters.diffuseBallistic = 2
-- parameters.diffuseLifetime = 5

-- parameters.numPlanes = 0

-- param_map["gravity"] = parameters.gravity[2]
-- param_map["radius"] = parameters.radius
-- param_map["viscosity"] = parameters.viscosity
-- param_map["dynamic_friction"] = parameters.dynamicFriction
-- param_map["static_friction"] = parameters.staticFriction
-- param_map["particle_friction"] = parameters.particleFriction
-- param_map["free_surface_drag"] = parameters.freeSurfaceDrag
-- param_map["drag"] = parameters.drag
-- param_map["lift"] = parameters.lift
-- param_map["fluid_rest_distance"] = parameters.fluidRestDistance
-- param_map["solid_rest_distance"] = parameters.solidRestDistance
-- param_map["anisotropy_scale"] = parameters.anisotropyScale
-- param_map["anisotropy_min"] = parameters.anisotropyMin
-- param_map["anisotropy_max"] = parameters.anisotropyMax
-- param_map["smoothing"] = parameters.smoothing
-- param_map["dissipation"] = parameters.dissipation
-- param_map["damping"] = parameters.damping
-- param_map["particle_collision_margin"] = parameters.particleCollisionMargin
-- param_map["shape_collision_margin"] = parameters.shapeCollisionMargin
-- param_map["collision_distance"] = parameters.collisionDistance
-- param_map["sleep_threshold"] = parameters.sleepThreshold
-- param_map["shock_propagation"] = parameters.shockPropagation
-- param_map["restitution"] = parameters.restitution
-- param_map["max_speed"] = parameters.maxSpeed
-- param_map["max_acceleration"] = parameters.maxAcceleration
-- param_map["relaxation_factor"] = parameters.relaxationFactor
-- param_map["solid_pressure"] = parameters.solidPressure
-- param_map["adhesion"] = parameters.adhesion
-- param_map["cohesion"] = parameters.cohesion
-- param_map["surface_tension"] = parameters.surfaceTension
-- param_map["vorticity_confinement"] = parameters.vorticityConfinement
-- param_map["buoyancy"] = parameters.buoyancy
-- param_map["diffuse_threshold"] = parameters.diffuseThreshold
-- param_map["diffuse_buoyancy"] = parameters.diffuseBuoyancy
-- param_map["diffuse_drag"] = parameters.diffuseDrag
-- param_map["diffuse_lifetime"] = parameters.diffuseLifetime

-- param_map["substeps"] = 3
-- param_map["timescale"] = 1
-- param_map["reaction_forces"] = 0

-- print("local defaults = {")
-- for i, v in pairs(param_map) do
-- print("   [\"" .. i .. "\"] = " .. tostring(v) .. ",")
-- end
-- print("}")