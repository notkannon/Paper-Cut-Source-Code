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
			Eyes = "rbxassetid://138065038849932",
		},
	},

	-- some characters need that because they look differently in injured state
	[FaceExpressionsEnum.InjuredBlink] = {
		Priority =  11,
		Textures = {
			Eyes = "rbxassetid://107841235011509"
		}
	},

	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://77247715343438",
			Eyes = "rbxassetid://120775305017842",
			Side = "",
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
			Mouth = "rbxassetid://118297468031175",
			Eyes = "rbxassetid://73363505046899",
			Side = "rbxassetid://111760887026343",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 12,
		Textures = {
			Mouth = "rbxassetid://122270891619218",
			Eyes = "rbxassetid://100284149848810",
			Side = "",
		},
	},

	----same OnDamage but appears if player got damaged while was injured
	--[FaceExpressionsEnum.OnInjuredDamage] = {
	--	Priority = 12,
	--	Textures = {
	--		Mouth = "",
	--		Eyes = "",
	--		Side = "",
	--	},
	--},

	--statically replaces default face expression while player is injured
	[FaceExpressionsEnum.Injured] = {
		Priority = 0,
		Textures = {
			Mouth = "rbxassetid://75272638248670",
			Eyes = "rbxassetid://76494268681962",
			Side = "rbxassetid://118880354806535",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://126773605458606",
			Eyes = "rbxassetid://131676245246504",
			Side = "rbxassetid://91388895693745",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://116040236641922",
			Eyes = "rbxassetid://72925608073740",
			Side = "rbxassetid://136555488657764",
		},
	},

	
} :: { [number]: BaseFacePack.FaceData }))