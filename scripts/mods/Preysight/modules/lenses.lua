local LENS_PATH = "/lens_primary_colors/"
local HSV_PROPERTY = "emissive_color_hsv_1"

local POSITIVE_TOKENS = {
	"goggle",
	"rebreath",
	"bioniceye",
	"bionic_eye",
	"snout_mask",
	"scions_mask",
	"eye_tech",
	"tech_eye",
	"eye_implant",
	"gasmask",
	"visor",
	"optic",
	"respir",
	"monocle",
	"lens",
}

local NEGATIVE_TOKENS = {
	"eyebrow",
	"eyepatch",
	"eye_patch",
	"eyelash",
	"eye_cover",
	"eyeliner",
	"eyeshadow",
	"eye_color",
	"eye_colour",
}

local MAX_ATTACHMENT_DEPTH = 6
local CRYPTIC = "cryptic"

local EMISSIVE_PATH = "/player_emissive/"

local HUE_WORDS = {
	red = 0.00,
	orange = 0.03,
	yellow = 0.15,
	green = 0.30,
	blue = 0.62,
}

local EMISSIVE_SATURATION = 1.0
local EMISSIVE_VALUE = 0.7

local lenses = {}

local function lens_hsv(defs, colour_item_id)
	if type(colour_item_id) ~= "string" or not defs then
		return nil
	end

	if not colour_item_id:find(LENS_PATH, 1, true) then
		return nil
	end

	local item = defs[colour_item_id]
	local override_items = item and item.material_override_items

	if not override_items then
		return nil
	end

	for _, override_id in ipairs(override_items) do
		local override = defs[override_id]
		local vectors = override and override.vector3_material_overrides

		if vectors then
			for _, entry in ipairs(vectors) do
				if entry.property_name == HSV_PROPERTY then
					local value = entry.value

					if type(value) ~= "table" then
						return nil
					end

					local h = tonumber(value[1])
					local s = tonumber(value[2])
					local v = tonumber(value[3])

					if not h or not s or not v then
						return nil
					end

					return h, s, v
				end
			end
		end
	end

	return nil
end

lenses.lens_hsv = lens_hsv

local function collect_names(defs, item, acc, depth)
	if not item or depth > MAX_ATTACHMENT_DEPTH then
		return
	end

	local base_unit = item.base_unit

	if type(base_unit) == "string" then
		acc[#acc + 1] = base_unit
	end

	local attachments = item.attachments

	if type(attachments) ~= "table" then
		return
	end

	for _, attachment in pairs(attachments) do
		if type(attachment) == "table" then
			local child_id = attachment.item

			if type(child_id) == "string" and child_id ~= "" then
				acc[#acc + 1] = child_id

				collect_names(defs, defs[child_id], acc, depth + 1)
			end

			local children = attachment.children

			if type(children) == "table" then
				for _, child in pairs(children) do
					if type(child) == "table" then
						local nested_id = child.item

						if type(nested_id) == "string" and nested_id ~= "" then
							acc[#acc + 1] = nested_id

							collect_names(defs, defs[nested_id], acc, depth + 1)
						end
					end
				end
			end
		end
	end
end

local function head_has_lenses(defs, head_item_id)
	if not defs or not head_item_id then
		return false
	end

	local item = defs[head_item_id]

	if not item then
		return false
	end

	local names = {}

	collect_names(defs, item, names, 0)

	for i = 1, #names do
		local name = names[i]:lower()
		local negated = false

		for n = 1, #NEGATIVE_TOKENS do
			if name:find(NEGATIVE_TOKENS[n], 1, true) then
				negated = true

				break
			end
		end

		if not negated then
			for p = 1, #POSITIVE_TOKENS do
				if name:find(POSITIVE_TOKENS[p], 1, true) then
					return true
				end
			end
		end
	end

	return false
end

local function qualifies(defs, archetype_name, eye_item_id, head_item_id, taught)
	if archetype_name == CRYPTIC then
		return true
	end

	if type(eye_item_id) == "string" and eye_item_id:find(LENS_PATH, 1, true) then
		return true
	end

	if head_has_lenses(defs, head_item_id) then
		return true
	end

	if head_item_id and taught and taught[head_item_id] then
		return true
	end

	return false
end

-- Headgear emissive hue

local function emissive_colour_word(override_id)
	if type(override_id) ~= "string" or not override_id:find(EMISSIVE_PATH, 1, true) then
		return nil
	end

	local word = override_id:match("emissive_(%a+)_%d+")

	if word and HUE_WORDS[word] then
		return word
	end

	return nil
end

local function item_emissive_word(defs, item_id)
	local item = item_id and defs[item_id]
	local override_items = item and item.material_override_items

	if not override_items then
		return nil
	end

	for _, override_id in ipairs(override_items) do
		local word = emissive_colour_word(override_id)

		if word then
			return word
		end
	end

	return nil
end

local function headgear_colour_word(defs, head_item_id)
	if not defs or not head_item_id then
		return nil
	end

	local item = defs[head_item_id]

	if not item then
		return nil
	end

	local word = item_emissive_word(defs, head_item_id)

	if word then
		return word
	end

	local names = {}

	collect_names(defs, item, names, 0)

	for i = 1, #names do
		word = item_emissive_word(defs, names[i])

		if word then
			return word
		end
	end

	return nil
end

local function headgear_hue(defs, head_item_id)
	local word = headgear_colour_word(defs, head_item_id)

	if not word then
		return nil
	end

	return HUE_WORDS[word], EMISSIVE_SATURATION, EMISSIVE_VALUE
end

lenses.collect_names = collect_names
lenses.head_has_lenses = head_has_lenses
lenses.qualifies = qualifies
lenses.headgear_colour_word = headgear_colour_word
lenses.headgear_hue = headgear_hue

return lenses
