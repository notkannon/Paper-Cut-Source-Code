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
			Eyes = "rbxassetid://108607238950040",
		},
	},
	
	-- some characters need that because they look differently in injured state
	[FaceExpressionsEnum.InjuredBlink] = {
		Priority =  11,
		Textures = {
			Eyes = "rbxassetid://95475513635058"
		}
	},
	
	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://131031572404283",
			Eyes = "rbxassetid://111523161740275",
			Side = "rbxassetid://127121328882859",
		},
	},
	
	--appears while player in terror
	[FaceExpressionsEnum.InTerror] = {
		Priority = 1,
		Textures = {
			Mouth = "rbxassetid://76610476031006",
			Eyes = "rbxassetid://78791200822676",
			Side = "",
		},
	},

	--appears while player in chase
	[FaceExpressionsEnum.InChase] = {
		Priority = 2,
		Textures = {
			Mouth = "rbxassetid://133148070657864",
			Eyes = "rbxassetid://82314965330348",
			Side = "rbxassetid://108892787613164",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 12,
		Textures = {
			Mouth = "rbxassetid://130905526441562",
			Eyes = "rbxassetid://135543347281399",
			Side = "",
		},
	},

	--same OnDamage but appears if player got damaged while was injured
	[FaceExpressionsEnum.OnInjuredDamage] = {
		Priority = 13,
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
			Mouth = "rbxassetid://128995226603933",
			Eyes = "rbxassetid://132928644523372",
			Side = "",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://101169077580118",
			Eyes = "rbxassetid://115397694571070",
			Side = "",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://72381409106131",
			Eyes = "rbxassetid://127776516912559",
		},
	},
} :: { [number]: BaseFacePack.FaceData }))