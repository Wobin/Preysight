local math_floor = math.floor

local colour = {}

local function hsv_to_rgb(h, s, v)
	if s <= 0 then
		return v, v, v
	end

	local sector = h * 6
	local index = math_floor(sector) % 6
	local frac = sector - math_floor(sector)
	local p = v * (1 - s)
	local q = v * (1 - frac * s)
	local t = v * (1 - (1 - frac) * s)

	if index == 0 then
		return v, t, p
	elseif index == 1 then
		return q, v, p
	elseif index == 2 then
		return p, v, t
	elseif index == 3 then
		return p, q, v
	elseif index == 4 then
		return t, p, v
	end

	return v, p, q
end

colour.hsv_to_rgb = hsv_to_rgb

return colour
