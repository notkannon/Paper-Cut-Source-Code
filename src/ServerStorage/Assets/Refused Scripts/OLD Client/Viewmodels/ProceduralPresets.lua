-- vars
local sin = math.sin
local cos = math.cos

-- initial
local ProceduralPresets = {}

-- returns time-based animation CFrame as Offset of viewmodel to apply
function ProceduralPresets.Idle(speed: number?, scale: number?)
	speed = speed or 1
	scale = scale or 1
	local RotScale = .12
	local PosScale = .2
	local t = os.clock() * speed * .25

	return CFrame.new(
		sin(t * .5) * scale * .3 * PosScale,
		cos(t) * scale * .3 * PosScale,
		sin(t) * scale * .1 * PosScale)

		* CFrame.Angles(
			sin(t * .25) * scale * RotScale,
			cos(t) * scale * RotScale,
			sin(t) * scale * RotScale * .3)
end

-- returns time-based animation CFrame as Offset of viewmodel to apply
function ProceduralPresets.Movement(speed: number?, scale: number?)
	speed = speed or 1
	scale = scale or 1
	local RotScale = .12
	local PosScale = .2
	local t = os.clock() * speed

	return CFrame.new(
		sin(t) * scale * .3 * PosScale,
		cos(t * .5) * scale * .3 * PosScale,
		sin(t) * scale * .3 * PosScale)

		* CFrame.Angles(
			sin(t) * scale * RotScale,
			cos(t * .5) * scale * RotScale,
			sin(t) * scale * RotScale * .4)
end

return ProceduralPresets