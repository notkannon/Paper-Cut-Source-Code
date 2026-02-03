--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local Utility = require(ReplicatedStorage.Shared.Utility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility) 
local MusicUtility = require(ReplicatedStorage.Client.Utility.MusicUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)

--//Constants

local TWEEN_INFO = TweenInfo.new(3)
local CHASE_MAX_DURATION = 7

--//Variables

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local TerrorLayers: { MusicUtility.MusicWrapper } = {
	MusicUtility.Music.Terror.Layer1,
	MusicUtility.Music.Terror.Layer2,
	MusicUtility.Music.Terror.Layer3,
	MusicUtility.Music.Terror.Layer4,	
}

local TerrorController = Classes.CreateSingleton("TerrorController") :: Impl
local Active = false

--//Types

export type Impl = {
	__index: Impl,

	IsImpl: (self: Controller) -> boolean,
	GetName: () -> "TerrorController",
	GetExtendsFrom: () -> nil,
	
	Stop: (self: Controller) -> (),
	Start: (self: Controller) -> (),
	IsChasing: (self: Controller) -> boolean,
	StartChase: (self: Controller) -> (),
	UpdateChase: (self: Controller) -> (),
	GetCurrentLayer: (self: Controller) -> MusicUtility.MusicWrapper,
	GetCurrentLayerId: (self: Controller) -> number?,
	
	_OnTerrorEnter: (self: Controller) -> (),
	_OnTerrorLeave: (self: Controller) -> (),
	_OnLayerChanged: (self: Controller, oldLayer: number?, newLayer: number?) -> (),
	
	new: () -> Controller,
	OnConstructClient: (self: Controller) -> (),
}

export type Fields = {
	
	Janitor: Janitor.Janitor,
	
	_CurrentOpponent: Player?,
	_CurrentLayerId: number?,
	_LastLayerId: number?,
	_ActiveLayers: { MusicUtility.MusicWrapper? },
	_ChaseDebounce: boolean,
	_LastChaseTime: number,
	_LastTerrorEnterTime: number,
	_LastTerrorLeaveTime: number,
}

export type Controller = typeof(setmetatable({} :: Fields, PlayerController :: Impl))


--//Functuions

local function GetOpponents() : { Player? }
	
	local Opponents = {} :: { Player? }

	for _, Character in ipairs(workspace.Characters:GetChildren()) do
		
		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

		if Character == Player.Character
			or not Humanoid
			or not Humanoid.RootPart
			or Humanoid.Health <= 0 then

			continue
		end

		if (Character:GetAttribute("DestinatedTransparency") or 0) > 0.5 then
			continue
		end

		local Opponent = Players:GetPlayerFromCharacter(Character)
		
		if not Opponent then
			continue
		end

		local Config = RolesManager:GetPlayerRoleConfig(Opponent)
		local Team = Config and Config.Team.Name

		if not Config
			or (PlayerController:IsStudent() and Team ~= "Killer")
			or (PlayerController:IsKiller() and Team ~= "Student") then

			continue
		end

		table.insert(Opponents, Opponent)
	end

	return Opponents
end

local function IsOpponentInRadius(opponent: Player, radius: number) : boolean
	local Position = opponent.Character.HumanoidRootPart.Position :: Vector3
	local CurrentPos = Player.Character.HumanoidRootPart.Position :: Vector3

	return (CurrentPos - Position).Magnitude < radius
end

local function IsOpponentInMovement(opponent: Player) : boolean
	return (opponent.Character :: PlayerTypes.Character).Humanoid.MoveDirection.Magnitude > 0
end

--returns true if player2 is in player1's Field of View
local function IsPlayerInOtherFOV(player1: Player, player2: Player) : boolean
	local CurrentCharacter = player1.Character :: PlayerTypes.Character
	local Position = player2.Character.HumanoidRootPart.Position :: Vector3
	local CurrentPos = CurrentCharacter.HumanoidRootPart.Position :: Vector3

	return CurrentCharacter.HumanoidRootPart.CFrame.LookVector:Dot((Position - CurrentPos).Unit) > 0
end

local function IsObstaclesOnOpponentSight(opponent: Player, filter: { Instance }?, iteration: number?) : boolean
	
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = TableKit.MergeArrays({ workspace.Characters, workspace.Temp }, filter or {})

	local CurrentCharacter = Player.Character :: PlayerTypes.Character
	local Position = opponent.Character.HumanoidRootPart.Position :: Vector3
	local CurrentPos = CurrentCharacter.HumanoidRootPart.Position :: Vector3
	local CameraToPos = Position - Camera.CFrame.Position

	local Result = workspace:Raycast(Camera.CFrame.Position, CameraToPos.Unit * (CameraToPos.Magnitude + 1), Params)
	
	if iteration and iteration == 3 or not Result then
		return false
	end
	
	local Instance = Result.Instance :: BasePart
	
	if Instance.Transparency > 0 then
		local Filter = filter or table.clone(Params.FilterDescendantsInstances)
		table.insert(Filter, Instance)
		
		return IsObstaclesOnOpponentSight(opponent, Filter, (iteration and iteration + 1) or 1)
	end
	return true
end

local function CanObserve() : boolean
	
	local CurrentCharacter = Player.Character :: PlayerTypes.Character
	local CurrentHumanoid = CurrentCharacter and CurrentCharacter:FindFirstChildWhichIsA("Humanoid") :: Humanoid?

	if not CurrentCharacter
		or not CurrentHumanoid
		or CurrentHumanoid.Health <= 0 then

		return
	end
	
	return true
	
	--local Opponents = GetOpponents()
	--if #Opponents == 0 then
	--	return
	--end

	--for _, Opponent in ipairs(Opponents) do
	--	if IsOpponentInRadius(Opponent)
	--		and IsOpponentInMovement(Opponent)
	--		and IsPlayerInOpponentFOV(Opponent)
	--		and not IsObstaclesOnOpponentSight(Opponent) then

	--		return true
	--	end
	--end

	--return false
end

local function IsPlayerMoving(player: Player) : boolean
	
	local Character = player.Character :: PlayerTypes.Character
	local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid?

	if not Humanoid or Humanoid.Health <= 0 then
		return false
	end

	return Humanoid.RootPart and (Humanoid.RootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude > 0.3
end

local function IsPlayerRunning(player: Player) : boolean
	
	local Character = player.Character :: PlayerTypes.Character
	local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid?
	
	if not Humanoid or Humanoid.Health <= 0 then
		return false
	end
	
	return Humanoid.RootPart and (Humanoid.RootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude > 19
end

local function GetNearestOpponent() : Player?
	
	local Opponents = GetOpponents()
	
	if #Opponents == 0 then
		return
	end
	
	local Nearest = Opponents[1]
	local Distance = (Nearest.Character.Humanoid.RootPart.Position - Player.Character.Humanoid.RootPart.Position).Magnitude
	
	for _, Opponent in ipairs(Opponents) do
		
		local NewDistance = (Opponent.Character.HumanoidRootPart.Position - Player.Character.HumanoidRootPart.Position).Magnitude
		
		if NewDistance < Distance then
			Nearest = Opponent
			Distance = NewDistance
		end
	end
	
	return Nearest or nil
end

local function CalculateLayerIndex(distance: number, terrorRadius: number) : number
	-- Вычисляем слой (1-3, где 1 - внутренний, 3 - внешний)
	--[[ ]]
	-- return math.min(3, math.ceil(3 * (distance / terrorRadius))) -- legacy layer calculations (все слои равны)
	
	-- DBD система:
	if distance < terrorRadius/4 then
		return 1
	elseif distance < terrorRadius/2 then
		return 2
	elseif distance <= terrorRadius then
		return 3
	else
		error(`Impossible distance from the Terror Radius: {distance}`)
	end
end

local function GetCurrentLayerData(): (number?, Player?, number?, string?)
	
	if not CanObserve() then
		return nil
	end

	local myPosition = Player.Character:GetPivot().Position
	local isStudent = PlayerController:IsStudent()
	local bestLayerIndex = nil
	local bestDistance = math.huge
	local bestOpponent = nil
	local bestLayerSoundId = nil

	-- Получаем всех релевантных оппонентов
	local opponents = GetOpponents()
	
	if #opponents == 0 then
		return nil
	end

	if isStudent then
		
		-- Для выживших: проверяем всех киллеров
		for _, opponent in ipairs(opponents) do
			
			local char = opponent.Character
			if not char then continue end

			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then continue end

			local config = RolesManager:GetPlayerRoleConfig(opponent)
			if not config or not config.TerrorData then continue end

			local TerrorData = config.TerrorData
			local distance = (myPosition - root.Position).Magnitude

			-- Если игрок ВНЕ террор-радиуса - пропускаем этого киллера
			if distance > TerrorData.Radius then
				continue
			end

			local layerIndex = CalculateLayerIndex(distance, TerrorData.Radius)
			layerIndex = 4 - layerIndex -- Инвертируем (1 = внешний, 3 = внутренний)

			-- Выбираем самый "опасный" слой
			if not bestLayerIndex or layerIndex > bestLayerIndex or 
				(layerIndex == bestLayerIndex and distance < bestDistance) then
				
				bestLayerSoundId = TerrorData.Layers and TerrorData.Layers[layerIndex]
				bestLayerIndex = layerIndex
				bestDistance = distance
				bestOpponent = opponent
			end
		end

		return bestLayerIndex, bestOpponent, bestDistance, bestLayerSoundId
		
	else
		-- Для киллеров: проверяем только ближайшего выжившего
		local nearestOpponent = GetNearestOpponent()
		
		if not nearestOpponent then
			return nil
		end

		local dist = (myPosition - nearestOpponent.Character.HumanoidRootPart.Position).Magnitude
		local RoleConfig = RolesManager:GetPlayerRoleConfig(Player)
		local TerrorData = RoleConfig.TerrorData

		-- Если выживший ВНЕ террор-радиуса - возвращаем nil
		if dist > TerrorData.Radius then
			return nil
		end

		local layerIndex = CalculateLayerIndex(dist, TerrorData.Radius)
		
		return 4 - layerIndex, nearestOpponent, dist, TerrorData.Layers and TerrorData.Layers[layerIndex]
	end
end

--local function GetCurrentLayerData() : (number?, Player?, number?)
	
--	if not CanObserve() then
--		return
--	end
	
--	local Opponent = GetNearestOpponent()
	
--	if not Opponent then
--		return
--	end
	
--	local Position = (Player.Character :: PlayerTypes.Character).HumanoidRootPart.Position
--	local OpponentPosition = (Opponent.Character :: PlayerTypes.Character).HumanoidRootPart.Position
--	local Distance = (Position - OpponentPosition).Magnitude
	
--	for Index = 1, 4 do
		
--		local LayerRadius = TERROR_MAX_DISTANCE / 4 * Index
		
--		-- if teacher running then chase layer distance will be increased
--		if Index == 4 and PlayerController:IsStudent() then
--			LayerRadius *= (IsPlayerRunning(Opponent) and 1.5 or 1)
--		end
		
--		if Distance <= LayerRadius then
--			return 5 - Index, Opponent, Distance
--		end
--	end
--end

--//Methods

function TerrorController.GetCurrentLayer(self: Controller)

	local Id = self:GetCurrentLayerId()
	
	if not Id then
		return
	end
	
	return TerrorLayers[Id]
end

function TerrorController.GetCurrentLayerId(self: Controller)
	return self._CurrentLayerId
end

function TerrorController.IsChasing(self: Controller)
	return os.clock() - self._LastChaseTime < CHASE_MAX_DURATION
end

function TerrorController.StartChase(self: Controller)
	
	if self._ChaseDebounce then
		return
	end
	
	for Index, Layer in ipairs(TerrorLayers) do
		Layer.Instance:Play()
	end
	
	self._ChaseDebounce = true
	
	TerrorLayers[4]:ChangeVolume(1, nil, "Set")
	
	--firing server state about chase started
	ClientRemotes.ClientChaseStateChanged.Fire(true)
	self.ChaseStateChanged:Fire(true)
end

function TerrorController.UpdateChase(self: Controller)
	
	if not self._ChaseDebounce then
		return
	end
	
	-- chase plays on entire terror radius
	if self:_ShouldUpdateChase() then
		self._LastChaseTime = os.clock()
	end
	
	-- if chase timed out
	if not self:IsChasing() then
		
		TerrorLayers[4]:ChangeVolume(0, TweenInfo.new(5), "Set")
		
		--firing server state about chase ended
		ClientRemotes.ClientChaseStateChanged.Fire(false)
		self.ChaseStateChanged:Fire(false)
		
		self._ChaseDebounce = false
		
	end
end

function TerrorController._ShouldUpdateChase(self: Controller)
	
	local Opponent = self._CurrentOpponent
	local TerrorRadius
	
	local TeacherPlayer
	local StudentPlayer
	
	if not Opponent then
		return false
	end
	
	if PlayerController:IsStudent() then
		
		StudentPlayer = Player
		TeacherPlayer = Opponent
		
	elseif PlayerController:IsKiller() then
		
		StudentPlayer = Opponent
		TeacherPlayer = Player
	end
	
	return
		IsPlayerMoving(Player) and IsPlayerMoving(Opponent) -- both required to just move
		and IsOpponentInRadius(Opponent, 35) -- forgive me for hardcoding, idk where to put this value
		and not IsObstaclesOnOpponentSight(Opponent)
		and IsPlayerInOtherFOV(TeacherPlayer, StudentPlayer) -- adding "Teacher sees Student" FOV requiremenets 
end

-- it uses literally "Layering" algorhitm, like.. If you on 2nd layer then [1 .. 2] layers active
function TerrorController._OnLayerChanged(self: Controller, oldLayer: number?, newLayer: number?)
	self.LayerChanged:Fire(oldLayer, newLayer)
	ClientRemotes.ClientTRStateChanged.Fire(newLayer)
	
	local NewLayer = newLayer or 0
	
	if NewLayer == 0 then
		
		for Index = 1, 3 do
			
			local Layer = TerrorLayers[Index]
			local ExistingIndex = table.find(self._ActiveLayers, Layer)
			
			Layer:ChangeVolume(0, TWEEN_INFO)
			
			if ExistingIndex then
				table.remove(self._ActiveLayers, ExistingIndex)
			end
		end
		
		return
	end
	
	-- updating first 3 layers
	for Index = 1, 3 do
		
		local Layer = TerrorLayers[Index]
		local ExistingIndex = table.find(self._ActiveLayers, Layer)

		if ExistingIndex then
			
			if NewLayer < Index or PlayerController:IsKiller() then
				
				Layer:ChangeVolume(0, TWEEN_INFO)
				table.remove(self._ActiveLayers, ExistingIndex)
			end

			continue
		end

		if NewLayer < Index then
			continue
		end
		
		if PlayerController:IsKiller() then
			
			if Index == 1 then
				Layer:ChangeVolume(1, TWEEN_INFO)
			end
			
			continue
		end

		table.insert(self._ActiveLayers, Layer)
		
		Layer:ChangeVolume(1, TWEEN_INFO)
	end
end

function TerrorController._OnTerrorLeave(self: Controller)
	self.TerrorLeave:Fire()
	
	if #self._ActiveLayers > 0 then
		for Index, Layer in ipairs(self._ActiveLayers) do
			Layer:ChangeVolume(0, TWEEN_INFO, "Set")
		end

		table.clear(self._ActiveLayers)
	end
	
	self._LastTerrorLeaveTime = os.clock()
end

function TerrorController._OnTerrorEnter(self: Controller)
	self.TerrorEnter:Fire()
	
	-- resetting TR playback (more immersive)
	if os.clock() - self._LastTerrorEnterTime > 7 then
		for Index, Layer in ipairs(TerrorLayers) do
			if Index == 4 then
				continue
			end
			
			Layer.Instance:Play()
		end
	end
	
	self._LastTerrorEnterTime = os.clock()
end

function TerrorController.Start(self: Controller)
	
	if self._IsActive then
		return
	end
	
	local LastUpdate = os.clock()
	local ActiveLayers = self._ActiveLayers
	
	self._IsActive = true
	self._LastLayerId = nil
	self._CurrentLayerId = nil
	
	--resetting all layers
	for Index, Layer in ipairs(TerrorLayers) do
		Layer:Reset()
	end
	
	self.Janitor:Add(function()
		table.clear(self._ActiveLayers)
	end)
	
	self.Janitor:Add(RunService.Stepped:Connect(function()
		
		--works only at round!
		if not MatchStateClient:IsRound() then
			return
		end
		
		--rate limiting
		if os.clock() - LastUpdate < 0.1 then
			return
		end
		
		LastUpdate = os.clock()
		
		local LayerId, Opponent, Distance, LayerSoundId = GetCurrentLayerData()
		local LastLayerId = self._LastLayerId
		
		self._CurrentLayerId = LayerId
		
		--applying sound IDs to layers
		if LayerId and LayerSoundId then
			TerrorLayers[LayerId].Instance.SoundId = LayerSoundId
		end 
		
		local TeacherPlayer
		local StudentPlayer

		if PlayerController:IsStudent() then
			
			StudentPlayer = Player
			TeacherPlayer = Opponent
			
		elseif PlayerController:IsKiller() then
			
			StudentPlayer = Opponent
			TeacherPlayer = Player
		end
		
		-- trying to start chase
		if LayerId and LayerId >= 2
			and Opponent -- we shall have chaser/victim
			and IsPlayerInOtherFOV(TeacherPlayer, StudentPlayer) -- teacher must see Student
			and not IsObstaclesOnOpponentSight(Opponent) -- no obstacles between players
			and IsPlayerMoving(TeacherPlayer) and IsPlayerMoving(StudentPlayer) then -- student moving teacher running
			
			self:StartChase()
			
			--if PlayerController:IsKiller()
			--	and IsPlayerRunning(Player) then

			--	self:StartChase()

			--elseif PlayerController:IsStudent()
			--	and IsPlayerRunning(Opponent) then

			--	self:StartChase()
			--end
		end
		
		self._CurrentOpponent = Opponent
		
		self:UpdateChase()
		
		if LastLayerId == LayerId then
			return
		end

		self:_OnLayerChanged(self._LastLayerId, LayerId or 0)
		
		if not LastLayerId then
			
			self:_OnTerrorEnter()
			
		elseif not LayerId then
			
			self:_OnTerrorLeave()
			self._LastLayerId = nil
			
			return
		end
		
		self._LastLayerId = LayerId
	end))
end

function TerrorController.Stop(self: Controller)
	
	if 	not self._IsActive then
		return
	end
	
	self._IsActive = false
	
	self.Janitor:Cleanup()
	
	--stopping all TR layers forcely
	for _, Layer in ipairs(TerrorLayers) do
		Layer:Reset()
	end
end

function TerrorController.OnConstructClient(self: Controller)
	self.Janitor = Janitor.new()
	
	self._IsActive = false
	self._LastLayerId = nil
	self._CurrentOpponent = nil
	self._ActiveLayers = {}
	self._ChaseDebounce = false
	self._LastChaseTime = 0
	self._LastTerrorEnterTime = 0
	self._LastTerrorLeaveTime = 0
	
	self.LayerChanged = Signal.new()
	self.TerrorEnter = Signal.new()
	self.TerrorLeave = Signal.new()
	self.ChaseStateChanged = Signal.new()
end

--//Returner

local Controller = TerrorController.new()
return Controller