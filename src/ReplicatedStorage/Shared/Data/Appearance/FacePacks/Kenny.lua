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
	[FaceExpressionsEnum.InChase] = nil
} :: { [number]: BaseFacePack.FaceData }))