--[[
	Responsible for threads
--]]

--//Variables

local FreeThread = nil

--//Functions

local function FunctionPasser(func, ...)
	local Thread = FreeThread
	FreeThread = nil
	func(...)

	FreeThread = Thread
end

local function Yielder()
	while true do
		FunctionPasser(coroutine.yield())
	end
end

local function UseThread(fn, ...)
	if not FreeThread then
		FreeThread = coroutine.create(Yielder)
		coroutine.resume(FreeThread)
	end
	
	task.spawn(FreeThread, fn, ...)
end

--//Returner

return {
	UseThread = UseThread,
}