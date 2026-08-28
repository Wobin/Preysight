local mod = get_mod("Preysight")

local table_insert = table.insert
local table_remove = table.remove

local overlay = {}

local ELEMENT_FILENAME = "Preysight/scripts/mods/Preysight/modules/hud_element_preysight"
local HUD_ELEMENTS_PATH = "scripts/ui/hud/hud_elements_player"

local DEFAULT_HUE = 110 / 360
local DEFAULT_SATURATION = 0.9
local DEFAULT_VALUE = 1.0
local DEFAULT_WASH_ALPHA = 0.25
local DEFAULT_VIGNETTE_ALPHA = 0.8
local DEFAULT_SCANLINE_ALPHA = 0.15
local DEFAULT_GRAIN_ALPHA = 0.25

local _installed = false
local _r, _g, _b = mod.colour.hsv_to_rgb(DEFAULT_HUE, DEFAULT_SATURATION, DEFAULT_VALUE)
local _wash_alpha = DEFAULT_WASH_ALPHA
local _scanline_alpha = DEFAULT_SCANLINE_ALPHA
local _grain_alpha = DEFAULT_GRAIN_ALPHA
local _vignette_alpha = DEFAULT_VIGNETTE_ALPHA

local function live_elements()
	local elements = package.loaded[HUD_ELEMENTS_PATH]

	if type(elements) == "table" then
		return elements
	end

	return nil
end

local function register_element(elements)
	for i = 1, #elements do
		if elements[i].class_name == "HudElementPreysight" then
			return
		end
	end

	table_insert(elements, 1, {
		class_name = "HudElementPreysight",
		filename = ELEMENT_FILENAME,
		visibility_groups = {
			"alive",
			"dead",
			"communication_wheel",
			"player_in_danger_zone",
		},
	})
end

overlay.install = function (mod)
	if _installed then
		return
	end

	mod:add_require_path(ELEMENT_FILENAME)
	mod:hook_require(HUD_ELEMENTS_PATH, register_element)

	_installed = true
end

overlay.enable_element = function ()
	local elements = live_elements()

	if elements then
		register_element(elements)
	end
end

overlay.disable_element = function ()
	local elements = live_elements()

	if not elements then
		return
	end

	for i = #elements, 1, -1 do
		if elements[i].class_name == "HudElementPreysight" then
			table_remove(elements, i)
		end
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
