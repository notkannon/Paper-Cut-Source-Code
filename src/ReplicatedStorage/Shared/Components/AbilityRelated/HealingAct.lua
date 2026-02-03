--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

local InputController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.InputController) or nil
local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil

--//Variables

local HealingAct = BaseComponent.CreateComponent("HealingAct", {
	
	isAbstract = false
	
}, SharedComponent) :: Impl

--//Types

type ConstructorData = {
	Healer: Player,
	Target: Player,
	Amount: number,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),
	
	GetComponentFromPlayer: (player: Player) -> Component?,
	
	Cancel: (self: Component) -> (),
}

export type Fields = {
	
	Healer: Player,
	Target: Player,
	Amount: number,
	
	Cancelled: boolean,
	
	_InternalCancelRequest: SharedComponent.ClientToServer,
	
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "HealingAct", Instance, ConstructorData>
export type Component = BaseComponent.Component<MyImpl, Fields, "HealingAct", Instance, ConstructorData>

--//Methods

--static method
function HealingAct.GetComponentFromPlayer(player: Player)
	
	local Components = ComponentsManager.GetAllComponentsOfType(HealingAct)
	
	for _, Component: Component in ipairs(Components) do
		if Component.Target == player or Component.Healer == player then
			return Component
		end
	end
end

--prompt to cancel (end) healer's skill
--both client/server
function HealingAct.Cancel(self: Component)
	
	if RunService:IsServer() then
		
		if self.Cancelled then
			return
		end
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Healer.Character)
		
		if not WCSCharacter then
			return
		end
		
		self.Cancelled = true
		
		local ProxyService = Classes.GetSingleton("ProxyService")
		ProxyService:AddProxy("HealCanceled"):Fire(self.Healer, self.Target)
		
		--cancelling
		WCSUtility.EndAllActiveSkillsWithNames(WCSCharacter, { "PatchUp" })
		
	else
		--client prompt
		self._InternalCancelRequest.Fire()
	end
end

function HealingAct.OnConstruct(self: Component, data: ConstructorData)
	SharedComponent.OnConstruct(self)
	
	--field filing
	self.Amount = data.Amount
	self.Target = data.Target
	self.Healer = data.Healer
	
	self.Cancelled = false
	
	self._InternalCancelRequest = self:CreateEvent(
		"InternalCancelRequest",
		"Reliable"
	)
end

function HealingAct.OnConstructServer(self: Component, data: ConstructorData)
	
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Healer.Character)
	local ActiveSkill = WCSCharacter:GetSkillFromString("PatchUp")
	
	assert(ActiveSkill, `No skill PatchUp exists for player { self.Healer.Name }`)
	
	--component will be destroyed when skill ends
	ActiveSkill.Janitor:Add(self)
	
	--listening to cancel prompts
	self.Janitor:Add(self._InternalCancelRequest.On(function(player)
		self:Cancel()
	end))
	
	--component replication
	ComponentReplicator:PromptCreate(self, {self.Healer, self.Target}, data)
end

function HealingAct.OnConstructClient(self: Component)
	
	--camera handling
	CameraController:SetActiveCamera("HeadLocked")
	CameraController.Cameras.HeadLocked.IsFlexible = true
	CameraController.Cameras.HeadLocked.FlexibilityScale = 5
	
	--def camera restoring
	self.Janitor:Add(function()
		CameraController:SetActiveCamera("Default")
	end)
	
	--cancel on "Space" input
	self.Janitor:Add(InputController.ContextStarted:Connect(function(context)
		
		if context ~= "Vault" then
			return
		end
		
		self:Cancel()
	end))
end

--//Returner

return HealingAct