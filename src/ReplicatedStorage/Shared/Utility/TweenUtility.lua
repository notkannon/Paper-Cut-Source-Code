--//Services

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Imports

local ThreadUtility = require(script.Parent.ThreadUtility)

--//Variables

local InstanceTweens = {} :: {[Instance]: {MyTween?}}

--//types

type MyTween = {
	Instance: Tween,
	Valid: boolean
}

--//Functions

local function DestroyMytween(tweensTable: {MyTween?}, myTween: MyTween)
	local Found = table.find(tweensTable, myTween)
	
	if Found then
		table.remove(tweensTable, Found)
	end
	
	myTween.Instance:Cancel()
	myTween.Instance:Destroy()
	myTween.Valid = false
	
	table.clear(myTween)
end

local function ClearAllTweens(instance: Instance)
	local Tweens = InstanceTweens[instance]
	
	if not Tweens then
		return
	end
	
	while #Tweens ~= 0 do
		DestroyMytween(Tweens, Tweens[1])
	end
end

local function PlayTween(instance: Instance, tweenInfo: TweenInfo, props: { [string]: any }, onEnd: ((Enum.TweenStatus) -> ())?, delay_playback: number?)
	local TweensTable = InstanceTweens[instance]
	
	if not TweensTable then
		InstanceTweens[instance] = {}
		TweensTable = InstanceTweens[instance]
	end
	
	local Tween = TweenService:Create(instance, tweenInfo, props)
	
	local MyTween = {
		Instance = Tween,
		Valid = true
	}
	
	table.insert(TweensTable, MyTween)
	
	if not delay_playback then
		Tween:Play()
	else
		task.delay(delay_playback, pcall, function()
			if not Tween or not MyTween.Valid then
				return
			end
			
			Tween:Play()
		end)
	end
	
	Tween.Completed:Once(function(...)
		if onEnd then
			onEnd(...)
		end
		
		if MyTween.Valid then
			DestroyMytween(TweensTable, MyTween)
		end
	end)

	return Tween
end

local function WaitForTween(tween: Tween, delayAfter: number?)
	tween.Completed:Wait()

	if delayAfter then
		task.wait(delayAfter)
	end
end

local function TweenStep(tweenInfo: TweenInfo, onStep: (time: number) -> (), onEnd: (() -> ())?)
	local Start = os.clock()
	local Connection

	local function Disconnect()
		if onEnd then
			ThreadUtility.UseThread(onEnd)
		end
		Connection:Disconnect()
	end

	Connection = RunService.Heartbeat:Connect(function()
		local TimeElasped = math.min((os.clock() - Start) / tweenInfo.Time, 1)
		local Value = TweenService:GetValue(TimeElasped, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

		onStep(Value)

		if TimeElasped >= 1 then
			Disconnect()
		end
	end)

	return Disconnect
end

--//Returner

return {
	PlayTween = PlayTween,
	TweenStep = TweenStep,
	WaitForTween = WaitForTween,
	ClearAllTweens = ClearAllTweens,
}
