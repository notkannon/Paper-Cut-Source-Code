--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local EnumUtil = require(ReplicatedStorage.Shared.Utility.EnumUtility)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)

--//Variables

local RoundActivationState: RoundTypes.RoundActivationState = EnumUtil.NewEnum(
	"NotStarted",
	"InProgress",
	"Finished"
)


local RoundsService: RoundTypes.ServiceImpl = Classes.CreateSingleton("RoundService") :: RoundTypes.ServiceImpl
RoundsService.RoundStats = "Unknow"
RoundsService.RoundActivationState = RoundActivationState

RoundsService.RoundActivationTime = Signal.new()
RoundsService.RoundAdded = Signal.new()
RoundsService.RoundEnded = Signal.new()
RoundsService.RoundStarted = Signal.new()

--//Methods

function RoundsService.GetRoundActivationState()
	return RoundsService.RoundStats[1] or "Loading"
end

function RoundsService.GetTime(self: RoundTypes.Service)
	return self.RoundDuration
end

function RoundsService.GetPassedTime(self: RoundTypes.Service)
	return self.RoundDuration - self.CurrentCountdown
end

function RoundsService.FreezeCountdown(self: RoundTypes.Service, state: boolean)
	if self.CurrentPhase then
		ServerRemotes.SetRoundState.FireAll({
			name = self.CurrentPhase.GetName(),
			frozen = state,
		})
	end

	self.FreezeCountdown = state
end

function RoundsService.NextRound(self: RoundTypes.Service)
	if self.DisableRounds then
		return
	end

	local ToRound

	if self.CurrentPhase then
		local Name = self.CurrentPhase.GetName()
	
		for _, Round in pairs(self.Rounds) do
			if Round:GetState() == RoundActivationState.InProgress then
				Round:End()
				continue
			end

			if not table.find(Round.Requirements, Name) then
				continue
			end

			ToRound = Round
			
		end
	else
		ToRound = self.DefaultRound
	end

	if not ToRound then
		warn("No round with the DefaultRound set to true found. Consider setting a default round.")
		self.CurrentPhase = nil
		return
	end
	
	RoundsService.RoundStats = ToRound.Requirements
	self:_StartRound(ToRound)
end

function RoundsService.SetRound(self: RoundTypes.Service, round: RoundTypes.AnyRound | RoundTypes.AnyRoundImpl | string)
	local Round = self:_GetRound(round)
	
	if not Round then
		return
	end
	
	self:EndRounds()
	self:_StartRound(Round)
end

function RoundsService.EndRounds(self: RoundTypes.Service, ignoreCountdown: boolean?)
	if not ignoreCountdown then
		self.CountdownConnection:Disconnect()
	end

	for _, Round in pairs(self.Rounds) do
		if Round:GetState() ~= RoundActivationState.InProgress then
			continue
		end
		
		Round:End()
	end
end

function RoundsService.OnConstruct(self: RoundTypes.Service)
	self.DisableRounds = false
	self.FreezeCountdown = false
	self.CurrentCountdown = 0
	
	self.Rounds = {}
end

function RoundsService.Start(self: RoundTypes.Service)	
	for _, Module in ipairs(script:GetChildren()) do		
		local Impl: RoundTypes.AnyRoundImpl = require(Module)
		local Name = Impl.GetName()

		assert(not self.Rounds[Name], `Round {Name} already registered`)

		local Round = Impl.new(self)

		

		self.Rounds[Name] = Round
		self.RoundAdded:Fire(Round)
	end
	
	self:NextRound()
end





function RoundsService._GetRound(self: RoundTypes.Service, round: RoundTypes.AnyRound | RoundTypes.AnyRoundImpl | string)
	local ToRound = if typeof(round) == "string" then self.Rounds[round] else round

	if not ToRound then
		return
	end

	if ToRound:IsImpl() then
		for _, Round in pairs(self.Rounds) do
			if Round:GetState() == RoundActivationState.InProgress then
				Round:End()
			end

			if getmetatable(Round) ~= ToRound then
				continue
			end

			ToRound = Round
		end
	end

	if ToRound:IsImpl() then
		return
	end

	return ToRound
end

--//Returner

local Singleton = RoundsService.new()
return Singleton