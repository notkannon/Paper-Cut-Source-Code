--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local StunnedStatusEffect = require(ReplicatedStorage.Shared.Combat.Statuses.Stunned)

--//Variables

local Ragdolled = WCS.RegisterStatusEffect("Ragdolled", BaseStatusEffect)

local MOTORS_NAMES = {
	"Waist",
	"Neck",
	"LeftShoulder",
	"RightShoulder",
	"LeftElbow",
	"RightElbow",
	"LeftWrist",
	"RightWrist",
	"LeftHip",
	"RightHip",
	"LeftKnee",
	"RightKnee",
	"LeftAnkle",
	"RightAnkle",
}

local AttachmentCFrames = {
	["Neck"] = {
		CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1),
		CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1),
	},
	["Left Shoulder"] = {
		CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
		CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
	},
	["Right Shoulder"] = {
		CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	},
	["Left Hip"] = {
		CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
	},
	["Right Hip"] = {
		CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
	},
}

local RagdollNames = { "RagdollAttachment", "RagdollConstraint", "ColliderPart" }

--//Types

export type Status = WCS.StatusEffect

--//Functions

local function CreateColliderPart(part: BasePart)

	if part.Name == "HumanoidRootPart" then

		part.CanCollide = false

		return
	end

	local coolider = Instance.new("Part")
	coolider.Name = "ColliderPart"
	coolider.Size = part.Size / 1.7
	coolider.Massless = true
	coolider.CFrame = part.CFrame
	coolider.Transparency = 1
	coolider.Shape = Enum.PartType.Ball
	coolider.CollisionGroup = "Players"

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = coolider
	weld.Part1 = part

	part.CanCollide = true
	part.Massless = false

	coolider.Parent = part
	weld.Parent = coolider
	
	return coolider
end

--//Methods

function Ragdolled.OnStartServer(self: Status)
	
	if #self.Character:GetAllActiveStatusEffectsOfType(Ragdolled) > 1 then
		return
	end

	self.Status:Start()

	for _, Motor in ipairs(self.Character.Instance:GetDescendants()) do
		
		if not Motor:IsA("Motor6D")
			or not table.find(MOTORS_NAMES, Motor.Name) then
			
			continue
		end

		--local Values = ATTACHMENT_CFRAMES[Motor.Name]
		--if not Values then continue end

		local IsNeck = Motor.Name == "Neck"
		Motor.Enabled = false

		local Attachment0 = Instance.new("Attachment")
		Attachment0.Name = "RagdollAttachment"
		Attachment0.CFrame = Motor.C0 --Values[1]
		Attachment0.Parent = Motor.Part0

		local Attachment1 = Instance.new("Attachment")
		Attachment1.Name = "RagdollAttachment"
		Attachment1.CFrame = Motor.C1 --Values[2]
		Attachment1.Parent = Motor.Part1

		self.Janitor:Add(CreateColliderPart(Motor.Part1))

		local BallSocket = Instance.new("BallSocketConstraint")
		BallSocket.Name = "RagdollConstraint"
		BallSocket.Attachment0 = Attachment0
		BallSocket.Attachment1 = Attachment1
		BallSocket.Radius = 0.15

		-- Немного ограничений
		BallSocket.UpperAngle = IsNeck and 30 or 60
		BallSocket.LimitsEnabled = true
		BallSocket.TwistUpperAngle = IsNeck and 70 or 45
		BallSocket.TwistLowerAngle = IsNeck and -70 or -45
		BallSocket.TwistLimitsEnabled = IsNeck

		-- Физика сопротивления
		BallSocket.Restitution = 0.13
		BallSocket.MaxFrictionTorque = 15

		BallSocket.Parent = Motor.Parent
	end

	local HumanoidRootPart = self.Character.Humanoid.RootPart

	if HumanoidRootPart and HumanoidRootPart.Parent then
		HumanoidRootPart.Anchored = false
		HumanoidRootPart:SetNetworkOwner(self.Player)
	end
end

function Ragdolled.OnStartClient(self: Status)
	self.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

function Ragdolled.OnEndServer(self: Status)
	
	if #self.Character:GetAllActiveStatusEffectsOfType(Ragdolled) > 1
		or self.Character.Humanoid.Health < 1 then
		
		return
	end

	self.Status:End()

	for _, instance in pairs(self.Character.Instance:GetDescendants()) do
		
		if RagdollNames[instance.Name] then
			instance:Destroy()
		end

		if instance:IsA("Motor6D") then
			instance.Enabled = true
		end
	end

	local HumanoidRootPart = self.Character.Humanoid.RootPart

	if HumanoidRootPart and HumanoidRootPart.Parent then
		HumanoidRootPart:SetNetworkOwnershipAuto()
	end
end

function Ragdolled.OnEndClient(self: Status)
	self.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

function Ragdolled.OnConstruct(self: Status)
	BaseStatusEffect.OnConstruct(self)
	
	self:SetHumanoidData({
		AutoRotate = { false, "Set" },
	})
	
	self.Status = StunnedStatusEffect.new(self.Character)
	--self.Status.DestroyOnEnd = false
end

--//Returner

return Ragdolled
