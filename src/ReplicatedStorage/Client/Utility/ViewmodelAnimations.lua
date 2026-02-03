--// Variables

local sin = math.sin
local cos = math.cos

--// Returner

local function GetMovementOffset(speed: number, scale: number)
	local t = os.clock() * speed

	return CFrame.new(
		sin(t) * scale * 0.4,  -- Простое боковое покачивание
		cos(t * 2) * scale * 0.3, -- Выраженное подпрыгивание
		0
	) * CFrame.Angles(
		sin(t) * scale * 0.2,  -- Ритмичное наклонение вперед-назад
		0,
		cos(t) * scale * 0.15  -- Легкое покачивание по Z
	)
end

local function GetIdleOffset(speed: number, scale: number)
	local t = os.clock() * speed * 0.5

	return CFrame.new(
		sin(t) * scale * 0.2,  
		cos(t) * scale * 0.1,  
		0
	) * CFrame.Angles(
		sin(t) * scale * 0.1,  
		0,
		cos(t) * scale * 0.08  
	)
end

return {
	GetMovementOffset = GetMovementOffset,
	GetIdleOffset = GetIdleOffset,
}