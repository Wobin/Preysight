return {
	mod_name = {
		en = "Preysight",
	},
	mod_description = {
		en = "Night vision for characters with augmetic lenses.",
	},

	preysight_general_group = {
		en = "General",
	},
	preysight_keybind_toggle = {
		en = "Toggle Preysight",
	},
	preysight_keybind_toggle_tooltip = {
		en = "Turn the effect off or back on mid-mission.",
	},
	preysight_always_on = {
		en = "Always on",
	},
	preysight_always_on_tooltip = {
		en = "Keep the effect active in every mission instead of only in darkness conditions.",
	},
	preysight_mute_sound = {
		en = "Mute sound",
	},
	preysight_mute_sound_tooltip = {
		en = "Silence the power-up whine, the running hum and the shutdown cue. The visual effect is unchanged.",
	},

	preysight_tuning_group = {
		en = "Tuning",
	},
	preysight_exposure = {
		en = "Exposure lift",
	},
	preysight_exposure_tooltip = {
		en = "How much the shadows are brightened. 4.0 and above blows out the highlights.",
	},
	preysight_greyscale = {
		en = "Greyscale amount",
	},
	preysight_greyscale_tooltip = {
		en = "How fully the world desaturates. The HUD and outlines are never affected.",
	},
	preysight_blur = {
		en = "Fullscreen blur",
	},
	preysight_blur_tooltip = {
		en = "Soft image-intensifier blur over the world.",
	},
	preysight_blend_in = {
		en = "Blend in time",
	},
	preysight_blend_in_tooltip = {
		en = "Seconds to ramp the effect up once it activates.",
	},
	preysight_blend_out = {
		en = "Blend out time",
	},
	preysight_blend_out_tooltip = {
		en = "Seconds to ramp the effect down once it deactivates.",
	},

	preysight_overlay_group = {
		en = "Overlay",
	},
	preysight_wash_alpha = {
		en = "Hue wash strength",
	},
	preysight_wash_alpha_tooltip = {
		en = "Opacity of the coloured tint drawn beneath the HUD.",
	},
	preysight_scanline_alpha = {
		en = "Scanline strength",
	},
	preysight_scanline_alpha_tooltip = {
		en = "Opacity of the scanline overlay.",
	},
	preysight_grain_alpha = {
		en = "Grain strength",
	},
	preysight_grain_alpha_tooltip = {
		en = "Opacity of the noise overlay.",
	},
	preysight_vignette_alpha = {
		en = "Vignette strength",
	},
	preysight_vignette_alpha_tooltip = {
		en = "Opacity of the edge darkening.",
	},
	preysight_hue_source = {
		en = "Hue source",
	},
	preysight_hue_source_tooltip = {
		en = "Drive the tint from whatever you are wearing, a lens colour item or coloured headgear, or always use the fixed colour below.",
	},
	preysight_hue_source_lens = {
		en = "Lens or headgear colour",
	},
	preysight_hue_source_lens_primary = {
		en = "Primary lens colour",
	},
	preysight_hue_source_lens_secondary = {
		en = "Secondary lens colour",
	},
	preysight_hue_source_fixed = {
		en = "Fixed colour",
	},
	preysight_fixed_colour = {
		en = "Fixed colour",
	},

	preysight_illuminator_group = {
		en = "Illuminator",
	},
	preysight_illuminator = {
		en = "Forward light",
	},
	preysight_illuminator_tooltip = {
		en = "Cast a modest light ahead while active, so darkness genuinely recedes instead of only looking brighter.",
	},
	preysight_illuminator_intensity = {
		en = "Light strength",
	},
	preysight_illuminator_intensity_tooltip = {
		en = "Brightness of the forward light. Keep it low; this is a clarity aid, not a floodlight.",
	},
	preysight_illuminator_range = {
		en = "Light reach",
	},
	preysight_illuminator_range_tooltip = {
		en = "How far the light falls off, in metres.",
	},
	preysight_illuminator_offset = {
		en = "Light offset",
	},
	preysight_illuminator_offset_tooltip = {
		en = "Distance from the head, in metres. Positive is ahead of the player, negative is behind.",
	},
	preysight_illuminator_height = {
		en = "Light height",
	},
	preysight_illuminator_height_tooltip = {
		en = "Height above the head, in metres. Negative sits below it.",
	},

	preysight_headgear_group = {
		en = "Headgear",
	},
	preysight_teach_head = {
		en = "No headgear detected",
	},
	preysight_teach_head_tooltip = {
		en = "Whether the headgear named above counts as lensed. Automatic uses the detector, which misses roughly four head items in five. Always on marks it lensed by hand; Never excludes it even if the detector finds lenses. The label always shows whatever head item you currently have equipped, and each headgear remembers its own choice.",
	},
	preysight_teach_head_no_headgear = {
		en = "No headgear detected",
	},
	preysight_teach_head_note_detected = {
		en = "Detector: lenses found on this headgear.",
	},
	preysight_teach_head_note_undetected = {
		en = "Detector: no lenses found on this headgear. Choose Always on to use it anyway.",
	},
	preysight_teach_head_note_skitarii = {
		en = "Skitarii always qualify by augmetics, whatever this is set to.",
	},

	preysight_teach_head_auto = {
		en = "Automatic",
	},
	preysight_teach_head_auto_detected = {
		en = " - lenses detected",
	},
	preysight_teach_head_auto_undetected = {
		en = " - NO lenses detected",
	},
	preysight_teach_head_auto_skitarii = {
		en = " - Skitarii augmetics",
	},
	preysight_teach_head_on = {
		en = "Always on",
	},
	preysight_teach_head_off = {
		en = "Never",
	},

	preysight_forget_taught = {
		en = "Reset this headgear",
	},
	preysight_forget_taught_tooltip = {
		en = "Hold to clear the settings for the headgear you are wearing, returning it to defaults. Other headgear is untouched.",
	},
}
