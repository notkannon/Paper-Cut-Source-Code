--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)

--//Constants

local RUN_CONTEXT = RunService:IsServer() and "Server" or "Client"

--//Variables

local BaseRound = Classes.CreateClass("BaseRound", true) :: RoundTypes.AnyRoundImpl

--//Functions

local function CreateRound(name: string)
	local Round = Classes.Create(nil, "Round", name, true, BaseRound)

	function Round.new(service: RoundTypes.Service)
		local self = setmetatable({}, Round)
		return self:_Constructor(service) or self
	end

	return Round
end

--//Methods

function BaseRound.Start(self: RoundTypes.AnyRound)
	if self._RoundActivationState == Enums.RoundState.InProgress then
		return
	end
	
	if self.Service.DisablePhases then
		return
	end
	
	if not self:ShouldStart() then
		return
	end
	
	self._StartTimestamp = os.clock()
	
	self:OnStartServer()
	
	ServerRemotes.MatchServiceSetMatchState.FireAll({
		name = self.GetName(),
		ended = false,
		duration = self.PhaseDuration,
		currentMap = self.Service.MapSelected
	})
	
	self.Started:Fire()
	self._RoundActivationState = Enums.RoundState.InProgress
end

function BaseRound.End(self: RoundTypes.AnyRound)
	if self._RoundActivationState == Enums.RoundState.Finished then
		return
	end

	if RunService:IsServer() then
		ServerRemotes.MatchServiceSetMatchState.FireAll({
			name = self.GetName(),
			ended = true,
			duration = self.PhaseDuration,
		})
	end
	
	self:OnEndServer()
	
	self.Ended:Fire()
	self.Janitor:Cleanup()
	self._RoundActivationState = Enums.RoundState.Finished
end

BaseRound.Stop = BaseRound.End

function BaseRound._Constructor(self: RoundTypes.AnyRound, service: RoundTypes.Service)
	self.Janitor = Janitor.new()
	self.Started = Signal.new()
	self.Ended = Signal.new()

	self.Service = service

	self._StartTimestamp = os.clock()
	self._RoundActivationState = Enums.RoundState.NotStarted

	self.PhaseDuration = 5
	self.Requirements = {}
	
	self:OnConstruct()
	self:OnConstructServer()
end

function BaseRound.GetState(self: RoundTypes.AnyRound)
	return self._RoundActivationState
end

function BaseRound.IsEnded(self: RoundTypes.AnyRound)
	return self._RoundActivationState ~= Enums.RoundState.InProgress
end

function BaseRound.GetRunTime(self: RoundTypes.AnyRound)
	return os.clock() - self._StartTimestamp
end

function BaseRound:OnConstruct() end

function BaseRound:OnConstructServer() end

function BaseRound:OnStartServer() end

function BaseRound:OnEndServer() end

function BaseRound:ShouldStart()
	return false
end

function BaseRound:ShouldSpawn()
	return false
end

--//Returner

return {
	CreateRound = CreateRound,
}