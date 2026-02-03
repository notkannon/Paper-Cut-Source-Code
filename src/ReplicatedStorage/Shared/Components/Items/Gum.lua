--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local GumDoorProtector = require(ReplicatedStorage.Shared.Components.Doors.Protectors.GumDoorProtector)
local InteractionService = require(ReplicatedStorage.Shared.Services.InteractionService)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Variables

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local GumItem = BaseComponent.CreateComponent("GumItem", {
	
	isAbstract = false,
	
}, BaseItem) :: BaseItem.Impl

--//Types

export type Fields = {
	
	_InstanceFocused: unknown,
	_UsageEvent: SharedComponent.ClientToServer<Instance>,

} & BaseItem.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseItem.Impl)),
	
	
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool>

--//Functions

local function GetDoorFromInteraction(interaction)
	
	local Model = (interaction.Instance :: ProximityPrompt):FindFirstAncestorWhichIsA("Model")

	if not Model or not Model:HasTag("Door") then
		return
	end

	return Model
end

--//Methods

function GumItem.OnAssumeStartClient(self: Component)
	
	--check for door component focused on
	if not self._InstanceFocused then
		return
	end
	
	self._UsageEvent.Fire(self._InstanceFocused)
end

function GumItem.OnConstructClient(self: Component)
	BaseItem.OnConstructClient(self)
	
	--extracting doors from their interactions
	self.Janitor:Add(

		InteractionService.InteractionShown:Connect(function(interaction)

			local DoorInstance = GetDoorFromInteraction(interaction)

			if not DoorInstance then
				return
			end

			self._InstanceFocused = DoorInstance

			self.Janitor:Add(

				interaction.Hidden:Once(function()

					if self._InstanceFocused ~= DoorInstance then
						return
					end

					self._InstanceFocused = nil
				end)
			)
		end)
	)
end

function GumItem.OnConstructServer(self: Component)
	BaseItem.OnConstructServer(self)
	
	--handling player's things
	self.Janitor:Add(self._UsageEvent.On(function(player, instance)
		
		--ignore when unequipped
		if not self.Equipped then
			return
		end
		
		--tryna get a door
		local DoorComponent = ComponentsUtility.GetComponentFromDoor(instance)
		local DoorPosition = DoorComponent and instance:FindFirstChild("Root").Position
		local Humanoid = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
		local Distance = DoorPosition and Humanoid and (Humanoid.RootPart.Position - DoorPosition).Magnitude
		
		if not DoorComponent
			or DoorComponent:IsOpened()
			or DoorComponent:IsProtected()
			or not Humanoid
			or Distance > 15 then
			
			return
		end
		
		--creating a protector thing
		DoorComponent:AddProtector(
			ComponentsManager.Add(instance, GumDoorProtector, player)
		)
		
		--removing tool
		self:Destroy()
	end))
end

function GumItem.OnConstruct(self: Component)
	BaseItem.OnConstruct(self)
	
	--client sends a door instance reference so server can handle to protect it
	self._UsageEvent = self:CreateEvent(
		"InternalUsageEvent",
		"Reliable",
		function(...) return typeof(...) == "Instance" end
	)
end

--//Returner

return GumItem