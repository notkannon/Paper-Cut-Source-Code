--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Promise = require(ReplicatedStorage.Packages.Promise)
local RoleTypes = require(ReplicatedStorage.Shared.Types.RoleTypes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ServerProducer = require(ServerScriptService.Server.ServerProducer)
local DefaultPlayerData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)

--//Types

export type ChanceTuple = {
	chance: number,
	role: string
}

export type Impl = {
	__index: Impl,

	GetReflexData: <S>(self: Component, selector: ServerProducer.PlayerSelector<S>?, ...any) -> any,
	
	IsLoaded: (self: Component) -> boolean,
	IsKiller: (self: Component) -> boolean,
	IsStudent: (self: Component) -> boolean,
	IsSpectator: (self: Component) -> boolean,
	
	GetRoleString: (self: Component) -> string,
	GetRoleConfig: (self: Component, role: string?) -> RoleTypes.Role?,
	GetPlayerStats: (self: Component) -> { [string]: any },
	
	Despawn: (self: Component) -> (),
	Respawn: (self: Component) -> (),
	
	SetRole: (self: Component, role: string, shouldRespawn: boolean?) -> (),
	
	GetChance: (self: ComponentTypes.PlayerComponent, group: "Default" | "Anomaly") -> number,
	SetChance: (self: ComponentTypes.PlayerComponent, group: "Default" | "Anomaly", value: number) -> (),
	
	_InitProfile: (self: Component) -> Promise.TypedPromise<DefaultPlayerData.SaveData>,
	_InitInventory: (self: Component) -> (),
	_InitCharacter: (self: Component) -> (),
	_InitRegistryActions: (self: Component) -> (),
}

export type Fields = {
	Instance: Player,
	ProfileData: DefaultPlayerData.SaveData,
	
	_IsLoaded: boolean,
}

type ComponentImpl = BaseComponent.ComponentImpl<Impl, Fields, "PlayerComponent", Player, {}>
type Component = BaseComponent.Component<Impl, Fields, "PlayerComponent", Player, {}>

--//Returner

return nil