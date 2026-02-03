--//Services

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local MapsData = require(ServerStorage.Data.MapsData)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TerrainSaveLoad = require(ServerScriptService.Server.Utility.TerrainSaveLoad)

--//Variables

local Terrain = workspace.Terrain
local MapsManager: Impl = Classes.CreateSingleton("MapsManager") :: Impl

--local Temp = Lighting:FindFirstChild("Temp") :: Folder

--//Types

export type Impl = {
	__index: Impl,

	new: () -> Service,
	IsImpl: (self: Service) -> boolean,
	GetName: () -> "MapsManager",
	GetExtendsFrom: () -> nil,
	
	LoadMap: (self: Service, mapName: string) -> (),
	UnloadMap: (self: Service) -> (),
	
	GetMapComponent: (self: Service) -> unknown?,
	GetSpawnLocations: (self: Service) -> { SpawnLocation }?,
	GetSpawnLocationsFor: (self: Service, player: Player) -> { SpawnLocation }?,
	GetListOfMaps: (self: Service) -> typeof(MapsData),
}

export type Fields = {
	Map: Instance?,
	--Lighting: Configuration
}

export type Service = typeof(setmetatable({} :: Fields, MapsManager :: Impl))

--//Methods

function MapsManager.GetSpawnLocations(self: Service)
	return self.Map
		and (self.Map:FindFirstChild("Spawns")
			and self.Map:FindFirstChild("Spawns"):GetChildren()
			or self.Map:WaitForChild("Spawns"):GetChildren())
end

function MapsManager.GetSpawnLocationsFor(self: Service, player: Player)
	if not self.Map then
		return
	end
	
	local MapComponent = self:GetMapComponent(self.Map)
	
	if RolesManager:IsPlayerKiller(player) then
		return MapComponent.KillerSpawns
	elseif RolesManager:IsPlayerStudent(player) then
		return MapComponent.StudentSpawns
	end
	
	return self:GetSpawnLocations()
end

function MapsManager.GetListOfMaps(self: Service)
	return MapsData
end

function MapsManager.GetMapComponent(self: Service)
	return ComponentsManager.GetFirstComponentInstanceOf(self.Map, "BaseMap")
end

-- for lighting application, see EnvironmentController on client
--function MapsManager.ApplyMapLighting(self: Service)
--	local savedChildren = self.Lighting:GetChildren()

--	for child = 1, #savedChildren do
--		local savedChild = savedChildren[child]
		
--		-- Look for an existing object in Lighting with the same class
--		local existing = Lighting:FindFirstChildOfClass(savedChild.ClassName)

--		if existing then
--			local clone = savedChild:Clone()
			
--			clone.Parent = Temp
--			existing:Destroy()
--		end
--	end
--end


function MapsManager.UnloadMap(self: Service)
	
	Terrain:Clear()
	
	if workspace:FindFirstChild("DroppedItems") then
		workspace.DroppedItems:ClearAllChildren()
	end
	
	for _, Child in CollectionService:GetTagged("PaperTestObjective") do
		Child:Destroy()
	end
	
	if self.Map then
		self.Map:Destroy()
	end
	
	--if Temp then
	--	for _, Child in Temp:GetChildren() do
	--		Child.Parent = Lighting
	--	end

	--	Temp:ClearAllChildren()
	--end
end

function MapsManager.LoadMap(self: Service, mapName: string)
	local Data = MapsData[mapName] :: MapsData.Map
	
	assert(Data,`Provided {mapName} map doesn't exist`)
	
	--copying map instance and placing under Workspace
	local Instance = Data.Instance:Clone()
	Instance.Parent = workspace
		
	self.Map = Instance
	--self.Lighting = Data.Lighting

	--loading map terrain/Lighting
	TerrainSaveLoad.Load(Data.Terrain)
end

--//Returner

local Singleton = MapsManager.new()
return Singleton