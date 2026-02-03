--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)

local InputController = require(ReplicatedStorage.Client.Controllers.InputController)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.Objectives.BaseMinigame)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

local Enums = require(ReplicatedStorage.Shared.Enums)

local Janitor = require(ReplicatedStorage.Packages.Janitor)

--//Variables

local LocalPlayer = Players.LocalPlayer
local ShapeFolder = ReplicatedStorage.Assets.Objectives.Related.ShapeSort
local BaseTile = ReplicatedStorage.Assets.Objectives.Related.Maze.MazeTile
local MazeTestPaperUI = BaseComponent.CreateComponent("MazeTestPaperUI", { isAbstract = false }, BaseMinigame) :: Impl

--//Constants

local OffsetMap = {
	Up = Vector2.new(0, -1),
	Left = Vector2.new(-1, 0),
	Right = Vector2.new(1, 0),
	Down = Vector2.new(0, 1)
}

local OppositeDirections = {
	Left = "Right",
	Right = "Left",
	Up = "Down",
	Down = "Up"
}


--//Types

export type Direction = "Up" | "Down" | "Left" | "Right"

export type Wall = {
	Type: "Normal" | "Red",
	Instance: ImageLabel,
	Direction: Direction
}

export type Tile = {
	Instance: Frame,
	Walls: {Wall},
	IsExit: boolean,
	Position: Vector2,

	RemoveWall: (self: Tile, direction: Direction) -> (),

	BacktrackingData: {
		Visited: boolean,
		Distance: number
	}
}

export type Map = {
	[string]: Tile
}

export type Player = {
	Instance: ImageLabel,
	Position: Vector2
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseMinigame.MyImpl) ),

	GetTile: (self: Component, position: Vector2) -> Tile,

	_Init: (self: Component) -> (),
	_InitTiles: (self: Component) -> (),
	_UpdateTile: (self: Component, Tile: Tile) -> (),

} & BaseMinigame.MyImpl

export type Fields = {

	RuntimeJanitor: Janitor.Janitor,
	RedWallProbability: number,
	Map: Map,

	Columns: number,
	Rows: number,

	PlayerShape: Player?,
	MostDistance: number?

} & BaseMinigame.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "MazeTestPaperUI", ImageLabel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "MazeTestPaperUI", ImageLabel, {}>

--//Methods

function MazeTestPaperUI.Start(self: Component) 
	if not self:ShouldStart() then
		return
	end
	BaseMinigame.Start(self)

	self:_Init()
	print('started')
end

function MazeTestPaperUI._Init(self: Component)
	local TileFolder : Frame = self.Instance.Content.Sections

	for _, Child: Instance in TileFolder:GetChildren() do
		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end

	local Grid : UIGridLayout = TileFolder:FindFirstChildWhichIsA("UIGridLayout")
	Grid.CellSize = UDim2.fromScale(1 / self.Columns, 1 / self.Rows)

	self:_InitTiles()
	self:_GenerateMaze()
	self:ToggleVisibility(true)
	self:_InitPlayer()
end

function MazeTestPaperUI._InitPlayer(self: Component)
	local Shape = ShapeFolder.Circle:Clone()
	Shape.AnchorPoint = Vector2.new(0.5, 0.5)
	Shape.Size = UDim2.fromScale(0.5, 0.5)

	self.PlayerShape = {
		Instance = Shape,
		Position = nil
	} :: Player

	self.RuntimeJanitor:Add(task.spawn(function()
		local TI = TweenInfo.new(0.5, Enum.EasingStyle.Quad)
		while true do
			TweenUtility.WaitForTween(TweenUtility.PlayTween(Shape, TI, {ImageColor3 = Color3.new(1, 0.968627, 0)}))
			TweenUtility.WaitForTween(TweenUtility.PlayTween(Shape, TI, {ImageColor3 = Color3.new(1, 0.215686, 0.227451)}))
		end
	end), nil, "HighlightCurrentShape")

	self.RuntimeJanitor:Add(function()
		if self.PlayerShape then
			self.PlayerShape.Instance:Destroy()
			table.clear(self.PlayerShape)
			self.PlayerShape = nil
		end
	end)

	self:_PlacePlayer(Vector2.new(1, 1))
end

function MazeTestPaperUI._PlacePlayer(self: Component, position: Vector2)
	assert(self.PlayerShape)
	local Tile: Tile = self:GetTile(position)
	self.PlayerShape.Instance.Parent = Tile.Instance
	self.PlayerShape.Instance.Position = UDim2.fromScale(0.5, 0.5)
	self.PlayerShape.Position = position
	
	if Tile.IsExit then
		self:PromptComplete("Success")
	end
end

function MazeTestPaperUI._InitTiles(self: Component)
	self.Map = {} :: Map

	local TileFolder = self.Instance.Content.Sections
	local TotalTiles = self.Rows * self.Columns	

	for i = 1, TotalTiles do
		local Row = math.ceil(i / self.Columns)
		local Column = ((i - 1) % self.Columns) + 1
		local Position: Vector2 = Vector2.new(Column, Row)

		local TileInstance = BaseTile:Clone()

		local Tile: Tile = {
			Instance = TileInstance,
			Walls = {},
			IsExit = false,
			Position = Position,
			RemoveWall = function(self: Tile, direction: Direction)
				self.Instance:FindFirstChild(direction):Destroy()
				for _, v in ipairs(self.Walls) do
					if v.Direction == direction then
						table.remove(self.Walls, table.find(self.Walls, v))
					end
				end
			end,

			BacktrackingData = {
				Visited = false,
				Distance = nil
			}
		}

		for _, Child: Instance in TileInstance:GetChildren() do
			if Child:IsA("ImageLabel") then
				local CanSpawnRed = i > 1 and not (Row == 2 and Column == 1 and Child.Name == "Up") and not (Row == 1 and Column == 2 and Child.Name == "Left")
				
				local Wall: Wall = {
					Instance = Child,
					Direction = Child.Name,
					Type = if (CanSpawnRed and math.random() <= self.RedWallProbability) then "Red" else "Normal"
				}

				Child.ImageColor3 = if Wall.Type == "Red" then Color3.fromRGB(200, 47, 47) else Color3.fromRGB(47, 47, 47)
				Child.ZIndex = if Wall.Type == "Red" then 2 else 1

				table.insert(Tile.Walls, Wall)
			end
		end

		TileInstance.Name = `{Column},{Row}`
		TileInstance.Visible = false -- maze not finished yet so
		TileInstance.Parent = TileFolder
		self.Map[TileInstance.Name] = Tile
	end

	--print(self.Map)

	self.RuntimeJanitor:Add(function()
		table.clear(self.Map)
	end)
end

function MazeTestPaperUI.GetTile(self: Component, position: Vector2) : Tile
	return self.Map[`{position.X},{position.Y}`]
end

function MazeTestPaperUI.CanMoveInDirection(self: Component, CurrentPosition: Vector2, direction: string, mode: "Backtracking" | "Navigating"): (boolean, string?)
	local ProposedTile = CurrentPosition + OffsetMap[direction]
	local Neighbour = self:GetTile(ProposedTile) :: Tile

	if mode == "Backtracking" then
		if Neighbour.BacktrackingData.Visited then
			return false, "This tile had been already visited"
		end
	elseif mode == "Navigating" then
		local CurrentCell = self:GetTile(CurrentPosition) :: Tile
		local CurrentWall = nil
		
		for k, v in CurrentCell.Walls do
			if v.Direction == direction then
				CurrentWall = if CurrentWall == "Red" then "Red" else v.Type
			end
		end
		
		if Neighbour and CurrentWall ~= "Red" then
			for k, v in Neighbour.Walls do
				if v.Direction == OppositeDirections[direction] then
					CurrentWall = if CurrentWall == "Red" then "Red" else v.Type
				end
			end
		end
		
		if CurrentWall then
			return false, CurrentWall
		elseif not Neighbour then
			return false, "No neighbour :skull:"
		end
	else
		warn("Unknown mode", mode)
		return false, "Unknown mode"
	end

	return true
end

function MazeTestPaperUI.GetAvailableNeighbours(self: Component, CurrentPosition: Vector2, mode: "Backtracking" | "Navigating") : {{Tile | Direction}}
	local Neighbours = {} :: {Tile}

	local function _AssessNeighbour(direction: Direction)

		local success, message = self:CanMoveInDirection(CurrentPosition, direction, mode)
		--print(CurrentPosition, direction, mode, '->', success, message)

		if success then
			local ProposedTile = CurrentPosition + OffsetMap[direction]
			local Neighbour = self:GetTile(ProposedTile)
			table.insert(Neighbours, {Neighbour, direction})
		end
	end

	if CurrentPosition.X > 1 then
		_AssessNeighbour("Left")
	end
	if CurrentPosition.Y > 1 then
		_AssessNeighbour("Up")
	end
	if CurrentPosition.X < self.Columns then
		_AssessNeighbour("Right")
	end
	if CurrentPosition.Y < self.Rows then
		_AssessNeighbour("Down")
	end

	return Neighbours
end

function MazeTestPaperUI._GenerateMaze(self: Component)
	local CurrentPoint = Vector2.new(1, 1)
	local BacktrackingStack = {CurrentPoint} :: {Vector2}

	local StartingTile =  self:GetTile(CurrentPoint) :: Tile
	StartingTile.BacktrackingData.Visited = true
	StartingTile.BacktrackingData.Distance = 0



	local FurthestPoint = CurrentPoint
	local MostDistance = 0

	local CurrentNeighbours = self:GetAvailableNeighbours(CurrentPoint, "Backtracking")
	while CurrentPoint ~= Vector2.new(1, 1) or #CurrentNeighbours > 0 do
		if #CurrentNeighbours > 0 then
			local __Neighbor = CurrentNeighbours[math.random(1, #CurrentNeighbours)]
			local NextPoint = __Neighbor[1] :: Tile
			local Direction = __Neighbor[2] :: Direction

			self:GetTile(CurrentPoint):RemoveWall(Direction)
			NextPoint:RemoveWall(OppositeDirections[Direction])

			NextPoint.BacktrackingData.Visited = true
			NextPoint.BacktrackingData.Distance = #BacktrackingStack

			if NextPoint.BacktrackingData.Distance > MostDistance then
				MostDistance = NextPoint.BacktrackingData.Distance
				FurthestPoint = NextPoint.Position
			end

			table.insert(BacktrackingStack, NextPoint.Position)

			CurrentPoint = NextPoint.Position
		else
			-- we backtrack
			table.remove(BacktrackingStack, #BacktrackingStack)
			CurrentPoint = BacktrackingStack[#BacktrackingStack]
		end

		CurrentNeighbours = self:GetAvailableNeighbours(CurrentPoint, "Backtracking")

		task.wait()
	end


	local ExitTile = self:GetTile(FurthestPoint) :: Tile
	--print(FurthestPoint, 'becomes the exit')

	self.MostDistance = MostDistance -- used for sounds later

	ExitTile.IsExit = true
	ExitTile.Instance.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
	ExitTile.Instance.BackgroundTransparency = 0.25
	ExitTile.Instance.Label.Visible = true
end

function MazeTestPaperUI.ToggleVisibility(self: Component, val: boolean)
	for k, v in self.Map do
		v.Instance.Visible = val
	end
end

function MazeTestPaperUI.Show(self: Component)
	BaseMinigame.Show(self)

	self.Instance.Visible = true
	self.Instance.Rotation = (math.random(0, 1) - 0.5) * 25
	self.Instance.UIScale.Scale = 0.8

	TweenUtility.PlayTween(
		self.Instance,
		TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Rotation = 0 } :: ImageLabel
	)

	TweenUtility.PlayTween(self.Instance.UIScale, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Scale = 1
	})

	local Desc = "Navigate the maze without hitting the red walls!"

	if self.CurrentDevice == Enums.InputType.Gamepad then
		Desc ..= " Use D-pad to move"
	else
		Desc ..= " Use WASD to move"
	end

	self.Instance.Description.Text = Desc
end

function MazeTestPaperUI._InitInput(self: Component)
	BaseMinigame._InitInput(self)

	local BindMap = {
		[Enum.KeyCode.W] = "Up",
		[Enum.KeyCode.S] = "Down",
		[Enum.KeyCode.A] = "Left",
		[Enum.KeyCode.D] = "Right",
		[Enum.KeyCode.DPadUp] = "Up",
		[Enum.KeyCode.DPadDown] = "Down",
		[Enum.KeyCode.DPadLeft] = "Left",
		[Enum.KeyCode.DPadRight] = "Right",
	}

	local BlockInput = false

	self.Janitor:Add(UserInputService.InputBegan:Connect(function(input, isProcessed)
		--print(input.KeyCode, isProcessed, BindMap[input.KeyCode], self._InProgress, self.PlayerShape)

		if BlockInput then
			return
		end

		if not BindMap[input.KeyCode] or not self._InProgress or not self.PlayerShape then
			return
		end

		local Direction = BindMap[input.KeyCode]
		local Offset: Vector2 = OffsetMap[Direction]

		local Success, Message = self:CanMoveInDirection(self.PlayerShape.Position, Direction, "Navigating")

		if not Success then
			--print(Message)
			
			if Message == "Red" then
				self:PromptComplete("Failed")
				return
			end
			
			TweenUtility.WaitForTween(TweenUtility.PlayTween(self.PlayerShape.Instance, TweenInfo.new(0.02, Enum.EasingStyle.Quad),
				{
					Position = self.PlayerShape.Instance.Position + UDim2.fromScale(Offset.X/2.5, Offset.Y/2.5)
				}
				))

			SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.Damage)
			BlockInput = true

			self.Janitor:Add(task.delay(0.5, function()
				BlockInput = false
			end))

			TweenUtility.PlayTween(self.PlayerShape.Instance, TweenInfo.new(0.45, Enum.EasingStyle.Quad),
				{
					Position = UDim2.fromScale(0.5, 0.5)
				}
			)

			return
		end

		local ProposedPosition: Vector2 = self.PlayerShape.Position + Offset

		BlockInput = true

		TweenUtility.WaitForTween(TweenUtility.PlayTween(self.PlayerShape.Instance, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{
				Position = self.PlayerShape.Instance.Position + UDim2.fromScale(Offset.X, Offset.Y)
			}
		))

		self:_PlacePlayer(ProposedPosition)

		BlockInput = false
		
		-- if we didnt win
		if self.PlayerShape then
			local Tick = SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.Click)

			local CurrentDistanceFromStart = (self:GetTile(self.PlayerShape.Position) :: Tile).BacktrackingData.Distance

			Tick.PlaybackSpeed = 0.6 + 0.3 * (CurrentDistanceFromStart / self.MostDistance)
		end
	end))
end

function MazeTestPaperUI.Hide(self: Component)
	BaseMinigame.Hide(self)
	self.RuntimeJanitor:Cleanup()
	self.Instance.Visible = false
end

function MazeTestPaperUI.OnConstructClient(self: Component, controller: any)
	self.RuntimeJanitor = Janitor.new()

	self.Rows = 6 
	self.Columns = 6

	self.RedWallProbability = 0.35

	BaseMinigame.OnConstructClient(self, controller)

	print('Maze spawned')
end

--//Returner

return MazeTestPaperUI