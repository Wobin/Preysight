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

local function rgb_to_hsv(r, g, b)
	local max = r

	if g > max then
		max = g
	end

	if b > max then
		max = b
	end

	local min = r

	if g < min then
		min = g
	end

	if b < min then
		min = b
	end

	local delta = max - min

	if max <= 0 or delta <= 0 then
		return 0, 0, max
	end

	local h

	if max == r then
		h = (g - b) / delta % 6
	elseif max == g then
		h = (b - r) / delta + 2
	else
		h = (r - g) / delta + 4
	end

	return h / 6, delta / max, max
end

colour.hsv_to_rgb = hsv_to_rgb
colour.rgb_to_hsv = rgb_to_hsv

return colour
