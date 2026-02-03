--//Service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--//Import

local InteractionProximites = require(script.Interaction)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Utility = require(ReplicatedStorage.Shared.Utility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)

local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes)
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes)

local PlayerController

--//Variables
local GlobalFrozen = false

local Interactable = BaseComponent.CreateComponent("Interactable", {
	tag = "Interactable",
	isAbstract = true,
}) :: Impl

--//Type
export type ApplyTo = "Role" | "Team"

export type BaseInteractionState = {
	Arrow: ImageLabel,
	Sign: ImageLabel & {
		Fill: UIGradient,

		Scale: UIScale,
		Details: TextLabel & {

			Input: ImageLabel
		}
	}
}

export type Fields = {
	_Freeze: boolean,
	_Cooldown: number,

	Instance: ProximityPrompt,	
	BillInteraction: BillboardGui & BaseInteractionState,

	Interaction: BaseInteractionState,
	Params: {},
	Permission: {
		Role: {string},
		Team: {string},
		
		Custom: {number},
	},

	Root: BasePart,
	CurrectPlayer: Player,
	
	Push: Signal.Signal<nil>,
	RbxSignal: RBXScriptSignal
}

export type MyImpl = {
	__index: MyImpl,

	OnConstruct: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),

	IsFreezeActive: (self: Component) -> boolean,
	IsCooldownActive: (self: Component) -> boolean,
	GetCooldown: (self: Component) -> number,
	ApplyCooldown: (self: Component, duration: number) -> (),

	_GetRole: (self: Component) -> string,

	ApplyFreeze: (self: Component, Freeze: boolean) -> (),
	ApplyProximityUI: (self: Component, IsHidden: boolean) -> () ,
	ApplyParams: (self: Component, tag: string, applyTo: ApplyTo, params: { [string]: any }) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, ProximityPrompt, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, ProximityPrompt, {}>

--//Methods

function Interactable.ApplyFreeze(self: Component, Freeze: boolean, Interaction: Interaction?)
	if Interaction and Interaction == self.Interaction then		
		self.Interaction._Freeze = Freeze
	elseif Interaction then
		Interaction._Freeze = Freeze
	else
		GlobalFrozen = Freeze
	end
end

function Interactable.IsFreezeActive(self: Component)
	return GlobalFrozen or false
end

function Interactable.IsCooldownActive(self: Component, interaction: Interaction?)
	return self:GetCooldown(interaction) > 0
end

function Interactable.GetCooldown(self: Component)
	return math.max(0, self._Cooldown - os.clock())
end

function Interactable.IsHasPermissionRole(self: Component, Player: Player)
	if RunService:IsServer() then
		warn("Can't run this function in server")
		return
	end
	
	local RoleAndTeam = {
		Role = PlayerController:GetRole(),
		Team = Player.Team and Player.Team.Name,
	}

	local Interaction = self.Permission.Role[RoleAndTeam.Role] or self.Permission.Team[RoleAndTeam.Team]
	if not table.find(self.Permission.Custom, Player.UserId) and Interaction ~= nil then
		return false
	end
	
	return true
end

function Interactable.ApplyCooldown(self: Component, Duration: number, Interaction: Interaction?)
	local Cooldown = os.clock() + Duration

	if Interaction and Interaction == self.Interaction then		
		self.Interactions._Cooldown = Cooldown
	elseif Interaction then
		Interaction._Cooldown = Cooldown
	else
		self._Cooldown = Cooldown
	end
end

function Interactable.CreateInteraction(self: Component, Tag: string, ApplyTo: string)    	
	local Interaction = {}

	Interaction._Freeze = false
	Interaction._Cooldown = os.clock()

	function Interaction.OnStartServer() end
	function Interaction.OnStartClient() end
	function Interaction.ShouldStart()
		local Cooldown = math.max(0, Interaction._Cooldown - os.clock())

		if Interaction._Freeze or Cooldown > 0 then
			return false
		end

		return true    
	end

	assert(Tag or ApplyTo, "No Tag or ApplyTo args was passed")
	
	self.Interactions[ApplyTo][Tag] = Interaction
	return Interaction 
end

function Interactable.OnConstruct(self: Component)	
	spawn(function()
		for index, functions in pairs(Interactable) do
			if typeof(functions) ~= "function" then
				continue
			end

			self[index] = functions
		end
	end)
	
	self._Freeze = false
	self._Cooldown = os.clock()

	self.Instance = self.Instance
	self.Interactions = {
		Role = {},
		Team = {}
	}

	self.Params = {
		Role = {},
		Team = {}
	}
	
	self.Permission = {
		Role = {},
		Team = {},
		Custom = {}
	}

	self.Root = self.Instance.Parent
	ComponentsManager.Add(self.Instance, Interactable, self)
end

function Interactable.AddPermissionRole(self: Component, Tag: string, ApplyTo: string, CustomPermission: {number})	
	self.Permission.Custom = CustomPermission
	self.Permission[ApplyTo][Tag] = true
	
	if RunService:IsServer() then
		
		ServerRemotes.InstancePermission.FireAll({
			Object = self.Instance,
			
			Custom = CustomPermission,
			ApplyTo = ApplyTo,
			Tag = Tag
		})
	end
end

function Interactable.ClearPermissions(self: Component)
	self.Permission.Role = {}
	self.Permission.Team = {}
	self.Permission.Custom = {}
	
	if RunService:IsServer() then
		ServerRemotes.ClearPermission.FireAll({
			Object = self.Instance
		})
	end
	
end


function Interactable.OnConstructServer(self: Component)	
	self.Janitor:Add(self.Instance.Triggered:Connect(function(player: Player)	
		if self:IsFreezeActive() or self:IsCooldownActive() then
			return
		end
				
		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(player)
		assert(PlayerComponent, "PlayerComponent not found.")

		local RoleAndTeam = {
			Role = PlayerComponent:GetRole(),
			Team = player.Team and player.Team.Name,
		}

		local Interaction = self.Interactions.Role[RoleAndTeam.Role] or self.Interactions.Team[RoleAndTeam.Team]
		if not Interaction or not Interaction.ShouldStart(player) then
			return
		end

		Interaction.OnStartServer(player)
	end))
end

function Interactable.ApplyParamsRole(self: Component, Tag: string, ApplTo: string, Info: {string})
	self.Params[ApplTo][Tag] = Info
end

function Interactable.OnConstructClient(self: Component)
	local Player: Player = Players.LocalPlayer
	PlayerController = Classes.GetSingleton("PlayerController")	
	
	self.Instance.Style = Enum.ProximityPromptStyle.Custom
	
	--//Remote (Client)
	self.Janitor:Add(ClientRemotes.InstancePermission.SetCallback(function(Info: { ApplyTo: string, Custom: {number}, Object: Instance, Tag: string})
		if Info.Object ~= self.Instance then
			local InfoInstance = ComponentsManager.Get(Info.Object, Interactable)

			if not InfoInstance then
				return
			end

			InfoInstance.AddPermissionRole(InfoInstance, Info.Tag, Info.ApplyTo, Info.Custom)
			return
		end

		self:AddPermissionRole(Info.Tag, Info.ApplyTo, Info.Custom)
	end))
	
	self.Janitor:Add(ClientRemotes.ClearPermission.SetCallback(function(Info: { Object: Instance })  
		if Info.Object ~= self.Instance then
			local InfoInstance = ComponentsManager.Get(Info.Object, Interactable)
			
			if not InfoInstance then
				return
			end

			InfoInstance.ClearPermissions(InfoInstance)
			return
		end
		
		self:ClearPermissions()
	end))
	
	
	--//Prompt
	self.Janitor:Add(self.Instance.PromptShown:Connect(function()
		if self:IsFreezeActive() or self:IsCooldownActive() then
			return false
		end
		
		local Permission: boolean = self:IsHasPermissionRole(Player)
		
		if not Permission then
			return
		end
		
		local RoleAndTeam = {
			Role = PlayerController:GetRole(),
			Team = Player.Team and Player.Team.Name,
		}
		
		local Params = self.Params.Role[RoleAndTeam.Role] or self.Params.Team[RoleAndTeam.Team]
		
		if Params then
			
			for Index, Value in Params do
				print(Index, Value)
				self.Instance[Index] = Value
			end
		end
		
		InteractionProximites.CreateInteraction(self)
	end))

	self.Janitor:Add(self.Instance.PromptHidden:Connect(function()
		if self:IsFreezeActive() or self:IsCooldownActive() then
			return false
		end

		InteractionProximites.DeleteInteraction(self)
	end))

	self.Janitor:Add(self.Instance.Triggered:Connect(function()		
		if self:IsFreezeActive() or self:IsCooldownActive() then
			return
		end
		
		local Permission: boolean = self:IsHasPermissionRole(Player)

		if not Permission then
			return
		end

		local RoleAndTeam = {
			Role = PlayerController:GetRole(),
			Team = Player.Team and Player.Team.Name,
		}

		local Interaction = self.Interactions.Role[RoleAndTeam.Role] or self.Interactions.Team[RoleAndTeam.Team]
		if not Interaction or not Interaction.ShouldStart(Player) then
			return
		end

		Interaction.OnStartClient(Player)
	end))

	InteractionProximites.OnConstruct(self)
end

return Interactable