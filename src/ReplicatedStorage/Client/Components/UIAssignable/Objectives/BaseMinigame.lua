--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UserInputService = game:GetService("UserInputService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)
local InteractionComponent = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)

local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local ObjectiveSolvingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.ObjectiveSolving)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

local BaseObjective = require(ReplicatedStorage.Shared.Components.Abstract.BaseObjective)
local InputController = require(ReplicatedStorage.Client.Controllers.InputController) 
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)

--//Variables

local KEYBINDS = {
	Cancel = {
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonA
	}
}

local LocalPlayer = Players.LocalPlayer
local BaseMinigame = BaseComponent.CreateComponent("BaseMinigame", { isAbstract = true, }, BaseUIComponent) :: Impl

--//Types

export type ObjectiveCompletionState = "Success" | "Failed" | "Cancelled"

type ObjectiveState = {
	Players: { Player? },
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl)),

	CreateEvent: BaseUIComponent.CreateEvent<Component>,
	
	PromptComplete: (self: Component, status: ObjectiveCompletionState, userData: { any }?) -> (),
	
	OnConstruct: (self: Component, options: BaseUIComponent.BaseUIComponentConstructOptions?) -> (),
	Hide: (self: Component) -> (),
	Show: (self: Component) -> (),
	Start: (self: Component) -> (),
	ShouldStart: (self: Component) -> boolean,
	_InitInput: (self: Component) -> (),
}

export type Fields = {
	Completed: Signal.Signal<Player, ObjectiveCompletionState>,
	ParentObjective: BaseObjective,
	
	_Enabled: boolean,
	_InProgress: boolean,
	
	CurrentDevice: string?,
	
	DestroyOnComplete: boolean
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseMinigame", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseMinigame", Instance, any...>

--//Methods

function BaseMinigame.PromptComplete(self: Component, status: ObjectiveCompletionState, userData: { any }?)
	assert(RunService:IsClient(), "Client only method")
	
	-- bro tries to prompt after game is over or before it started
	if not self._InProgress then
		return
	end
	
	--can't call it twice
	if self:IsDestroying() then
		return
	end
	
	self._InProgress = false
	self.Completed:Fire(LocalPlayer, status or "Cancelled", userData)
	
	print("BaseMinigame: ", status, self.DestroyOnComplete)
	
	if status == "Success" and self.DestroyOnComplete then
		if self.Instance then self.Instance:Destroy() end -- idk why that has to be done separately
		self:Destroy()
	end
end

-- @override
function BaseMinigame.Show(self: Component)
	self._Enabled = true
	self.CurrentDevice = InputController:GetInputType() -- for compatability checks
end

-- @override
function BaseMinigame.Hide(self: Component)
	print('hiding', self:GetName())
	self._Enabled = false
	self._InProgress = false
end

-- @override
function BaseMinigame.ShouldStart(self: Component)
	return self._Enabled and not self._InProgress
end

-- @override
function BaseMinigame.Start(self: Component)
	self._InProgress = true
end

function BaseMinigame._InitInput(self: Component)
	--cancel on "Space" input
	self.Janitor:Add(InputController.ContextStarted:Connect(function(context)

		if context ~= "Vault" or not self._InProgress then
			return
		end

		self:PromptComplete("Cancelled")
	end))
end

function BaseMinigame.OnConstructClient(self: Component, uiController: unknown, options: BaseUIComponent.UIConstructorOptions?, ...: any)
	BaseUIComponent.OnConstructClient(self, uiController, options, ...)
	
	self._Enabled = false
	self._InProgress = false
	
	self.DestroyOnComplete = true
	
	self.ParentObjective = nil
	self.Completed = self.Janitor:Add(Signal.new())
	
	self:Hide()
	self:_InitInput()
	
	--self.Janitor:Add(PlayerController.CharacterComponent.WCSCharacter.CharacterCreated:Connect(function(Character)
	--	if not self._InProgress then
	--		return
	--	end
		
	--	Character.StatusEffectStarted:Connect(function(Skill)
	--		WCSUtility.GetAllActiveStatusEffectsFromString(Character, "Healing")
	--		if Skill:GetName() == "Healing" then
	--			self:PromptComplete("Cancelled")
	--		end
	--	end)
	--end))
	
	self.Janitor:Add(ClientRemotes.MatchServiceStartLMS.On(function()
		self:Hide()
		self:Destroy()
	end))
end

--//Returner

return BaseMinigame