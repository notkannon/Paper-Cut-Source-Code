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
			Eyes = "rbxassetid://107626102115961",
		},
	},
	
	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://110191179575586",
			Eyes = "rbxassetid://91341449163780",
			Side = "",
		},
	},
	
	--appears while player in terror
	[FaceExpressionsEnum.InTerror] = {
		Priority = 1,
		Textures = {
			Mouth = "rbxassetid://101108818294668",
			Eyes = "rbxassetid://116707968720709",
			Side = "rbxassetid://129146148813801",
		},
	},

	--appears while player in chase
	[FaceExpressionsEnum.InChase] = {
		Priority = 2,
		Textures = {
			Mouth = "rbxassetid://89588168166325",
			Eyes = "rbxassetid://110874725438874",
			Side = "rbxassetid://117904842042845",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 11,
		Textures = {
			Mouth = "rbxassetid://116104987627628",
			Eyes = "rbxassetid://107342980005257",
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
			Mouth = "rbxassetid://105632049784158",
			Eyes = "rbxassetid://111974389041025",
			Side = "rbxassetid://128156518022185",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://81872291886585",
			Eyes = "rbxassetid://85725322497023",
			Side = "rbxassetid://96576950436796",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://104257912885063",
			Eyes = "rbxassetid://103253208491856",
			Side = "rbxassetid://77528460084295"
		},
	},
} :: { [number]: BaseFacePack.FaceData }))