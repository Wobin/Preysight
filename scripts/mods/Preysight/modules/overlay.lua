local mod = get_mod("Preysight")

local overlay = {}

local ELEMENT_FILENAME = "Preysight/scripts/mods/Preysight/modules/hud_element_preysight"

local DEFAULT_HUE = 110 / 360
local DEFAULT_SATURATION = 0.9
local DEFAULT_VALUE = 1.0
local DEFAULT_WASH_ALPHA = 0.25
local DEFAULT_VIGNETTE_ALPHA = 0.8
local DEFAULT_SCANLINE_ALPHA = 0.15
local DEFAULT_GRAIN_ALPHA = 0.25

local _r, _g, _b = mod.colour.hsv_to_rgb(DEFAULT_HUE, DEFAULT_SATURATION, DEFAULT_VALUE)
local _wash_alpha = DEFAULT_WASH_ALPHA
local _scanline_alpha = DEFAULT_SCANLINE_ALPHA
local _grain_alpha = DEFAULT_GRAIN_ALPHA
local _vignette_alpha = DEFAULT_VIGNETTE_ALPHA

local ELEMENT_SETTINGS = {
	class_name = "HudElementPreysight",
	filename = ELEMENT_FILENAME,
	visibility_groups = {
		"alive",
		"dead",
		"communication_wheel",
		"player_in_danger_zone",
	},
}

local function dmf_mod()
	local dmf = get_mod("DMF")

	if type(dmf) == "table" then
		return dmf
	end

	return nil
end

overlay.install = function (mod)
	local dmf = dmf_mod()

	if dmf and dmf.remove_injected_hud_elements then
		dmf.remove_injected_hud_elements(mod)
	end

	mod:register_hud_element(ELEMENT_SETTINGS)
end

overlay.enable_element = function ()
	local dmf = dmf_mod()

	if dmf and dmf.inject_hud_elements then
		dmf.inject_hud_elements(mod)
	end
end

overlay.disable_element = function ()
	local dmf = dmf_mod()

	if dmf and dmf.remove_injected_hud_elements then
		dmf.remove_injected_hud_elements(mod)
	end
end

overlay.set_colour = function (r, g, b)
	_r, _g, _b = r, g, b
end

overlay.set_alphas = function (wash, scanline, grain, vignette)
	_wash_alpha = wash
	_scanline_alpha = scanline
	_grain_alpha = grain
	_vignette_alpha = vignette
end

overlay.colour = function ()
	return _r, _g, _b
end

overlay.alphas = function ()
	return _wash_alpha, _scanline_alpha, _grain_alpha, _vignette_alpha
end

return overlay
