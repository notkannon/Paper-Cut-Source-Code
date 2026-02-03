--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Types = require(ReplicatedStorage.Shared.Types)
local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local PlayerUtility = require(ServerScriptService.Server.Utility.PlayerUtility)
local SpatialDebugger = require(ReplicatedStorage.Shared.Utility.SpatialDebugger)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Constants

local DEBUG = false

--//Functions

local function GetPartsInHitbox(
	origin: CFrame,
	hitbox: Types.Hitbox,
	overlapParams: ({} & OverlapParams)?
): { BasePart }
	
	local List = overlapParams and overlapParams.FilterDescendantsInstances or {}
	local Size = typeof(hitbox.Size) == "Vector3" and hitbox.Size or Vector3.one * hitbox.Size
	local HitboxCFrame = origin + origin:Inverse():VectorToObjectSpace(hitbox.Offset)

	if RunService:IsStudio() and DEBUG then
		table.insert(List, SpatialDebugger.Create(HitboxCFrame, Size, 5))
	end

	local OverlapParameters = OverlapParams.new()
	
	if overlapParams then
		Utility.ApplyParams(OverlapParameters, overlapParams)
	end
	
	OverlapParameters.FilterDescendantsInstances = List
	OverlapParameters.FilterType = overlapParams and overlapParams.FilterType or Enum.RaycastFilterType.Exclude
	
	return workspace:GetPartBoundsInBox(HitboxCFrame, Size, OverlapParameters)
end

local function GetCharactersInHitbox(
	origin: CFrame,
	hitbox: Types.Hitbox,
	excludeCharacters: { Instance }?
) : { PlayerTypes.Character? }
	
	local PartsInHitbox = GetPartsInHitbox(origin, hitbox, {
		FilterDescendantsInstances = excludeCharacters
	})
	
	local Characters = {}

	for _, Part in ipairs(PartsInHitbox) do
		local Character = Part:FindFirstAncestorWhichIsA("Model")
		if Character and Character:FindFirstChildOfClass("Humanoid") and not table.find(Characters, Character) then
			table.insert(Characters, Character)
		end
	end
	
	return Characters
end

local function GetCharacterComponentsInHitbox(
	origin: CFrame,
	hitbox: Types.Hitbox,
	excludeCharacters: { Instance }?,
	excludeStatuses: { string }?
) : { ComponentsUtility.CharacterComponent? }

	local Characters = GetCharactersInHitbox(origin, hitbox, excludeCharacters)
	local CharacterComponents = {}
	
	for _, Character in ipairs(Characters) do
		local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(Character)
		if not CharacterComponent or WCSUtility.HasActiveStatusEffectsWithNames(CharacterComponent.WCSCharacter, excludeStatuses or {}) then
			continue
		end

		table.insert(CharacterComponents, CharacterComponent)
	end
	
	return CharacterComponents
end

local function GetPartsInRadius(
	origin: CFrame,
	hitbox: Types.Hitbox,
	list: { Instance }?,
	filterType: Enum.RaycastFilterType?
): { BasePart? }
	
	local List = list or {}
	local FilterType = filterType or Enum.RaycastFilterType.Exclude
	local Size = typeof(hitbox.Size) == "Vector3" and hitbox.Size.Y or hitbox.Size :: number

	if RunService:IsStudio() and DEBUG then
		table.insert(List, SpatialDebugger.Create(origin, Size, 5))
	end

	local OverlapParameters = OverlapParams.new()
	OverlapParameters.FilterType = FilterType
	OverlapParameters.FilterDescendantsInstances = List

	return workspace:GetPartBoundsInRadius(origin.Position, Size, OverlapParameters)
end

local function GetCharactersInRadius(
	origin: CFrame,
	hitbox: Types.Hitbox,
	excludeCharacters: { Instance }?,
	excludeStatuses: { string }?
): ({ ComponentsUtility.CharacterComponent }, { PlayerTypes.Character })
	
	local Characters = {}
	local CharacterComponents = {}
	local PartsInRadius = GetPartsInRadius(origin, hitbox, excludeCharacters)

	for _, Part in ipairs(PartsInRadius) do
		local Character = Part:FindFirstAncestorWhichIsA("Model")
		if Character and Character:FindFirstChildOfClass("Humanoid") and not table.find(Characters, Character) then
			table.insert(Characters, Character)
		end
	end

	for _, Character in ipairs(Characters) do
		local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(Character)
		if not CharacterComponent or WCSUtility.HasActiveStatusEffectsWithNames(CharacterComponent.WCSCharacter, excludeStatuses or {}) then
			continue
		end

		table.insert(CharacterComponents, CharacterComponent)
	end

	return CharacterComponents, Characters
end

local function GetCharactersInHitboxFromPlayer(
	player: Player,
	hitbox: Types.Hitbox,
	excludeCharacters: { Instance }?
) : { PlayerTypes.Character }
	
	local ClientPlayersInHitbox = PlayerUtility.RequestPlayersInHitbox(player, 12, hitbox):expect()
	local Characters = {}
	
	for _, Player in ipairs(ClientPlayersInHitbox) do
		if not Player.Character then
			continue
		end
		
		if excludeCharacters and table.find(excludeCharacters, Player.Character) then
			continue
		end
		
		table.insert(Characters, Player.Character)
	end
	
	return Characters
end

local function GetCharacterComponentsInHitboxFromPlayer(
	player: Player,
	hitbox: Types.Hitbox,
	excludeCharacters: { Instance }?,
	excludeStatuses: { string }?
) : { ComponentsUtility.CharacterComponent }

	local Components = {}
	local Characters = GetCharactersInHitboxFromPlayer(player, hitbox, excludeCharacters)

	for _, Character in ipairs(Characters) do
		local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(Character)
		if not CharacterComponent or WCSUtility.HasActiveStatusEffectsWithNames(CharacterComponent.WCSCharacter, excludeStatuses or {}) then
			continue
		end

		table.insert(Components, CharacterComponent)
	end
	
	return Components
end

--local function PlayerCFramesDistanceCheck(
--	origin: CFrame,
--	distance: number,
--	constraintAngle: number,
--	playerCFrames: { [Player]: CFrame },
--	excludeCharacters: { Instance }?,
--	excludeStatuses: { string }?,
--	checkNearest: boolean?
	
--): ({ ComponentsUtility.CharacterComponent } | ComponentsUtility.CharacterComponent)
	
--	local CharacterComponents = {}
	
--	for Player, PlayerOrigin in pairs(playerCFrames) do
--		--same player checked from
--		if origin == PlayerOrigin then
--			continue
--		end
		
--		if not Player.Character or table.find(excludeCharacters, Player.Character) then
--			continue
--		end
		
--		--too far
--		if (origin.Position - PlayerOrigin.Position).Magnitude > distance then
--			continue
--		end
		
--		local LookVector = origin.LookVector
--		local VectorToPlayer = (PlayerOrigin.Position - origin.Position).Unit
		
--		--not in allowed zone
--		if LookVector:Dot(VectorToPlayer) < math.cos(math.rad(constraintAngle)) then
--			continue
--		end
		
--		local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(Player.Character)
--		if not CharacterComponent or WCSUtility.HasActiveStatusEffectsWithNames(CharacterComponent.WCSCharacter, excludeStatuses or {}) then
--			continue
--		end
		
--		table.insert(CharacterComponents, CharacterComponent)
--	end
	
--	if checkNearest then
--		if #CharacterComponents > 0 then
--			table.sort(CharacterComponents, function(a, b)
--				local CFrameA = playerCFrames[a.PlayerComponent.Instance]
--				local CFrameB = playerCFrames[b.PlayerComponent.Instance]
--				return (origin.Position - CFrameA.Position).Magnitude < (origin.Position - CFrameB.Position).Magnitude
--			end)
--		end
		
--		return CharacterComponents[1]
--	end
	
--	return CharacterComponents
--end

--//Returner

return {
	GetPartsInHitbox = GetPartsInHitbox,
	GetPartsInRadius = GetPartsInRadius,
	GetCharactersInRadius = GetCharactersInRadius,
	
	GetCharactersInHitbox = GetCharactersInHitbox,
	GetCharacterComponentsInHitbox = GetCharacterComponentsInHitbox,
	
	GetCharactersInHitboxFromPlayer = GetCharactersInHitboxFromPlayer,
	GetCharacterComponentsInHitboxFromPlayer = GetCharacterComponentsInHitboxFromPlayer,
}