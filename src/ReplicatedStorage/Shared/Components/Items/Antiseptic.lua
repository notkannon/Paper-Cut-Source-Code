--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local PhysicsStatusEffect = require(ReplicatedStorage.Shared.Combat.Statuses.Physics)

--//Variables

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AntisepticItem = BaseComponent.CreateComponent("AntisepticItem", {
	isAbstract = false,
	
	defaults = {
		Charge = 1,
	}
	
}, BaseItem) :: BaseItem.Impl

--//Types

export type Fields = {
	Instance: typeof(ItemsData.Flashlight.Instance),
	
	GripMotor6D: Motor6D,
	
} & BaseItem.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseItem.Impl)),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool, {}>

--//Methods

function AntisepticItem.ShouldStart(self: Component)
	local Humanoid = self.CharacterComponent.Humanoid :: Humanoid
	
	return self.Attributes.Charge > 0 and Humanoid.Health < Humanoid.MaxHealth
end

function AntisepticItem.OnConstruct(self: Component)
	BaseItem.OnConstruct(self)
	
	self.GripMotor6D = self.Handle:FindFirstChildWhichIsA("Motor6D")
end

function AntisepticItem.OnConstructServer(self: Component)
	BaseItem.OnConstructServer(self)

	local Motor = self.GripMotor6D
	Motor.Part1 = self.Handle
	Motor.Part0 = nil

	self.InventoryChanged:Connect(function(inventory)
		if inventory then
			Motor.Part0 = self.CharacterComponent.Instance:FindFirstChild("Right Arm")
			Motor.Enabled = true
		else
			Motor.Part0 = nil
			Motor.Enabled = false
		end
	end)
end

function AntisepticItem.OnStartServer(self: Component)
	local Humanoid = self.CharacterComponent.Humanoid :: Humanoid
	
	self.ActiveJanitor:Add(RunService.Stepped:Connect(function()
		if self.Attributes.Charge == 0 then
			self:Destroy()

			return
		end
		
		if Humanoid.Health == Humanoid.MaxHealth then
			self.Instance:Deactivate()
			return
		end
		
		Humanoid.Health = math.clamp(Humanoid.Health + 1 / 9, 0, Humanoid.MaxHealth)
		
		self.Attributes.Charge = math.max(0, self.Attributes.Charge - 1 / 400)
		
	end), nil, "ChargeDrainConnection")
end

function AntisepticItem.OnEquipClient(self: Component)
	
	local UIController = Classes.GetSingleton("UIController")
	
	UIController.GameplayUI.Misc.ItemCharge.SetVisible(true)
	UIController.GameplayUI.Misc.ItemCharge.SetCharge(self.Attributes.Charge)
	
	self.EquipJanitor:Add(self.Attributes.AttributeChanged:Connect(function(attribute, value)
		if attribute ~= "Charge" then
			return
		end

		UIController.GameplayUI.Misc.ItemCharge.SetCharge(value)
	end))
end

function AntisepticItem.OnUnequipClient(self: Component)
	local UIController = Classes.GetSingleton("UIController")
	UIController.GameplayUI.Misc.ItemCharge.SetVisible(false)
end

--//Returner

return AntisepticItem