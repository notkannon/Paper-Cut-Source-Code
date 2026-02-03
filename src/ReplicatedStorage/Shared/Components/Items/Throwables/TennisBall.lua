--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService("Players")

--//Imports

local ItemsData = require(ReplicatedStorage.Shared.Data.Items)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local BaseThrowable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseThrowable)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local ThrowableImpactEffect = require(ReplicatedStorage.Shared.Effects.Specific.Components.Items.ThrowableImpact)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

local StunnedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Stunned)

--//Functions

local function SerializeVector3(vec: Vector3) : { number }
	return { vec.X, vec.Y, vec.Z }
end

--//Variables

local ThrowableTennisBallItem = BaseComponent.CreateComponent("ThrowableTennisBallItem", {
	isAbstract = false,
}, BaseThrowable) :: BaseThrowable.Impl

--//Methods

function ThrowableTennisBallItem.OnFlightStart(self, instance: BasePart, janitor: any, userData: { any })
	BaseThrowable:OnFlightStart(instance, janitor, userData)
	self.DynamicInstance = instance
	
	--print('flying yippe', instance, self.Instance, userData, instance:FindFirstChildWhichIsA("LinearVelocity"))

	local Alignment = instance:FindFirstChild("Alignment")
	
	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = instance
		Alignment.Name = "Alignment"
	end
	
	while instance:FindFirstChildWhichIsA("LinearVelocity") do
		instance:FindFirstChildWhichIsA("LinearVelocity"):Destroy()
	end
	local Velocity = instance:FindFirstChildWhichIsA("LinearVelocity") or Instance.new("LinearVelocity")
	Velocity.Parent = instance
	Velocity.MaxForce = 2000
	Velocity.Attachment0 = Alignment
	Velocity.VectorVelocity = userData.Direction * math.max(0.3, userData.Strength) * 110
	Velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	
	local Gravity = 0 --0.15 + 0.3*math.clamp(1-userData.Strength, 0, 1)
	local debugTick = tick()

	janitor:Add(RunService.Stepped:Connect(function(deltaTime)
		if tick() - debugTick > 0.5 then
			debugTick = tick()
			--print(instance, instance.Position, Velocity.VectorVelocity, userData.Direction * math.max(0.3, userData.Strength) * 20)
		end
		instance.AssemblyAngularVelocity = Vector3.one * instance.AssemblyLinearVelocity.Magnitude / 15

		Velocity.VectorVelocity = Vector3.new(
			Velocity.VectorVelocity.X,
			Velocity.VectorVelocity.Y - Gravity * deltaTime,
			Velocity.VectorVelocity.Z
		)
	end), nil, "VelocityUpkeep")
end

function ThrowableTennisBallItem.OnConstruct(self: Component)
	BaseThrowable.OnConstruct(self)
	self.Bounces = 0
	self.BaseStunDuration = 4
	self.DestroyOnHit = false
	self.LastBounceTick = 0
end

function ThrowableTennisBallItem.OnHit(self: Component, raycastResult: RaycastResult, playerHit: Player?)
	
	--print(self, raycastResult, playerHit)
	
	local UnclipHelp = false
	
	if self.LastBounceTick and os.time() - self.LastBounceTick <= 0.001 then
		--return
		self.Bounces -= 1
		UnclipHelp = true
	end

	if RunService:IsServer() then
		
		local ThrowableEffect = ThrowableImpactEffect.new(raycastResult.Position)
		ThrowableEffect:Start(Players:GetPlayers())
		
		local PlayerComponent = ComponentsManager.Get(playerHit, "PlayerComponent")
		if not PlayerComponent then
			return
		end
		
		if PlayerComponent:IsKiller() then
			local CharacterComponent = PlayerComponent.CharacterComponent
			if not CharacterComponent then
				return
			end
			
			local WCSCharacter = CharacterComponent.WCSCharacter :: WCS.Character
			if not WCSCharacter then
				return
			end
			
			local StatusEffectBlacklist = WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, {"Invincible", "Handled", "Stunned"})
			if not StatusEffectBlacklist then
				-- Creating Ouch Sound
				SoundUtility.CreateTemporarySound(
					SoundUtility.Sounds.Players.Replicas.Ouch
				).Parent = CharacterComponent.HumanoidRootPart
				
				SoundUtility.CreateTemporarySound(
					SoundUtility.Sounds.Players.Gore.Impact
				).Parent = ComponentsManager.HumanoidRootPart
				
				local StunDuration = self.BaseStunDuration
				if self.Bounces < 1 then
					StunDuration = self.BaseStunDuration * 0.5
				end
				
				local StunnedEffect = StunnedStatus.new(WCSCharacter)
				StunnedEffect:Start(StunDuration)
				
				--// Let make little gambling this
				-- you know it can bounce into you right?.. also why == 10? that's 5% chance
				local ChangeWithDamage = math.random(1, 20)
				if ChangeWithDamage == 10 then
					local Damage = math.random(1, 15)
					
					-- Taking Damage
					WCSCharacter:TakeDamage(Damage)
				end
				
			end
		end
		
		-- Adding Bouces
		self.Bounces += 1
		self.LastBounceTick = os.time()
	else
		if self.Bounces < 5 then
			local Velocity = self.DynamicInstance.LinearVelocity.VectorVelocity
			print(Velocity)
			
			-- Provitia Code for tennis ball bounce
			local v : Vector3 = Velocity.Unit
			local n : Vector3 = raycastResult.Normal.Unit
			local u : Vector3 = (v:Dot(n) / n:Dot(n)) * n 
			local w : Vector3 = v - u
			local newVelocity : Vector3 = (w - u).Unit
			
			if UnclipHelp then
				newVelocity = (newVelocity + Vector3.new(0, 1, 0)).Unit
			end
			
			self:HandleAssumeStartServer(
				nil, -- no player
				0.75,
				SerializeVector3(raycastResult.Position - Velocity.Unit * 2),
				SerializeVector3(newVelocity),
				{
					CastType = "Shapecast",
					Radius = (self.DynamicInstancep.Size :: Vector3).X * 2
				}
			)
		else
			self.Instance:Destroy()
		end
	end
end

--//Returner

return ThrowableTennisBallItem