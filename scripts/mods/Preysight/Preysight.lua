--[[
	Name: Preysight
	Author: Wobin
	Date: 28/08/2026
	Repository: https://github.com/Wobin/Preysight
]]--

local mod = get_mod("Preysight")
mod.version = mod.get_metadata and mod:get_metadata("version") or "unknown"

mod.colour  = mod.colour  or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/colour")
mod.ramp    = mod.ramp    or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/ramp")
mod.lenses  = mod.lenses  or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/lenses")
mod.optics  = mod.optics  or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/optics")
mod.overlay = mod.overlay or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/overlay")
mod.assets  = mod.assets  or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/assets")
mod.illuminator = mod.illuminator or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/illuminator")
mod.profiles = mod.profiles or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/profiles")
mod.audio = mod.audio or mod:io_dofile("Preysight/scripts/mods/Preysight/modules/audio")

local MutatorUtility = require("scripts/utilities/mutator/mutator_utility")
local MasterItems = require("scripts/backend/master_items")

local Managers = Managers

local UPDATE_INTERVAL = 0.25
local TEACH_SETTING_ID = "preysight_teach_head"
local HUE_SETTING_ID = "preysight_hue_source"
local OPTIONS_VIEW = "dmf_options_view"
local SWATCH_BLOCK = string.char(0xE2, 0x96, 0xA0)
local SWATCH_SIZE = 60

local math_floor = math.floor
local PROFILES_SETTING_ID = "preysight_profiles"

local COSMETIC_SLOTS = {
	slot_gear_head = true,
	slot_body_eye_color = true,
	slot_body_eye_color_secondary = true,
}

local LEFT_GAMEPLAY_STATES = {
	StateLoading = true,
	StateMainMenu = true,
	StateExitToMainMenu = true,
	StateTitle = true,
}

-- ─────────────────────────────────────────────────────────────────────

mod.qualified = false
mod.user_disabled = false

local DEFAULT = mod.profiles.DEFAULTS

local _always_on = false
local _mute_sound = false
local _exposure = DEFAULT.preysight_exposure
local _greyscale = DEFAULT.preysight_greyscale
local _blur = DEFAULT.preysight_blur
local _blend_in = DEFAULT.preysight_blend_in
local _blend_out = DEFAULT.preysight_blend_out
local _wash_alpha = DEFAULT.preysight_wash_alpha
local _scanline_alpha = DEFAULT.preysight_scanline_alpha
local _grain_alpha = DEFAULT.preysight_grain_alpha
local _vignette_alpha = DEFAULT.preysight_vignette_alpha
local _hue_source = DEFAULT.preysight_hue_source
local _fixed_r = DEFAULT.preysight_fixed_colour[2] / 255
local _fixed_g = DEFAULT.preysight_fixed_colour[3] / 255
local _fixed_b = DEFAULT.preysight_fixed_colour[4] / 255
local _taught = {}
local _profiles = {}
local _write_guard = false

local _illuminator_enabled = DEFAULT.preysight_illuminator
local _illuminator_intensity = DEFAULT.preysight_illuminator_intensity
local _illuminator_range = DEFAULT.preysight_illuminator_range
local _illuminator_offset = DEFAULT.preysight_illuminator_offset
local _illuminator_height = DEFAULT.preysight_illuminator_height

local _lens_h, _lens_s, _lens_v = nil, nil, nil
local _lens2_h, _lens2_s, _lens2_v = nil, nil, nil
local _has_lens_colour = false
local _has_secondary_lens = false

local _cached_archetype = nil
local _cached_head_id = nil
local _cached_eye_id = nil
local _cached_eye2_id = nil

local _mgb_active = false
local _accum = 0

-- ─────────────────────────────────────────────────────────────────────

local function update_colour()
	local r, g, b

	if _hue_source == "lens_secondary" and _lens2_h then
		r, g, b = mod.colour.hsv_to_rgb(_lens2_h, _lens2_s, _lens2_v)
	elseif _hue_source == "lens" and _lens_h then
		r, g, b = mod.colour.hsv_to_rgb(_lens_h, _lens_s, _lens_v)
	else
		r, g, b = _fixed_r, _fixed_g, _fixed_b
	end

	mod.overlay.set_colour(r, g, b)
end

local function apply_tuning()
	mod.optics.set_tuning(_exposure, _blur, _greyscale, _blend_in, _blend_out)
	mod.overlay.set_alphas(_wash_alpha, _scanline_alpha, _grain_alpha, _vignette_alpha)
	mod.illuminator.set_tuning(_illuminator_intensity, _illuminator_range)
	mod.illuminator.set_offset(_illuminator_offset, _illuminator_height)
	mod.audio.set_muted(_mute_sound)
end

local function refresh_settings()
	_always_on = mod:get("preysight_always_on") == true
	_mute_sound = mod:get("preysight_mute_sound") == true
	_exposure = mod:get("preysight_exposure") or DEFAULT.preysight_exposure
	_greyscale = mod:get("preysight_greyscale") or DEFAULT.preysight_greyscale
	_blur = mod:get("preysight_blur") or DEFAULT.preysight_blur
	_blend_in = mod:get("preysight_blend_in") or DEFAULT.preysight_blend_in
	_blend_out = mod:get("preysight_blend_out") or DEFAULT.preysight_blend_out
	_wash_alpha = mod:get("preysight_wash_alpha") or DEFAULT.preysight_wash_alpha
	_scanline_alpha = mod:get("preysight_scanline_alpha") or DEFAULT.preysight_scanline_alpha
	_grain_alpha = mod:get("preysight_grain_alpha") or DEFAULT.preysight_grain_alpha
	_vignette_alpha = mod:get("preysight_vignette_alpha") or DEFAULT.preysight_vignette_alpha
	_hue_source = mod:get("preysight_hue_source") or DEFAULT.preysight_hue_source

	local illuminator_setting = mod:get("preysight_illuminator")

	_illuminator_enabled = illuminator_setting ~= false
	_illuminator_intensity = mod:get("preysight_illuminator_intensity") or DEFAULT.preysight_illuminator_intensity
	_illuminator_range = mod:get("preysight_illuminator_range") or DEFAULT.preysight_illuminator_range
	_illuminator_offset = mod:get("preysight_illuminator_offset") or DEFAULT.preysight_illuminator_offset
	_illuminator_height = mod:get("preysight_illuminator_height") or DEFAULT.preysight_illuminator_height

	local fixed_colour = mod:get("preysight_fixed_colour")

	if type(fixed_colour) ~= "table" then
		fixed_colour = DEFAULT.preysight_fixed_colour
	end

	_fixed_r = (fixed_colour[2] or DEFAULT.preysight_fixed_colour[2]) / 255
	_fixed_g = (fixed_colour[3] or DEFAULT.preysight_fixed_colour[3]) / 255
	_fixed_b = (fixed_colour[4] or DEFAULT.preysight_fixed_colour[4]) / 255

	local taught = mod:get("preysight_taught_heads")

	_taught = type(taught) == "table" and taught or {}

	local stored_profiles = mod:get(PROFILES_SETTING_ID)

	_profiles = type(stored_profiles) == "table" and stored_profiles or {}

	apply_tuning()
	update_colour()
end

-- ─────────────────────────────────────────────────────────────────────

local INVENTORY_VIEWS = {
	"inventory_cosmetics_view",
	"inventory_background_view",
}

local function master_item_name(entry)
	if type(entry) ~= "table" then
		return nil
	end

	local master = rawget(entry, "__master_item")
	local id = master and rawget(master, "name")

	if type(id) == "string" and id ~= "" then
		return id
	end

	return nil
end

local function view_equipped_ids()
	local ui = Managers.ui

	if not ui or not ui.view_active or not ui.has_active_view then
		return nil, nil
	end

	if not ui:has_active_view() then
		return nil, nil
	end

	for i = 1, #INVENTORY_VIEWS do
		local name = INVENTORY_VIEWS[i]

		if ui:view_active(name) then
			local view = ui:view_instance(name)
			local equipped = view and rawget(view, "_current_profile_equipped_items")

			if type(equipped) == "table" then
				local head = master_item_name(rawget(equipped, "slot_gear_head"))
				local eye = master_item_name(rawget(equipped, "slot_body_eye_color"))

				if head then
					return head, eye
				end
			end
		end
	end

	return nil, nil
end

local function resolve_loadout_ids()
	local player = Managers.player and Managers.player:local_player_safe(1)

	if not player then
		return nil, nil, nil
	end

	local profile = player:profile()

	if not profile or not profile.archetype then
		return nil, nil, nil
	end

	local archetype_name = profile.archetype.name
	local loadout = profile.loadout
	local head_item = loadout and loadout.slot_gear_head
	local eye_item = loadout and loadout.slot_body_eye_color
	local eye2_item = loadout and loadout.slot_body_eye_color_secondary
	local head_id = head_item and head_item.name
	local eye_id = eye_item and eye_item.name
	local eye2_id = eye2_item and eye2_item.name

	local view_head, view_eye = view_equipped_ids()

	if view_head then
		head_id = view_head
		eye_id = view_eye or eye_id
	end

	return archetype_name, head_id, eye_id, eye2_id
end

-- Profile functions

local function apply_profile_for_head(head_item_id, has_lens_colour)
	local first_run = mod:get(PROFILES_SETTING_ID) == nil

	local current = {}

	for i = 1, #mod.profiles.FIELDS do
		local id = mod.profiles.FIELDS[i]
		current[id] = mod:get(id)
	end

	if first_run then
		_profiles[head_item_id] = mod.profiles.merge(current, mod.profiles.DEFAULTS, mod.profiles.FIELDS)
		mod:set(PROFILES_SETTING_ID, _profiles)
	end

	local profile = mod.profiles.select_profile(_profiles, head_item_id)
	local defaults = mod.profiles.resolve_defaults(mod.profiles.DEFAULTS, has_lens_colour)
	local target = mod.profiles.merge(profile, defaults, mod.profiles.FIELDS)
	local updates = mod.profiles.diff(current, target, mod.profiles.FIELDS)

	if #updates == 0 then
		return
	end

	_write_guard = true

	for i = 1, #updates do
		mod:set(updates[i].id, updates[i].value)
	end

	_write_guard = false

	refresh_settings()
end

local function handle_profile_field_changed(setting_id)
	local value = mod:get(setting_id)
	local defaults = mod.profiles.resolve_defaults(mod.profiles.DEFAULTS, _has_lens_colour)
	local default_value = defaults[setting_id]
	local _, changed = mod.profiles.record_change(_profiles, _cached_head_id, setting_id, value, default_value)

	if changed then
		mod:set(PROFILES_SETTING_ID, _profiles)
	end
end

-- Teach widget functions

local function find_widget(list, target)
	if type(list) ~= "table" then
		return nil
	end

	for _, w in ipairs(list) do
		if type(w) == "table" then
			if w.setting_id == target then
				return w
			end

			local found = find_widget(w.sub_widgets, target) or find_widget(w.widgets, target)

			if found then
				return found
			end
		end
	end

	return nil
end

local function live_content(target)
	local ui = Managers.ui

	if not ui or not ui.view_active or not ui.view_instance then
		return nil
	end

	if not ui:view_active(OPTIONS_VIEW) then
		return nil
	end

	local view = ui:view_instance(OPTIONS_VIEW)
	local list = view and rawget(view, "_settings_content_widgets")

	if type(list) ~= "table" then
		return nil
	end

	for i = 1, #list do
		local widget = list[i]
		local content = widget and rawget(widget, "content")
		local entry = content and rawget(content, "entry")

		if entry and rawget(entry, "setting_id") == target then
			return content
		end
	end

	return nil
end

local function widget_by_id(target)
	local dmf = get_mod("DMF")

	if not dmf or not dmf.options_widgets_data then
		return nil
	end

	for _, entry in ipairs(dmf.options_widgets_data) do
		local found = find_widget(entry, target)

		if found then
			return found
		end
	end

	return nil
end

local function set_teach_widget_title(text, tooltip)
	local widget = widget_by_id(TEACH_SETTING_ID)

	if not widget then
		return
	end

	widget.title = text
	widget.tooltip = tooltip

	local live = live_content(TEACH_SETTING_ID)

	if live then
		live.text = text
	end
end

local function swatch(r, g, b)
	if not r or not g or not b then
		return ""
	end

	return string.format("{#size(%d);color(%d,%d,%d)}%s{#reset()} ",
		SWATCH_SIZE, math_floor(r * 255), math_floor(g * 255), math_floor(b * 255), SWATCH_BLOCK)
end

local function hsv_swatch(h, s, v)
	if not h then
		return ""
	end

	return swatch(mod.colour.hsv_to_rgb(h, s, v))
end

local function apply_dropdown_options(setting_id, options)
	local widget = widget_by_id(setting_id)

	if widget then
		widget.options = options
	end

	local live = live_content(setting_id)
	local live_options = live and rawget(live, "options")

	if type(live_options) ~= "table" or #live_options ~= #options then
		return
	end

	for i = 1, #options do
		live_options[i].display_name = options[i].text
		live_options[i].text = options[i].text
	end
end

local function auto_suffix(defs, head_item_id, archetype_name)
	if mod.lenses.is_skitarii(archetype_name) then
		return mod:localize("preysight_teach_head_auto_skitarii")
	end

	if head_item_id and mod.lenses.head_has_lenses(defs, head_item_id) then
		return mod:localize("preysight_teach_head_auto_detected")
	end

	return mod:localize("preysight_teach_head_auto_undetected")
end

local function sync_hue_options(archetype_name)
	local skitarii = mod.lenses.is_skitarii(archetype_name)
	local options = {}

	options[#options + 1] = {
		text = hsv_swatch(_lens_h, _lens_s, _lens_v)
			.. mod:localize(skitarii and "preysight_hue_source_lens_primary" or "preysight_hue_source_lens"),
		value = "lens",
	}

	if skitarii then
		options[#options + 1] = {
			text = hsv_swatch(_lens2_h, _lens2_s, _lens2_v)
				.. mod:localize("preysight_hue_source_lens_secondary"),
			value = "lens_secondary",
		}
	end

	options[#options + 1] = {
		text = swatch(_fixed_r, _fixed_g, _fixed_b) .. mod:localize("preysight_hue_source_fixed"),
		value = "fixed",
		show_widgets = { 1 },
	}

	apply_dropdown_options(HUE_SETTING_ID, options)
end

local function sync_teach_options(defs, head_item_id, archetype_name)
	local options = {
		{ text = mod:localize("preysight_teach_head_auto") .. auto_suffix(defs, head_item_id, archetype_name), value = "auto" },
		{ text = mod:localize("preysight_teach_head_on"), value = "on" },
		{ text = mod:localize("preysight_teach_head_off"), value = "off" },
	}

	apply_dropdown_options(TEACH_SETTING_ID, options)
end

local function set_teach_widget_value(value)
	_write_guard = true
	mod:set(TEACH_SETTING_ID, value)
	_write_guard = false
end

local function stored_to_option(stored)
	if stored == true then
		return "on"
	end

	if stored == false then
		return "off"
	end

	return "auto"
end

local function option_to_stored(option)
	if option == "on" then
		return true
	end

	if option == "off" then
		return false
	end

	return nil
end

local function resolve_teach_label(defs, head_item_id)
	if not head_item_id or not defs then
		return mod:localize("preysight_teach_head_no_headgear")
	end

	local item = defs[head_item_id]
	local display_key = item and item.display_name

	if not display_key then
		return mod:localize("preysight_teach_head_no_headgear")
	end

	return Localize(display_key)
end

local function detection_note(defs, head_item_id, archetype_name)
	if mod.lenses.is_skitarii(archetype_name) then
		return mod:localize("preysight_teach_head_note_skitarii")
	end

	if head_item_id and mod.lenses.head_has_lenses(defs, head_item_id) then
		return mod:localize("preysight_teach_head_note_detected")
	end

	return mod:localize("preysight_teach_head_note_undetected")
end

local function sync_teach_widget(defs, head_item_id, archetype_name)
	local label = resolve_teach_label(defs, head_item_id)
	local tooltip = label
		.. "\n" .. mod:localize("preysight_teach_head_tooltip")
		.. "\n\n" .. detection_note(defs, head_item_id, archetype_name)

	sync_hue_options(archetype_name)
	sync_teach_options(defs, head_item_id, archetype_name)
	set_teach_widget_title(label, tooltip)

	local stored = head_item_id and _taught[head_item_id]

	set_teach_widget_value(stored_to_option(stored))
end

local function refresh_qualification(force)
	local archetype_name, head_item_id, eye_item_id, eye2_item_id = resolve_loadout_ids()

	if not force
		and archetype_name == _cached_archetype
		and head_item_id == _cached_head_id
		and eye_item_id == _cached_eye_id
		and eye2_item_id == _cached_eye2_id then
		return
	end

	_cached_archetype = archetype_name
	_cached_head_id = head_item_id
	_cached_eye_id = eye_item_id
	_cached_eye2_id = eye2_item_id

	local defs = MasterItems.get_cached()

	if not archetype_name or not defs then
		mod.qualified = false
		_lens_h, _lens_s, _lens_v = nil, nil, nil
		_lens2_h, _lens2_s, _lens2_v = nil, nil, nil
		_has_lens_colour = false
		_has_secondary_lens = false
		update_colour()
		sync_teach_widget(nil, nil, nil)

		return
	end

	_lens_h, _lens_s, _lens_v = mod.lenses.lens_hsv(defs, eye_item_id)
	_lens2_h, _lens2_s, _lens2_v = mod.lenses.lens_hsv(defs, eye2_item_id)

	if not _lens_h then
		_lens_h, _lens_s, _lens_v = mod.lenses.headgear_hue(defs, head_item_id)
	end

	_has_lens_colour = _lens_h ~= nil
	_has_secondary_lens = _lens2_h ~= nil

	if head_item_id then
		apply_profile_for_head(head_item_id, _has_lens_colour)
	end

	mod.qualified = mod.lenses.qualifies(defs, archetype_name, eye_item_id, head_item_id, _taught)

	update_colour()
	sync_teach_widget(defs, head_item_id, archetype_name)
end

-- ─────────────────────────────────────────────────────────────────────

local function check_machine_gods_beacon()
	local beacon = get_mod("machine_gods_beacon")

	if beacon and beacon.is_enabled and beacon:is_enabled() then
		_mgb_active = true

		mod:info("Machine God's Beacon detected and enabled. Darkness auto-detection disabled, use Always On to arm Preysight.")
	end
end

local function should_be_on()
	if not mod.qualified or mod.user_disabled or not mod:is_enabled() then
		return false
	end

	if _always_on then
		return true
	end

	if _mgb_active then
		return false
	end

	return MutatorUtility.is_current_level_dark() == true
end

local function tick(dt)
	_accum = _accum + dt

	if _accum < UPDATE_INTERVAL then
		return
	end

	_accum = 0

	mod.assets.ensure_loaded()
	refresh_qualification(false)

	local on = should_be_on()

	mod.optics.set_target(on and 1 or 0)
	mod.audio.set_active(on)
end

-- ─────────────────────────────────────────────────────────────────────

mod._kb_toggle = function()
	mod.user_disabled = not mod.user_disabled

	mod:info("Preysight " .. (mod.user_disabled and "disabled" or "enabled") .. " by keybind")
end

local function handle_teach_toggle()
	local head_item_id = _cached_head_id

	if not head_item_id then
		set_teach_widget_value("auto")

		return
	end

	local option = mod:get(TEACH_SETTING_ID)

	_taught[head_item_id] = option_to_stored(option)

	mod:set("preysight_taught_heads", _taught)
	refresh_qualification(true)

	mod:info("Preysight: headgear " .. head_item_id .. " set to " .. tostring(option))
end

mod.on_setting_changed = function(setting_id)
	if _write_guard then
		return
	end

	if setting_id == TEACH_SETTING_ID then
		handle_teach_toggle()

		return
	end

	if mod.profiles.is_field(setting_id) then
		handle_profile_field_changed(setting_id)
	end

	refresh_settings()
end

mod._forget_taught = function()
	local head_item_id = _cached_head_id

	if not head_item_id then
		mod:info("Preysight: no headgear equipped, nothing to reset")

		return
	end

	_taught[head_item_id] = nil
	_profiles[head_item_id] = nil

	mod:set("preysight_taught_heads", _taught)
	mod:set(PROFILES_SETTING_ID, _profiles)
	refresh_qualification(true)

	mod:info("Preysight: reset headgear " .. head_item_id)
end

-- ─────────────────────────────────────────────────────────────────────

mod.on_all_mods_loaded = function()
	mod:info("Preysight " .. tostring(mod.version) .. " loaded")
	mod.optics.install(mod)
	mod.overlay.install(mod)
	mod.assets.ensure_loaded()

	refresh_settings()
	check_machine_gods_beacon()

	mod:hook_safe("InventoryCosmeticsView", "_equip_item", function (_, slot_name)
		if COSMETIC_SLOTS[slot_name] then
			refresh_qualification(true)
		end
	end)
end

mod.update = function(dt)
	mod.optics.update(dt)
	tick(dt)

	local illuminator_active = _illuminator_enabled and not mod.user_disabled and mod:is_enabled()

	mod.illuminator.update(dt, illuminator_active, mod.optics.weight())
	mod.audio.update(dt)
end

mod.on_enabled = function()
	mod.overlay.enable_element()
end

mod.on_disabled = function()
	mod.optics.set_target(0)
	mod.audio.silence()
	mod.illuminator.destroy()
	mod.overlay.disable_element()
end

mod.on_unload = function()
	mod.optics.set_target(0)
	mod.audio.silence()
	mod.illuminator.destroy()
	mod.illuminator.release_package()
	mod.overlay.disable_element()
end

mod.on_game_state_changed = function(status, state_name)
	if status == "enter" and LEFT_GAMEPLAY_STATES[state_name] then
		mod.audio.silence()
		mod.illuminator.destroy()
		mod.optics.arm_intro()
	end
end
