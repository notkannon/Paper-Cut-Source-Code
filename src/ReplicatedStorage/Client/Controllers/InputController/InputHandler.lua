--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Classes = require(ReplicatedStorage.Shared.Classes)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

--//Variables

local Player = Players.LocalPlayer
local InputHandler = Classes.CreateClass("InputHandler", false) :: Impl

local DEFAULT_OPTIONS = {
	Context = "Unknown",
	Priority = 0,
	RespectGameProcessed = true
}

--//Types

export type InputHandlerOptions = {
	Context: string?,
	Priority: number?,
	RespectGameProcessed: boolean?
}

export type Fields = {
	Context: string,
	Enabled: boolean,
	Priority: number,
	InputType: number,
	
	IgnoreOnEnd: boolean,
	StartWhileActive: boolean,

	Janitor: Janitor.Janitor,
	Keybinds: {Enum.UserInputType | Enum.KeyCode},
	Controller: {any},

	Ended: Signal.Signal,
	Started: Signal.Signal,
	
	_Active: boolean,
}

export type Impl = {
	__index: Impl,
	
	IsImpl: (self: Impl) -> boolean,
	GetName: () -> string,

	new: (inputController: {any}, options: InputHandlerOptions?) -> Object,
	Destroy: (self: Object) -> (),
	
	OnUpdate: (self: Object) -> (),
	ShouldStart: (self: Object) -> boolean,
	OnInputBegan: (self: Object, input: InputObject) -> (),
	OnInputEnded: (self: Object, input: InputObject) -> (),
	OnInputChanged: (self: Object, input: InputObject) -> (),
	ShouldProcessInput: (self: Object, input: InputObject) -> boolean,

	End: (self: Object) -> (),
	Start: (self: Object) -> (),
	IsActive: (self: Object) -> boolean,
	
	IsVR: (self: Object) -> boolean,
	IsSensor: (self: Object) -> boolean,
	IsGamepad: (self: Object) -> boolean,
	IsKeyboard: (self: Object) -> boolean,

	OnConstructClient: (self: Object, inputController: {any}, options: InputHandlerOptions?) -> (),
}

export type Object = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

--@override
function InputHandler.OnUpdate(self: Object) end

--@override
function InputHandler.OnInputBegan(self: Object)
	self:Start()
end

--@override
function InputHandler.OnInputEnded(self: Object)
	self:End()
end

--@override
function InputHandler.OnInputChanged(self: Object) end

--@override
--useful if we want to override any keybinds for current handler
function InputHandler.ShouldProcessInput(self: Object, input: InputObject)
	return self.Controller:IsContextualInput(self.Context, input)
end

--@override
--useful if we want to override default behavior of how handler should validate to fire start event
function InputHandler.ShouldStart(self: Object)
	return self.Controller:GetHighestContextPriority(self.Context) <= self.Priority
end

function InputHandler.IsVR(self: Object)
	return self.Controller:IsVR()
end

function InputHandler.IsSensor(self: Object)
	return self.Controller:IsSensor()
end

function InputHandler.IsGamepad(self: Object)
	return self.Controller:IsGamepad()
end

function InputHandler.IsKeyboard(self: Object)
	return self.Controller:IsKeyboard()
end

function InputHandler.IsActive(self: Object)
	return self._Active
end

function InputHandler.Start(self: Object)
	if self:IsActive() or not self:ShouldStart() then
		return
	end
	
	self._Active = true
	
	self.Started:Fire()
	
	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		
		self:OnUpdate()
		
	end), nil, "UpdateConnection")
end

function InputHandler.End(self: Object)
	if not self:IsActive() then
		return
	end
	
	self.Janitor:Remove("UpdateConnection")
	
	self._Active = false
	
	self.Ended:Fire()
end

function InputHandler.OnConstructClient(self: Object, inputController: {any}, options: InputHandlerOptions?)
	
	self.Options = TableKit.MergeDictionary(DEFAULT_OPTIONS, options or {})
	
	-- backwards compatibility
	self.Context = self.Options.Context
	self.Priority = self.Options.Priority
	
	self.Enabled = true
	self.Janitor = Janitor.new()
	--self.InputType = inputController:GetInputType() -- из-за этой фигни тип хендлера определяется только 1 раз, при его создании :skull:
	self.Controller = inputController
	self.Ended = self.Janitor:Add(Signal.new())
	self.Started = self.Janitor:Add(Signal.new())
	self.Keybinds = inputController:GetKeybindsFromContext(self.Options.Context)
	
	--useful for skills which shall be started forcely along input active
	self.StartWhileActive = false
	
	--useful for skills which should be started once, but not stopped
	self.IgnoreOnEnd = false
end

function InputHandler.Destroy(self: Object)
	self.Janitor:Destroy()
	Classes.CleanupObject(self)
end

--//Returner

return InputHandler