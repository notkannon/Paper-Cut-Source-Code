--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ComponentTypes = RunService:IsServer() and require(ServerScriptService.Server.Types.ComponentTypes) or nil
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Types

export type PlayerComponent = ComponentTypes.PlayerComponent
export type CharacterComponent = ComponentTypes.CharacterComponent
export type PlayerComponentImpl = ComponentTypes.PlayerComponentImpl
export type CharacterComponentImpl = ComponentTypes.CharacterComponentImpl
export type BaseComponent = ComponentTypes.BaseComponent

--//Functions

--works both client/server. Returns an instance of BaseDoor component if exists.
local function GetComponentFromDoor(instance: Model)
	return ComponentsManager.GetFirstComponentInstanceOf(instance, "BaseDoor")
end

--works both client/server. Returns an instance of BaseItem component if exists.
local function GetComponentFromItem(instance: Tool)
	return ComponentsManager.GetFirstComponentInstanceOf(instance, "BaseItem")
end

--works both client/server. Returns an instance of BaseHideout component if exists.
local function GetComponentFromHideout(instance: Model)
	return ComponentsManager.GetFirstComponentInstanceOf(instance, "BaseHideout")
end


-- much less laggy but still dont spam
-- this is used for finding stuff like HealingAct or Selections
local function FindFirstTemporaryComponent(predicate: (name: string, component: BaseComponent) -> boolean)
	for _, Instance: Instance in workspace.Temp:GetChildren() do
		for name, component in pairs(ComponentsManager.GetAll(Instance)) do
			if predicate(name, component) then
				return component
			end
		end
	end
end


-- laggy!
local function FindFirstComponent(predicate: (name: string, component: BaseComponent) -> boolean)
	for _, component in ipairs(ComponentsManager.ListAll()) do
		if predicate(component:GetName(), component) then
			return component
		end
	end
end

--returns an instance of BaseHideout component, if provided character has one of following statuses: Hidden, HiddenComing, HiddenLeaving
local function GetHideoutFromCharacter(character: PlayerTypes.Character)
	
	--getting wcscharacter
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(character)
	
	if not WCSCharacter then
		return
	end
	
	local Statuses = {
		"Hidden",
		"HiddenComing",
		"HiddenLeaving",
	}
	
	for _, Status in ipairs(WCSCharacter:GetAllActiveStatusEffects()) do
		
		--skipping if status not defined in list
		if not table.find(Statuses, Status.Name) then
			continue
		end
		
		local HideoutInstance = GetComponentFromHideout(Status.HideoutInstance)
		
		--extracted component from instance stored in status
		if HideoutInstance then
			return HideoutInstance
		end
	end
end

--works both client/server. Returns an instance of BaseVault component if exists.
local function GetComponentFromVault(instance: Model)
	return ComponentsManager.GetFirstComponentInstanceOf(instance, "BaseVault")
end

--works both client/server. Returns an instance of BaseAppearance component if exists.
local function GetAppearanceComponent(instance: PlayerTypes.Character)
	return ComponentsManager.GetFirstComponentInstanceOf(instance, "BaseAppearance")
end

--server-only. Returns PlayerComponent exists
local function GetComponentFromPlayer(player: Player): ComponentTypes.PlayerComponent?
	return ComponentsManager.Get(player, "PlayerComponent")
end

--server-only. Returns a list if existing player components
local function GetAllPlayerComponents(): { ComponentTypes.PlayerComponent }
	local Components = {}

	for _, Player in ipairs(Players:GetPlayers()) do
		table.insert(Components, GetComponentFromPlayer(Player))
	end

	return Components
end

local function GetInventoryComponentFromPlayer(player: Player): unknown
	
	if RunService:IsClient() then

		return ComponentsManager.Get(player.Backpack, "ClientInventoryComponent")

	elseif RunService:IsServer() then

		return ComponentsManager.Get(player.Backpack, "InventoryComponent")
	end
end

--server-only. Returns an instance of _ if exists
local function GetPlayerComponentFromCharacter(character: Model): ComponentTypes.PlayerComponent
	local Player = Players:GetPlayerFromCharacter(character)

	if not Player then
		return
	end

	return ComponentsManager.Get(Player, "PlayerComponent")
end

--server-only. Returns PlayerComponent if exists
local function WaitForPlayerComponent(player: Player): PlayerComponent
	return ComponentsManager.Await(player, "PlayerComponent"):expect()
end

--works both client/server. Returns CharacterComponent if exists
local function GetComponentFromCharacter(character: Model): CharacterComponent?
	
	if RunService:IsClient() then
		
		return ComponentsManager.Get(character, "ClientCharacterComponent")
		
	elseif RunService:IsServer() then
		
		return ComponentsManager.Get(character, "CharacterComponent")
	end
end

--works both client/server. Returns a list of character components (for client returns single component if exists)
local function GetAllCharacterComponents(): { [Model]: CharacterComponent }
	local Components = {}

	for _, Player in ipairs(Players:GetPlayers()) do
		
		local Character: Model? = Player.Character

		if not Character then
			continue
		end

		Components[Character] = GetComponentFromCharacter(Character)
	end

	return Components
end

--works both client/server. Returns CharacterComponent if provided instance parented to it
local function GetCharacterComponentFromBasePart(basePart: BasePart): CharacterComponent?
	local Character = basePart:FindFirstAncestorWhichIsA("Model")

	if not Character or not Character:FindFirstChildWhichIsA("Humanoid") then
		return
	end

	return GetComponentFromCharacter(Character)
end

--works both client/server. Yields until CharacterComponent appear
local function WaitForCharacterComponent(character: Model): CharacterComponent
	
	if RunService:IsClient() then
		
		return ComponentsManager.Await(character, "ClientCharacterComponent"):expect()
	else
		return ComponentsManager.Await(character, "CharacterComponent"):expect()
	end
end

local function WaitForInventoryComponent(player: Player)
	if RunService:IsClient() then

		return ComponentsManager.Await(player.Backpack, "ClientInventoryComponent"):expect()

	elseif RunService:IsServer() then

		return ComponentsManager.Await(player.Backpack, "InventoryComponent"):expect()
	end
end

--//Returner

return {
	--shared
	GetAppearanceComponent = GetAppearanceComponent,
	
	FindFirstComponent = FindFirstComponent,
	FindFirstTemporaryComponent = FindFirstTemporaryComponent,
	
	GetComponentFromDoor = GetComponentFromDoor,
	GetComponentFromItem = GetComponentFromItem,
	GetComponentFromVault = GetComponentFromVault,
	
	--hideouts
	GetComponentFromHideout = GetComponentFromHideout,
	GetHideoutFromCharacter = GetHideoutFromCharacter,
	
	GetComponentFromPlayer = GetComponentFromPlayer,
	GetAllPlayerComponents = GetAllPlayerComponents,
	WaitForPlayerComponent = WaitForPlayerComponent,
	
	GetComponentFromCharacter = GetComponentFromCharacter,
	GetAllCharacterComponents = GetAllCharacterComponents,
	WaitForCharacterComponent = WaitForCharacterComponent,
	
	WaitForInventoryComponent = WaitForInventoryComponent,
	GetInventoryComponentFromPlayer = GetInventoryComponentFromPlayer,
	GetPlayerComponentFromCharacter = GetPlayerComponentFromCharacter,
	GetCharacterComponentFromBasePart = GetCharacterComponentFromBasePart,
}