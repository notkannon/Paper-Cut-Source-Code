--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local Type = require(ReplicatedStorage.Packages.Type)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local LocalPlayer = Players.LocalPlayer
local BaseVault = BaseComponent.CreateComponent("BaseVault", {
	
	isAbstract = true,
	defaults = {
		
		--means if vault can be used
		Enabled = true,
	},
	
	ancestorWhitelist = { workspace },
	
}, SharedComponent) :: Impl

--//Types

export type Attributes = {
	Enabled: boolean,
	AttributeChanged: Signal.Signal<string, any>,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),

	IsEnabled: (self: Component) -> boolean,
	SetEnabled: (self: Component, value: boolean) -> (),
	CreateEvent: SharedComponent.CreateEvent<Component>,

	OnConstruct: (self: Component, options: SharedComponent.SharedComponentConstructOptions?) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}

export type Fields = {

	Interaction: InteractionComponent.Component,
	Attributes: Attributes,

} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseVault", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseVault", Instance, any...>

--//Methods

function BaseVault.IsEnabled(self: Component)
	return self.Attributes.Enabled
end

function BaseVault.SetEnabled(self: Component, value: boolean)
	
	Type.strict(Type.boolean)(value)
	
	self.Attributes.Enabled = value
end

function BaseVault.OnConstruct(self: Component, options: SharedComponent.SharedComponentConstructOptions?, ...: any)
	SharedComponent.OnConstruct(self, options)

	--awaiting interaction component
	self.Interaction = self.Janitor:AddPromise(

		ComponentsManager.Await(

			self.Instance
				:WaitForChild("Root", 15)
				:WaitForChild("RootPoint", 15)
				:FindFirstChildWhichIsA("ProximityPrompt"),
			
			Interaction
		)
	):expect()
	
	--interaction removal
	self.Janitor:Add(self.Interaction)
	
	--applying changes
	self:SetEnabled(self.Attributes.Enabled)
end

function BaseVault.OnConstructServer(self: Component)
	
	--interaction access
	self.Interaction:SetFilteringType("Exclude")
	self.Interaction.Instance.RequiresLineOfSight = false
	self.Interaction.Instance.MaxActivationDistance = 10
	
	self.Janitor:Add(self.Interaction.Started:Connect(function(player: Player)
		local OldState = self.Attributes.Enabled
		local NewState = not OldState
		local ProxyService = Classes.GetSingleton("ProxyService")
		
		self:SetEnabled(NewState)
		if NewState then
			ProxyService:AddProxy("VaultOpened"):Fire(player)
		else
			ProxyService:AddProxy("VaultClosed"):Fire(player)
		end
	end))
end

--//Returner

return BaseVault