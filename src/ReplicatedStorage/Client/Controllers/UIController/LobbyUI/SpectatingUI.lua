--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local Utility = require(ReplicatedStorage.Shared.Utility)
local EnumsType = require(ReplicatedStorage.Shared.Enums)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local MusicUtility = require(ReplicatedStorage.Client.Utility.MusicUtility)

local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--//Variables

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI.Misc
local SpectatingUI = BaseComponent.CreateComponent("SpectatingUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	SetSubjectPlayer: (self: Component, player: Player?) -> (),
	
	_ConnectUiEvents: (self: Component) -> (),
}

export type Fields = {
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SpectatingUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "SpectatingUI", Frame & any, {}>

--//Methods

function SpectatingUI.OnEnabledChanged(self: Component, value: boolean)
	
	self.Instance.Visible = value
	
	if not value then
		
		--putting camera back
		if LocalPlayer.Character then
			self:SetSubjectPlayer(LocalPlayer)
		end
		
		return
	end
	
	--music plays only at round
	if not MatchStateClient:IsRound() then
		return
	end

	--music playback
	MusicUtility.Music.Misc.Spectating:PlayQuiet()
	MusicUtility.Music.Misc.Spectating:ChangeVolume(1, TweenInfo.new(2))
	
	ProxyService:AddProxy("LightingChangeClient"):Fire(MatchStateClient.CurrentMap, true)

	self.ActiveJanitor:Add(function()
		ProxyService:FireProxy("LightingChangeClient", "Lobby", true)
		MusicUtility.Music.Misc.Spectating:Reset()
	end)
end

function SpectatingUI.SetSubjectPlayer(self: Component, player: Player?)
	
	--resetting if no player provided
	if not player or not player.Character then
		
		self.Instance.Subject.Text = ""
		self.Instance.Subject.Username.Text = ""
		
		return
	end
	
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = player.Character:FindFirstChildWhichIsA("Humanoid")
	
	self.Instance.Subject.Text = player.DisplayName
	self.Instance.Subject.Username.Text = player.Name
end

function SpectatingUI._ConnectUiEvents(self: Component)
	
	local Index = 0
	local ButtonExit = self.Instance.Subject.SpectateExit :: TextButton
	local ButtonNext = self.Instance.Subject.Buttons.Next :: ImageButton
	local ButtonPrevious = self.Instance.Subject.Buttons.Previous :: ImageButton
	
	--selects any player on above buttons press
	local function Select(increment: number)
		
		local AlivePlayers = MatchStateClient:GetAlivePlayers("Spectator", "Exclude")
		local Max = #AlivePlayers
		
		Index += increment
		
		if Index > Max then
			Index = 1
			
		elseif Index < 1 then
			Index = Max
		end
		
		if Max == 0 then
			self:SetEnabled(false)
			return
		end
		
		self:SetSubjectPlayer(AlivePlayers[Index])
	end
	
	--selection
	ButtonNext.MouseButton1Click:Connect(function() Select(1) end)
	ButtonPrevious.MouseButton1Click:Connect(function() Select(-1) end)
	
	--exit button connection
	ButtonExit.MouseButton1Click:Connect(function()
		self:SetEnabled(false)
	end)
	
	--reset
	Select(1)
end

function SpectatingUI._ConnectMatchEvents(self: Component)
	MatchStateClient.MatchEnded:Connect(function()
		self:SetEnabled(false)
	end)
end

function SpectatingUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self:SetEnabled(false)
	self:_ConnectUiEvents()
	self:_ConnectMatchEvents()
end

--//Returner

return SpectatingUI