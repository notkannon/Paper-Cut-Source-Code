--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local RoleTypes = require(ReplicatedStorage.Shared.Types.RoleTypes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local Utility = require(ReplicatedStorage.Shared.Utility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility) 
local MusicUtility = require(ReplicatedStorage.Client.Utility.MusicUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)

local LampComponent = require(ReplicatedStorage.Client.Components.Environment.LampComponent)
local ClockComponent = require(ReplicatedStorage.Client.Components.Environment.ClockComponent)
local TerrorController = require(script.TerrorController)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local CameraController = require(ReplicatedStorage.Client.Controllers.CameraController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--//Constants

local LowQualityPresets = {
	Terrain = {
		WaterReflectance = 0,
		WaterTransparency = 0.15,
		WaterWaveSize = 0.25,
		WaterWaveSpeed = 10,
	}
}

--//Variables


local LightingColorCorrection

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local EnvironmentSfx = SoundUtility.Sounds.Environment

local EnvironmentController = Classes.CreateSingleton("EnvironmentController") :: Impl
local ClockComponents = {}

--//Types

export type Impl = {
	__index: Impl,

	GetName: () -> "EnvironmentController",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Controller) -> boolean,
	
	ApplyLightingPreset: (self: Controller, preset: string, force: boolean?) -> (),
	ApplyLowDetails: (self: Controller, Value: boolean) -> (),
	
	-- deprecated
	--ApplyDayEnvironment: (self: Controller) -> (),
	--ApplyNightEnvironment: (self: Controller) -> (),
	
	new: () -> Controller,
	OnConstruct: (self: Controller) -> (),
	OnConstructServer: (self: Controller) -> (),
	OnConstructClient: (self: Controller) -> (),
	
	_OnEndRound: (self: Controller) -> (),
	_OnStartRound: (self: Controller) -> (),
	_OnEndIntermission: (self: Controller) -> (),
	_OnStartIntermission: (self: Controller) -> (),
	_ConnectRoundEvents: (self: Controller) -> (),
	_InitEnvironmentalComponents: (self: Controller) -> (),
}

export type Fields = {
	Janitor: Janitor.Janitor,
	RoundJanitor: Janitor.Janitor,
}

export type Controller = typeof(setmetatable({} :: Fields, PlayerController :: Impl))

--//Methods

function EnvironmentController.ApplyLowDetails(self: Controller, Value: boolean)
	local Terrain = workspace:FindFirstChildOfClass("Terrain")
	local AllDetails = CollectionService:GetTagged("Details")
	local Config = LowQualityPresets[Terrain.ClassName]
	
	for _, Detail in AllDetails do
		local Temp: ObjectValue
		if Value then
			if Detail:FindFirstChild("Temp") 
				and Detail:FindFirstChild("Temp"):IsA("ObjectValue") then
				
				continue
			end
			
			Temp = Instance.new("ObjectValue")
			Utility.ApplyParams(Temp, {
				Name = "Temp",
				Parent = Detail,
				Value = Detail.Parent,
			})

			Detail.Parent = ReplicatedStorage.DisabledQualityAssets
		else
			Temp = Detail:FindFirstChild("Temp") :: ObjectValue
			if Temp then
				if not Temp.Value:IsDescendantOf(workspace) then
					Detail:Destroy() -- doesnt exist it
					continue
				end
				
				Detail.Parent = Temp.Value
				Temp:Destroy()
			end
		end
	end
	
	if Config then
		Utility.ApplyParams(Terrain, Config)
	end
	
	print("Changed")
end

function EnvironmentController.ApplyLightingPreset(self: Controller, preset: string, force: boolean?)
	local Config = Lighting:FindFirstChild(preset) :: Configuration
	assert(Config, `Couldn't find lighting preset: {preset}`)
	
	self.Janitor:Cleanup()
	
	local Properties = Config:GetAttributes()
	local GenericTweenInfo = TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	if force then
		Utility.ApplyParams(Lighting, Properties)
	else
		self.Janitor:Add(TweenUtility.PlayTween(Lighting, GenericTweenInfo, Properties), "Cancel")
	end
	
	local LightingComponents = Config:GetChildren()
	
	-- cleaning old lighting components
	for _, Component: Instance in CollectionService:GetTagged("CurrentLighting") do
		Component:Destroy()
	end
	
	-- applying new lighting components
	for _, Component: Instance in LightingComponents do
		local CopiedComponent = Component:Clone()
		CopiedComponent:AddTag("CurrentLighting")
		
		if Component:IsA("Clouds") then
			CopiedComponent.Parent = workspace.Terrain
		else
			CopiedComponent.Parent = Lighting
		end
		
	end
end

function EnvironmentController._OnStartRound(self: Controller, force: boolean?, ...)
	task.wait(7.5) -- waiting for the map to load
	
	local Args = table.pack(...)
	print('gotten args', Args)
	
	local Map = Args[1]
	
	--environment
	self:ApplyLightingPreset(Map, force)
	
	--playback reset
	self.RoundJanitor:Add(function()
		for _, Loop in pairs(MusicUtility.Music.Round) do
			Loop:ChangeVolume(-1, TweenInfo.new(3))
		end
	end)
end

function EnvironmentController._OnStartIntermission(self: Controller, force: boolean?)
	self:ApplyLightingPreset("Lobby", force)
end

function EnvironmentController._OnStartResult(self: Controller) 
	
	TerrorController:Stop()
end

function EnvironmentController._OnEndRound(self: Controller) end

function EnvironmentController._OnEndIntermission(self: Controller)	 end

function EnvironmentController._OnEndResult(self: Controller) end

function EnvironmentController._InitEnvironmentalComponents(self: Controller)
	
	local function CacheComponent(component, t)
		
		table.insert(t, component)

		--cleanup thing
		component.Janitor:Add(function()
			table.remove(t,
				table.find(t, component)
			)
		end)
	end
	
	--collecting already existing ones
	for _, Component in ipairs(ComponentsManager.GetAllComponentsOfType("Clock")) do
		CacheComponent(Component, ClockComponents)
	end
	
	--subcribing to new components adding
	
	ComponentsManager.ComponentAdded:Connect(function(component)
		
		if Classes.InstanceOf(component, ClockComponent) then
			CacheComponent(component, ClockComponents)
		end
	end)

	--clock updates
	MatchStateClient.CountdownStepped:Connect(function(currentTime)
		
		for _, ClockComponent in ipairs(ClockComponents) do
			ClockComponent:ApplyTime(currentTime, MatchStateClient.CurrentDuration)
		end
	end)
end

function EnvironmentController._ConnectRoundEvents(self: Controller)
	
	local Last30SecTheme = MusicUtility.Music.Misc.RoundLast30Sec
	local LastStandThemes = {MusicUtility.Music.LastStand["1v1"], MusicUtility.Music.LastStand["1v2"], MusicUtility.Music.LastStand["1v3"]}
	
	ProxyService:AwaitProxyAndConnect("LightingChangeClient", function(name, force)
		self:ApplyLightingPreset(name, force)
	end)
	
	--last 30 seconds theme trigger
	MatchStateClient.CountdownStepped:Connect(function(countdown)
		
		if not MatchStateClient:IsRound() or MatchStateClient.CurrentPhase == "Result" then
			return
		end
		
		if countdown > 30 or countdown == 31 then
			
			--reset track if time was increased and it was not stopped
			if Last30SecTheme.Instance.Playing then
				
				Last30SecTheme:Reset()
			end
			
			return
				
				--no playback repeat
		elseif Last30SecTheme.Instance.Playing then
			
			return
		end
		
		Last30SecTheme:PlayQuiet()
		Last30SecTheme:ChangeVolume(1, TweenInfo.new(30, Enum.EasingStyle.Sine, Enum.EasingDirection.In))
	end)
	
	--last standing trigger
	ClientRemotes.MatchServiceStartLMS.On(function(killerAmount : number)
		LastStandThemes[math.clamp(killerAmount, 1, 3)]:Play()
	end)
	
	MatchStateClient.PlayersChanged:Connect(function(state)
		
		if not MatchStateClient:IsRound() then
			
			for _, theme in LastStandThemes do
				theme:Reset()
			end
			
			return
		end
		
		local UIController = Classes.GetSingleton("UIController")
		local IsSpectating = UIController:GetInterface("SpectatingUI"):IsEnabled()
		
		if table.find(state.Killers, Player) or table.find(state.Students, Player) or IsSpectating then
			self:ApplyLightingPreset(MatchStateClient.CurrentMap, true)
		else
			self:ApplyLightingPreset("Lobby", true)
		end
	end)
	
	--every round we shall keep janitor removal theme
	MatchStateClient.MatchStarted:Connect(function()
		
		if not MatchStateClient:IsRound() then
			return
		end
		
		self.RoundJanitor:Add(function()
			
			for _, Theme in LastStandThemes do
				Theme:Reset()
			end
			Last30SecTheme:Reset()
		end)
	end)
	
	--client role changing
	PlayerController.RoleConfigChanged:Connect(function()
		
		--resetting all background tracks
		for _, Loop: MusicUtility.MusicWrapper in pairs(MusicUtility.Music.Round) do
			Loop:Reset()
		end
		
		MusicUtility.Music.Misc.DayTime:PlayQuiet()
		MusicUtility.Music.Misc.DayTime:ChangeVolume(0, nil, "Set")
		MusicUtility.Music.Misc.DayTime:ChangePlayback(0, nil, "Set")
		
		--if spectator then play lobby music
		if PlayerController:IsSpectator() then
			
			MusicUtility.Music.Misc.DayTime:Play()
			MusicUtility.Music.Misc.DayTime:ChangeVolume(1, TweenInfo.new(1), "Set")
			MusicUtility.Music.Misc.DayTime:ChangePlayback(1, TweenInfo.new(1), "Set")
			TerrorController:Stop() -- disabling TR detections and music
			
			return
		end
		
		--terror radius enabling
		TerrorController:Start()
		
		--gameplay roles related
		
		local LoopName = (PlayerController:IsKiller() and "Killer")
			or (PlayerController:IsStudent() and "Student")
		
		if LoopName == "Student" then
			LoopName ..= MatchStateClient.CurrentMap
		end
		print(LoopName)
		
		local Loop =  MusicUtility.Music.Round[LoopName] :: MusicUtility.MusicWrapper
		
		if not Loop then
			return
		end
		
		Loop:Play()
		Loop:ChangeVolume(0, nil, "Set")
		Loop:ChangeVolume(1, TweenInfo.new(7), "Set")
	end)
end

function EnvironmentController.OnConstructClient(self: Controller)
	
	self.Janitor = Janitor.new()
	self.RoundJanitor = Janitor.new()
	
	--LightingColorCorrection = Lighting:FindFirstChild("RootCR")
	--LightingColorCorrection.Enabled = true
	
	self:_ConnectRoundEvents()
	self:_InitEnvironmentalComponents()
	
	MatchStateClient.MatchStarted:Connect(function(roundName)
		self["_OnStart" .. roundName](self, false, MatchStateClient.CurrentMap)
	end)

	MatchStateClient.MatchEnded:Connect(function(roundName)
		self["_OnEnd" .. roundName](self)
		self.RoundJanitor:Cleanup()
	end)
	
	if MatchStateClient.CurrentPhase then
		self["_OnStart" .. MatchStateClient.CurrentPhase](self, false, MatchStateClient.CurrentMap)
	end
end

--//Returner

local Controller = EnvironmentController.new()
return Controller :: Controller