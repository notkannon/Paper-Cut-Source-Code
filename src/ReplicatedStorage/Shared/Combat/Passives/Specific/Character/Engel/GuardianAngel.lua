--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
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

local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

local ModifiedDamageTakenStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedDamageTaken)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local ChaseReplicator = RunService:IsServer() and require(ServerScriptService.Server.Services.ChaseReplicator) or nil

--//Variables

local GuardianAngel = BaseComponent.CreateComponent("GuardianAngel", {

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

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "GuardianAngel", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "GuardianAngel", PlayerTypes.Character>

--//Methods

function GuardianAngel.OnEnabledServer(self: Component)
	
	local Config = self:GetConfig()
	local LastTimestamp = os.clock()
	
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Instance)
	local DamageTakenModifier = self.EnabledJanitor:Add(ModifiedDamageTakenStatus.new(WCSCharacter, "Multiply", Config.DamageTakenMultiplier, {Tag = "GuardianAngel"})) :: WCS.StatusEffect
	DamageTakenModifier.DestroyOnEnd = false -- we need special behavior for this modifier
	
	local StudentHighlights = {} :: { [Player]: Refx.ServerProxy }

	--literally
	local function RemoveHighlight(player: Player)

		if StudentHighlights[player] then

			local Effect = StudentHighlights[player]

			pcall(Effect.Destroy, Effect)

			StudentHighlights[player] = nil
		end
	end

	--checks if player should get protection effect
	local function ApplyCheck(characters: { PlayerTypes.Character? })
		
		if #characters > 0  and not DamageTakenModifier:GetState().IsActive then
			
			DamageTakenModifier:Start()
			
		elseif #characters == 0 and DamageTakenModifier:GetState().IsActive then
			
			DamageTakenModifier:End()
			
		end
	end
	
	--memory clean
	self.EnabledJanitor:Add(Players.PlayerRemoving:Connect(RemoveHighlight))
	
	--could locate every player nearly
	self.EnabledJanitor:Add(RunService.Heartbeat:Connect(function()
		
		--rate limit
		if os.clock() - LastTimestamp < 0.3 then
			return
		end
		
		LastTimestamp = os.clock()
		
		if not self.Instance then
			return
		end
		
		--initials
		local Characters = {}
		local OwnPosition = self.Instance.PrimaryPart.Position :: Vector3
		
		--parsing plrs
		for _, Player: Player in ipairs(MatchService:GetAlivePlayers("Student")) do
			
			--ignore ourself
			if Player == self.Player then
				continue
			end
			
			local Character = Player.Character :: PlayerTypes.Character
			local Position = Character.PrimaryPart.Position
			local CharacterName = RolesManager:GetPlayerCharacterName(Player, "Student")
			
			--print(Character, CharacterName, (OwnPosition - Position).Magnitude)
			
			if (OwnPosition - Position).Magnitude > Config.MaxProtectionDistance or (CharacterName == "Engel" and Config.IgnoreOtherEngels) then
				RemoveHighlight(Player)
				continue
			end
			
			table.insert(Characters, Character)
			
			if not StudentHighlights[Player] then
				local Highlight = HighlightPlayerEffect.new(Character, {

					mode = "Overlay",
					color = Color3.new(0.0156863, 0.678431, 0.00392157),
					lifetime = 10000,
					fadeInTime = 0.5,
					fadeOutTime = 0.5,
					transparency = 0.7,
					respectTargetTransparency = false

				})
				
				Highlight:Start({ self.Player })
				
				StudentHighlights[Player] = Highlight
				
				--removing on passive disabling/destroying
				self.EnabledJanitor:Add(function()
					--if not Highlight.IsDestroyed then
						Highlight:Destroy()
					--end
				end)
			end
		end
		
		--so
		ApplyCheck(Characters)
		
		--memory things
		table.clear(Characters)
	end))
end

--//Returner

return GuardianAngel