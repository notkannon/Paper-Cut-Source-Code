--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local RolesManager = Classes.GetSingleton("RolesManager")

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

--//Constants

local FOOTPRINT_LIFETIME = 10

--//Variables

local Player = Players.LocalPlayer
local Flair = Refx.CreateEffect("Flair") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Janitor: Janitor.Janitor,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, { PlayerTypes.Character }>
export type Effect = Refx.Effect<MyImpl, Fields, { PlayerTypes.Character }>

--//Functions

local function CreateTrailPoint(cframe: CFrame, timestamp: number)
	
	local Effect = ReplicatedStorage.Assets.Particles.Specific.Skill.Flair.Flair:Clone()
	local TimeRemains = FOOTPRINT_LIFETIME - (os.clock() - timestamp)
	
	local a = Instance.new("Attachment")
	a.WorldCFrame = cframe
	a.Visible = true
	
	game:GetService("Debris"):AddItem(a, 3)
	
	Effect.ZOffset = 3
	Effect.Lifetime = NumberRange.new( TimeRemains )
	Effect.Transparency = NumberSequence.new(1 - TimeRemains / FOOTPRINT_LIFETIME, 1)
	
	EffectUtility.EmitParticlesInWorldSpace(
		cframe * CFrame.Angles(math.rad(90), 0, 0),
		{ Effect }
	)
end

--//Methods

function Flair.OnConstruct(self: Effect)
	
	self.Janitor = Janitor.new()
	
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
	self.DestroyOnLifecycleEnd = false
end

function Flair.OnStart(self: Effect, characters: { PlayerTypes.Character })
	
	for _, Character in ipairs(characters) do
		
		local Player = Players:GetPlayerFromCharacter(Character)
		local Role = RolesManager:GetPlayerRoleString(Player)
		
		--any Student appearance
		local StudentAppearance = ComponentsManager.GetFirstComponentInstanceOf(Character, `StudentAppearance`)
		
		--tryna get appearance module to get footprints data
		if not StudentAppearance then
			continue
		end
		
		--new footprints connection
		self.Janitor:Add(
			StudentAppearance.Janitor:Add(
				StudentAppearance.FootprintAdded:Connect(function(cframe)
					CreateTrailPoint(cframe, os.clock())
				end)
			)
		)
		
		for _, Footprint: { CFrame: CFrame, Timestamp: number } in ipairs(StudentAppearance.Footprints) do
			
			--skip old footprints
			if os.clock() - Footprint.Timestamp > FOOTPRINT_LIFETIME then
				continue
			end
			
			CreateTrailPoint(
				Footprint.CFrame,
				Footprint.Timestamp
			)
		end
	end
end

function Flair.OnDestroy(self: Effect)
	print("Destroying flair efect owdaodsd")
	self.Janitor:Destroy()
end

--//Return

return Flair