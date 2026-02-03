--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local ZipFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Zip)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 500,
	Name = "Zip",
	Icon = "rbxassetid://137027348534375",
	Description = "Zip is a bully character with one mean throwing arm on her. Zip often portrays herself as a pirate inside and outside of the poolroom to the dismay of others, even going as far as to raid others lockers in search for treasure and goodies",
	
	AltIcons = {
		Injured = "rbxassetid://100825713888577",
		Critical = "rbxassetid://131637022497565"
	},

	FacePack = ZipFacePack,
	
	PassivesData = {},
	
	CharacterData = {
		UniqueProperties = {
			ThrowStrength = 1.5
		}
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))