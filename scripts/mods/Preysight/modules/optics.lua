local mod = get_mod("Preysight")

local ShadingEnvironment = ShadingEnvironment
local Managers = Managers

local optics = {}

local _installed = false
local _weight = 0
local _target = 0
local _exposure = 3.0
local _blur = 0.1
local _greyscale = 1.0
local _blend_in = 1.0
local _blend_out = 0.6

local function apply(shading_env)
	if _weight <= 0 then
		return
	end

	ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 1)
	ShadingEnvironment.set_scalar(shading_env, "grey_scale_amount", _greyscale * _weight)

	local exposure = ShadingEnvironment.scalar(shading_env, "exposure_compensation")

	ShadingEnvironment.set_scalar(shading_env, "exposure_compensation", exposure + _exposure * _weight)

	ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 1)
	ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_amount", _blur * _weight)
end

optics.install = function(mod)
	if _installed then
		return
	end

	mod:hook(CLASS.CameraManager, "shading_callback", function(func, self, world, shading_env, viewport, default_resource, ...)
		func(self, world, shading_env, viewport, default_resource, ...)

		if Managers.ui and Managers.ui:has_active_view() then
			return
		end

		apply(shading_env)
	end)

	_installed = true
end

optics.update = function(dt)
	_weight = mod.ramp.step(_weight, _target, dt, _blend_in, _blend_out)
end

optics.set_target = function(target)
	_target = target
end

optics.weight = function()
	return _weight
end

optics.set_tuning = function(exposure, blur, greyscale, blend_in, blend_out)
	_exposure = exposure
	_blur = blur
	_greyscale = greyscale
	_blend_in = blend_in
	_blend_out = blend_out
end

return optics
