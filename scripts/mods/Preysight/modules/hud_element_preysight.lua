local mod = get_mod("Preysight")

local Gui = Gui
local Color = Color
local Vector3 = Vector3
local math_floor = math.floor

local MATERIAL_VIGNETTE = "content/ui/materials/masks/gradient_vignette"

local Definitions = {
	scenegraph_definition = {},
	widget_definitions = {},
}

local HudElementPreysight = class("HudElementPreysight", "HudElementBase")

HudElementPreysight.init = function (self, parent, draw_layer, start_scale)
	HudElementPreysight.super.init(self, parent, draw_layer, start_scale, Definitions)

	self._scanline_material = nil
	self._grain_material = nil
	self._scanline_failed = false
	self._grain_failed = false
end

local function ensure_material(self, field, gui, texture)
	local material = self[field]

	if material then
		return material
	end

	material = mod.assets.build_material(gui, texture)
	self[field] = material

	return material
end

local function draw_bitmap_safe(self, failed_field, gui, material, position, size, color, pass_name)
	local ok, err = pcall(Gui.bitmap, gui, material, position, size, color)

	if not ok then
		self[failed_field] = true

		mod:error("Preysight: %s pass failed and is disabled for this HUD element (%s)", pass_name, tostring(err))
	end
end

HudElementPreysight.draw = function (self, dt, t, ui_renderer, render_settings, input_service)
	local weight = mod.optics.weight()

	if weight <= 0 then
		return
	end

	local wash_alpha, scanline_alpha, grain_alpha, vignette_alpha = mod.overlay.alphas()
	local wash = wash_alpha * weight
	local scanlines = scanline_alpha * weight
	local grain = grain_alpha * weight
	local vignette = vignette_alpha * weight

	if wash <= 0 and scanlines <= 0 and grain <= 0 and vignette <= 0 then
		return
	end

	local r, g, b = mod.overlay.colour()
	local width, height = Gui.resolution()
	local gui = ui_renderer.gui
	local position = Vector3(0, 0, self._draw_layer or 0)
	local size = Vector3(width, height, 0)

	if wash > 0 then
		local wash_color = Color(math_floor(wash * 255), math_floor(r * 255), math_floor(g * 255), math_floor(b * 255))

		Gui.rect(gui, position, size, wash_color)
	end

	if scanlines > 0 and not self._scanline_failed then
		local scanline_material = ensure_material(self, "_scanline_material", gui, mod.assets.scanline_texture())

		if scanline_material then
			local scanline_color = Color(math_floor(scanlines * 255), 255, 255, 255)

			draw_bitmap_safe(self, "_scanline_failed", gui, scanline_material, position, size, scanline_color, "scanline")
		end
	end

	if grain > 0 and not self._grain_failed then
		local grain_material = ensure_material(self, "_grain_material", gui, mod.assets.grain_texture())

		if grain_material then
			local grain_color = Color(math_floor(grain * 255), 255, 255, 255)

			draw_bitmap_safe(self, "_grain_failed", gui, grain_material, position, size, grain_color, "grain")
		end
	end

	if vignette > 0 then
		local vignette_color = Color(math_floor(vignette * 255), 0, 0, 0)

		Gui.bitmap(gui, MATERIAL_VIGNETTE, position, size, vignette_color)
	end
end

HudElementPreysight.destroy = function (self, ui_renderer)
	self._scanline_material = nil
	self._grain_material = nil

	HudElementPreysight.super.destroy(self, ui_renderer)
end

return HudElementPreysight
