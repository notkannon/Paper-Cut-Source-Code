--//Services

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentTypes = require(ServerScriptService.Server.Types.ComponentTypes)
local BaseAppearance = require(ReplicatedStorage.Shared.Components.Abstract.BaseAppearance)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local CorpseEffect = require(ReplicatedStorage.Shared.Effects.PlayerCorpse)
local RagdolledStatusEffect = require(ReplicatedStorage.Shared.Combat.Statuses.Ragdolled)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)

--//Variables

local DamageEventsFolder = ServerScriptService.Server.Components.CharacterComponent.DamageEvents
local AppearanceComponents = ReplicatedStorage.Shared.Components.Appearance

local CharacterComponent = BaseComponent.CreateComponent("CharacterComponent", {
	isAbstract = false,
}) :: ComponentTypes.CharacterComponentImpl

--//Methods

function CharacterComponent.ApplyRagdoll(self: ComponentTypes.CharacterComponent, duration: number?)
	RagdolledStatusEffect.new(self.WCSCharacter):Start(duration)
end

function CharacterComponent.RemoveRagdoll(self: ComponentTypes.CharacterComponent)
	WCSUtility.EndAllStatusEffectsOfType(self.WCSCharacter, RagdolledStatusEffect)
end

function CharacterComponent._ApplyPassives(self: ComponentTypes.CharacterComponent)
	
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
	local PassivesData = RoleConfig.PassivesData
	
	if not PassivesData then
		return
	end
	
	--applying passives components
	for PassiveName, _ in pairs(PassivesData) do
		self.Janitor:Add(task.spawn(ComponentsManager.Add, self.Instance, PassiveName))
	end
end

function CharacterComponent._ApplyRole(self: ComponentTypes.CharacterComponent)
	
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
	local Moveset = WCS.GetMovesetObjectByName(RoleConfig.MovesetName)
	
	assert(Moveset, `Moveset for role { RoleConfig.Name } doesn't exist`)
	
	--wcs character related
	self.WCSCharacter:ApplyMoveset(Moveset)
	self.WCSCharacter:SetDefaultProps(TableKit.MergeDictionary(self.WCSCharacter:GetDefaultProps(), {
		
		--set default walkspeed for player
		WalkSpeed = RoleConfig.CharacterData.DefaultWalkSpeed
		
	} :: WCS.AffectableHumanoidProps))
end

function CharacterComponent._InitCustomBehavior(self: ComponentTypes.CharacterComponent)
	
	self.Humanoid.RequiresNeck = false
	self.Humanoid.BreakJointsOnDeath = false
	self.Humanoid.EvaluateStateMachine = true
	
	self.Humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
	self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	
	-- collision removal & group set
	for _, Bodypart: BasePart in ipairs(self.Instance:GetDescendants()) do
		
		if not Bodypart:IsA('BasePart') then
			continue
		end

		Bodypart.CollisionGroup = "Players"
		
		--skip for collider
		if Bodypart.Name == "Collider" then
			
			Bodypart.CanCollide = false -- umm maybe ill leave it like this
			Bodypart.Transparency = 1
			Bodypart.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0)
			
			continue
		end
		
		Bodypart.CanCollide = false

		-- bodypart check
		if Bodypart.Parent == self.Instance
			or Bodypart == self.Humanoid.RootPart then
			
			continue
		end

		Bodypart.CanTouch = false
		Bodypart.CanQuery = false
	end
	
	--removing sliding effect when moving
	self.HumanoidRootPart.CanCollide = true
	self.HumanoidRootPart.Transparency = 1
	self.HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0)

	-- collision hitbox
	if not self.Instance:FindFirstChild("Collider") then
		
		local ColliderPart: Part = Instance.new('Part')
		
		Utility.ApplyParams(ColliderPart, {
			
			Name = "Collider",
			Size = Vector3.one * 3,
			Shape = Enum.PartType.Ball,
			Parent = self.Instance,
			Massless = true,
			CanTouch = false,
			CanCollide = true,
			CastShadow = false,
			Transparency = 1,
			CollisionGroup = "Players",
		})
		
		local Weld: Weld = Instance.new('Weld', ColliderPart)
		Weld.Part0 = self.Instance.PrimaryPart
		Weld.Part1 = ColliderPart
	end
end



function CharacterComponent._InitDamageEvents(self: ComponentTypes.CharacterComponent)
	
	self.DamageEvents = {
		DamageDealt = {},
		DamageTaken = {},
	}
	
	for _, DamageEvent in ipairs(DamageEventsFolder:GetDescendants()) do
		
		if not DamageEvent:IsA("ModuleScript") then
			continue
		end

		local EventData: ComponentTypes.DamageHandler = require(DamageEvent)
		
		self.DamageEvents[DamageEvent.Parent.Name][EventData.EventName] = {
			IsActive = EventData.IsActive,
			Handler = EventData.Handler,
		}
	end
	
	self.Janitor:Add(self.WCSCharacter.DamageDealt:Connect(function(DamageContainer)
		
		for _, DamageEvent in pairs(self.DamageEvents.DamageDealt) do
			
			if not DamageEvent.IsActive then
				continue
			end
			
			ThreadUtility.UseThread(DamageEvent.Handler, self, DamageContainer)
		end
	end))

	self.Janitor:Add(self.WCSCharacter.DamageTaken:Connect(function(DamageContainer)
		
		for _, DamageEvent in pairs(self.DamageEvents.DamageTaken) do
			
			if not DamageEvent.IsActive then
				continue
			end
			
			ThreadUtility.UseThread(DamageEvent.Handler, self, DamageContainer)
		end
	end))
end

function CharacterComponent._InitAppearance(self: ComponentTypes.CharacterComponent)
	
	local RoleConfig = self.PlayerComponent:GetRoleConfig()
	local AppearanceName = self.PlayerComponent:IsSpectator() and "Spectator" or RoleConfig.CharacterName
	local Impl = ComponentsManager.GetImpl(`{ AppearanceName }Appearance`) :: BaseAppearance.Impl?
		
	if not Impl then
		
		warn("Appearance module not found for", AppearanceName)
		
		return
	end
	
	self.Appearance = self.Janitor:Add(ComponentsManager.Add(self.Instance, Impl), "Destroy")
end

function CharacterComponent.OnConstructServer(self: ComponentTypes.CharacterComponent, playerComponent: ComponentTypes.PlayerComponent)
	
	self.PlayerComponent = playerComponent

	playerComponent.CharacterComponent = self
	
	self.Player = Players:GetPlayerFromCharacter(self.Instance)
	self.Humanoid = self.Instance:FindFirstChildWhichIsA("Humanoid") :: PlayerTypes.IHumanoid
	self.Instance.Parent = workspace.Characters
	self.HumanoidRootPart = self.Instance.HumanoidRootPart :: PlayerTypes.HumanoidRootPart
	self.Instance.Archivable = true
	self.Instance.PrimaryPart = self.HumanoidRootPart
	
	--removing this shit
	if self.Instance:FindFirstChild("AnimSaves") then
		
		warn(`Anim saves was destroyed in character model { self.Instance:GetFullName() }. Did you forget to remove it manually?`)
		
		self.Instance:FindFirstChild("AnimSaves"):Destroy()
	end
	
	self.WCSCharacter = WCS.Character.new(self.Instance)
	
	--TODO: Make character service which looks for player current state respawn responsible
	self.Janitor:Add(self.Humanoid.Died:Once(function()
		
		--making player not fell under map
		self:ApplyRagdoll()
		
		--making base model invisible
		for _, Descendant: Instance in ipairs(self.Instance:GetDescendants()) do
			
			if not (Descendant:IsA("BasePart") or Descendant:IsA("Decal")) then
				continue
			end
			
			Descendant:SetAttribute("InitialTransparency", Descendant.Transparency)
			Descendant.Transparency = 1
		end
		
		--TEST
		if not self.PlayerComponent:IsKiller() then
			
			local Velocities = {}
			
			for _, BasePart: BasePart in ipairs(self.Instance:GetChildren()) do
				
				if not BasePart:IsA("BasePart") then
					continue
				end
				
				table.insert(Velocities, {
					BasePart,
					BasePart.AssemblyLinearVelocity
				})
			end
			
			CorpseEffect.new(
				
				self.Instance,
				{{self.HumanoidRootPart, self.HumanoidRootPart.CFrame.LookVector}}
				
			):Start(Players:GetPlayers())
		end
		
		--self.WCSCharacter:ClearMoveset()
		self.WCSCharacter:Destroy()
	end))

	self.Instance:AddTag("Character")

	self:_ApplyRole()
	self:_ApplyPassives()
	self:_InitAppearance()
	self:_InitDamageEvents()
	self:_InitCustomBehavior()
end

function CharacterComponent.OnDestroy(self: ComponentTypes.CharacterComponent)
	
	if self.PlayerComponent then
		self.PlayerComponent.CharacterComponent = nil
	end
	
	--self.WCSCharacter:ClearMoveset()
	self.WCSCharacter:Destroy()
	self.Janitor:Cleanup()
end

--//Returner

return CharacterComponent