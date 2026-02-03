local Server = shared.Server

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local WCS = require(ReplicatedStorage.Package.wcs)
local Enums = require(ReplicatedStorage.Enums)
local Util = require(ReplicatedStorage.Shared.Util)
local Signal = require(ReplicatedStorage.Package.Signal)
local CharacterComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent.CharacterComponent)
local DownedHealthStatus = require(ReplicatedStorage.Shared.Skill.StatusEffects.Downed)
local InjuredHealthStatus = require(ReplicatedStorage.Shared.Skill.StatusEffects.Injured)


--// INITIALIZATION
local ServerCharacter = setmetatable({}, CharacterComponent)
ServerCharacter.__index = ServerCharacter

-- server Character object constructor
function ServerCharacter.new(player_object, instance: Model)
	local Object = setmetatable(CharacterComponent.new(player_object, instance), ServerCharacter)
	Object:Init()
	return Object
end

--// METHODS
-- initial method override
function ServerCharacter:Init()
	self.Instance.PrimaryPart = self.Instance.HumanoidRootPart
	
	-- humanoid setting up
	local Humanoid: Humanoid = self:GetHumanoid()
	Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	Humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
	Humanoid.BreakJointsOnDeath = false
	Humanoid.RequiresNeck = false
	
	-- player collision initial
	local ColliderPart: Part = Instance.new('Part')
	ColliderPart.Parent = self.Instance.PrimaryPart
	ColliderPart.Shape = Enum.PartType.Cylinder
	ColliderPart.Size = Vector3.one * 3
	ColliderPart.Massless = true
	ColliderPart.CanTouch = false
	ColliderPart.CanCollide = true
	ColliderPart.CastShadow = false
	ColliderPart.Transparency = 1
	
	local Weld: Weld = Instance.new('Weld', ColliderPart)
	Weld.C0 = CFrame.Angles(0, 0, math.pi/2)
	Weld.Part0 = self.Instance.PrimaryPart
	Weld.Part1 = ColliderPart
	
	-- health & collision setting
	for _, Bodypart: BasePart in ipairs(self.Instance:GetDescendants()) do
		if not Bodypart:IsA('BasePart') then continue end
		Bodypart.CollisionGroup = "Players"
		
		if Bodypart.Parent == self.Instance then
			Bodypart.CanCollide = false
			if Bodypart.Name == 'HumanoidRootPart' then continue end
			Bodypart:SetAttribute('Health', 100)
		end
	end
	
	-- setting player`s character instance
	self.Player.Character = self.Instance
	self.Player.SharedReplica:SetValue('Character.Instance', self.Instance)
	
	-- super initialization
	CharacterComponent.Init(self)
end

-- initial method for Wcs character
function ServerCharacter:InitWcsCharacter()
	assert(not self.WcsCharacterObject, `WCS character already exists for character "{ self.Instance.Name }"`)
	
	-- WCS character initialization
	local WcsCharacterObject = WCS.Character.new( self.Instance )
	self.WcsCharacterObject = WcsCharacterObject
	
	-- default humanoid properties
	WcsCharacterObject:SetDefaultProps({
		WalkSpeed = self.Player.Role.character.DefaultWalkspeed,
	})
	
	-- Wcs character moveset (skillset) applying
	
	print(self.Player.Role.moveset_name)
	WcsCharacterObject:ApplyMoveset(WCS.GetMovesetObjectByName( self.Player.Role.moveset_name ))
	
	-- saving status effects
	local InjuredStatus = InjuredHealthStatus.new(WcsCharacterObject)
	local DownedStatus = DownedHealthStatus.new(WcsCharacterObject)
	--HiddenStatus.new(WcsCharacterObject)
	
	-- health status effect handling
	local Humanoid: Humanoid = self.Instance:FindFirstChildWhichIsA('Humanoid')
	Humanoid.HealthChanged:Connect(function(health: number)
		if health < 15 then
			-- applying "Downed" health status effect to character
			DownedStatus:Start()
			InjuredStatus:Stop()
			
		elseif health < 50 then
			-- applying "Injured" health status effect to character
			InjuredStatus:Start()
			DownedStatus:Stop()
			
		else -- removing all health status effects
			DownedStatus:Stop()
			InjuredStatus:Stop()
		end
	end)
end

-- handling on server message
function ServerCharacter:OnServerMessage(context: string, ...)
	if context == 'create_wcs_character' then
		if self.WcsCharacterObject then return end
		self:InitWcsCharacter()
		
	elseif context == 'load_local_scripts' then
		for _, LocalScript: LocalScript? in ipairs(self.Instance:GetChildren()) do
			if LocalScript:IsA('LocalScript') then LocalScript.Enabled = true end
		end
	end
end

-- client character destruction
function ServerCharacter:Destroy()
	self.Player.SharedReplica:SetValue('Character.Instance', nil)
	self.WcsCharacterObject:Destroy()
	CharacterComponent.Destroy(self)
end

return ServerCharacter