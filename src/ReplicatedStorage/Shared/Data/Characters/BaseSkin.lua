--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Assets = ReplicatedStorage.Assets

--//Types

export type SkinData = {

	Name: string, -- morph extracted by skin name from Assets.Morphs[ character name ][ skin name / "Default" ]
	Icon: string,
	Cost: number,
	
	IsFree: boolean,
	IsForSale: boolean, -- If will show on the Shop or just Commands
	
	FacePack: {}?,
	SoundPack: {}?,
}

--//Returner

return table.freeze({
	
	Name = "Unknown",
	Icon = "",
	Cost = 500,
	IsFree = false,
	IsForSale = true,
	FacePack = nil,
	SoundPack = nil,
	
} :: SkinData)