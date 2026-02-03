--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local SFX = SoundUtility.Sounds.Players.Skills.EyeForTrouble.Trigger

local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

--//Variables

local EyeForTroublePassive = BaseComponent.CreateComponent("EyeForTrouble", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),

	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {

} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "EyeForTroublePassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "EyeForTroublePassive", PlayerTypes.Character>

--//Methods


function EyeForTroublePassive.OnEnabledClient(self: Component)
	local Config = self:GetConfig()
	local LastUpdate = os.clock()
	
	self.EnabledJanitor:Add(RunService.Heartbeat:Connect(function()

		--limiting update rate
		if os.clock() - LastUpdate < Config.CooldownTime then
			return
		end
		SoundUtility.CreateTemporarySound(SFX)
		LastUpdate = os.clock()
		
	end))
end

function EyeForTroublePassive.OnEnabledServer(self: Component)
	local Config = self:GetConfig()
	local LastUpdate = os.clock()

	--running detection cycle
	self.EnabledJanitor:Add(RunService.Heartbeat:Connect(function()

		--limiting update rate
		if os.clock() - LastUpdate < Config.CooldownTime then
			return
		end
		
		LastUpdate = os.clock()
		
		local SelfEffect = HighlightPlayerEffect.new(self.Player.Character, {
			color = Color3.fromRGB(255, 57, 57),
			lifetime = Config.SelfHighlightDuration,
			fadeInTime = 0,
			fadeOutTime = 0.5,
			transparency = 0.5,
			respectTargetTransparency = true
		})
		
		local Teachers = {}

		--getting all teachers
		for _, Player: Player in ipairs(MatchService:GetAlivePlayers("Killer")) do
			local Effect = HighlightPlayerEffect.new(Player.Character, {
				color = Color3.fromRGB(255, 57, 57),
				lifetime = Config.TeacherHighlightDuration,
				fadeInTime = 0,
				fadeOutTime = 0.5,
				transparency = 0.5,
				respectTargetTransparency = true
			})

			Effect:Start({ self.Player })
			

			table.insert(Teachers, Player)
			--removing on passive disabling/destroying
			self.EnabledJanitor:Add(function()
				--if not Effect.IsDestroyed then
					Effect:Destroy()
				--end
			end)
		end
		
		-- revealing self to teachers
		SelfEffect:Start(Teachers)
		self.EnabledJanitor:Add(function()
			--if not SelfEffect.IsDestroyed then
				SelfEffect:Destroy()
			--end
		end)
	end))
end

function EyeForTroublePassive.OnConstruct(self: Component, enabled: boolean?)
	BasePassive.OnConstruct(self)
	self.Permanent = true
end

--//Returner

return EyeForTroublePassive