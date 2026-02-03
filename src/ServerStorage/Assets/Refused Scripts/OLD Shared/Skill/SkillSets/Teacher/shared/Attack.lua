local Shared = shared.Server or shared.Client

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Imports
local WCS = require(ReplicatedStorage.Package.wcs)
local Util = require(ReplicatedStorage.Shared.Util)
local RaycastHitbox = require(ReplicatedStorage.Package.RaycastHitboxV4)
local AttackEffect = require(ReplicatedStorage.Shared.Effects.Skill.Attack)
local DoorsService = require(ReplicatedStorage.Shared.DoorsService)
local HitTracker = require(ReplicatedStorage.Package.HitTracker)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)
local CharacterComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent.CharacterComponent)
local BaseSkill = require(ReplicatedStorage.Shared.Skill.SkillSets.BaseSkill)

--//Variables
local DoorRaycastParams = RaycastParams.new()
DoorRaycastParams.FilterDescendantsInstances = { workspace.Players }
DoorRaycastParams.FilterType = Enum.RaycastFilterType.Include
DoorRaycastParams.IgnoreWater = true

local Animations = ReplicatedStorage.Assets.Animations.Teacher
local WeaponSlarksEffect = require(ReplicatedStorage.Shared.Effects.Attack.WeaponSparks)
local AttackEffect = require(ReplicatedStorage.Shared.Effects.Skill.Attack)
local Attack = WCS.RegisterSkill("Attack", BaseSkill)

--//Methods
function Attack:OnConstruct()
	local PlayerObject = PlayerComponent.GetObjectFromInstance(self.Player)
	local CharacterObject = CharacterComponent.GetObjectFromPlayer(self.Player)
	
	local OverrideData = PlayerObject.Role.skills_data.Attack
	self.Component = CharacterObject
	self.Role = PlayerObject.Role
	
	self.Data = {
		Icon = OverrideData.SkillIcon,
		Name = "Attack",
		Visible = true,
		Cooldown = OverrideData.Cooldown,
		Description = "Basic teacher's skill. Appears you to Attack in your facing direction.",
		DisplayOrder = 1,
	}
end

function Attack:GetPlayerWrapperFromBasePart(part: BasePart)
	local CharacterModel = part:FindFirstAncestorOfClass("Model")

	if not CharacterModel
		or CharacterModel == self.Character.Instance
		or not CharacterModel:FindFirstChildOfClass("Humanoid")
	then return end

	return PlayerComponent.GetObjectFromCharacter(CharacterModel)
end

-- main attack handler
function Attack:OnStartServer()	
	local Hitboxes = {}
	local HitPlayers = {}
	
	-- getting/creating hitboxes from player`s model
	for _, Part: BasePart in ipairs(self.Character.Instance:GetChildren()) do
		if not Part:GetAttribute("Weapon") then continue end
		local Hitbox = RaycastHitbox.GetHitbox(Part) 
		 
		 -- initializing new hitbox if not exists
		if not Hitbox then
			Hitbox = RaycastHitbox.new(Part)
			Hitbox.Visualizer = false
			
			-- connecting to hitbox (once when initialized)
			Hitbox.OnHit:Connect(function(hit: BasePart, _, result: RaycastResult)
				local PlayerObject = self:GetPlayerWrapperFromBasePart(hit)
				
				-- effect applying
				if not PlayerObject then
					local DoorObject = DoorsService:GetDoorByInstance(hit:FindFirstAncestorWhichIsA('Model'))
					if DoorObject then
						-- LOL YEAH
						DoorObject:TakeDamage(self.Player, 20)
					end
					
					--[[local cframe = CFrame.lookAt(result.Position, result.Position + result.Normal)
					WeaponSlarksEffect.new(cframe):Start(Util.GetPlayersExcluding()) --self.Player]]
					return
				end
				
				--NOTICE: We using 2 types of hitboxes: RaycastHitbox - gore applying, Box - damage registering
				--PlayerObject.Character.Gore:RegisterDamage(self.Character.Player, hit.Name, 0)
				if hit:GetAttribute('Health') then
					local Health: number = hit:GetAttribute('Health')
					hit:SetAttribute('Health', math.clamp(Health - 15, 0, 100))
				end
			end)
		end
		
		table.insert(Hitboxes, Hitbox)
	end
	
	-- getting random attack animation track
	local AnimationTrack: AnimationTrack = self.Component.Animator.Animations[ 'Attack' .. math.random(1, 3) ].Track
	
	-- starting all hitboxes when animation reaches START keyframe
	self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("HitStart"):Connect(function()
		for _, Hitbox in ipairs(Hitboxes) do
			Hitbox:HitStart()
		end
		
		-- effect replication
		AttackEffect.new(self.Character.Instance)
			:Start(game:GetService('Players'):GetPlayers())
		
		-- debounce 😎
		local BoxAppearLast = 0
		
		-- box hitbox frame check
		self.Janitor:Add(RunService.Heartbeat:Connect(function()
			if os.clock() - BoxAppearLast < .03 then return end
			BoxAppearLast = os.clock()
			
			-- predicting hitbox position
			local Velocity = self.Character.Instance.HumanoidRootPart.AssemblyLinearVelocity.Magnitude
			
			-- getting characters which was detected in hitbox
			local CharactersIn = HitTracker.GetCharactersInHitbox(
				self.Character.Instance.HumanoidRootPart.CFrame,
				{ Size = Vector3.new(7, 5, 7), Offset = Vector3.new(0, 0, -3.5 - math.sqrt(Velocity * 2)) },
				Enum.RaycastFilterType.Include,
				{ workspace.Players }
			)
			
			-- parse registered table
			for _, Character in ipairs(CharactersIn) do
				
				-- pass if we hit own character
				if Character == self.Character.Instance
					or table.find(HitPlayers, Character)
				then continue end
				
				if Shared._requirements.HideoutService:GetPlayerHideout() then
					continue
				end
				
				-- TODO: Rework damage registering
				Character:FindFirstChildOfClass("Humanoid"):TakeDamage(15)
				table.insert(HitPlayers, Character)
			end
		end), "Disconnect", "Hitbox")
	end))
	
	-- removing hitboxes when animation reaches END keyframe
	self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("HitEnd"):Connect(function()
		for _, Hitbox in ipairs(Hitboxes) do
			Hitbox:HitStop()
		end
		
		self.Janitor:Remove("Hitbox")
	end))
	
	-- applying cooldown to skill
	AnimationTrack.Priority = Enum.AnimationPriority.Action4
	AnimationTrack.Looped = false
	AnimationTrack:Play()
	
	-- cooldown
	AnimationTrack.Stopped:Wait()
	self:ApplyCooldown(self.Data.Cooldown)
end

-- client attack visualizer
function Attack:OnStartClient()
	Shared._requirements.CharacterView:GetCurrentViewmodel():TestAttack()
	Shared._requirements.Camera:Shake(2.5, 1, 'Bump')
end

return Attack