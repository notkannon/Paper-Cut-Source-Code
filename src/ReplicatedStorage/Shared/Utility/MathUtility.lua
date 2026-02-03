--[[
	Makes math-related stuff easier to use
	Merged with LerpUtility
--]]

--//Functions

local function Lerp(startValue: number, endValue: number)
	return function(time: number)
		return startValue * (1 - time) + endValue * time
	end
end

local function QuickLerp(startValue: number, endValue: number, time: number)
	return startValue * (1 - time) + endValue * time
end

--//Returner

return {
	Lerp = Lerp,
	QuickLerp = QuickLerp,
}
