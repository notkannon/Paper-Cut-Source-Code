--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local PlayerComponentType = require(script.PlayerComponent)
local CharacterComponentType = require(script.CharacterComponent)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)

--//Types

type PlayerComponentFields = PlayerComponentType.Fields & {
	InventoryComponent: InventoryComponent.Component?,
	CharacterComponent: CharacterComponent?
}

export type ChanceTuple = PlayerComponentType.ChanceTuple

export type PlayerComponentImpl = BaseComponent.ComponentImpl<PlayerComponentType.Impl, PlayerComponentFields, "PlayerComponent", Player, {}>
export type PlayerComponent = BaseComponent.Component<PlayerComponentType.Impl, PlayerComponentFields, "PlayerComponent", Player, {}>
export type BaseComponent = BaseComponent.Component


type CharacterComponentFields = CharacterComponentType.Fields & {
	PlayerComponent: PlayerComponent,
}

export type CharacterComponentImpl = BaseComponent.ComponentImpl<CharacterComponentType.Impl, CharacterComponentFields, "CharacterComponent", PlayerTypes.Character, {}>
export type CharacterComponent =  BaseComponent.Component<CharacterComponentType.Impl, CharacterComponentFields, "CharacterComponent", PlayerTypes.Character, {}>

--//Returner

return nil