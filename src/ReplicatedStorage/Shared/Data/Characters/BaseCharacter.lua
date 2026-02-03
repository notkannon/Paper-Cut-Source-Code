--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Assets = ReplicatedStorage.Assets

--//Types

export type CharacterData = {

	Name: string,
	Description: string,
	Icon: string,
	Thumbnail: string,
	
	Cost: number,
	IsFree: boolean,
	MovesetName: string?,
	
	TerrorData: {
		Radius: number,
		MusicLayers: { Sound },
	}?,
	
	SkillsData: { [string]: { any } }?,
	PassivesData: { [string]: { any } }?,
	StatusesData: { [string]: { any } }?,
	
	CharacterData: {
		
		FacePack: {}?,
		SoundPack: {}?,
		MorphInstance: Instance?,
		
		FootstepQuakeScale: number,
		DefaultWalkSpeed: number,
		Animations: { [string]: Animation },
		
		Stamina: {
			Max: number,
			GainPerSecond: number,
		},
	}?,

	Skins: { [string]: { any } },
}

--//Returner

return table.freeze({
	
	Name = "Unnamed",
	Icon = "",
	Thumbnail = "",
	Description = "No description provided yet",
	Cost = 500,
	IsFree = false,
	
	SkillsData = {},
	PassivesData = {},
	StatusesData = {},
	CharacterData = {
		Stamina = {
		},
	},
	
}) :: CharacterData