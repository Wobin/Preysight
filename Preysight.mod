return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Preysight` encountered an error loading the Darktide Mod Framework.")

		new_mod("Preysight", {
			mod_script       = "Preysight/scripts/mods/Preysight/Preysight",
			mod_data         = "Preysight/scripts/mods/Preysight/Preysight_data",
			mod_localization = "Preysight/scripts/mods/Preysight/Preysight_localization",
		})
	end,
	packages = {},
	load_after = { "SimpleAssets" },
}
