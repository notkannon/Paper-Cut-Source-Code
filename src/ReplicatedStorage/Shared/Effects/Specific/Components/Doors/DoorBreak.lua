--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Utility = require(ReplicatedStorage.Shared.Utility)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local EnumUtility = require(ReplicatedStorage.Shared.Utility.EnumUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local DoorBreak = Refx.CreateEffect("DoorBreak") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Instance: Highlight,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Model, Model>
export type Effect = Refx.Effect<MyImpl, Fields, Model, Model>

--//Methods

function DoorBreak.OnConstruct(self: Effect)
	self.DestroyOnEnd = true
end

function DoorBreak.OnStart(self: Effect, instance: Model, reference: Model)
	
	local Hinges = {
		instance:FindFirstChild("HingeA"),
		instance:FindFirstChild("HingeB"),
	} :: { BasePart }

	for _, Hinge: BasePart in ipairs(Hinges) do

		for _, Child in ipairs(Hinge:GetChildren()) do
			if Child:IsA("BasePart") then
				Child:Destroy()
			end
		end

		local Fractured = reference:Clone() :: Model
		Fractured.Parent = workspace.Temp
		Fractured:PivotTo(Hinge.CFrame)

		for _, Child in ipairs(Fractured:GetChildren()) do
			Child.Parent = Hinge
		end

		Fractured:Destroy()

		for _, Child: Weld? | BasePart? in ipairs(Hinge:GetDescendants()) do

			if Child:IsA("Weld") then

				Child:Destroy()

			elseif Child:IsA("BasePart") then

				Child.CanCollide = true
				Child.CollisionGroup = "Players"

				local Velocity = Instance.new('BodyVelocity')
				Velocity.Velocity = instance.Root.CFrame.LookVector * Child:GetMass() * 30 * instance:GetAttribute("ForceDirection") + Random.new():NextUnitVector() * 7
				Velocity.MaxForce = Vector3.one * 30000
				Velocity.Parent = Child
				Velocity.P = 70

				local Angular = Instance.new('BodyAngularVelocity')
				Angular.AngularVelocity = Random.new():NextUnitVector() * Child:GetMass() * 10
				Angular.MaxTorque = Vector3.one * 300
				Angular.Parent = Child
				Angular.P = 40

				Debris:AddItem(Velocity, .1)
				Debris:AddItem(Angular, .1)
			end
		end

		Hinge.Door.Anchored = true
		Debris:AddItem(Hinge, 7)

		task.delay(5, function()
			
			for _, part: BasePart? in ipairs(Hinge:GetDescendants()) do

				if not part:IsA('BasePart') then
					continue
				end

				TweenUtility.PlayTween(part, TweenInfo.new(2), {Transparency = 1})
			end
		end)
	end
end

--//Returner

return DoorBreak