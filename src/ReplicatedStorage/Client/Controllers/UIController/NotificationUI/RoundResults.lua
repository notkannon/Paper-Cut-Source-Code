--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--//Imports
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local PlayerRoundStats = require(ReplicatedStorage.Shared.Components.Matchmaking.PlayerRoundStats)
local ComponentManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)

local CameraController = require(ReplicatedStorage.Client.Controllers.CameraController)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local Characters = require(ReplicatedStorage.Shared.Data.Characters)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

--//Variables
local CanExit = false

local LocalPlayer = Players.LocalPlayer

local RoundResultFolder = ReplicatedStorage.Assets.UI.RoundResult
local RoundResultUI = BaseComponent.CreateComponent("RoundResultUI", { isAbstract = false }) :: Impl

--// Constants
local PlayerList_Colors = {
	Teacher = {
		BackgroundColor = Color3.fromRGB(255, 2, 2),
		GlowColor = Color3.fromRGB(129, 0, 2),
		ThumbnailColor = Color3.fromRGB(227, 50, 37),
		RoleColor = Color3.fromRGB(255, 128, 105),
		UsernameColor = Color3.fromRGB(255, 132, 128)
	},
	
	Student = {
		BackgroundColor = Color3.fromRGB(176, 208, 255),
		GlowColor = Color3.fromRGB(36, 93, 129),
		ThumbnailColor = Color3.fromRGB(211, 221, 255),
		RoleColor = Color3.fromRGB(208, 226, 255),
		UsernameColor = Color3.fromRGB(255, 255, 255)
	},
	
	Dead = {
		BackgroundColor = Color3.fromRGB(255, 0, 0),
		GlowColor = Color3.fromRGB(144, 36, 14),
		ThumbnailColor = Color3.fromRGB(255, 79, 25),
		RoleColor = Color3.fromRGB(181, 86, 69),
		UsernameColor = Color3.fromRGB(218, 118, 97)
	},
}

--// Types
export type CharacterType = {
	LastHealth: number,
	Stats: {[string]: PlayerRoundStats.ClientAwardsType}, -- Stats: [ Objectives: { Resolved: 4 (meaning 4 objectives resolved) } or Kills: 4 ]
	RoleConfig: { any? },
	
	Started: number,
	Ended: number
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl)),

	ConnectEvents: (self: Component) -> (),
	StartResults: (self: Component) -> (),
	HideScreen: (self: Component) -> (),
	
	ConstructAwardResults: (self: Component) -> Promise.TypedPromise<>,

	_End: (self: Component) -> (),
	_Show: (self: Component) -> Promise.TypedPromise<>,

	_ShowPlayersList: (self: Component) -> Promise.TypedPromise<>,
	
	_OnStartRound: (self: Component) -> (),
	_OnStartResult: (self: Component) -> (),
}

export type Fields = {
	RoundJanitor: Janitor.Janitor,
	Players: { [Player]: CharacterType }, -- Player/ Status(Dead, Survivor, Teacher)
	AwardMap: { [string] : number },
	
	CharacterComponent: any,
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "RoundResultUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "RoundResultUI", Frame & any, {}>

--// Methods

local function SplitCamelCase(text)
	return (
		text:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
	)
end

local function TransparencyText(Prefix: string, Subprefix: string)
	return `{Prefix} <font transparency="0.5">{Subprefix}</font>`
end

local function FormatSecondsToMS(seconds)
	local Minutes = math.floor(seconds / 60)
	local Seconds = seconds % 60

	return string.format("%02d:%02d", Minutes, Seconds)
end

function RoundResultUI.HideScreen(self: Component)
	self.Instance.Visible = false
end

function RoundResultUI._End(self: Component)
	self.Players = {}
	--self:HideScreen()
end

function RoundResultUI._Show(self: Component)
	return Promise.new(function(resolve)
		local Screen = self.Instance
		local PlayerList = self.Instance.Global.Screen :: Frame
		local LocalStats = self.Instance.Local :: Frame

		Screen.Visible = true
		CameraController:SetActiveCamera("ResultAttached")

		-- Cleanning up
		for _, v in PlayerList.Content:GetChildren() do
			if v:IsA("Frame") or 
				v:IsA("TextLabel") or v:IsA("CanvasGroup") then

				v:Destroy()
			end

		end

		for _, v in LocalStats.Awards.Content:GetChildren() do
			if v:IsA("Frame") or 
				v:IsA("TextLabel") or v:IsA("CanvasGroup") then

				v:Destroy()
			end
		end
		
		for _, v in LocalStats.Awards.Final:GetChildren() do
			if v:IsA("Frame") or v:IsA("CanvasGroup") then

				v:Destroy()
			end
		end

		-- Initializing
		print("A")
		self:_ShowPlayersList():andThen(function()
			print("B")
			task.wait(5)
			resolve()
		end)
	end)
end

function RoundResultUI._ShowPlayersList(self: Component)
	return Promise.new(function(resolve)
		local Screen = self.Instance
		local PlayerList = self.Instance.Global.Screen :: Frame
		local LocalStats = self.Instance.Local :: Frame

		local function SearchAward(Player: Player, Name: string, IsMap: boolean?)
			local Data = self.Players[Player]
			print(Data, Player)
			if not Data then
				return
			end

			if IsMap == nil then
				IsMap = false
			end

			local Award
			if IsMap then
				Award = self.AwardMap[Name]
			else
				Award = Data.Stats[Name]
			end

			print(Award, Data.Stats)
			return Award ~= nil and Award or nil
		end

		local function AddStatToCard(
			Player: Player, 
			Icon: string, 
			Name: string, 
			IconColor: Color3, 
			TextColor: Color3
		)

			print(Player, Icon, Name)

			local Template = RoundResultFolder.PlayerList_StatsLabel:Clone()
			Template.Icon.Image = Icon
			Template.Icon.ImageColor3 = IconColor or Color3.fromRGB(255, 255, 255)
			Template.Text = Name
			Template.TextColor3 = TextColor or Color3.fromRGB(255, 255, 255)

			Template.Visible = true
			Template.Parent = PlayerList.Content:FindFirstChild(Player.Name).Main.Stats
		end

		local function GetPlayerHealthColor(Player: Player)
			local Start = Color3.fromRGB(255, 255, 255)
			local End = Color3.fromRGB(255, 97, 92)

			local Percent = self.Players[Player].LastHealth / 100
			local Color = End:Lerp(Start, Percent)

			return Color
		end

		local function AddCard(Player: Player, Order: number)

			local PlayerConfig = self.Players[Player].RoleConfig
			local Colors = PlayerConfig.Group == "Teacher" 
				and PlayerList_Colors.Teacher 
				or PlayerList_Colors.Student

			local Template = RoundResultFolder.PlayerList_Card:Clone()
			local Main = Template.Main

			Template.Name = Player.Name
			Template.LayoutOrder = Order + 1
			Template.Visible = true
			Template.Parent = PlayerList.Content


			Main.Position = UDim2.fromScale(-0.2, 0.5)
			Main.GroupTransparency = 1
			Main.Rotation = Random.new():NextNumber(-10, 10)
			
			Main.Icon.Image = PlayerConfig.Character.Icon
			Main.Thumbnail.Image = PlayerConfig.Character.Thumbnail or PlayerConfig.Character.Icon
			Main.Username.Text = TransparencyText(Player.DisplayName, Player.Name)
			Main.Role.Text = TransparencyText(
				PlayerConfig.CharacterDisplayName and PlayerConfig.CharacterDisplayName or PlayerConfig.Character.Name,
				PlayerConfig.Group == "Teacher" and "" or PlayerConfig.Role.Name or PlayerConfig.Role.RoleDisplayName
			)

			print(PlayerConfig)
			-- Stats kinad?
			if PlayerConfig.Role.Group ~= "Teacher" then
				-- Adding if dead visuals
				
				print(self.Players[Player].LastHealth)
				if self.Players[Player].LastHealth <= 0 then
					Template.LayoutOrder += 2
					Colors = PlayerList_Colors.Dead
				end

				--initial Stats
				AddStatToCard(Player, "rbxassetid://87367001678941", FormatSecondsToMS(SearchAward(Player, "SurvivalTime")))
				AddStatToCard(Player, "rbxassetid://72215827673764", self.Players[Player].LastHealth, GetPlayerHealthColor(Player))
				AddStatToCard(Player, "rbxassetid://85460964461080", SearchAward(Player, "Objectives").Completed)
				
			elseif RolesManager:IsPlayerKiller(Player) then
				AddStatToCard(Player, "rbxassetid://104576121877268", SearchAward(Player, "Kills"))
				AddStatToCard(Player, "rbxassetid://87984673070379", SearchAward(Player, "Hits"))
			end

			-- visuals
			Main.Glow.ImageColor3 = Colors.GlowColor
			Main.Thumbnail.BackgroundColor3 = Colors.BackgroundColor
			Main.Thumbnail.ImageColor3 = Colors.ThumbnailColor
			Main.Role.TextColor3 = Colors.RoleColor
			Main.Username.TextColor3 = Colors.UsernameColor

			TweenUtility.PlayTween(Main, TweenInfo.new(0.5), { Position = UDim2.fromScale(0, 0.5), Rotation = 0, GroupTransparency = 0 }, nil, Random.new():NextNumber(0.1, 0.15))
			task.wait(0.03)
		end

		local function AddGroup(Name: string, players: {Player}, Order: number)
			if players and #players == 0 then
				return
			end

			local Template = RoundResultFolder.PlayerList_Title:Clone()
			Template.Name = `{Name}Group`
			Template.LayoutOrder = Order
			Template.Text = string.upper(Name)
			Template.Visible = true
			Template.Parent = PlayerList.Content

			for _, player in players do
				print("Adding: ",player)
				
				-- loop for cheap multiplayer test :skull:
				--for i = 1, 10 do
					AddCard(player, Order)
				--end
			end
		end

		PlayerList.Visible = true
		LocalStats.Visible = false

		PlayerList.Position = UDim2.fromScale(-0.4, 0.22)
		TweenUtility.WaitForTween(
			TweenUtility.PlayTween(PlayerList, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.015, 0.22)})
		)

		local Teachers = {}
		local Students = {}
		
		for _, Player in MatchStateClient:GetPlayersEngaged() do
			print(Player, "Players Engaged")
			--print(self.Players)
			
			if not self.Players[Player] then
				continue
			end

			local RoleConfig = self.Players[Player].RoleConfig
			if RoleConfig.Role.Group == "Teacher" then
				table.insert(Teachers, Player)
			elseif RoleConfig.Role.Group == "Student" then
				table.insert(Students, Player)
			end
		end

		print(Teachers, Students)
		print("Added round results")

		AddGroup("Teachers", Teachers, 0)
		AddGroup("Students", Students, 2)

		task.wait(5)
		self:ConstructAwardResults():andThen(function()
			print("Awards")
			return resolve()
		end)
	end)
end

function RoundResultUI.ConstructAwardResults(self: Component)
	return Promise.new(function(resolve)
		local Screen = self.Instance
		local LocalStats = Screen.Local :: Frame

		local PlayerConfig = self.Players[LocalPlayer]
		if not PlayerConfig then
			return resolve() -- if this player doesnt played lmao
		end
		
		print('award map:', self.AwardMap)

		local function ValidAward(Player: Player, Name: string, Mode: "AwardMap" | "Stats" | "Other")
			local Data = self.Players[Player]
			if not Data then
				return
			end

			if Mode == nil then
				Mode = "Stats"
			end

			local Award
			if Mode == "AwardMap" then
				Award = Data.AwardMap[Name]
			elseif Mode == "Stats" then
				Award = Data.Stats[Name]
			elseif Mode == "Other" then
				Award = Data.Stats.Others[Name]
			else
				error("skibidi")
			end

			return Award ~= nil and Award or nil
		end

		local function NewAward(Title: string, Amount: number, Order: number, IsFinal: boolean)
			if not Title or not Amount then
				return
			end

			if not IsFinal and Amount <= 0 then
				return
			end

			local Template = RoundResultFolder.Award_Card:Clone()
			Template.Title.Text = SplitCamelCase(Title)
			
			local AwardData = self.AwardMap[Title]
				
			if not IsFinal and Amount > 1 then 
				local AddString = ` (x{Amount})`
				if AwardData.Cap and Amount >= AwardData.Cap then
					AddString = `<font color="rgb(180, 20, 20)">{AddString}</font>`
				end
				Template.Title.Text ..= AddString 
			end
			
			local PointsReceived = IsFinal and Amount or Amount * AwardData.Reward
			
			Template.Points.Text = type(Amount) == "number" and "0" or Amount 
			Template.LayoutOrder = Order
			Template.Visible = true
			Template.GroupTransparency = 1
			Template.Parent = IsFinal and LocalStats.Awards.Final
				or LocalStats.Awards.Content
			
			Template.Points.Rotation = Random.new():NextNumber(-10, 10)
			TweenUtility.PlayTween(Template.Points, TweenInfo.new(0.12), {Rotation = 0})
			
			if type(Amount) == "number" then
				TweenUtility.PlayTween(Template, TweenInfo.new(0.12), {GroupTransparency = 0}, function()
					self.Janitor:Add(TweenUtility.TweenStep(TweenInfo.new(0.2, Enum.EasingStyle.Quad), function(t)
						Template.Points.Text = tostring(math.round(PointsReceived * t))
					end, function()
						Template.Points.Text = tostring(PointsReceived)
					end))
				end)
			end

			return Template
		end

		local function NewCategoryAward(Category: string, Order: number)

			local LastCategory = #LocalStats.Awards.Content:GetChildren()
			local Template = RoundResultFolder.Award_Title:Clone()

			Order = Order or LastCategory

			Template.Name = Category
			Template.Text = Category
			Template.TextTransparency = 1
			Template.LayoutOrder = Order
			Template.Visible = true
			Template.Parent = LocalStats.Awards.Content
			
			TweenUtility.WaitForTween(TweenUtility.PlayTween(Template, TweenInfo.new(0.2), {TextTransparency = 0}))

			local Awards = ValidAward(LocalPlayer, Category, "Other")
			print(Awards)
			if Awards then
				for Name, Amount in Awards do
					print(Name, Amount)

					if Amount <= 0 then
						continue
					end

					NewAward(Name, Amount, Order)
					task.wait(0.03)
				end
			end
		end

		LocalStats.Visible = true
		
		local Names = {}
		for categoryName, categoryData in PlayerConfig.Stats.Others do
			table.insert(Names, categoryName)
		end
		table.sort(Names)
		
		
		for i, categoryName in Names do
			NewCategoryAward(categoryName, i)
			task.wait(.3)
		end

		task.wait(2)
		
		print(PlayerConfig)
		
		if PlayerConfig.RoleConfig.Role.Group == "Student" then

			local HealthStatues = self.Players[LocalPlayer].LastHealth > 0
				and "Survived" or "Eliminated"

			local HealthColor = HealthStatues == "Survived" and Color3.fromRGB(169, 255, 223)
				or Color3.fromRGB(209, 89, 80)


			--NewCategoryAward("Objectives", 0)

			local HealthAward = NewAward("Status", HealthStatues, 99, true)
			HealthAward.Size = UDim2.fromScale(1, 0.45)
			HealthAward.Points.TextColor3 = HealthColor
		end
		
		--if PlayerConfig.Stats.Total > 0 then
			local FinalTotal = NewAward("Total", PlayerConfig.Stats.Total, 100, true)
			FinalTotal.Size = UDim2.fromScale(1, 0.45)
			FinalTotal.Points.TextColor3 = Color3.fromRGB(255, 216, 161)
		--end
		

		task.wait(5)

		return resolve()
	end)
end

function RoundResultUI._OnStartRound(self: Component)
	self.Players = {}
	self:HideScreen()
end

function RoundResultUI._OnEndRound(self: Component) end

function RoundResultUI._OnStartResult(self: Component)
	-- skip everything if you didnt play
	if not self.Players[LocalPlayer] then
		return
	end
	
	self.Instance.CloseButton.Visible = false
	
	self:_Show():andThen(function()
		print("Done")
		self:_End()
	end)
end

function RoundResultUI._OnEndResult(self: Component)
	self.Instance.CloseButton.Visible = true
end

function RoundResultUI.ConnectEvents(self: Component)
	local ConnectionJanitor = self.Janitor:Add(Janitor.new())
	
	ConnectionJanitor:Add(self.Instance.CloseButton.MouseButton1Click:Connect(function()
		self:HideScreen()
	end))
	
	self.AwardMap = {}
	
	ConnectionJanitor:Add(ClientRemotes.RoundStatsComponentReplicator.On(function(Value: { [Player]: unknown })
		if MatchStateClient.CurrentPhase ~= "Round" then
			return	
		end
		
		print(Value, 'val')
		
		for Player, Awards in Value do
			if not self.Players[Player] then
				continue
			end
			
			self.Players[Player].LastHealth = Awards.Stats.Health
			self.Players[Player].Stats = Awards.Stats
			self.AwardMap = TableKit.DeepReconcile(self.AwardMap, Awards.AwardMap)
		end
	end))
	
	ConnectionJanitor:Add(MatchStateClient.MatchStarted:Connect(function(Phase)
		if Phase == "Intermission" then
			return
		end
		
		-- initialize functions
		self[`_OnStart`..Phase](self)
	end))
	
	ConnectionJanitor:Add(MatchStateClient.MatchEnded:Connect(function(Phase)
		if Phase == "Intermission" then
			return
		end

		-- initialize functions
		self[`_OnEnd`..Phase](self)
	end))
	
	ConnectionJanitor:Add(Players.PlayerRemoving:Connect(function(Player)
		if not self.Players[Player] then
			return
		end
		
		self.Players[Player] = nil
	end))
	
	--ConnectionJanitor:Add(MatchStateClient.PlayerHealthChanged:Connect(function(Player, Health)
	--	if MatchStateClient.CurrentPhase == "Round" then
	--		if not MatchStateClient:IsPlayerEngaged(Player) then
	--			return
	--		end

	--		if RolesManager:IsPlayerSpectator(Player) then
	--			return
	--		end

	--		if not self.Players[Player] then
	--			return
	--		end

	--		self.Players[Player].LastHealth = Health
	--	end
	--end))
	
	ConnectionJanitor:Add(MatchStateClient.PlayerSpawned:Connect(function(Player)
		if MatchStateClient.CurrentPhase == "Intermission" then 
			return
		end
		
		if RolesManager:IsPlayerSpectator(Player) then
			return
		end
		
		local RoleData = RolesManager:GetPlayerRoleConfig(Player)
		self.Players[Player] = {
			RoleConfig = RoleData,
			LastHealth = Player.Character.Humanoid.Health,
			Started = os.clock() -- resetting count
		}
	end))
	
	ConnectionJanitor:Add(MatchStateClient.PlayerDied:Connect(function(Player)
		if MatchStateClient.CurrentPhase ~= "Round" then
			return
		end
		
		if not MatchStateClient:IsPlayerEngaged(Player) then
			return
		end
		
		if not self.Players[Player] then
			return
		end
		
		self.Players[Player].Ended = os.clock()
	end))
	
	ConnectionJanitor:Add(RolesManager.PlayerRoleConfigChanged:Connect(function(Player, Config)
		if MatchStateClient.CurrentPhase == "Intermission" then
			return
		end
		
		if not MatchStateClient:IsPlayerEngaged(Player) then
			return
		end
		
		if not self.Players[Player] then
			return
		end
		
		if RolesManager:IsPlayerSpectator(Player) then
			return
		end
		
		local LastData = RolesManager:GetPlayerRoleConfig(Player)
		if LastData == Config then
			return
		end
		
		local Data: CharacterType = {
			Stats = {},
			RoleConfig = Config,
			
			LastHealth = Player.Character.Humanoid.Health,
			Started = os.clock(),
			Ended = 0,
		}
		
		self.Players[Player] = Data
	end))
	
	--this will get the players if on round
	for _, Player in Players:GetPlayers() do
		if MatchStateClient.CurrentPhase ~= "Round" then
			continue
		end
		
		if not MatchStateClient:IsPlayerEngaged(Player) then
			continue
		end
		
		if self.Players[Player] then
			continue
		end
		
		if RolesManager:IsPlayerSpectator(Player) then
			continue
		end
		
		local Data: CharacterType = {
			Stats = {},
			RoleConfig = RolesManager:GetPlayerRoleConfig(Player),
			LastHealth = Player.Character.Humanoid.Health,
		}
		
		self.Players[Player] = Data
	end
end

function RoundResultUI.OnConstruct(self: Component)
	
	self.RoundJanitor = self.Janitor:Add(Janitor.new())
	
	self.Players = {}
	
	self.Instance.Visible = false
	self.Instance.CloseButton.Visible = false
	
	--self:ConnectEvents()
end

function RoundResultUI.OnConstructClient(self: Component)
	
	self:ConnectEvents()
end

--// Returner
return RoundResultUI :: Impl