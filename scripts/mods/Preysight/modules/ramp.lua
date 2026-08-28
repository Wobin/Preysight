local math_min = math.min
local math_max = math.max

local ramp = {}

local function step(current, target, dt, blend_in, blend_out)
	if current == target then
		return target
	end

	local rising = target > current
	local duration = rising and blend_in or blend_out

	if not duration or duration <= 0 then
		return target
	end

	local delta = dt / duration

	if rising then
		return math_min(target, current + delta)
	end

	return math_max(target, current - delta)
end

ramp.step = step

return ramp
