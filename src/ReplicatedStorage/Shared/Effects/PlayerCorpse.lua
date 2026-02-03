--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectsUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local MatchStateClient = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.MatchStateClient) or nil

--//Constants

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

local PI = math.pi
local DEBUG = false

--//Variables

local TempContainer = workspace.Temp
local PlayerCorpse = Refx.CreateEffect("PlayerCorpse") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {}

export type Impl = Refx.EffectImpl<MyImpl, Fields, PlayerTypes.Character, { [BasePart]: Vector3 }>
export type Effect = Refx.Effect<MyImpl, Fields, PlayerTypes.Character, { [BasePart]: Vector3 }>

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
	
	part.CanCollide = false
	part.Massless = false

	coolider.Parent = part
	weld.Parent = coolider
end

--//Methods

function PlayerCorpse.OnStart(self: Effect, character: Instance, velocity: { { BasePart | Vector3 } })
	
	if not character then
		self:Destroy()
		return
	end

	character.Archivable = true

	-- Сохраняем текущую физику и вставляем труп
	for _, VelocityData in ipairs(velocity) do
		
		local Velocity = VelocityData[2] :: Vector3
		
		VelocityData[2] = VelocityData[1].AssemblyLinearVelocity
		VelocityData[1].AssemblyLinearVelocity = Velocity
	end

	local Corpse = character:Clone() :: PlayerTypes.Character
	local humanoid = Corpse:FindFirstChildWhichIsA("Humanoid")
	
	--avoiding creating some components
	Corpse:RemoveTag("Character")

	-- Переводим в "трупное" состояние, чтобы отключить контролируемую анимацию
	if humanoid then
		
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	end

	-- Деанчерим всё и врубаем физику
	for _, part in ipairs(Corpse:GetDescendants()) do
		
		if part:IsA("BasePart") then
			
			part.Anchored = false
			
			if part.Name ~= "Hair" then
				part.CanCollide = true
			end
			
			--removing smartbone cuz it causes lags :sob:
			part:RemoveTag("SmartBone")
		end
	end

	-- Восстанавливаем прозрачность
	for _, Descendant: Instance in ipairs(Corpse:GetDescendants()) do
		
		if Descendant:IsA("Highlight") then
			
			Descendant:Destroy()
			
			continue
		end
		
		--kinda.. We have Ruby or other guys who shall have unique effects on death..
		if Descendant:IsA("SurfaceGui")
			or Descendant:IsA("BillboardGui")
			or Descendant:IsA("Light") then
			
			Descendant.Enabled = true
		end
		
		if not Descendant:GetAttribute("InitialTransparency")
			or Descendant:GetAttribute("ShouldKeepTransparent") then
			
			continue
		end
		
		Descendant.Transparency = Descendant:GetAttribute("InitialTransparency")
	end
	
	for _, VelocityData in ipairs(velocity) do
		VelocityData[1].AssemblyLinearVelocity = VelocityData[2]
	end
	
	Corpse.Parent = workspace.Temp
	character.Archivable = false

	-- Заменяем моторы на физику
	for _, Motor in ipairs(Corpse:GetDescendants()) do
		
		if not Motor:IsA("Motor6D")
			or not table.find(MOTORS_NAMES, Motor.Name) then
			
			continue
		end
		
		local IsNeck = Motor.Name == "Neck"
		Motor.Enabled = false

		CreateColliderPart(Motor.Part1)

		local BallSocket = Motor.Parent:FindFirstChild("RagdollConstraint") :: BallSocketConstraint

		if not BallSocket then
			local Attachment0 = Instance.new("Attachment")
			Attachment0.Name = "RagdollAttachment"
			Attachment0.CFrame = CFrame.new()
			Attachment0.Parent = Motor.Part0

			local Attachment1 = Instance.new("Attachment")
			Attachment1.Name = "RagdollAttachment"
			Attachment1.CFrame = CFrame.new()
			Attachment1.Parent = Motor.Part1

			BallSocket = Instance.new("BallSocketConstraint")
			BallSocket.Name = "RagdollConstraint"
			BallSocket.Attachment0 = Attachment0
			BallSocket.Attachment1 = Attachment1
			BallSocket.Radius = 0.15

			BallSocket.Parent = Motor.Parent
		end

		BallSocket.Enabled = true

		BallSocket.LimitsEnabled = true
		BallSocket.UpperAngle = IsNeck and 15 or 30

		BallSocket.TwistLimitsEnabled = true
		BallSocket.TwistUpperAngle = 25
		BallSocket.TwistLowerAngle = -25
		
		BallSocket.Restitution = 0.35
		BallSocket.MaxFrictionTorque = 10

		BallSocket.Parent = Motor.Parent
	end
	
	if not RolesManager:IsPlayerSpectator(Players:GetPlayerFromCharacter(character)) then
		
		Corpse.Parent = game:GetService("CollectionService"):GetTagged("Map")[1] or workspace.Temp
		MatchStateClient.Janitor:Add(Corpse)
		
		return
	end
	
	for _, BasePart in ipairs(Corpse:GetDescendants()) do
		
		if not (BasePart:IsA("BasePart") or BasePart:IsA("Decal")) then
			continue
		end
		
		TweenUtility.PlayTween(BasePart, TweenInfo.new(7), {Transparency = 1}, function()
			if BasePart then
				BasePart:Destroy()
			end
		end, 10)
	end
end

--//Return

return PlayerCorpse