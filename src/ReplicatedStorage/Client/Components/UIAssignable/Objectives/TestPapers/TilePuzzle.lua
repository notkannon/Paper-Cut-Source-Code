--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.Objectives.BaseMinigame)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

local Enums = require(ReplicatedStorage.Shared.Enums)

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local MouseUnlockedEffect = require(ReplicatedStorage.Shared.Combat.Statuses.MouseUnlocked)
local WCS = require(ReplicatedStorage.Packages.WCS)

--//Variables

local LocalPlayer = Players.LocalPlayer
local TilePuzzleTestPaperUI = BaseComponent.CreateComponent("TilePuzzleTestPaperUI", { isAbstract = false }, BaseMinigame) :: Impl

--//Constants
local TestImages = {
	-- placeholders
	--[["rbxassetid://123734931351217",
	"rbxassetid://132540577090268",
	"rbxassetid://133105719245739"]]
	"rbxassetid://81456455712165",
	"rbxassetid://115676373597955",
	"rbxassetid://126200900175572",
	"rbxassetid://83211539886666",
	"rbxassetid://110980454518244",
	"rbxassetid://114827068961777"
}

--//Types

export type Tile = {
	Instance: Frame,
	Button: ImageButton,
	CorrectlyPlaced: boolean,
	Rotation: number
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseMinigame.MyImpl) ),
	
	GetCorrectlyPlacedAmount: (self: Component) -> (),
	IsComplete: (self: Component) -> (),
	
	_Init: (self: Component) -> (),
	_InitTiles: (self: Component) -> (),
	_UpdateTile: (self: Component, Tile: Tile) -> (),
	
} & BaseMinigame.MyImpl

export type Fields = {

	Tiles: {Tile},
	RuntimeJanitor: Janitor.Janitor
	
} & BaseMinigame.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "TilePuzzleTestPaperUI", ImageLabel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "TilePuzzleTestPaperUI", ImageLabel, {}>

--//Methods
-- CSP lazy :pensive:
function TilePuzzleTestPaperUI.Start(self: Component) -- lol but let me create an image with that size xd 1023x904 -- fixed
	if not self:ShouldStart() then
		return
	end
	BaseMinigame.Start(self)
	
	local WCSChar = WCS.Character.GetLocalCharacter()
	assert(WCSChar)
 
 	self.RuntimeJanitor:Add(MouseUnlockedEffect.new(WCSChar), "End", "MouseUnlockedEffect"):Start()
	
	self:_InitTiles()
	print('started')
end

function TilePuzzleTestPaperUI._InitTiles(self: Component)
	self.Tiles = {}
	
	for _, Child: Frame in self.Instance.Content.Sections:GetChildren() do
		if not Child:IsA("Frame") then
			continue
		end
		
		local Tile: Tile = {
			Instance = Child,
			Button = Child:FindFirstChildWhichIsA("ImageButton"),
			CorrectlyPlaced = nil,
			Rotation = math.random(1, 3) * 90
		}
		
		
		Tile.Button.Rotation = Tile.Rotation
		Tile.Button.Image = self.ImageId
		
		
		table.insert(self.Tiles, Tile)
		
		self.RuntimeJanitor:Add(Tile.Button.MouseButton1Click:Connect(function()
			self:_UpdateTile(Tile)
		end))
		
		self.RuntimeJanitor:Add(Tile.Button.MouseEnter:Connect(function()
			TweenUtility.PlayTween(Tile.Button, TweenInfo.new(0.1), {ImageColor3 = Color3.new(0.8, 0.8, 0.8)}) 
		end))
		
		self.RuntimeJanitor:Add(Tile.Button.MouseLeave:Connect(function()
			TweenUtility.PlayTween(Tile.Button, TweenInfo.new(0.1), {ImageColor3 = Color3.new(1, 1, 1)}) 
		end))
		
		-- restoring color on cleanup just in case
		self.RuntimeJanitor:Add(function()
			Tile.Button.ImageColor3 = Color3.new(1, 1, 1)
		end)
	end
	
	self.RuntimeJanitor:Add(function()
		table.clear(self.Tiles)
	end)
end

function TilePuzzleTestPaperUI.GetCorrectlyPlacedAmount(self: Component)
	local CorrectlyPlaced = 0
	for _, Tile: Tile in pairs(self.Tiles) do
		if Tile.CorrectlyPlaced then
			CorrectlyPlaced += 1
		end
	end
	return CorrectlyPlaced
end

function TilePuzzleTestPaperUI.IsComplete(self: Component)
	local CorrectlyPlaced = self:GetCorrectlyPlacedAmount()
	
	return CorrectlyPlaced >= 9
end

function TilePuzzleTestPaperUI._UpdateTile(self: Component, Tile: Tile)
	local Frame = Tile.Instance
	
	Tile.Rotation += 90
	
	TweenUtility.PlayTween(Tile.Button, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Rotation = Tile.Rotation})
	
	local IsPlacedCorrectly = (Tile.Rotation % 360) == 0
	
	if Tile.CorrectlyPlaced ~= IsPlacedCorrectly then
		Tile.CorrectlyPlaced = IsPlacedCorrectly
	end
		
	local Tick = SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.Click)
	Tick.PlaybackSpeed = 0.6 + 0.3 * (self:GetCorrectlyPlacedAmount() / 9)
	
	if self:IsComplete() then
		self:PromptComplete("Success")
	end
end

function TilePuzzleTestPaperUI.Show(self: Component)
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
end

function TilePuzzleTestPaperUI.Hide(self: Component)
	BaseMinigame.Hide(self)
	self.RuntimeJanitor:Cleanup()
	self.Instance.Visible = false
end

function TilePuzzleTestPaperUI.OnConstructClient(self: Component, controller: any)
	self.RuntimeJanitor = self.Janitor:Add(Janitor.new())
	self.ImageId = TestImages[math.random(1, #TestImages)]
	
	BaseMinigame.OnConstructClient(self, controller)
	
	--self:_InitInput() -- is in BaseMinigame
	
	
	
	print('TilePuzzle spawned')
end

--//Returner

return TilePuzzleTestPaperUI