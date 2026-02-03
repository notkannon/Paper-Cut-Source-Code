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

local Camera = workspace.CurrentCamera
local FlashlightItem = BaseComponent.CreateComponent("FlashlightItem", {

	isAbstract = false,

	defaults = {
		Charge = 1,
		Enabled = false,
	}

}, BaseItem) :: BaseItem.Impl

--//Types

export type Fields = {
	Attributes: {
		Charge: number,
		Enabled: boolean,
	} & BaseItem.ItemAttributes,

	MaxCharge: number,
	GripMotor6D: Motor6D,
	DrainSpeed: number

} & BaseItem.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseItem.MyImpl)),

	SetActive: (self: Component, value: boolean) -> (),

	_ToggleChargeDrain: (self: Component, value: boolean) -> (),
	_ToggleActiveAnimation: (self: Component, value: boolean) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool, {}>

--//Methods

function FlashlightItem._ToggleChargeDrain(self: Component, value: boolean)
	assert(RunService:IsServer())

	if not value then
		self.EquipJanitor:Remove("ChargeDrainConnection")
		return

	elseif self.EquipJanitor:Get("ChargeDrainConnection") and value then
		return
	end

	self.EquipJanitor:Add(RunService.Stepped:Connect(function(_, delta: number)
		if self.Attributes.Charge == 0 then
			self:SetActive(false)

			return
		end

		self.Attributes.Charge = math.max(0, self.Attributes.Charge - delta * self.DrainSpeed)

	end), nil, "ChargeDrainConnection")
end

function FlashlightItem._ToggleActiveAnimation(self: Component, value: boolean)

	if not value then

		self.EquipJanitor:Remove("ActiveAnimation")

		return

	elseif self.EquipJanitor:Get("ActiveAnimation") and value then
		return
	end

	local ActiveAnimation = AnimationUtility.QuickPlay(

		self.Character:FindFirstChildWhichIsA("Humanoid"),
		ReplicatedStorage.Assets.Animations.Items.Flashlight.Idle, {
			Looped = true,
			Priority = Enum.AnimationPriority.Action4,
		}
	)

	self.EquipJanitor:Add(function()

		ActiveAnimation:Stop(0.5)

	end, nil, "ActiveAnimation")
end

function FlashlightItem.SetActive(self: Component, value: boolean, force: boolean)

	if value and self.Attributes.Charge == 0
		or value == self.Attributes.Enabled then

		if not force then
			return
		end
	end

	self.Attributes.Enabled = value

	self.Handle.Neon.Beam.Enabled = value
	self.Handle.Neon.Material = Enum.Material[ value and "Neon" or "SmoothPlastic" ]
	self.Handle.Neon.LightSource:FindFirstChildWhichIsA("SpotLight").Enabled = value

	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Misc.Flashlight:FindFirstChild(
			value and "On" or "Off"
		)
	).Parent = self.Handle

	self:_ToggleChargeDrain(value)
	self:_ToggleActiveAnimation(value)
end

function FlashlightItem.ShouldStart(self: Component)
	return self.Attributes.Charge > 0
end

function FlashlightItem.OnConstruct(self: Component, ...)
	BaseItem.OnConstruct(self, ...)

	self.MaxCharge = 1
	self.DrainSpeed = 1/200
	self.GripMotor6D = self.Handle:FindFirstChildWhichIsA("Motor6D")
end

function FlashlightItem.OnConstructClient(self: Component, ...)
	BaseItem.OnConstructClient(self, ...)

	self.GripMotor6D.Part0 = self.Character:FindFirstChild("RightHand")
	self.GripMotor6D.Enabled = true
end

function FlashlightItem.OnConstructServer(self: Component, ...)
	BaseItem.OnConstructServer(self, ...)

	local Motor = self.GripMotor6D
	Motor.Part1 = self.Handle
	Motor.Part0 = nil

	self.InventoryChanged:Connect(function(inventory)
		if inventory then
			Motor.Part0 = self.Character:FindFirstChild("RightHand")
			Motor.Enabled = true
		else
			Motor.Part0 = nil
			Motor.Enabled = false
		end
	end)

	self:SetActive(false, true)
end

function FlashlightItem.OnStartServer(self: Component)
	self:SetActive(not self.Attributes.Enabled)
end

function FlashlightItem.OnEquipServer(self: Component)

	self.EquipJanitor:Add(

		AnimationUtility.QuickPlay(

			self.Character:FindFirstChildWhichIsA("Humanoid"),
			ReplicatedStorage.Assets.Animations.Items.Flashlight.Hold, {
				Looped = true,
				Priority = Enum.AnimationPriority.Idle,
			}
		), "Stop"
	)

	if self.Attributes.Enabled then
		self:_ToggleChargeDrain(true)
		self:_ToggleActiveAnimation(true)
	end
end

function FlashlightItem.OnUnequipServer(self: Component)
	self:_ToggleChargeDrain(false)
	self:_ToggleActiveAnimation(false)
end

function FlashlightItem.OnEquipClient(self: Component)
	
	--local function CleanCameraLight()
		
	--	self.Janitor:RemoveList(
	--		"CameraLight",
	--		"CameraLightRender"
	--	)
		
	--	--restoring base flashlight visuals
		
	--	if not self.Handle:FindFirstChild("Neon") then
	--		return
	--	end
		
	--	self.Handle.Neon.Beam.Enabled = self.Attributes.Enabled
	--	self.Handle.Neon.LightSource:FindFirstChildWhichIsA("SpotLight").Enabled = self.Attributes.Enabled
	--end
	
	--local function CreateClientCameraLight()
		
	--	CleanCameraLight()
		
	--	--creating a copy of flashlight
	--	local CameraLight = self.Janitor:Add(self.Handle:Clone(), nil, "Camera")
		
	--	--hiding original flashlight visuals
	--	--self.Handle.Neon.Beam.Enabled = false
	--	--self.Handle.Neon.LightSource:FindFirstChildWhichIsA("SpotLight").Enabled = false
		
	--	--for _, a in ipairs(CameraLight:GetDescendants()) do
	--	--	if a:IsA("BasePart") then
	--	--		a.Anchored = true
	--	--	elseif a:IsA("Weld") or a:IsA("WeldConstraint") then
	--	--		a:Destroy()
	--	--	end
	--	--end
		
	--	--local Model = self.Janitor:Add(Instance.new("Model"), nil, "CameraLight")
		
	--	--CameraLight.Parent = Model
	--	--CameraLight.Anchored = true
		
	--	--Model.Parent = workspace.Temp
	--	--Model.PrimaryPart = CameraLight
		
	--	--CameraLight.Neon:FindFirstChildWhichIsA("Beam"):Destroy()
	--	--CameraLight:FindFirstChildWhichIsA("Motor6D"):Destroy()
	--	--CameraLight:FindFirstChildWhichIsA("ProximityPrompt"):Destroy()
	--	--CameraLight.Neon.LightSource:FindFirstChildWhichIsA("SpotLight").Brightness = 1 -- increase local brightness
		
	--	--rendering light
	--	--self.Janitor:Add(RunService.RenderStepped:Connect(function()	
			
	--	--	Model:PivotTo( Camera.CFrame * CFrame.new(0, 0, 0.8) * CFrame.Angles(-math.rad(90), -math.rad(90), 0) )
			
	--	--end), "Disconnect", "CameraLightRender")
	--end

	--self.EquipJanitor:Add(self.Attributes.AttributeChanged:Connect(function(attribute, value)

	--	if attribute ~= "Enabled" then
	--		return
	--	end
		
	--	if value then
	--		CreateClientCameraLight()
	--	else
	--		CleanCameraLight()
	--	end
	--end))
	
	--clear on unequip
	--self.EquipJanitor:Add(CleanCameraLight)
	
	--create on equip
	--if self.Attributes.Enabled then
	--	CreateClientCameraLight()
	--end
end

--//Returner

return FlashlightItem