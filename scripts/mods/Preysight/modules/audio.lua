local audio = {}

local ON_BLIP = "wwise/events/player/play_ability_cryptic_voltaic_buff_loop"
local BED     = "wwise/events/player/play_device_auspex_scanner_minigame_sinus_background_loop"
local OFF_CUE = "wwise/events/ui/play_ui_npc_interacts_havoc_terminal_exit"

local BLIP_SECONDS = 2.7

local _active = false
local _muted = false
local _suppressed = false
local _bed_id = nil
local _blip_id = nil
local _blip_left = 0

-- ─────────────────────────────────────────────────────────────────────
-- Playback helpers
-- ─────────────────────────────────────────────────────────────────────

local function play(event)
	local ui = Managers and Managers.ui

	if _muted or not ui or not ui.play_2d_sound then
		return nil
	end

	local id = ui:play_2d_sound(event)

	if id then
		return id
	end

	return nil
end

local function stop(id)
	local ui = Managers and Managers.ui

	if not id or not ui or not ui.stop_2d_sound then
		return
	end

	ui:stop_2d_sound(id)
end

-- ─────────────────────────────────────────────────────────────────────
-- Transitions
-- ─────────────────────────────────────────────────────────────────────

local function power_on()
	if _suppressed then
		return
	end

	stop(_blip_id)

	_blip_id = play(ON_BLIP)
	_blip_left = BLIP_SECONDS

	if not _bed_id then
		_bed_id = play(BED)
	end
end

local function power_off(with_cue)
	stop(_blip_id)
	_blip_id = nil
	_blip_left = 0

	stop(_bed_id)
	_bed_id = nil

	if with_cue then
		play(OFF_CUE)
	end
end

audio.set_active = function(active)
	local want = active and true or false

	if want == _active then
		return
	end

	_active = want

	if want then
		power_on()
	else
		power_off(true)
	end
end

local function view_is_open()
	local ui = Managers and Managers.ui

	if not ui or not ui.has_active_view then
		return false
	end

	return ui:has_active_view() == true
end

audio.update = function(dt)
	local hidden = view_is_open()

	if hidden ~= _suppressed then
		_suppressed = hidden

		if _suppressed then
			stop(_blip_id)
			_blip_id = nil
			_blip_left = 0

			stop(_bed_id)
			_bed_id = nil
		elseif _active then
			_bed_id = play(BED)
		end
	end

	if _suppressed or _blip_left <= 0 then
		return
	end

	_blip_left = _blip_left - dt

	if _blip_left <= 0 then
		stop(_blip_id)
		_blip_id = nil
		_blip_left = 0
	end
end

audio.set_muted = function(muted)
	local want = muted and true or false

	if want == _muted then
		return
	end

	_muted = want

	if _muted then
		stop(_blip_id)
		_blip_id = nil
		_blip_left = 0

		stop(_bed_id)
		_bed_id = nil
	elseif _active then
		_bed_id = play(BED)
	end
end

audio.silence = function()
	_active = false

	power_off(false)
end

audio.is_active = function()
	return _active
end

return audio
