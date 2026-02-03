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
			Eyes = "rbxassetid://125181571405820",
		},
	},

	---- some characters need that because they look differently in injured state
	--[FaceExpressionsEnum.InjuredBlink] = {
	--	Priority =  11,
	--	Textures = {
	--		Eyes = "rbxassetid://107841235011509"
	--	}
	--},

	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://97529665631742",
			Eyes = "rbxassetid://87580247378349",
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
			Mouth = "rbxassetid://70475464841509",
			Eyes = "rbxassetid://86516793658560",
			Side = "rbxassetid://91225973952987",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 12,
		Textures = {
			Mouth = "rbxassetid://119132376441176",
			Eyes = "rbxassetid://121931976999122",
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
			Mouth = "rbxassetid://79108269686574",
			Eyes = "rbxassetid://135584691887965",
			Side = "rbxassetid://133104933326953",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://85788291906044",
			Eyes = "rbxassetid://109869533560850",
			Side = "rbxassetid://101794011341833",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://70862996955905",
			Eyes = "rbxassetid://79254158660162",
			Side = "rbxassetid://119067480762499",
		},
	},

} :: { [number]: BaseFacePack.FaceData }))