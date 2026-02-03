--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)
local InteractionService = require(ReplicatedStorage.Shared.Services.InteractionService)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

--//Constants

local DOOR_DETECT_DISTANCE = 3.3
local DOOR_CHECK_RAYCAST_PARAMS = RaycastParams.new()
DOOR_CHECK_RAYCAST_PARAMS.CollisionGroup = "Players"
DOOR_CHECK_RAYCAST_PARAMS.RespectCanCollide = true
DOOR_CHECK_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
DOOR_CHECK_RAYCAST_PARAMS.FilterDescendantsInstances = { workspace.Characters, workspace.Temp }

--//Variables

local Lockup = WCS.RegisterHoldableSkill("Lockup", BaseHoldableSkill)

--//Types

export type Skill = BaseHoldableSkill.BaseHoldableSkill & {
	SpeedModifier: ModifiedSpeedStatus.Status,
}

--//Functions

local function GetDoorComponentFromInteraction(interaction)
	local Model = (interaction.Instance :: ProximityPrompt):FindFirstAncestorWhichIsA("Model")
	
	if not Model or not Model:HasTag("Door") then
		return
	end
	
	return ComponentsManager.GetComponentsFromInstance(Model)[1]
end

--//Methods

function Lockup.Start(self: Skill, ...: any?)
	if RunService:IsServer() then
		
		WCS.Skill.Start(self, ...)
		
		return
	end
	
	if not self.DoorComponentOnFocus then
		return
	end
	
	WCS.Skill.Start(
		self,
		self.DoorComponentOnFocus.Instance,
		self.DoorComponentOnFocus.GetName()
	)
end

function Lockup.OnStartServer(self: Skill, doorInstance, doorImpl)
	local Component = ComponentsManager.Get(doorInstance, doorImpl)
	
	if not Component or Component:IsOpened() then
		return
	end
	
	Component:SetLocked(true)
	
	self:End()
	self:ApplyCooldown(self.FromRoleData.Cooldown)
end

function Lockup.ShouldStart(self: Skill)
	if RunService:IsClient() then
		
		if not self.DoorComponentOnFocus
			or self.DoorComponentOnFocus:IsOpened() then
			
			return false
		end
	end
	
	return BaseHoldableSkill.ShouldStart(self)
end

function Lockup.OnConstructClient(self: Skill)
	--used to track any door while their prompts active
	self.DoorComponentOnFocus = nil
	
	self.GenericJanitor:Add(
		
		InteractionService.InteractionShown:Connect(function(interaction)
			local DoorComponent = GetDoorComponentFromInteraction(interaction)
			
			if not DoorComponent then
				return
			end
			
			self.DoorComponentOnFocus = DoorComponent
			
			self.GenericJanitor:Add(
				
				interaction.Hidden:Once(function()
					if self.DoorComponentOnFocus ~= DoorComponent then
						return
					end
					
					self.DoorComponentOnFocus = nil
				end)
			)
		end)
	)
end

function Lockup.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	self:SetMaxHoldTime(5)

	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {
		--circle
		"Harpoon", "Shockwave",
	}

	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Aiming", "Downed", "Hidden", "Stunned", "Handled", "Physics", "HarpoonPierced",
		-- Speed modifiers
		{"ModifiedSpeed", {"FallDamageSlowed", "Slowed", "Freezed"}},
	}
end

--//Returner

return Lockup