--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local PlayerTypes = require(script.Parent.PlayerTypes)
local Refx = require(ReplicatedStorage.Packages.Refx)
local Types = require(script.Parent)

--//Types

export type Roles = {
	[string]: Role,
}

export type Role = {
	DisplayName: string,
	Team: Team,

	SkillsData: {
		Sprint: {
			Animation: Animation,
			Cooldown: number,
		}?,
		LowHP: {
			IdleDowned: Animation,
			MovementAnimation: Animation,
		}?,
		Crouch: {
			IdleAnimation: Animation,
			MovementAnimation: Animation,
			Cooldown: number,
		}?,
		Attack: {
			Animations: { Animation },
			RefxEffect: Refx.EffectImpl<any, any, PlayerTypes.Character>,
			Hitbox: Types.Hitbox,
			Cooldown: number,
		}?,
	},

	CharacterData: {
		Morph: Model?,
	},

	Keybinds: {
		SinglePressHoldable: { string },
		[Enum.KeyCode]: string,
	},
}

--//Returner
return nil
