--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)

--//Variables

local TimerState = table.freeze({
	NotRunning = 1,
	Running = 2,
	Paused = 3,
})

local Timer: Impl = Classes.CreateSingleton("Timer") :: Impl

--//Types

export type TimerState = typeof(TimerState)

export type Impl = {
	__index: Impl,

	GetState: (self: Class) -> number,
	GetName: () -> "Timer",
	IsImpl: (self: Class) -> boolean,

	Start: (self: Class) -> (),
	Pause: (self: Class) -> (),
	Resume: (self: Class) -> (),
	End: (self: Class) -> (),
	Stop: (self: Class) -> (),
	Destroy: (self: Class) -> (),

	SetLength: (self: Class, time: number) -> (),

	new: (time: number?) -> Class,
	OnConstruct: (self: Class, time: number?) -> (),
	OnConstructServer: (self: Class, time: number?) -> (),
	OnConstructClient: (self: Class, time: number?) -> (),
}

export type Fields = {
	Started: Signal.Signal<nil>,
	Paused: Signal.Signal<nil>,
	Resumed: Signal.Signal<nil>,
	Stopped: Signal.Signal<nil>,
	Completed: Signal.Signal<nil>,

	TimeLeft: number,
	TimeStep: number,

	_State: number,
	_Janitor: Janitor.Janitor,
}

export type Class = typeof(setmetatable({} :: Fields, Timer :: Impl))

--//Methods

function Timer.GetState(self: Class)
	return self._State
end

function Timer.Start(self: Class)
	assert(self._State == TimerState.NotRunning, "Timer is already running. Consider using :Resume() instead.")

	self._Janitor:Add(
		RunService.Heartbeat:Connect(function(delta)
			if self._State ~= TimerState.Running then
				return
			end

			self.TimeLeft -= self.TimeStep * delta

			if self.TimeLeft > 0 then
				return
			end

			self._State = TimerState.NotRunning
			self.Completed:Fire()
			self._Janitor:Remove("TimerConnection")
		end),
		nil,
		"TimerConnection"
	)
end

function Timer.Pause(self: Class)
	assert(self._State == TimerState.Running, "Timer is not running. Consider using :Start() instead.")

	self._State = TimerState.Paused
	self.Paused:Fire()
end

function Timer.Resume(self: Class)
	assert(self._State == TimerState.Paused, "Timer is not paused. Consider using :Pause() instead.")

	self._State = TimerState.Running
	self.Resumed:Fire()
end

function Timer.End(self: Class)
	assert(
		self._State == TimerState.Running or self._State == TimerState.Paused,
		"Timer is not running. Consider using :Start() instead."
	)

	self._State = TimerState.NotRunning
	self.Stopped:Fire()
	self._Janitor:Remove("TimerConnection")
end

Timer.Stop = Timer.End

function Timer.Destroy(self: Class)
	if self._State ~= TimerState.NotRunning then
		self:End()
	end

	self._Janitor:Destroy()
end

function Timer.SetLength(self: Class, time: number)
	self.TimeLeft = time
end

function Timer.OnConstruct(self: Class, time: number?)
	self._Janitor = Janitor.new()
	self._State = TimerState.NotRunning

	self.Started = self._Janitor:Add(Signal.new())
	self.Paused = self._Janitor:Add(Signal.new())
	self.Resumed = self._Janitor:Add(Signal.new())
	self.Stopped = self._Janitor:Add(Signal.new())
	self.Completed = self._Janitor:Add(Signal.new())

	self.TimeLeft = time or 10
	self.TimeStep = 1
end

--//Returner

local Singleton = Timer.new()
return Singleton