--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)

--//Variables

local Assets = ReplicatedStorage.Assets
local FaceExpressionsEnum = Enums.FaceExpression

--//Types

export type FaceData = {
	
	Duration: NumberRange?,
	Priority: number?,
	Textures: {
		Side: string?,
		Eyes: string?,
		Mouth: string?,
	},
}

--//Returner

return table.freeze({
	
	[FaceExpressionsEnum.Blink] = {
		Duration = NumberRange.new(0.1, 0.3),
		Priority = 10,
		Textures = {
			Eyes = "rbxassetid://108105574782139",
		},
	},
	
	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://121198023451703",
			Eyes = "rbxassetid://104116331720813",
			Side = "",
		},
	},
	
	----appears while player in terror
	--[FaceExpressionsEnum.InTerror] = {
	--	Priority = 1,
	--	Textures = {
	--		Mouth = "",
	--		Eyes = "",
	--		Side = "",
	--	},
	--},
	
	--appears while player in chase
	[FaceExpressionsEnum.InChase] = {
		Priority = 2,
		Textures = {
			--Mouth = "",
			--Eyes = "",
			--Side = "",
		},
	},
	
	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 3,
		Textures = {
			Mouth = "rbxassetid://132288660943885",
			Eyes = "rbxassetid://90326045187664",
			Side = "",
		},
	},
	
	--same OnDamage but appears if player got damaged while was injured
	[FaceExpressionsEnum.OnInjuredDamage] = {
		Priority = 4,
		Textures = {
			Mouth = "",
			Eyes = "",
			Side = "",
		},
	},
	
	--statically replaces default face expression while player is injured
	[FaceExpressionsEnum.Injured] = {
		Priority = 0,
		Textures = {
			Mouth = "rbxassetid://132288660943885",
			Eyes = "rbxassetid://79973350623711",
			Side = "rbxassetid://131684232010658",
		},
	},
	
	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://122620745201176",
			Eyes = "rbxassetid://83280477346802",
			Side = "",
		},
	},
	
	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://122620745201176",
			Eyes = "rbxassetid://98664321188661",
			Side = "rbxassetid://131684232010658",
		},
	},
	
} :: { [string]: FaceData })