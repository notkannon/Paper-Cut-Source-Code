--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

--//Types

export type AnyRoundImpl = {
	__index: AnyRoundImpl,

	new: (unknown) -> AnyRound,
	_Constructor: (self: AnyRound, service: unknown) -> (),

	Start: (self: AnyRound) -> (),
	Stop: (self: AnyRound) -> (),
	End: (self: AnyRound) -> (),

	GetState: (self: AnyRound) -> number,
	GetName: () -> string,
	GetExtendsFrom: () -> nil,
	IsImpl: (self: AnyRound) -> boolean,
	IsEnded: (self: AnyRound) -> boolean,
	
	OnConstruct: (self: AnyRound) -> (),
	OnConstructClient: (self: AnyRound) -> (),
	OnConstructServer: (self: AnyRound) -> (),
	
	OnStartClient: (self: AnyRound) -> (),
	OnEndClient: (self: AnyRound) -> (),
	
	OnStartServer: (self: AnyRound) -> (),
	OnEndServer: (self: AnyRound) -> (),

	ShouldStart: (self: AnyRound) -> boolean,
	ShouldSpawn: (self: AnyRound, player: Player) -> boolean,
}

export type RoundFields = {
	Service: unknown,
	PhaseDuration: number,
	NextPhaseName: string,

	_RoundActivationState: number,

	Janitor: Janitor.Janitor,

	Ended: Signal.Signal<nil>,
	Started: Signal.Signal<nil>,
}

export type AnyRound = typeof(setmetatable({} :: RoundFields, {} :: AnyRoundImpl))

export type RoundImpl<EXImpl, EXFields, Name> = {
	__index: RoundImpl<EXImpl, EXFields, Name>,
	
	new: (unknown) -> Round<EXImpl, EXFields, Name>,
	_Constructor: (self: Round<EXImpl, EXFields, Name>, service: unknown) -> (),

	Start: (self: Round<EXImpl, EXFields, Name>) -> (),
	Stop: (self: Round<EXImpl, EXFields, Name>) -> (),
	End: (self: Round<EXImpl, EXFields, Name>) -> (),

	GetState: (self: Round<EXImpl, EXFields, Name>) -> number,
	GetName: () -> Name,
	GetExtendsFrom: () -> AnyRoundImpl?,
	IsImpl: (self: Round<EXImpl, EXFields, Name>) -> boolean,
	IsEnded: (self: Round<EXImpl, EXFields, Name>) -> boolean,
	
	OnConstruct: (self: Round<EXImpl, EXFields, Name>) -> (),
	OnConstructClient: (self: Round<EXImpl, EXFields, Name>) -> (),
	OnConstructServer: (self: Round<EXImpl, EXFields, Name>) -> (),

	OnStartClient: (self: Round<EXImpl, EXFields, Name>) -> (),
	OnEndClient: (self: Round<EXImpl, EXFields, Name>) -> (),

	OnStartServer: (self: Round<EXImpl, EXFields, Name>) -> (),
	OnEndServer: (self: Round<EXImpl, EXFields, Name>) -> (),

	ShouldStart: (self: Round<EXImpl, EXFields, Name>) -> boolean,
	ShouldSpawn: (self: Round<EXImpl, EXFields, Name>, player: Player) -> boolean,
}

export type Round<EXImpl, EXFields, Name> =
	typeof(setmetatable({} :: RoundFields, {} :: RoundImpl<EXImpl, EXFields, Name>))
	& typeof(setmetatable({}, ({} :: any) :: EXImpl))
	& EXFields

--//Returner

return nil