--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local Type = require(ReplicatedStorage.Packages.Type)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local MapsData = require(ServerStorage.Data.MapsData)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local ItemSpawnData = require(ServerStorage.Data.ItemSpawnData)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)

local Enums = require(ReplicatedStorage.Shared.Enums)
local Utility = require(ReplicatedStorage.Shared.Utility)
local ItemService = require(ServerScriptService.Server.Services.ItemService)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local HighlightItem = require(ReplicatedStorage.Shared.Effects.HighlightItem)

--//Variables

local ItemIdsEnum = Enums.ItemIdsEnum
local DoorInstances = ReplicatedStorage.Assets.Doors
local HideoutInstances = ReplicatedStorage.Assets.Lockers
local ObjectivesFolder = ReplicatedStorage.Assets.Objectives.Instances
local BaseMap = BaseComponent.CreateComponent("BaseMap", {
	isAbstract = true,
	ancestorWhitelist = { workspace },

}) :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
	
	GetData: (self: Component) -> MapsData.Map,
	
	ToggleDebugCollisions: (self: Component, force: boolean) -> (),	

	_InitItems: (self: Component) -> (),
	_InitDoors: (self: Component) -> (),
	_InitHideouts: (self: Component) -> (),
	_InitObjectives: (self: Component) -> (),
	_InitSpawns: (self: Component) -> (),
	
	OnConstruct: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
	StudentSpawns: {CFrame?},
	KillerSpawns: {CFrame?}
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseMap", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseMap", Instance, any...>

--//Functions

local function distanceSquared(a: CFrame, b: CFrame)
	local p1, p2 = a.Position, b.Position
	return (p1 - p2).Magnitude ^ 2
end

local function getPointFurthestFromPoints(points, furthest_from)
	local bestIdx, bestDist = nil, -math.huge
	for i, candidate in ipairs(points) do
		local minDist = math.huge
		for _, sel in ipairs(furthest_from) do
			local d = distanceSquared(candidate, sel)
			if d < minDist then minDist = d end
		end
		if minDist > bestDist then
			bestDist = minDist
			bestIdx = i
		end
	end
	return bestIdx, bestDist
end

local function selectSpreadPoints(points, count, first: CFrame?)
	local selected, remaining = {}, table.clone(points)
	if #remaining == 0 then return selected, remaining end


	if not first then
		table.insert(selected, table.remove(remaining, math.random(1, #remaining)))
	else
		table.insert(selected, table.remove(remaining, table.find(remaining, first)))
	end

	while #selected < count and #remaining > 0 do
		local bestIdx, bestDist = getPointFurthestFromPoints(remaining, selected)
		table.insert(selected, table.remove(remaining, bestIdx))
	end

	return selected, remaining
end

local function selectNearPoints(points, count, first: CFrame?)
	local selected, remaining = {}, table.clone(points)
	if #remaining == 0 then return selected, remaining end

	if not first then
		table.insert(selected, table.remove(remaining, math.random(1, #remaining)))
	else
		table.insert(selected, table.remove(remaining, table.find(remaining, first)))
	end

	while #selected < count and #remaining > 0 do
		local bestIdx, bestDist = nil, math.huge
		for i, candidate in ipairs(remaining) do
			local maxDist = -math.huge
			for _, sel in ipairs(selected) do
				local d = distanceSquared(candidate, sel)
				if d > maxDist then maxDist = d end
			end
			if maxDist < bestDist then
				bestDist = maxDist
				bestIdx = i
			end
		end
		table.insert(selected, table.remove(remaining, bestIdx))
	end

	return selected, remaining
end

local function getPlayerAlpha()
	return #Classes.GetSingleton("MatchService").GetEngagedPlayers() / GlobalSettings.ServerSize
end

--//Methods

function BaseMap.GetData(self: Component)
	return MapsData[self.GetName()]
end

function BaseMap._InitDoors(self: Component)
	
	--collecting all initial poses of doors
	local DoorsFolder = self.Instance:FindFirstChild("Doors")
	local Initials = DoorsFolder:GetChildren()
	
	local UnlockedPoints = {}
	for _, Initial: BasePart in ipairs(Initials) do
		local IsLocked = Initial:HasTag("Locked")
		
		if not IsLocked then
			table.insert(UnlockedPoints, Initial.CFrame)
		end
	end
	
	local UnlockedAmount = math.round(math.lerp(0.25 * #UnlockedPoints, #UnlockedPoints, getPlayerAlpha())) -- from 25% to 100% of unlocked doors, depending on player count
	print('spawning', UnlockedAmount, 'doors')
	UnlockedPoints = selectSpreadPoints(UnlockedPoints, UnlockedAmount)
	
	
	for _, Initial: BasePart in ipairs(Initials) do

		local IsDouble = Initial.Size.X > 5
		local IsLocked = Initial:HasTag("Locked")
		local IsClassic = Initial:HasTag("Classic")

		local Default = DoorInstances
			:FindFirstChild(IsClassic and "Classic" or "Windowed")
			:FindFirstChild(IsDouble and "Double" or "Single")

		local Instance = Default:Clone()
		Instance.Parent = DoorsFolder

		if IsLocked then

			Instance.Root.CanCollide = true

			for _, Descendant in ipairs(Instance:GetDescendants()) do

				if Descendant:IsA("ProximityPrompt")
					or Descendant:IsA("AlignOrientation")
					or Descendant:IsA("BallSocketConstraint") then

					Descendant:Destroy()
				end
			end

			for _, Descendant in ipairs(Instance:GetDescendants()) do

				if Descendant:IsA("BasePart") then

					Descendant.Anchored = true
				end
			end

			Instance:PivotTo(Initial.CFrame)

		else
			if not table.find(UnlockedPoints, Initial.CFrame) then
				Instance:Destroy()
				continue
			end
			
			--initializing door
			local Tag = IsDouble and "DoubleDoor" or "SingleDoor"

			Instance:PivotTo(Initial.CFrame)
			Instance:AddTag("Door")
			Instance:AddTag(Tag)
			
			--component initial stuff
			local Component = self.Janitor:AddPromise(ComponentsManager.Await(Instance, Tag)):expect()
			Component:SetReferenceInstance(Default)
			Component.BrokenInstanceReference = DoorInstances.Broken
				:FindFirstChild(IsClassic and "Classic" or "Windowed")
			
			--shall be removed with map entirely
			self.Janitor:Add(Component, "Destroy")
		end
	end

	for _, Initial in ipairs(Initials) do
		Initial:Destroy()
	end
end

function BaseMap._InitHideouts(self: Component)
	
	local lockerFolder = self.Instance:WaitForChild("Hideouts"):FindFirstChild("Lockers")
	local allPoints = lockerFolder:GetChildren()

	-- Получаем точки с тегом Locked
	local lockedSet = {}
	for _, point in ipairs(CollectionService:GetTagged("Locked")) do
		lockedSet[point] = true
	end

	local normalPoints = {}
	local lockedPoints = {}

	for _, point in ipairs(allPoints) do
		if lockedSet[point] then
			table.insert(lockedPoints, point)
		else
			table.insert(normalPoints, point)
		end
	end

	local normalCount = self:GetData().Hideouts.LockerCount

	-- Clone random instance from folder
	local function cloneRandom(folder)
		local src = folder:GetChildren()
		if #src == 0 then return nil end
		return src[math.random(1, #src)]:Clone()
		--return src[math.min(5, #src)]:Clone()
	end

	local normalInstances = {}
	for i = 1, normalCount do
		local inst = cloneRandom(HideoutInstances.Normal)
		if inst then table.insert(normalInstances, inst) end
	end

	local selectedNormalPoints, leftoverPoints = selectSpreadPoints(normalPoints, normalCount)

	local usedPointsSet = {}

	-- Устанавливаем нормальные шкафы
	for _, point in ipairs(selectedNormalPoints) do
		local cf = point.CFrame
		local locker = table.remove(normalInstances)

		if locker then
			locker:PivotTo(cf)
			locker.Parent = lockerFolder
			locker:AddTag("Hideout")
			locker:AddTag("HidingLocker")

			local Component = self.Janitor:AddPromise(
				ComponentsManager.Await(locker, "HidingLocker")
			):expect()
			self.Janitor:Add(Component, "Destroy")
		end

		usedPointsSet[point] = true
	end

	-- Объединяем оставшиеся точки и Locked
	local allBrokenTargets = {}

	for _, point in ipairs(lockedPoints) do
		if not usedPointsSet[point] then
			table.insert(allBrokenTargets, point)
			usedPointsSet[point] = true
		end
	end

	for _, point in ipairs(leftoverPoints) do
		if not usedPointsSet[point] then
			table.insert(allBrokenTargets, point)
			usedPointsSet[point] = true
		end
	end

	-- Устанавливаем сломанные модели
	for _, point in ipairs(allBrokenTargets) do
		local cf = point.CFrame
		local locker = cloneRandom(HideoutInstances.Broken)

		if locker then
			
			locker:PivotTo(cf)
			locker.Parent = lockerFolder
			locker:AddTag("Locked")
			locker:PivotTo(locker:GetPivot() * CFrame.Angles(0, math.pi, 0))

			for _, part in ipairs(locker:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
		end
	end

	-- Удаляем все исходные точки
	for _, point in ipairs(allPoints) do
		if point and point.Parent then
			point:Destroy()
		end
	end
end

function BaseMap._InitObjectives(self: Component)
	local MapSelected = string.gsub(self.GetName(), "Map", "")
	local MaxObjectives = math.round(math.lerp(1, self:GetData().Objectives.Amount, getPlayerAlpha()))
	local MinSpawnDistance = self:GetData().Objectives.MinSpawnDistance
	local Points = CollectionService:GetTagged("ObjectivePoint"..MapSelected) -- ObjectivePointSchoolMap / ObjectivePointSchool
	
	local Available = ObjectivesFolder:GetChildren()
	local ChosenPoints = {}
	local shuffledPoints = {}

	for _, point in ipairs(Points) do
		table.insert(shuffledPoints, point)
	end

	Utility.ShuffleTable(shuffledPoints)

	-- 1. Сначала пробуем выбрать точки с соблюдением расстояния
	for _, Point in ipairs(shuffledPoints) do

		if #ChosenPoints >= MaxObjectives then
			break
		end

		local tooClose = false

		for _, chosen in ipairs(ChosenPoints) do

			if (Point.Position - chosen.Position).Magnitude < MinSpawnDistance then

				tooClose = true

				break
			end
		end

		if not tooClose then
			table.insert(ChosenPoints, Point)
		end
	end

	-- 2. Если точек не хватило, добавляем остальные без проверки
	if #ChosenPoints < MaxObjectives then

		for _, Point in ipairs(shuffledPoints) do

			if #ChosenPoints >= MaxObjectives then
				break
			end

			if not table.find(ChosenPoints, Point) then
				table.insert(ChosenPoints, Point)
			end
		end
	end

	-- 3. Спавним объекты
	for _, Point in ipairs(ChosenPoints) do

		local ObjectiveInstance = Available[math.random(1, #Available)]:Clone()
		ObjectiveInstance.Parent = workspace
		ObjectiveInstance:PivotTo(CFrame.new(Point.Position))
		ObjectiveInstance:AddTag("PaperTestObjective")
	end
end

function BaseMap._InitItems(self: Component)
	
	local NumberToVectorMap = {}
	
	local ItemSpawnPositions = {}
	local ItemsFolder = self.Instance:FindFirstChild("Items")
		
	for i = 1, #ItemsFolder:GetChildren() do
		local Part = ItemsFolder:FindFirstChild(`Part{i}`) :: BasePart?
		if not Part then
			continue
		end
		
		NumberToVectorMap[i] = Part.Position
		table.insert(ItemSpawnPositions, i)
	end
	
	ItemsFolder:ClearAllChildren()

	local usedPoints = {}
	local ToSpawnList = {}
	local totalAvailablePoints = #ItemSpawnPositions

	for _, itemId in ipairs(ItemSpawnData.ItemsShouldSpawnOnMap) do
		
		local config = ItemSpawnData.Specific[itemId]
		local minAmount = ItemSpawnData.Global.DefaultMinAmount
		local maxAmount = ItemSpawnData.Global.DefaultMaxAmount
		
		if config then
			
			minAmount = config.MinAmount
			maxAmount = config.MaxAmount
		end
		
		table.insert(ToSpawnList, {
			ItemId = itemId,
			MinAmount = minAmount,
			MaxAmount = maxAmount,
		})
		print(ToSpawnList[#ToSpawnList])
	end

	-- Расставляем предметы с максимальным расстоянием между ними
	local function pickSpreadPoints(points: {Vector3}, count: number): {Vector3}
		
		local selected = {}
		
		if #points == 0 or count == 0 then return selected end

		local available = table.clone(points)
		
		table.insert(selected, table.remove(available, Random.new():NextInteger(1, #available)))

		while #selected < count and #available > 0 do
			
			local bestIdx, bestMinDist = nil, -math.huge
			
			for i, candidate in available do
				
				candidate = NumberToVectorMap[candidate]
				
				local minDist = math.huge
				
				for _, existing in selected do
					
					existing = NumberToVectorMap[existing]
					
					local d = (candidate - existing).Magnitude
					
					if d < minDist then
						minDist = d
					end
				end
				
				if minDist > bestMinDist then
					
					bestMinDist = minDist
					bestIdx = i
				end
			end
			
			print(bestMinDist, bestIdx)
			table.insert(selected, table.remove(available, bestIdx))
		end
		
		return selected
	end

	for _, item in ipairs(ToSpawnList) do
		
		--calculating amount of available items depending on player count
		local availablePoints = {}
		local amount = math.round(math.lerp(item.MinAmount, item.MaxAmount, getPlayerAlpha()))
		--amount = 78 -- debug

		for _, point in ipairs(ItemSpawnPositions) do
			if not usedPoints[point] then
				table.insert(availablePoints, point)
			end
		end

		local chosenPoints = pickSpreadPoints(availablePoints, amount)
		
		for _, point in ipairs(chosenPoints) do
			
			local ItemName = ItemIdsEnum:GetEnumFromIndex(item.ItemId)
			local Component = ItemService:CreateItem(ItemName, true, true)
			
			Component.Handle.Anchored = true -- freezing instance
			Component.Instance.Parent = workspace:FindFirstChild("DroppedItems")
			
			local Vector = NumberToVectorMap[point]
			
			Component.Instance:PivotTo(CFrame.new(Vector) * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0))
			
			usedPoints[point] = (usedPoints[point] or 0) + 1
			
			
			print(`spawning item {ItemName} at point {point} - {Vector}`)
		end
		
		
		task.wait(0.1)
	end
	
	print('freqmap:', usedPoints)
end

function BaseMap._InitSpawns(self: Component)
	local SpawnCFrames = {}
	
	for _, spawn: SpawnLocation in self.Instance.Spawns:GetChildren() do
		table.insert(SpawnCFrames, spawn.CFrame)
	end
	
	local StudentSpawns = selectNearPoints(SpawnCFrames, 3)
	local _furthest = SpawnCFrames[getPointFurthestFromPoints(SpawnCFrames, StudentSpawns)]
	local KillerSpawns = selectNearPoints(SpawnCFrames, 3, _furthest)
	
	-- to avoid algorithmic bias
	if math.random() < 0.5 then
		self.StudentSpawns = StudentSpawns
		self.KillerSpawns = KillerSpawns
	else
		self.StudentSpawns = KillerSpawns
		self.KillerSpawns = StudentSpawns
	end
	
	print(self.StudentSpawns, 'for students')
	print(self.KillerSpawns, 'for killers')
end

function BaseMap.ToggleDebugCollisions(self: Component, force: boolean)
	local InvisibleWalls = self.Instance:FindFirstChild("InvisibleWalls") :: Folder

	for _, Collision in InvisibleWalls:GetChildren() do
		Collision.Transparency = force and 0.78 or 1
	end
end

function BaseMap.OnConstruct(self: Component)
	self:ToggleDebugCollisions(RunService:IsStudio())
	
	for _, Points in self.Instance.Views:GetDescendants() do
		if not Points:IsA("BasePart") then
			continue
		end
		
		Points.Transparency = 1
	end
end

function BaseMap.OnConstructServer(self: Component)
	self.StudentSpawns = {}
	self.KillerSpawns = {}
	
	local function PcallHandler(success, ...)
		
		if success then
			return
		end
		
		warn("Map generation error catched:", ...)
	end
	

	PcallHandler(pcall(task.spawn, self._InitItems, self))
	PcallHandler(pcall(task.spawn, self._InitDoors, self))
	PcallHandler(pcall(task.spawn, self._InitHideouts, self))
	PcallHandler(pcall(task.spawn, self._InitObjectives, self))
	PcallHandler(pcall(task.spawn, self._InitSpawns, self))
end

--//Returner

return BaseMap