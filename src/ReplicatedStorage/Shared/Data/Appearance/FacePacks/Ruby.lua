--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseFacePack = require(ReplicatedStorage.Shared.Data.Appearance.BaseFacePack)

--//Variables

local FaceExpressionsEnum = Enums.FaceExpression

--//Returner

return table.freeze(TableKit.MergeDictionary(BaseFacePack, {
	
	[FaceExpressionsEnum.Blink] = {
		Duration = NumberRange.new(0.4, 0.8),
		Priority = 10,
		Textures = {
			Eyes = "rbxassetid://107450068966996",
		},
	},

	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "",
			Eyes = "rbxassetid://103435636250305",
			Side = "rbxassetid://95079221140692",
		},
	},

	--appears while player in terror
	[FaceExpressionsEnum.InTerror] = {
		Priority = 1,
		Textures = {
			Mouth = "",
			Eyes = "",
			Side = "",
		},
	},

	--appears while player in chase
	[FaceExpressionsEnum.InChase] = {
		Priority = 2,
		Textures = {
			Mouth = "",
			Eyes = "",
			Side = "",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 11,
		Textures = {
			Mouth = "",
			Eyes = "rbxassetid://137278864886224",
			Side = "",
		},
	},

	--same OnDamage but appears if player got damaged while was injured
	[FaceExpressionsEnum.OnInjuredDamage] = {
		Priority = 12,
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
			Mouth = "",
			Eyes = "rbxassetid://129955026755451",
			Side = "",
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
			Mouth = "",
			Eyes = "",
			Side = "rbxassetid://91748712779029",
		},
	},

} :: { [number]: BaseFacePack.FaceData }))