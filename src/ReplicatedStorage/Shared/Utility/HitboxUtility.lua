--[[
	
	Suitable for hitboxes stuff
	
]]

--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local EnumUtility = require(ReplicatedStorage.Shared.Utility.EnumUtility)
local SpatialDebugger = require(ReplicatedStorage.Shared.Utility.SpatialDebugger)

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Constants

local DEBUG = true

local DEFAULT_HITBOX = {
	Type = "Box",
	Size = Vector3.one,
	Offset = Vector3.zero,
}

--//Variables

local Player = Players.LocalPlayer

--//Types

type OverlapParamsConfig = {
	MaxParts: number,
	CollisionGroup: string?,
	RespectCanCollide: boolean?,
}

type HitboxOptions = {
	Mode: Enum.RaycastFilterType?,
	Instances: { Instance }?,
	OverlapParams: OverlapParamsConfig?,
}

type CharacterComponentHitboxOptions = {
	SkillsNames: {string}?,
	StatusesNames: {string}?,
	ComponentMode: "Include" | "Exclude",
} & HitboxOptions

export type Hitbox = {
	Type: "Box" | "Sphere",
	Size: Vector3 | number,
	Offset: Vector3,
}

--//Functions

local function IsCharacterObstacleInFront(
	Part: Model | PlayerTypes.Character?,
	Distance: number
): boolean
	
	
	local HDP = Part:FindFirstChild("HumanoidRootPart")
	local Root = HDP.CFrame.LookVector
	local Origin = HDP.Position
	local Direction = Root * (Distance or 5)
	local List = { Part }
	
	local MapInstance = workspace:FindFirstChild("Map") or nil :: Model
	-- for a moment
	--if MapInstance then
	--	-- why not :GetChildren at least and actually lets print what gets detected first before we go with your theory
	--	for _, objects in MapInstance:GetChildren() do
	--		if objects:IsA("Folder") or objects:IsA("Model") and objects.Name == "InvisibleWalls" then
	--			continue
	--		end
			
	--		if o
	--	end
	--bend
	
	local Params = RaycastParams.new()
	Utility.ApplyParams(Params, {
		FilterType = Enum.RaycastFilterType.Exclude,
		FilterDescendantsInstances = { Part, workspace.Temp, workspace.Characters }
	})
	
	local CastResult = workspace:Raycast(Origin, Direction, Params)
	if CastResult then
		print(CastResult.Instance)
		return true
	end
	
	return false
end

local function GetPartsInRadius(
	origin: CFrame,
	hitbox: Hitbox,
	options: HitboxOptions?
): { BasePart? }
	
	options = options or {}

	local List = options.Instances or {}
	local Size = typeof(hitbox.Size) == "Vector3" and hitbox.Size.Magnitude or hitbox.Size
	local FilterType = options and options.Mode or Enum.RaycastFilterType.Exclude

	--TODO: radius hitbox debug
	if RunService:IsStudio() and DEBUG then
		table.insert(List, SpatialDebugger.Sphere(origin, Size, 5))
	end

	local OverlapParameters = OverlapParams.new()
	
	if options and options.OverlapParams then
		Utility.ApplyParams(OverlapParameters, options.OverlapParams)
	end
	
	OverlapParameters.FilterType = FilterType
	OverlapParameters.FilterDescendantsInstances = List
	
	local Result = workspace:GetPartBoundsInRadius(origin.Position, Size, OverlapParameters)
	--print(Result)
	
	return Result
end

local function GetCharactersInRadius(
	origin: CFrame,
	hitbox: Hitbox,
	options: CharacterComponentHitboxOptions?
): ({ PlayerTypes.Character }, { ComponentsUtility.CharacterComponent }?)
	
	options = options or {}

	local Characters = {}
	local CharacterComponents = {}

	local PartsInRadius = GetPartsInRadius(origin, hitbox, {
		Mode = Enum.RaycastFilterType.Include,
		Instances = { workspace.Characters },
	})

	for _, Part in ipairs(PartsInRadius) do
		local Character = Part:FindFirstAncestorWhichIsA("Model")

		if Character
			and Character:FindFirstChildOfClass("Humanoid")
			and not table.find(Characters, Character) then
			
			table.insert(Characters, Character)
		end
	end

	if RunService:IsServer() then
		for _, Character in ipairs(Characters) do
			local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(Character)

			if not CharacterComponent then
				continue
			end

			local HasStatuses = WCSUtility.HasActiveStatusEffectsWithNames(
				CharacterComponent.WCSCharacter,
				options.StatusesNames or {}
			)

			if (HasStatuses and options.ComponentMode == "Exclude")
				or (not HasStatuses and options.ComponentMode == "Include") then

				continue
			end

			table.insert(CharacterComponents, CharacterComponent)
		end
	end

	return Characters, RunService:IsServer() and CharacterComponents or nil
end

local function GetPartsInHitbox(
	origin: CFrame,
	hitbox: Hitbox,
	options: HitboxOptions?
): { BasePart }
	
	if hitbox.Type == "Sphere" then
		return GetPartsInRadius(origin, hitbox, options)
	end
	
	options = options or {}

	local List = options.Instances or {}
	local Size = typeof(hitbox.Size) == "Vector3" and hitbox.Size or Vector3.one * hitbox.Size
	local FilterType = options and options.Mode or Enum.RaycastFilterType.Exclude
	local HitboxCFrame = origin + origin:Inverse():VectorToObjectSpace(hitbox.Offset or Vector3.zero)

	if RunService:IsStudio() and DEBUG then
		table.insert(List, SpatialDebugger.Box(HitboxCFrame, Size, 5))
	end

	local OverlapParameters = OverlapParams.new()

	if options and options.OverlapParams then
		Utility.ApplyParams(OverlapParameters, options.OverlapParams)
	end
	
	OverlapParameters.FilterType = FilterType
	OverlapParameters.FilterDescendantsInstances = List

	return workspace:GetPartBoundsInBox(HitboxCFrame, Size, OverlapParameters)
end

local function GetCharactersInHitbox(
	origin: CFrame,
	hitbox: Hitbox,
	options: CharacterComponentHitboxOptions?
): ({ PlayerTypes.Character }, { ComponentsUtility.CharacterComponent }?)
	
	options = options or {}
	
	if hitbox.Type == "Sphere" then
		return GetCharactersInRadius(origin, hitbox, options)
	end
	
	local Characters = {}
	local CharacterComponents = {}
	
	local PartsInHitbox = GetPartsInHitbox(origin, hitbox, {
		Mode = Enum.RaycastFilterType.Include,
		Instances = { workspace.Characters },
	})

	for _, Part in ipairs(PartsInHitbox) do
		local WallChecker = workspace:Raycast(origin.Position, Part.Position - origin.Position)
		local Character = Part:FindFirstAncestorWhichIsA("Model")

		if Character
			and not table.find(Characters, Character)
			and Character:FindFirstChildOfClass("Humanoid")
			and Players:GetPlayerFromCharacter(Character) then

		--	print(IsCharacterObstacleInFront(Character, 10))

			table.insert(Characters, Character)
		end
	end
	
	if RunService:IsServer() then
		for _, Character in ipairs(Characters) do
			local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(Character)

			if not CharacterComponent then
				continue
			end

			local HasStatuses = WCSUtility.HasActiveStatusEffectsWithNames(
				CharacterComponent.WCSCharacter,
				options.StatusesNames or {}
			)

			if (HasStatuses and options.ComponentMode == "Exclude")
				or (not HasStatuses and options.ComponentMode == "Include") then

				continue
			end

			table.insert(CharacterComponents, CharacterComponent)
		end
	end

	return Characters, RunService:IsServer() and CharacterComponents or nil
end

local function RequestPlayersInHitbox(
	player: Player,
	hitbox: Hitbox,
	maxDistance: number,
	timeout: number?
): Promise.TypedPromise<{ Player? }>
	
	assert(RunService:IsServer())
	
	local Hitbox = TableKit.MergeDictionary(DEFAULT_HITBOX, hitbox)

	ServerRemotes.RequestPlayersInHitbox.Fire(player, Hitbox)

	local Disconnect
	local Disconnected = false
	local MaxDistance = maxDistance or 15

	return Promise.new(function(resolve)
		Disconnect = ServerRemotes.RespondPlayersInHitbox.On(function(playerWhoResponded, ...)
			if Disconnected then
				if Disconnect then
					Disconnect()
				end
				
				return
			end

			if playerWhoResponded ~= player then
				return
			end

			Disconnected = true
			
			Disconnect()
			resolve(...)
		end)
	end)
		:timeout(timeout or 1.75)
		:catch(function(error)
			warn("PlayersInHitboxRequest promise error catched:", tostring(error))
			return {}
		end)
		:andThen(function(players: { Player? })
			if not players or #players == 0 then
				return Promise.resolve({})
			end

			if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
				return Promise.resolve({})
			end

			local ValidPlayers = table.clone(players)
			local PlayerPosition = player.Character.HumanoidRootPart.Position :: Vector3

			for _, Player in ipairs(players) do
				if (PlayerPosition - Player.Character.HumanoidRootPart.Position).Magnitude > MaxDistance then

					table.remove(ValidPlayers,
						table.find(ValidPlayers, Player)
					)

					continue
				end
			end

			return Promise.resolve(ValidPlayers)
		end)
end

local function RequestCharactersInHitbox(
	player: Player,
	hitbox: Hitbox,
	maxDistance: number,
	timeout: number?,
	options: CharacterComponentHitboxOptions?
): ({ PlayerTypes.Character }, { ComponentsUtility.CharacterComponent })
	
	assert(RunService:IsServer())
	
	options = options or {}
	
	local Characters = {}
	local CharacterComponents = {}
	local RegisteredPlayers = RequestPlayersInHitbox(player, hitbox, maxDistance, timeout):expect()
	
	for _, Player in ipairs(RegisteredPlayers) do
		if options.Instances
			and options.Mode == Enum.RaycastFilterType.Exclude
			and table.find(options.Instances, Player.Character) then
			
			continue
		end
		
		table.insert(Characters, Player.Character)
		
		local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(Player.Character)
		if not CharacterComponent or not CharacterComponent.WCSCharacter then
			continue
		end
		
		local HasStatuses = WCSUtility.HasActiveStatusEffectsWithNames(
			CharacterComponent.WCSCharacter,
			options.StatusesNames or {}
		)

		if (HasStatuses and options.ComponentMode == "Exclude")
			or (not HasStatuses and options.ComponentMode == "Include") then

			continue
		end
		
		table.insert(CharacterComponents, CharacterComponent)
	end
	
	return Characters, CharacterComponents
end

--//Callbacks

if RunService:IsClient() then
	
	ClientRemotes.RequestPlayersInHitbox.SetCallback(function(hitbox)
		
		if not Player.Character then
			return
		end
		
		local PlayersInHitbox = {}
		local Characters = GetCharactersInHitbox(
			Player.Character.HumanoidRootPart.CFrame,
			hitbox
		)

		for _, Character in ipairs(Characters) do
			local RegisteredPlayer = Players:GetPlayerFromCharacter(Character)
			if not RegisteredPlayer or RegisteredPlayer == Player then
				continue
			end

			table.insert(PlayersInHitbox, RegisteredPlayer)
		end
		
		ClientRemotes.RespondPlayersInHitbox.Fire(PlayersInHitbox)
	end)
end

--//Returner

return {
	GetPartsInHitbox = GetPartsInHitbox,
	GetCharactersInHitbox = GetCharactersInHitbox,
	IsCharacterObstacleInFront = IsCharacterObstacleInFront,
	
	--server-only
	RequestPlayersInHitbox = RequestPlayersInHitbox,
	RequestCharactersInHitbox = RequestCharactersInHitbox,
}