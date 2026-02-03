--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Assets = ReplicatedStorage.Assets

--//Returner

return {

	--generic data
	
	Group = "Unknown",

	Guide = "No guide provided yet.",
	DisplayName = "Unnamed",
	Description = "No description provided yet.",
	Thumbnail = "",
	Icon = "",

	--defines if player has inventory
	HasInventory = false,
}