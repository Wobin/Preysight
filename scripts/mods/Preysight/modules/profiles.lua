local FIELDS = {
	"preysight_exposure",
	"preysight_greyscale",
	"preysight_blur",
	"preysight_blend_in",
	"preysight_blend_out",
	"preysight_wash_alpha",
	"preysight_scanline_alpha",
	"preysight_grain_alpha",
	"preysight_vignette_alpha",
	"preysight_hue_source",
	"preysight_fixed_colour",
	"preysight_illuminator",
	"preysight_illuminator_intensity",
	"preysight_illuminator_range",
	"preysight_illuminator_offset",
	"preysight_illuminator_height",
}

local DEFAULTS = {
	preysight_exposure = 3.0,
	preysight_greyscale = 1.0,
	preysight_blur = 0.1,
	preysight_blend_in = 1.0,
	preysight_blend_out = 0.6,
	preysight_wash_alpha = 0.25,
	preysight_scanline_alpha = 0.15,
	preysight_grain_alpha = 0.25,
	preysight_vignette_alpha = 0.8,
	preysight_hue_source = "lens",
	preysight_fixed_colour = { 255, 64, 255, 26 },
	preysight_illuminator = true,
	preysight_illuminator_intensity = 4,
	preysight_illuminator_range = 15,
	preysight_illuminator_offset = -1.5,
	preysight_illuminator_height = 1.5,
}

local FIELD_SET = {}

for i = 1, #FIELDS do
	FIELD_SET[FIELDS[i]] = true
end

local profiles = {}

-- Comparison functions

local function values_equal(a, b)
	if type(a) == "table" and type(b) == "table" then
		local len_a = #a
		local len_b = #b

		if len_a ~= len_b then
			return false
		end

		for i = 1, len_a do
			if a[i] ~= b[i] then
				return false
			end
		end

		return true
	end

	return a == b
end

-- Field functions

local function is_field(setting_id)
	return FIELD_SET[setting_id] == true
end

local function select_profile(store, head_item_id)
	if not store or not head_item_id then
		return {}
	end

	return store[head_item_id] or {}
end

local function resolve_defaults(defaults, has_lens_colour)
	local result = {}

	for i = 1, #FIELDS do
		local id = FIELDS[i]
		result[id] = defaults[id]
	end

	result.preysight_hue_source = has_lens_colour and "lens" or "fixed"

	return result
end

local function merge(overrides, defaults, fields)
	local result = {}

	for i = 1, #fields do
		local id = fields[i]
		local value = overrides and overrides[id]

		if value == nil then
			result[id] = defaults[id]
		else
			result[id] = value
		end
	end

	return result
end

local function diff(current, target, fields)
	local updates = {}

	for i = 1, #fields do
		local id = fields[i]

		if not values_equal(current[id], target[id]) then
			updates[#updates + 1] = { id = id, value = target[id] }
		end
	end

	return updates
end

local function record_change(store, head_item_id, field, value, default_value)
	if not head_item_id then
		return store, false
	end

	local entry = store[head_item_id]

	if values_equal(value, default_value) then
		if entry and entry[field] ~= nil then
			entry[field] = nil

			if next(entry) == nil then
				store[head_item_id] = nil
			end

			return store, true
		end

		return store, false
	end

	if entry and values_equal(entry[field], value) then
		return store, false
	end

	entry = entry or {}
	entry[field] = value
	store[head_item_id] = entry

	return store, true
end

profiles.FIELDS = FIELDS
profiles.DEFAULTS = DEFAULTS
profiles.values_equal = values_equal
profiles.is_field = is_field
profiles.select_profile = select_profile
profiles.resolve_defaults = resolve_defaults
profiles.merge = merge
profiles.diff = diff
profiles.record_change = record_change

return profiles
