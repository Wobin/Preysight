local mod = get_mod("Preysight")

local Managers = Managers

local Unit_alive = Unit.alive
local Unit_has_node = Unit.has_node
local Unit_node = Unit.node
local Unit_light = Unit.light
local Unit_num_lights = Unit.num_lights
local Unit_num_meshes = Unit.num_meshes
local Unit_set_mesh_visibility = Unit.set_mesh_visibility
local Unit_world_pose = Unit.world_pose
local Unit_world_rotation = Unit.world_rotation
local Unit_set_local_rotation = Unit.set_local_rotation
local Unit_set_local_position = Unit.set_local_position

local World_spawn_unit_ex = World.spawn_unit_ex
local World_link_unit = World.link_unit
local World_unlink_unit = World.unlink_unit
local World_destroy_unit = World.destroy_unit
local World_update_unit = World.update_unit

local Light_set_type = Light.set_type
local Light_set_enabled = Light.set_enabled
local Light_set_intensity = Light.set_intensity
local Light_set_color_filter = Light.set_color_filter
local Light_set_ies_profile = Light.set_ies_profile
local Light_set_casts_shadows = Light.set_casts_shadows
local Light_set_spot_reflector = Light.set_spot_reflector
local Light_set_spot_angle_start = Light.set_spot_angle_start
local Light_set_spot_angle_end = Light.set_spot_angle_end
local Light_set_falloff_start = Light.set_falloff_start
local Light_set_falloff_end = Light.set_falloff_end
local Light_set_volumetric_intensity = Light.set_volumetric_intensity

local ScriptUnit_has_extension = ScriptUnit.has_extension
local ScriptUnit_extension = ScriptUnit.extension

local Quaternion_inverse = Quaternion.inverse
local Quaternion_multiply = Quaternion.multiply
local Quaternion_forward = Quaternion.forward
local Quaternion_rotate = Quaternion.rotate

local Vector3_up = Vector3.up

local math_pi = math.pi

local illuminator = {}

local LIGHT_UNIT = "content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01"
local IES_PROFILE = "content/environment/ies_profiles/narrow/flashlight_custom_03"

local NODE_CANDIDATES = { "j_head", "j_neck" }

local VALID_LIGHT_TYPES = { omni = true, spot = true }

local CAST_SHADOWS = false
local VOLUMETRIC_INTENSITY = 0

local _package_loaded = false

local _world = nil
local _unit = nil
local _light = nil
local _light_enabled = false
local _owner_unit = nil
local _node_index = nil

local _intensity = 4
local _falloff_end = 15
local _spot_start_deg = 35
local _spot_end_deg = 90
local _use_ies = false
local _light_type = "omni"
local _offset = -1.5
local _offset_up = 1.5

-- ─────────────────────────────────────────────────────────────────────

local function ensure_package()
	if _package_loaded then
		return
	end

	_package_loaded = true

	mod:load_package(LIGHT_UNIT)
end

local function package_ready()
	return mod:package_status(LIGHT_UNIT) == "loaded"
end

illuminator.release_package = function()
	if not _package_loaded then
		return
	end

	_package_loaded = false

	mod:unload_package(LIGHT_UNIT)
end

-- ─────────────────────────────────────────────────────────────────────

local function resolve_node(unit)
	for i = 1, #NODE_CANDIDATES do
		if Unit_has_node(unit, NODE_CANDIDATES[i]) then
			return Unit_node(unit, NODE_CANDIDATES[i])
		end
	end

	return 1
end

local function destroy()
	local unit = _unit

	_unit = nil
	_light = nil
	_light_enabled = false
	_owner_unit = nil
	_node_index = nil

	if not unit or not Unit_alive(unit) then
		return
	end

	World_unlink_unit(_world, unit)
	World_destroy_unit(_world, unit)
end

illuminator.destroy = destroy

local function apply_spot_shape()
	if not _light then
		return
	end

	Light_set_spot_reflector(_light, true)
	Light_set_spot_angle_start(_light, _spot_start_deg / 180 * math_pi)
	Light_set_spot_angle_end(_light, _spot_end_deg / 180 * math_pi)

	if _use_ies then
		Light_set_ies_profile(_light, IES_PROFILE)
	end
end

local function apply_static_tuning()
	if not _light then
		return
	end

	Light_set_type(_light, _light_type)

	if _light_type == "spot" then
		apply_spot_shape()
	end

	Light_set_casts_shadows(_light, CAST_SHADOWS)
	Light_set_falloff_start(_light, 0)
	Light_set_falloff_end(_light, _falloff_end)
	Light_set_volumetric_intensity(_light, VOLUMETRIC_INTENSITY)
	Light_set_color_filter(_light, Vector3(1, 1, 1))
end

local function spawn(world, owner_unit)
	if not package_ready() then
		return false
	end

	local node_index = resolve_node(owner_unit)
	local light_unit = World_spawn_unit_ex(world, LIGHT_UNIT, nil, Unit_world_pose(owner_unit, node_index))

	if not light_unit then
		mod:error("Preysight: illuminator spawn_unit_ex returned nil for %s", LIGHT_UNIT)

		return false
	end

	World_link_unit(world, light_unit, 1, owner_unit, node_index, World.LINK_MODE_NODE_NAME)

	for i = 1, Unit_num_meshes(light_unit) do
		Unit_set_mesh_visibility(light_unit, i, false)
	end

	if Unit_num_lights(light_unit) < 1 then
		World_unlink_unit(world, light_unit)
		World_destroy_unit(world, light_unit)

		return false
	end

	_world = world
	_unit = light_unit
	_light = Unit_light(light_unit, 1)
	_owner_unit = owner_unit
	_node_index = node_index
	_light_enabled = false

	Light_set_enabled(_light, false)
	apply_static_tuning()

	World_update_unit(world, light_unit)

	return true
end

-- ─────────────────────────────────────────────────────────────────────

illuminator.set_tuning = function(intensity, falloff_end)
	_intensity = intensity
	_falloff_end = falloff_end

	if _light then
		Light_set_falloff_end(_light, _falloff_end)
	end
end

illuminator.set_shape = function(start_deg, end_deg, use_ies)
	_spot_start_deg = start_deg
	_spot_end_deg = end_deg
	_use_ies = use_ies

	if _light_type == "spot" then
		apply_spot_shape()
	end
end

illuminator.set_light_type = function(kind)
	if not VALID_LIGHT_TYPES[kind] then
		mod:error("Preysight: illuminator.set_light_type rejected %s", tostring(kind))

		return
	end

	_light_type = kind

	if not _light then
		return
	end

	Light_set_type(_light, _light_type)

	if _light_type == "spot" then
		apply_spot_shape()
	end
end

illuminator.set_offset = function(forward, up)
	_offset = forward

	if up ~= nil then
		_offset_up = up
	end
end

illuminator.shape = function()
	return _spot_start_deg, _spot_end_deg, _use_ies, _light_type, _offset, _offset_up
end

illuminator.update = function(dt, active, weight)
	if not active then
		if _unit then
			destroy()
		end

		return
	end

	if weight <= 0 then
		if _light_enabled then
			Light_set_enabled(_light, false)
			_light_enabled = false
		end

		return
	end

	local player = Managers.player and Managers.player:local_player_safe(1)
	local owner_unit = player and player.player_unit

	if not owner_unit or not Unit_alive(owner_unit) then
		if _unit then
			destroy()
		end

		return
	end

	if _owner_unit and _owner_unit ~= owner_unit then
		destroy()
	end

	if not _unit then
		local world = Managers.world and Managers.world:world("level_world")

		if not world or not Unit_alive(owner_unit) then
			return
		end

		ensure_package()

		if not spawn(world, owner_unit) then
			return
		end
	end

	if not Unit_alive(_unit) or not Unit_alive(_owner_unit) then
		destroy()

		return
	end

	if not _light_enabled then
		Light_set_enabled(_light, true)
		_light_enabled = true
	end

	local first_person = ScriptUnit_has_extension(_owner_unit, "first_person_system")
		and ScriptUnit_extension(_owner_unit, "first_person_system")

	if first_person then
		local desired_rotation = first_person:extrapolated_rotation()
		local node_rotation = Unit_world_rotation(_owner_unit, _node_index)
		local inverse_node_rotation = Quaternion_inverse(node_rotation)
		local local_rotation = Quaternion_multiply(inverse_node_rotation, desired_rotation)
		local world_offset = Quaternion_forward(desired_rotation) * _offset + Vector3_up() * _offset_up
		local local_offset = Quaternion_rotate(inverse_node_rotation, world_offset)

		Unit_set_local_rotation(_unit, 1, local_rotation)
		Unit_set_local_position(_unit, 1, local_offset)
		World_update_unit(_world, _unit)
	end

	Light_set_intensity(_light, _intensity * weight)
end

return illuminator
