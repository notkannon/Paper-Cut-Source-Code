--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local AimingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Aiming)
local BaseSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseSkill)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseThrowable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseThrowable)

local InputController = require(ReplicatedStorage.Client.Controllers.InputController)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Types

export type MyImpl = {
	__index: MyImpl,

	End: (self: Component) -> (),
	Start: (self: Component) -> (),
	ShouldStart: (self: Component) -> boolean,
	OnConstructClient: (self: Component) -> (),
	
	_ConnectInputEvents: (self: Component) -> (),
}

export type Fields = {
	Status: WCS.StatusEffect,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "AimHandler">
export type Component = BaseComponent.Component<MyImpl, Fields, "AimHandler">

--//Variables

local LocalPlayer = Players.LocalPlayer
local AimHandler = BaseComponent.CreateComponent("AimHandler", {
	
	tag = "Character",
	isAbstract = false,
	predicate = function(instance)
		return instance == LocalPlayer.Character
	end,
	
}) :: Impl

--//Methods

function AimHandler.ShouldStart(self: Component)
	
	local WCSCharacter = WCS.Character.GetLocalCharacter()
	
	--we should have existing wcs character
	if not WCSCharacter then
		return
	end
		
	if Classes.GetSingleton("PlayerController"):GetRoleConfig().HasInventory then

		-- getting inventory component reference both client/server
		local Inventory = ComponentsManager.Get(LocalPlayer.Backpack, "ClientInventoryComponent")

		if not Inventory then
			return false
		end

		local Item = Inventory:GetEquippedItemComponent()

		-- if item is not throwable or not item
		if not Item or not Classes.InstanceOf(Item, BaseThrowable) then
			return false
		end

		-- has no skills which requires aiming
	elseif not WCSUtility.HasSkillsWithName(WCSCharacter, {"Harpoon"}) then
		return false
	end
	
	-- WOW WTF
	-- huh it just contains .ExclusivesSkill and .ExclusivesStatuses names
	return BaseSkill.ShouldStart(self.Status)
end

function AimHandler.Start(self: Component)
	if not self:ShouldStart()
		or self.Status:GetState().IsActive then
		
		return
	end
	
	self.Status:Start()
end

function AimHandler.End(self: Component)
	if not self.Status:GetState().IsActive then
		return
	end
	
	self.Status:End()
	self.Janitor:Remove("StarterConnection")
end

function AimHandler._ConnectInputEvents(self: Component)
	self.Janitor:Add(InputController.ContextStarted:Connect(function(context)
		if context ~= "Aim" then
			return
		end
		
		self.Janitor:Add(RunService.RenderStepped:Connect(function()
			if not InputController:IsContextActive("Aim") then
				self.Janitor:Remove("StarterConnection")
				
				return
			end
			
			self:Start()
			
		end), nil, "StarterConnection")
	end))
	
	self.Janitor:Add(InputController.ContextEnded:Connect(function(context)
		if context ~= "Aim" then
			return
		end
		
		self:End()
	end))
end

function AimHandler.OnConstructClient(self: Component)
	
	print(self.Instance, "AimHandler Component")
	
	local WCSCharacter = self.Janitor:AddPromise(
		WCSUtility.PromiseCharacterAdded(self.Instance)
	):timeout(35):expect()
	
	if not WCSCharacter or not self.Instance then
		return
	end
	
	--listening to WCS character removal
	self.Janitor:Add(WCS.Character.CharacterDestroyed:Once(function()
		self:Destroy()
	end))
	
	self.Status = AimingStatus.new(WCSCharacter)
	
	self:_ConnectInputEvents()
end

--//Returner

return AimHandler