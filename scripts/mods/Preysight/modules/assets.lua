local mod = get_mod("Preysight")

local Gui = Gui
local Material = Material

local assets = {}

local ASSET_ROOT = "mods/Preysight/assets/"
local SCANLINE_FILE = "scanline.png"
local GRAIN_FILE = "grain.png"
local BASE_MATERIAL = "content/ui/materials/backgrounds/default_square"
local TEXTURE_SLOT = "texture_map"

local _requested = false

local _scanline_texture = nil
local _grain_texture = nil

local function load_texture(path, on_ready)
	local SimpleAssets = get_mod("SimpleAssets")

	if not (SimpleAssets and type(SimpleAssets.load_texture) == "function") then
		return
	end

	local promise = SimpleAssets.load_texture(path)

	if not (promise and type(promise.next) == "function") then
		mod:error("Preysight: SimpleAssets.load_texture did not return a promise for %s", path)

		return
	end

	promise:next(function (res)
		if res and res.is_ok and res.texture then
			on_ready(res.texture)
		else
			mod:error("Preysight: %s loaded but returned no texture", path)
		end
	end, function (err)
		mod:error("Preysight: failed to load %s (%s)", path, err and err.error or "unknown error")
	end)
end

local function request_textures()
	load_texture(ASSET_ROOT .. SCANLINE_FILE, function (texture)
		_scanline_texture = texture
	end)

	load_texture(ASSET_ROOT .. GRAIN_FILE, function (texture)
		_grain_texture = texture
	end)
end

assets.ensure_loaded = function ()
	if _requested then
		return
	end

	local backend = Managers and Managers.backend

	if not backend or type(backend.authenticate) ~= "function" then
		return
	end

	local promise = backend:authenticate()

	if not (promise and type(promise.next) == "function") then
		return
	end

	_requested = true

	promise:next(request_textures, function (err)
		_requested = false

		mod:error("Preysight: backend authentication failed, textures deferred (%s)",
			err and err.error or "unknown error")
	end)
end

assets.scanline_texture = function ()
	return _scanline_texture
end

assets.grain_texture = function ()
	return _grain_texture
end

assets.build_material = function (gui, texture)
	if not (gui and texture) then
		return nil
	end

	local material = Gui.create_material(gui, BASE_MATERIAL)

	Material.set_resource(material, TEXTURE_SLOT, texture)

	return material
end

return assets
