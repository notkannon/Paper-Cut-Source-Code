--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseUI = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local ClientMatchState = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local LocalPlayer = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local RoleListUI = BaseComponent.CreateComponent("RoleListUI", {

	isAbstract = false,

}, BaseUI) :: Impl

--//Types

type PlayerTab = {
	Player: Player,
	CoreSize: UDim2,
	Instance: typeof(UIAssets.Misc.StudentTab),
	Connections: {
		[string]: RBXScriptConnection,
	}
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUI.MyImpl) ),
	
	Cleanup: (self: Component) -> (),
	GetTabFromPlayer: (self: Component, player: Player) -> PlayerTab?,
	
	EmitPlayerDeath: (self: Component, player: Player) -> (),
	ApplyPlayerHealth: (self: Component, player: Player) -> (),
	
	_InitTabs: (self: Component) -> (),
	_RemoveTab: (self: Component, tab: PlayerTab) -> (),
	_CreateTab: (self: Component, player: Player) -> (),
	_ConnectRoleEvents: (self: Component) -> (),
	
	IsPlayerSameRole: (self: Component, player: Player) -> boolean,
	IsPlayerOppositeRole: (self: Component, player: Player) -> boolean,
}

export type Fields = {

	Tabs: { PlayerTab },
	Role: string,
	Mode: string

} & BaseUI.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "RoleListUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "RoleListUI", Frame & any, {}>

--//Methods

--visual

function RoleListUI.IsPlayerSameRole(self: Component, player: Player)
	return (self.Options.Role == "Student" and RolesManager:IsPlayerStudent(player)) or (self.Options.Role ~= "Student" and RolesManager:IsPlayerKiller(player))
end

function RoleListUI.IsPlayerOppositeRole(self: Component, player: Player)
	if RolesManager:IsPlayerSpectator(player) then
		return false
	end
	return not self:IsPlayerSameRole(player)
end

function RoleListUI.ApplyPlayerHealth(self: Component, player: Player, new: number, old: number)
	
	local Tab = self:GetTabFromPlayer(player)
	local Core = Tab and Tab.Instance:FindFirstChild("Core")
	
	local Config = RolesManager:GetPlayerRoleConfig(player)

	-- 	:(
	if not Core then
		return
	end

	TweenUtility.ClearAllTweens(Core)
	if Core:FindFirstChild("Class") then TweenUtility.ClearAllTweens(Core.Class) end
	TweenUtility.ClearAllTweens(Core.PlayerName)
	TweenUtility.ClearAllTweens(Core:FindFirstChild("Name"))
	
	--initials
	local Humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
	local IsDamaged = new < old
	local Alpha = math.abs(new - old) / Humanoid.MaxHealth
	local Color = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(112, 29, 29), 1 - new / Humanoid.MaxHealth)
	local TweenTime = math.clamp(Alpha * 3, 0.1, 1.5)
	local Transparency = math.clamp(new / Humanoid.MaxHealth, 0, 0.6)
	
	--updating health data
	Core.Health.Text = `{ math.round(new / Humanoid.MaxHealth * 100) }%`
	Core.Health.Visible = math.round(new) < Humanoid.MaxHealth
	
	if IsDamaged then
		
		--Core.Size = UDim2.fromScale(
		--	math.clamp(Tab.CoreSize.X.Scale * 2 * Alpha + 1, 1, 1.7),
		--	math.clamp(Tab.CoreSize.Y.Scale * 2 * Alpha + 1, 1, 1.7)
		--)
		
		--flashing light effect
		
		Core.Rotation = math.clamp(Alpha * 20, 5, 20)
		Core.ImageColor3 = Color3.new(1, 1, 1)
		Core.ImageTransparency = 0.15
		
		if Core:FindFirstChild("Class") then
			Core.Class.ImageColor3 = Color3.new(1, 1, 1)
			Core.Class.ImageTransparency = 0.3
		end
		
		Core.PlayerName.TextColor3 = Color3.new(1, 1, 1)
		Core.PlayerName.TextTransparency = 0.3
		
		Core:FindFirstChild("Name").TextColor3 = Color3.new(1, 1, 1)
		Core:FindFirstChild("Name").TextTransparency = 0.3
		
		Core.Health.TextColor3 = Color3.new(1, 1, 1)
		Core.Health.TextTransparency = 0.3
	end
	
	--base size change
	TweenUtility.PlayTween(Core, TweenInfo.new(TweenTime / 4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {

		Size = Tab.CoreSize,
		Rotation = 0,

	} :: ImageLabel)
	
	--visuals
	
	local _TweenInfo = TweenInfo.new(TweenTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out) -- can you cannon just call tweeninfo once?
	
	TweenUtility.PlayTween(Core, _TweenInfo, {

		ImageColor3 = Color,
		ImageTransparency = Transparency / 2,

	} :: ImageLabel)
	
	if Core:FindFirstChild("Class") then
		TweenUtility.PlayTween(Core.Class, _TweenInfo, {

			ImageColor3 = Color,
			ImageTransparency = Transparency,

		} :: ImageLabel)
	end

	TweenUtility.PlayTween(Core.PlayerName, _TweenInfo, {

		TextColor3 = Color,
		TextTransparency = Transparency,

	} :: TextLabel)

	TweenUtility.PlayTween(Core:FindFirstChild("Name"), _TweenInfo, {

		TextColor3 = Color,
		TextTransparency = Transparency,

	} :: TextLabel)
	
	TweenUtility.PlayTween(Core.Health, _TweenInfo, {

		TextColor3 = Color,
		TextTransparency = Transparency,

	} :: TextLabel)
	
	local HPPercentage = Humanoid.Health / Humanoid.MaxHealth
	
	if HPPercentage <= 0.25 and Config.AltIcons.Critical then
		Core.Image = Config.AltIcons.Critical
	elseif HPPercentage <= 0.5 and Config.AltIcons.Injured then
		Core.Image = Config.AltIcons.Injured
	else
		Core.Image = Config.Icon
	end
end

function RoleListUI.EmitPlayerDeath(self: Component, player: Player)
	
	local Tab = self:GetTabFromPlayer(player)
	local Core = Tab and Tab.Instance:FindFirstChild("Core")
	
	-- 	:(
	if not Core then
		return
	end
	
	--TweenUtility.ClearAllTweens(Core)
	--TweenUtility.ClearAllTweens(Core.Class)
	--TweenUtility.ClearAllTweens(Core.PlayerName)
	--TweenUtility.ClearAllTweens(Core:FindFirstChild("Name"))
	
	--local Color = Color3.fromRGB(112, 29, 29)
	
	Core.Health.Visible = false
	Core.Executed.Visible = true
	
	--Core.ImageColor3 = Color
	--Core.ImageTransparency = 0.2

	--Core.Class.ImageColor3 = Color
	--Core.Class.ImageTransparency = 0.2

	--Core.PlayerName.TextColor3 = Color
	--Core.PlayerName.TextTransparency = 0.2

	--Core:FindFirstChild("Name").TextColor3 = Color
	--Core:FindFirstChild("Name").TextTransparency = 0.2

	--Core.Health.TextColor3 = Color
	--Core.Health.TextTransparency = 0.2
end

--core

function RoleListUI.Cleanup(self: Component)
	while #self.Tabs > 0 do
		self:_RemoveTab(self.Tabs[1])
	end
end

function RoleListUI.GetTabFromPlayer(self: Component, player: Player)
	
	for _, Tab in ipairs(self.Tabs) do
		
		--UsedId cuz somtimes instances could be different :D
		if Tab.Player.UserId == player.UserId then
			return Tab
		end
	end
end

function RoleListUI._RemoveTab(self: Component, tab: PlayerTab)
	
	--removin from cache if parented to
	local Index = table.find(self.Tabs, tab)
	
	if Index then
		table.remove(self.Tabs, Index)
	end
	
	--removing connections
	for Key, Connection in pairs(tab.Connections) do
		Connection:Disconnect()
		tab.Connections.Key = nil
	end
	
	tab.Instance:Destroy()
	
	--finalize
	table.clear(tab)
end

function RoleListUI._CreateTab(self: Component, player: Player)
	
	--oh yes
	local Config = RolesManager:GetPlayerRoleConfig(player)
	
	--instances
	local Humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
	local Instance = UIAssets.Misc[`{self.Options.Role}Tab`]:Clone()
	local Core = Instance:FindFirstChild("Core")
	
	--tab creation
	local Tab = {
		
		Player = player,
		Instance = Instance,
		CoreSize = Core.Size,
		
		Connections = {
			
			Died = ClientMatchState.PlayerDied:Connect(function(player)
				
				if player ~= player or not self:IsEnabled() then
					return
				end
				
				self:EmitPlayerDeath(player)
			end),
			
			HealthChanged = ClientMatchState.PlayerHealthChanged:Connect(function(player, new, old)
				
				if self.Options.IgnoreHealth then
					return
				end
				
				if player ~= player or not self:IsEnabled() then
					return
				end
				
				self:ApplyPlayerHealth(player, new, old)
			end),
		},
		
	} :: PlayerTab
	
	--caching
	table.insert(self.Tabs, Tab)
	
	--alignment
	if self.Options.Mode == "LeftRight" then
		local IsRight = #self.Tabs > 7
		
		--property applying
		Instance.Parent = self.Instance:FindFirstChild(IsRight and "Left" or "Right")
		
		--offset changing
		if Core:FindFirstChild("Class") then Core.Class.Position = UDim2.fromScale(IsRight and 1 or 0, 0) end
		Core.PlayerName.Position = UDim2.fromScale( -(IsRight and 0.1 or 2), 1.3)
	else
		Instance.Parent = self.Instance
	end
	Instance.LayoutOrder = #self.Tabs
	
	Core.Image = Config.Character.Icon or "" -- character icon
	if Core:FindFirstChild("Class") then
		Core.Class.Image = Config.Role.Icon or "" -- class icon
	end
	Core:FindFirstChild("Name").Text = Config.CharacterDisplayName or Config.CharacterName -- character name
	Core.PlayerName.Text = player.Name -- sure
	
	
	
	
	--initial apply
	if not self.Options.IgnoreHealth then self:ApplyPlayerHealth(player, Humanoid.Health, Humanoid.MaxHealth) end
end

function RoleListUI._InitTabs(self: Component)
	
	--cleaning older ones
	
	--right side
	if self.Options.Mode == "LeftRight" then
		for _, Instance: Instance in ipairs(self.Instance.Right:GetChildren()) do
			if Instance:IsA("UIListLayout") then
				continue
			end
			
			Instance:Destroy()
		end
		
		--left side
		for _, Instance: Instance in ipairs(self.Instance.Left:GetChildren()) do
			if Instance:IsA("UIListLayout") then
				continue
			end

			Instance:Destroy()
		end
	else
		for _, Instance: Instance in ipairs(self.Instance:GetChildren()) do
			if Instance:IsA("UIListLayout") then
				continue
			end

			Instance:Destroy()
		end
	end
	
	--creating tabs for already existing players
	for _, Player in ipairs(Players:GetPlayers()) do
		
		--tests
		if Player == LocalPlayer
			and not RunService:IsStudio() then

			continue
		end
		
		if not self:IsPlayerSameRole(Player)
			or not Player.Character then
			
			continue
		end
		
		self:_CreateTab(Player)
	end
end

function RoleListUI._ConnectRoleEvents(self: Component)
	
	--general
	
	--resetting on match ending
	ClientMatchState.MatchEnded:Connect(function()
		self:Cleanup()
	end)
	
	--recreate tab on player role change/respawn
	ClientMatchState.PlayerSpawned:Connect(function(player)
		
		--tests
		if player == LocalPlayer
			and not RunService:IsStudio() then
			
			return
		end
		
		local Tab = self:GetTabFromPlayer(player)
		
		if RunService:IsStudio() then
			print(player, Tab, self:IsPlayerSameRole(player), self.Role, RolesManager:GetPlayerRoleString(player))
		end
		
		--we dont delete tab cuz it shall be kept in-round
		if Tab and self:IsPlayerSameRole(player) then
			self:_RemoveTab(Tab)
		end

		--no need to create, but potential need to delete
		if not self:IsPlayerSameRole(player) then
			if Tab and self:IsPlayerOppositeRole(player) then
				self:_RemoveTab(Tab)
			end
			return
		end

		--create a new tab based on updated config
		self:_CreateTab(player)
	end)
	
	--tabs removal
	Players.PlayerRemoving:Connect(function(player)
		
		local Tab = self:GetTabFromPlayer(player)
		
		--keep tab in round if player left as spectator (it could reset itself)
		if Tab and self:IsPlayerSameRole(player) then
			self:_RemoveTab(Tab)
		end
	end)
	
	--show only when player is in-round
	PlayerController.RoleConfigChanged:Connect(function()
		self:SetEnabled(not PlayerController:IsSpectator())
	end)
	
	--initial state
	self:SetEnabled(not PlayerController:IsSpectator())
end


function RoleListUI.OnConstructClient(self: Component, ...)
	local Args = table.pack(...)
	
	BaseUI.OnConstructClient(self, ...)
	
	self.Tabs = {}
	self.Options = Args[1]
	assert(self.Options)
	assert(self.Options.Role)
	assert(table.find({"LeftRight", "Center"}, self.Options.Mode), `Incorrect mode specified for RoleListUI: got {self.Options.Mode}`)
	
--	print('hi, running at ', self.Instance, self.Options)

	--role event connections
	self:_InitTabs()
	self:_ConnectRoleEvents()
end

--//Returner

return RoleListUI