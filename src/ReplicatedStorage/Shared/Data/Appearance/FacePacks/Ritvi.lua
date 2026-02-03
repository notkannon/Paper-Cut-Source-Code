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
			Eyes = "rbxassetid://138151644931331",
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
			Mouth = "rbxassetid://139667143421651",
			Eyes = "rbxassetid://115531931425590",
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
			Mouth = "rbxassetid://129074695499919",
			Eyes = "rbxassetid://86407590810987",
			Side = "rbxassetid://116960693128233",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 12,
		Textures = {
			Mouth = "rbxassetid://127588768597230",
			Eyes = "rbxassetid://124662312083441",
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
			Mouth = "rbxassetid://108363464964645",
			Eyes = "rbxassetid://85316705980832",
			Side = "rbxassetid://110652566487194",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://131233426596717",
			Eyes = "rbxassetid://75846468194391",
			Side = "rbxassetid://132375473573146",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://87147360097895",
			Eyes = "rbxassetid://111452593988589",
			Side = "rbxassetid://113552238422360",
		},
	},

} :: { [number]: BaseFacePack.FaceData }))