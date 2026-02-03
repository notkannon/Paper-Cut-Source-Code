--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseSkin = require(ReplicatedStorage.Shared.Data.Characters.BaseSkin)

--//Returner

return table.freeze(TableKit.MergeDictionary(BaseSkin, {

	Name = "JohnBloomy",
	Description = "",

} :: BaseSkin.SkinData))