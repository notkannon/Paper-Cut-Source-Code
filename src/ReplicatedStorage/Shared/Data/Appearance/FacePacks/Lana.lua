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
			Eyes = "rbxassetid://103659890798089",
		},
	},
	
	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://107616242864383",
			Eyes = "rbxassetid://108922043083071",
			Side = "",
		},
	},
	
	--appears while player in terror
	[FaceExpressionsEnum.InTerror] = {
		Priority = 1,
		Textures = {
			Mouth = "rbxassetid://99506539176428",
			Eyes = "rbxassetid://95927083506176",
			Side = "rbxassetid://103501048596730",
		},
	},

	--appears while player in chase
	[FaceExpressionsEnum.InChase] = {
		Priority = 2,
		Textures = {
			Mouth = "rbxassetid://136668307357980",
			Eyes = "rbxassetid://76890675945742",
			Side = "rbxassetid://99680300459896",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 11,
		Textures = {
			Mouth = "rbxassetid://86548340845235",
			Eyes = "rbxassetid://127612449245715",
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
			Mouth = "rbxassetid://116058090079535",
			Eyes = "rbxassetid://83879621458625",
			Side = "",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://109771670259353",
			Eyes = "rbxassetid://134278416608862",
			Side = "rbxassetid://132198765398148",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://123151133404171",
			Eyes = "rbxassetid://111207310934447",
			Side = "rbxassetid://111017851890409",
		},
	},

} :: { [number]: BaseFacePack.FaceData }))