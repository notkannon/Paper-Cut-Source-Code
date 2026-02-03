--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)
local Utility = require(ReplicatedStorage.Shared.Utility)
local Type = require(ReplicatedStorage.Packages.Type)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local Promise = require(ReplicatedStorage.Packages.Promise)

--//Variables

local LocalPlayer = Players.LocalPlayer
local BaseDoorProtector = BaseComponent.CreateComponent("BaseDoorProtector", {

	isAbstract = true,
	ancestorWhitelist = { workspace },

}, SharedComponent) :: Impl

--//Types

export type Fields = {

	Door: unknown,
	Owner: Player?,
	Interaction: Interaction.Component,

} & SharedComponent.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),
	
	TakeDamage: (self: Component, damageContainer: WCS.DamageContainer) -> (),
	
	OnConstruct: (self: Component, options: SharedComponent.SharedComponentConstructOptions?, owner: Player?) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseDoorProtector", Instance, SharedComponent.SharedComponentConstructOptions?, Player?>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseDoorProtector", Instance, SharedComponent.SharedComponentConstructOptions?, Player?>

--//Methods

function BaseDoorProtector.TakeDamage(self: Component, damageContainer: WCS.DamageContainer)
	print("Taken protected damage", damageContainer.Source and damageContainer.Source.Player, self.Owner)
end

function BaseDoorProtector.OnConstruct(self: Component, options: SharedComponent.SharedComponentConstructOptions?, owner: Player?)
	SharedComponent.OnConstruct(self, options)
	
	--filling fields
	self.Door = ComponentsUtility.GetComponentFromDoor(self.Instance)
	self.Owner = owner
	
	--local function PromiseChild(inst: Instance, name: string)
	--	local Child = inst:FindFirstChild(name)

	--	if Child then
	--		return Promise.resolve(Child)
	--	end

	--	return Promise.fromEvent(inst.ChildAdded, function(potentialChild: Instance)
	--		return potentialChild.Name == name
	--	end)
	--end
end

function BaseDoorProtector.OnConstructServer(self: Component)
	
	local Root = self.Instance:FindFirstChild("Root") :: BasePart
	local Barrier = self.Janitor:Add(Instance.new("Part"), nil, "Barrier")
	
	Barrier.Parent = workspace.Temp
	Barrier.Anchored = true
	Barrier.Material = Enum.Material.ForceField
	Barrier.Size = Root.Size
	Barrier.CFrame = Root.CFrame
	Barrier.CanCollide = true
	Barrier.Transparency = 1
	
	local ProximityPrompt = self.Janitor:Add(Instance.new("ProximityPrompt"))
	Utility.ApplyParams(ProximityPrompt,
		{
			RequiresLineOfSight = false,
			MaxActivationDistance = 0,
			HoldDuration = 15,
			ActionText = self.ActionText or "Remove",
			
			Parent = Barrier
		}
	)
	ProximityPrompt:AddTag("Interaction")
	
	self.Janitor:AddPromise(ComponentsManager.Await(ProximityPrompt, Interaction):timeout(35):andThen(function(inter: Interaction)
		self.Interaction = inter
		print(inter)
		
		self.Janitor:Add(task.delay(0.5, function()
			ProximityPrompt.MaxActivationDistance = 10
		end))

		self.Interaction:SetFilteringType("Include")
		self.Interaction:SetTeamAccessibility("Student", true)

		self.Janitor:Add(self.Interaction.Started:Connect(function(plr)
			self.Door:RemoveProtector(self) -- without it SetOpened doesnt work
			self.Door:SetOpened(true)
			self.Door:OnOpen(plr)
			self.Door.Interaction:ApplyCooldown(0.5)
			self:Destroy()
		end))
	end))

end

--//Returner

return BaseDoorProtector