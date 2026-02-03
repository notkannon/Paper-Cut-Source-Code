--//Service

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService('RunService')
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Import

local BaseDoor = require(ReplicatedStorage.Shared.Components.Abstract.BaseDoor)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local RandomUtility = require(ReplicatedStorage.Shared.Utility.Random)

--//Variables

local PI = math.pi

local SingleDoor = BaseComponent.CreateComponent("SingleDoor", {
	tag = "SingleDoor",
	isAbstract = false,
}, BaseDoor) :: Impl

--//Type

export type Fields = {
	InitialCFrames: { [Attachment]: CFrame }
} & BaseDoor.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseDoor.MyImpl)),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SingleDoor", BaseDoor.BaseDoorModel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "SingleDoor", BaseDoor.BaseDoorModel, {}> 

--//Methods

function SingleDoor.OnSlam(self: Component, ...)
	BaseDoor.OnSlam(self, ...)

	if RunService:IsClient() then

		if self:IsBroken() then
			return
		end

		local StartedResponsiveness = self.Instance.HingeA.AlignOrientation.Responsiveness
		self.Instance.HingeA.AlignOrientation.Responsiveness = 100
		self.Instance.HingeA.Door.CanCollide = false

		self.Janitor:Add(task.delay(0.3, function()

			if self:IsBroken() then
				return
			end

			self.Instance.HingeA.AlignOrientation.Responsiveness = StartedResponsiveness
			self.Instance.HingeA.Door.CanCollide = true
		end))
	end
end

function SingleDoor.OnOpen(self: Component, player: Player, playerPosition: Vector3?)
	BaseDoor.OnOpen(self, player, playerPosition)
	
	if RunService:IsServer() then

		local HingeAttachmentA = self.Instance.Root.HingeA :: Attachment
		local playerPosition = playerPosition or player.Character.HumanoidRootPart.Position
		local OpenDirection = self:GetOpenDirection(playerPosition) == "Forward" and 1 or -1

		HingeAttachmentA.CFrame = self.InitialCFrames[HingeAttachmentA] * CFrame.Angles(OpenDirection * PI / 2, 0, 0)
	end
end

function SingleDoor.OnClose(self: Component, player: Player)
	BaseDoor.OnClose(self, player)

	if RunService:IsServer() then

		local HingeAttachmentA = self.Instance.Root.HingeA :: Attachment
		HingeAttachmentA.CFrame = self.InitialCFrames[HingeAttachmentA]
	end
end

function SingleDoor.OnConstructServer(self: Component)
	
	self.InitialCFrames = {
		[self.Instance.Root.HingeA] = self.Instance.Root.HingeA.CFrame,
	}

	self.Instance.HingeA:ClearAllChildren()
	
	BaseDoor.OnConstructServer(self)
end

function SingleDoor.OnConstructClient(self: Component)
	BaseDoor.OnConstructClient(self)

	local ClientHingeA = self:GetReferenceInstance().HingeA:Clone() :: BasePart
	
	ClientHingeA.Parent = self.Instance

	ClientHingeA:PivotTo(self.Instance.HingeA.CFrame)

	ClientHingeA.AlignOrientation.Attachment1 = self.Instance.Root.HingeA
	ClientHingeA.AlignOrientation.Attachment0 = ClientHingeA.Door.Hinge

	ClientHingeA.HingeConstraint.Attachment1 = self.Instance.Root.HingeA
	ClientHingeA.HingeConstraint.Attachment0 = ClientHingeA.Door.Hinge

	self.InitialCFrames = {
		[ClientHingeA.Door.Hinge] = ClientHingeA.Door.Hinge.CFrame,
	}

	for _, a: BasePart? in ipairs(self.Instance:GetDescendants()) do

		if not a:IsA("BasePart") then
			continue
		end

		a.CollisionGroup = "Doors"
	end

	self.Instance.HingeA:Destroy()
end

--//Returner

return SingleDoor