--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local Signal = require(ReplicatedStorage.Packages.Signal)
local Timer = require(ReplicatedStorage.Shared.Classes.Timer)
local Utility = require(ReplicatedStorage.Shared.Utility)

--//Variables

local Started: Signal.Signal<BaseQTEImpl, boolean?> = Signal.new()
local Ended = Signal.new()
local Destroyed = Signal.new()

local Ids = Utility.CreateIdGenerator()

local ConstructorsMap: { [string]: BaseQTEImpl } = {}
local ClassesMap = {}
local WinnersCooldowns = {}

local BaseQTE: BaseQTEImpl = Classes.CreateClass("BaseQTE", true) :: BaseQTEImpl

--//Types

export type QTEImpl<EXImpl, EXFields, Name, Args...> = {
	__index: QTEImpl<EXImpl, EXFields, Name, Args...>,

	new: ({ Player }, Args...) -> QTEClass<EXImpl, EXFields, Name, Args...>,

	Start: (self: QTEClass<EXImpl, EXFields, Name, Args...>, duration: number) -> (),
	Stop: (self: QTEClass<EXImpl, EXFields, Name, Args...>) -> (),
	End: (self: QTEClass<EXImpl, EXFields, Name, Args...>) -> (),
	Destroy: (self: QTEClass<EXImpl, EXFields, Name, Args...>) -> (),
	Hit: (self: QTEClass<EXImpl, EXFields, Name, Args...>, hit: boolean, player: Player?) -> (),

	GetName: () -> Name,
	GetExtendsFrom: () -> nil,
	GetType: () -> string,
	IsImpl: (self: QTEClass<EXImpl, EXFields, Name, Args...>) -> boolean,
	IsDestroyed: (self: QTEClass<EXImpl, EXFields, Name, Args...>) -> boolean,

	OnConstruct: (self: QTEClass<EXImpl, EXFields, Name, Args...>, Args...) -> (),
	OnConstructServer: (self: QTEClass<EXImpl, EXFields, Name, Args...>, Args...) -> (),
	OnConstructClient: (self: QTEClass<EXImpl, EXFields, Name, Args...>, Args...) -> (),

	OnStartServer: (self: QTEClass<EXImpl, EXFields, Name, Args...>, players: { Player }, Args...) -> (),
	OnStartClient: (self: QTEClass<EXImpl, EXFields, Name, Args...>, players: { Player }, Args...) -> (),

	OnEndServer: (self: QTEClass<EXImpl, EXFields, Name, Args...>, winner: Player, winnerScore: number, Args...) -> (),
	OnEndClient: (self: QTEClass<EXImpl, EXFields, Name, Args...>, winner: Player, winnerScore: number, Args...) -> (),

	ShouldDisplay: (self: QTEClass<EXImpl, EXFields, Name, Args...>, player: Player) -> boolean | number,

	_Constructor: (self: QTEClass<EXImpl, EXFields, Name, Args...>, id: number?, players: { Player }, Args...) -> (),
	_Start: (self: QTEClass<EXImpl, EXFields, Name, Args...>, duration: number, shouldDisplay: boolean?) -> (),
	_End: (self: QTEClass<EXImpl, EXFields, Name, Args...>, winner: Player?, winnerScore: number?) -> (),
}

export type QTEFields = {
	Players: { Player },
	ConstructorArguments: { unknown },

	DefaultScore: number,
	WinnerCooldown: number,
	ButtonsConfig: {
		[Enum.KeyCode]: { number },
	} | Enum.KeyCode,

	_IsDestroyed: boolean,
	_Id: number,
	_PlayerScores: { [Player]: number | boolean },
	_Timer: Timer.Class,

	Janitor: Janitor.Janitor,

	Started: Signal.Signal<boolean?>,
	Ended: Signal.Signal<nil>,
	Destroyed: Signal.Signal<nil>,
}

export type QTEClass<EXImpl, EXFields, Name, Args...> =
	typeof(setmetatable({} :: QTEFields, {} :: QTEImpl<EXImpl, EXFields, Name, Args...>))
	& typeof(setmetatable({}, ({} :: any) :: EXImpl))
	& EXFields

export type BaseQTEImpl = QTEImpl<nil, nil, string, ...any>
export type BaseQTEClass = QTEClass<nil, nil, string, ...any>

--//Functions

local function CreateQTE(name: string, qteType: string?)
	local QTE = Classes.Create(ConstructorsMap, "QTE", name, true, BaseQTE)

	function QTE.new(...: any)
		local self = setmetatable({}, QTE)
		return self:_Constructor(...) or self
	end

	function QTE.GetType()
		return qteType
	end

	return QTE
end

--//Methods

function BaseQTE.Start(self: BaseQTEClass, duration: number)
	self:_Start(duration)
end

function BaseQTE.End(self: BaseQTEClass)
	self:_End()
end

BaseQTE.Stop = BaseQTE.End

function BaseQTE.Destroy(self: BaseQTEClass)
	if self._IsDestroyed then
		return
	end

	if self._Timer:GetState() == Timer.TimerState.Running then
		self:End()
	end

	self._IsDestroyed = true
	self.Destroyed:Fire()
	self.Janitor:Destroy()
	self._Timer:Destroy()

	ClassesMap[self._Id] = nil
	Ids.IncrementId(-1)

	if RunService:IsServer() then
		ServerRemotes.QTEReplicator.FireList(self.Players, {
			id = self._Id,
			method = "_Destroy",
			arguments = {},
		})
	end
end

function BaseQTE.Hit(self: BaseQTEClass, hit: boolean, player: Player?)
	if self.IsDestroyed then
		return
	end

	if RunService:IsClient() then
		
		ClientRemotes.QTEHit.Fire({
			id = self._Id,
			hit = hit,
		})
		return
	end

	if self._Timer:GetState() ~= Timer.TimerState.Running or not player or self._PlayerScores[player] == nil then
		return
	end

	local Score = self._PlayerScores[player]

	if typeof(Score) ~= "number" then
		return
	end

	self._PlayerScores[player] = Score + 1
end

function BaseQTE._Constructor(self: BaseQTEClass, id: number?, players: { Player }, ...: any)
	self.Janitor = Janitor.new()

	self.Started = Signal.new()
	self.Ended = Signal.new()
	self.Destroyed = Signal.new()

	self.ConstructorArguments = { ... }
	self.Players = players

	self.WinnerCooldown = 30
	self.DefaultScore = 0
	self.ButtonsConfig = {
		[Enum.KeyCode.Q] = true,
	}

	self._Id = typeof(id) == "number" and id or Ids.NextId()
	self._IsDestroyed = false
	self._PlayerScores = {}
	self._Timer = Timer.new()

	ClassesMap[self._Id] = self

	self.Started:Connect(function(shouldDisplay)
		Started:Fire(self, shouldDisplay)
	end)

	self.Ended:Connect(function()
		Ended:Fire(self)
	end)

	self.Destroyed:Once(function()
		Destroyed:Fire(self)
	end)

	self._Timer.Completed:Connect(function()
		self:End()
	end)

	self:OnConstruct(...)

	if RunService:IsServer() then
		self:OnConstructServer(table.unpack(self.ConstructorArguments))
	else
		self:OnConstructClient(table.unpack(self.ConstructorArguments))
	end
end

function BaseQTE._Start(self: BaseQTEClass, duration: number, shouldDisplay: boolean?)
	if self._IsDestroyed or self._Timer:GetState() == Timer.TimerState.Running then
		return
	end

	self.Started:Fire(shouldDisplay)

	if RunService:IsClient() then
		self:OnStartClient(self.Players, table.unpack(self.ConstructorArguments))
		return
	end

	for _, Player in ipairs(self.Players) do
		local Answer = self:ShouldDisplay(Player)
		self._PlayerScores[Player] = typeof(Answer) == "number" and Answer or true
	
		ServerRemotes.QTEReplicator.Fire(Player, {
			id = self._Id,
			method = "_Start",
			arguments = { duration, typeof(Answer) == "number" },
		})
	end

	self._Timer:SetLength(duration)
	self._Timer:Start()

	self:OnStartServer(self.Players, table.unpack(self.ConstructorArguments))
end

function BaseQTE._End(self: BaseQTEClass, winner: Player?, winnerScore: number?)
	if self._IsDestroyed or (RunService:IsServer() and self._Timer:GetState() ~= Timer.TimerState.Running) then
		return
	end

	self.Ended:Fire()
	self.Janitor:Cleanup()

	if RunService:IsClient() and winner and winnerScore then
		self:OnEndClient(winner, winnerScore, table.unpack(self.ConstructorArguments))
		return
	elseif RunService:IsClient() then
		return
	end

	self._Timer:End()

	local Winner
	local WinnerScore = 0

	for Player, PlayerScore in pairs(self._PlayerScores) do
		local Score = typeof(PlayerScore) == "number" and PlayerScore or self.DefaultScore

		if Score > WinnerScore and (not WinnersCooldowns[Player] or os.clock() > WinnersCooldowns[Player]) then
			Winner = Player
			WinnerScore = Score
		end
	end

	if not Winner then
		return
	end

	WinnersCooldowns[Winner] = os.clock() + self.WinnerCooldown

	ServerRemotes.QTEReplicator.FireList(self.Players, {
		id = self._Id,
		method = "_End",
		arguments = { Winner, WinnerScore },
	})

	self:OnEndServer(Winner, WinnerScore, table.unpack(self.ConstructorArguments))
end

function BaseQTE.IsDestroyed(self: BaseQTEClass)
	return self._IsDestroyed
end

function BaseQTE:OnConstruct() end

function BaseQTE:OnConstructServer() end

function BaseQTE:OnConstructClient() end

function BaseQTE:OnStartServer() end

function BaseQTE:OnStartClient() end

function BaseQTE:OnEndServer() end

function BaseQTE:OnEndClient() end

function BaseQTE:ShouldDisplay()
	return true
end

if RunService:IsClient() then
	ClientRemotes.QTEReplicator.SetCallback(function(args)
		if args.name then
			local Constructor = ConstructorsMap[args.name]
			assert(Constructor, `Invalid constructor for {args.name}.`)

			Constructor.new(args.id, table.unpack(args.arguments))
		else
			local Class = ClassesMap[args.id]
			assert(Class, `Invalid class for {args.id}.`)

			Class[args.method](Class, table.unpack(args.arguments))
		end
	end)
else
	ServerRemotes.QTEHit.SetCallback(function(player, args)
		local Class = ClassesMap[args.id]
		assert(Class, `Invalid class for {args.id}.`)

		Class:Hit(args.hit, player)
	end)
end

--//Returner

return {
	CreateQTE = CreateQTE,
	Started = Started,
	Ended = Ended,
	Destroyed = Destroyed,
}
