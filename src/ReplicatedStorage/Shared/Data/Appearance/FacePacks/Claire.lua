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
			Eyes = "rbxassetid://72771677444785",
		},
	},
	
	--default face expression
	[FaceExpressionsEnum.Default] = {
		Priority = -1,
		Textures = {
			Mouth = "rbxassetid://102238880423123",
			Eyes = "rbxassetid://83870932364364",
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
			Mouth = "rbxassetid://119408539295966",
			Eyes = "rbxassetid://86395010342991",
			Side = "rbxassetid://125345111548316",
		},
	},

	--replaces player's face for a while when got damaged
	[FaceExpressionsEnum.OnDamage] = {
		Priority = 11,
		Textures = {
			Mouth = "rbxassetid://121330617869022",
			Eyes = "rbxassetid://122089257041231",
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
			Mouth = "rbxassetid://77035517331568",
			Eyes = "rbxassetid://111220967195855",
			Side = "rbxassetid://108892334681601",
		},
	},

	--appears while player is being in finisher
	[FaceExpressionsEnum.Finisher] = {
		Priority = 9,
		Textures = {
			Mouth = "rbxassetid://78351468519214",
			Eyes = "rbxassetid://88427916268472",
			Side = "",
		},
	},

	--statically replaces default face when player is died
	[FaceExpressionsEnum.Died] = {
		Priority = 100,
		Textures = {
			Mouth = "rbxassetid://137046247809136",
			Eyes = "rbxassetid://117193169081831",
			Side = "rbxassetid://79828310518086"
		},
	},
} :: { [number]: BaseFacePack.FaceData }))