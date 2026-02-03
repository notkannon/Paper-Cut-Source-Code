--//Services

local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Variables

local WCS = require(ReplicatedStorage.Packages.WCS)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

--//Types

export type DamageHandler = {
	IsActive: boolean,
	EventName: string,
	Handler: (component: Component, container: WCS.DamageContainer) -> (),
}

export type Impl = {
	__index: Impl,

	ApplyRagdoll: (self: Component, duration: number?) -> (),
	RemoveRagdoll: (self: Component) -> (),

	_ApplyRole: (self: Component, roleName: string) -> (),
	_InitDamageEvents: (self: Component) -> (),
	_InitStatusEffects: (self: Component) -> (),
	_InitCustomBehavior: (self: Component) -> (),
}

export type Fields = {
	Humanoid: PlayerTypes.IHumanoid,
	HumanoidRootPart: PlayerTypes.HumanoidRootPart,

	WCSCharacter: WCS.Character,
	
	DamageEvents: {
		DamageDealt: { [string]: DamageHandler? },
		DamageTaken: { [string]: DamageHandler? },
	},
}

type ComponentImpl = BaseComponent.ComponentImpl<Impl, Fields, "CharacterComponent", PlayerTypes.Character, {}>
type Component =  BaseComponent.Component<Impl, Fields, "CharacterComponent", PlayerTypes.Character, {}>


--//Returner

return nil