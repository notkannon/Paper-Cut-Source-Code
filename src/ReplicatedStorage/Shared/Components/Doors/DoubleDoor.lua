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

local DoubleDoor = BaseComponent.CreateComponent("DoubleDoor", {
	tag = "DoubleDoor",
	isAbstract = false,
}, BaseDoor) :: Impl

--//Type

export type Fields = {
	InitialCFrames: { [Attachment]: CFrame }
} & BaseDoor.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseDoor.MyImpl)),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "DoubleDoor", BaseDoor.BaseDoorModel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "DoubleDoor", BaseDoor.BaseDoorModel, {}> 

--//Methods

function DoubleDoor.OnSlam(self: Component, ...)
	BaseDoor.OnSlam(self, ...)
	
	if RunService:IsClient() then
		
		if self:IsBroken() then
			return
		end
		
		local StartedResponsiveness = self.Instance.HingeA.AlignOrientation.Responsiveness
		self.Instance.HingeA.AlignOrientation.Responsiveness = 100
		self.Instance.HingeB.AlignOrientation.Responsiveness = 100
		self.Instance.HingeA.Door.CanCollide = false
		self.Instance.HingeB.Door.CanCollide = false
		
		self.Janitor:Add(task.delay(0.3, function()
			
			if self:IsBroken() then
				return
			end
			
			self.Instance.HingeA.AlignOrientation.Responsiveness = StartedResponsiveness
			self.Instance.HingeB.AlignOrientation.Responsiveness = StartedResponsiveness
			self.Instance.HingeA.Door.CanCollide = true
			self.Instance.HingeB.Door.CanCollide = true
		end))
	end
end

function DoubleDoor.OnOpen(self: Component, player: Player, playerPosition: Vector3?)
	BaseDoor.OnOpen(self, player, playerPosition)
	
	if RunService:IsServer() then
		
		local playerPosition = playerPosition or player.Character.HumanoidRootPart.Position
		local OpenDirection = self:GetOpenDirection(playerPosition) == "Forward" and 1 or -1

		local HingeAttachmentA = self.Instance.Root.HingeA :: Attachment
		local HingeAttachmentB = self.Instance.Root.HingeB :: Attachment

		HingeAttachmentA.CFrame = self.InitialCFrames[HingeAttachmentA] * CFrame.Angles(-OpenDirection * PI / 2, 0, 0)
		HingeAttachmentB.CFrame = self.InitialCFrames[HingeAttachmentB] * CFrame.Angles(OpenDirection * PI / 2, 0, 0)
	end
end

function DoubleDoor.OnClose(self: Component, player: Player)
	BaseDoor.OnClose(self, player)
	
	if RunService:IsServer() then
		
		local HingeAttachmentA = self.Instance.Root.HingeA :: Attachment
		local HingeAttachmentB = self.Instance.Root.HingeB :: Attachment
		
		HingeAttachmentA.CFrame = self.InitialCFrames[HingeAttachmentA]
		HingeAttachmentB.CFrame = self.InitialCFrames[HingeAttachmentB]
	end
end

function DoubleDoor.OnConstructServer(self: Component)
	
	self.InitialCFrames = {
		[self.Instance.Root.HingeA] = self.Instance.Root.HingeA.CFrame,
		[self.Instance.Root.HingeB] = self.Instance.Root.HingeB.CFrame,
	}
	
	self.Instance.HingeA:ClearAllChildren()
	self.Instance.HingeB:ClearAllChildren()
	
	BaseDoor.OnConstructServer(self)
end

function DoubleDoor.OnConstructClient(self: Component)
	BaseDoor.OnConstructClient(self)
	
	local ClientHingeA = self:GetReferenceInstance().HingeA:Clone() :: BasePart
	local ClientHingeB = self:GetReferenceInstance().HingeB:Clone() :: BasePart
	
	ClientHingeA.Parent = self.Instance
	ClientHingeB.Parent = self.Instance
	
	ClientHingeA:PivotTo(self.Instance.HingeA.CFrame)
	ClientHingeB:PivotTo(self.Instance.HingeB.CFrame)
	
	ClientHingeA.AlignOrientation.Attachment1 = self.Instance.Root.HingeA
	ClientHingeB.AlignOrientation.Attachment1 = self.Instance.Root.HingeB
	ClientHingeA.AlignOrientation.Attachment0 = ClientHingeA.Door.Hinge
	ClientHingeB.AlignOrientation.Attachment0 = ClientHingeB.Door.Hinge
	
	ClientHingeA.HingeConstraint.Attachment1 = self.Instance.Root.HingeA
	ClientHingeB.HingeConstraint.Attachment1 = self.Instance.Root.HingeB
	ClientHingeA.HingeConstraint.Attachment0 = ClientHingeA.Door.Hinge
	ClientHingeB.HingeConstraint.Attachment0 = ClientHingeB.Door.Hinge
	
	self.InitialCFrames = {
		[ClientHingeA.Door.Hinge] = ClientHingeA.Door.Hinge.CFrame,
		[ClientHingeB.Door.Hinge] = ClientHingeB.Door.Hinge.CFrame,
	}
	
	for _, a: BasePart? in ipairs(self.Instance:GetDescendants()) do
		
		if not a:IsA("BasePart") then
			continue
		end

		a.CollisionGroup = "Doors"
	end
	
	self.Instance.HingeA:Destroy()
	self.Instance.HingeB:Destroy()
end

--//Returner

return DoubleDoor