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
		Priority = 10,
		Textures = {
			Eyes = "rbxassetid://131379807672162",
		},
	},
	
	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://91458919513509",
			Eyes = "rbxassetid://95468523860125",
			Side = "",
		},
	},
	
	----appears while player in terror
	--[FaceExpressionsEnum.InTerror] = {
	--	Priority = 1,
	--	Textures = {
	--		Mouth = "rbxassetid://101108818294668",
	--		Eyes = "rbxassetid://116707968720709",
	--		Side = "rbxassetid://129146148813801",
	--	},
	--},

	--appears while player in chase
	[FaceExpressionsEnum.InChase] = {
		Priority = 2,
		Textures = {
			Mouth = "rbxassetid://83578399540254",
			Eyes = "rbxassetid://80703392768924",
			Side = "rbxassetid://90623852691423",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 11,
		Textures = {
			Mouth = "rbxassetid://112346097098815",
			Eyes = "rbxassetid://110300855052893",
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
			Mouth = "rbxassetid://104918448672253",
			Eyes = "rbxassetid://100678460456660",
			Side = "rbxassetid://97041426323174",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://103302821054040",
			Eyes = "rbxassetid://139422706532280",
			Side = "rbxassetid://127315700024606",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://82603634336392",
			Eyes = "rbxassetid://81116723801409",
			Side = "rbxassetid://129051431938759"
		},
	},
} :: { [number]: BaseFacePack.FaceData }))