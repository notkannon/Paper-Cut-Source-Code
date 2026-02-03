--// Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundServices = game:GetService("SoundService")

--// Packages

local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil
local EnvironmentController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.EnvironmentController) or nil

--// Types

export type _keybind = Enum.KeyCode | Enum.UserInputType
export type Value = string | number | boolean | _keybind

export type PerformanceHit = "None" | "Low" | "Medium" | "High"
export type MyGraphicsLevel = "Low" | "Medium" | "High"
export type MyOptionType = "Slider" | "Toggle" | "TextBox" | "Option" | "Keybind"
export type MyKeybinds = {
	Keyboard: { _keybind },
	Gamepad: { _keybind },
}


export type MySettings = {
	DisplayName: string,
	Description: string,
	InitialValue: Value | MyGraphicsLevel,
	
	Order: number?,
	
	ValueRange: {
		Min: number,
		Max: number
	}?, -- for sliders only, defaults to {Min = 0, Max = 1}
	ValueStep: number?, -- for sliders only, defaults to 0.01
	
	OptionList: { string }, -- for option only, example: { "Option 1", "Option 2" }
	
	KeybindNameContext: string?, -- for keybinds name
	
	FramesAffectedLevel: PerformanceHit, -- this its will like, low because just disabled vignette, and high for, oh the globalshadows its high because, yeah change the shadows / Ed
	
	Type: MyOptionType,
	OnChanged: (value: Value) -> (),
	Required: { [string]: Value }, -- this its for like, i need enabled globalshadows to modify the sharpness of the blurred chadow / Ed
}

export type MySection = {
	Order: number,
	DisplayName: string,
	Settings: { [string]: MySettings } -- settings name/ Config
}

--// Returner

return table.freeze({
	Video = { -- The Catagory
		DisplayName = "Graphics",
		Order = 1,
		Image = "",
		Settings = { -- The list of settings in this catagory
			GammaIncrement = {
				-- a singular setting
				DisplayName = "Gamma Increment",
				Description = "Makes the game brighter or darker",
				--InitialValue = 0.5,
				
				ValueRange = {
					Min = -0.5,
					Max = 0.5
				},
				
				FramesAffectedLevel = "Low",
				ValueStep = 0.01,
				Type = "Slider",
				OnChanged = function(Value: Value)
					local Lighting = game:GetService("Lighting")
					local SettingsCorrection = Lighting:FindFirstChild("SettingsCorrection")
					
					if not SettingsCorrection then return end
					
					SettingsCorrection.Brightness = Value / 2
					SettingsCorrection.Contrast = Value
				end,
				
				Required = {},
			},
			FieldOfViewIncrement = {
				-- a singular setting
				DisplayName = "Field of View Increment",
				Description = "Changes your field of view (only in the matches)",
				--InitialValue = 0,
				ValueRange = {
					Min = -15,
					Max = 15
				},

				FramesAffectedLevel = "High",

				Type = "Slider",
				ValueStep = 1,
				OnChanged = function(Value: Value)
					--local Mapped = math.clamp(Value, 50, 120)
					--local inputRange = 120 - 50 
					--local Position = Mapped - 50 
					--local Normalized = Position / inputRange
					--print(Normalized)
					
					CameraController.IncrementFov = Value
				end,

				Required = {},
			},
			GlobalShadowsEnabled = {
				-- a singular setting
				DisplayName = "Global Shadows",
				Description = "Shows shadows from objects",
				--InitialValue = true,

				FramesAffectedLevel = "High",

				Type = "Toggle",
				OnChanged = function(Value: Value)
					print(Value)
					game.Lighting.GlobalShadows = Value
				end,

				Required = {},
			},
			GenericEffectsToggled = {
				-- a singular setting
				DisplayName = "Generic Effects",
				Description = "Shows effects",
				--InitialValue = true,

				FramesAffectedLevel = "Medium",

				Type = "Toggle",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
			LowDetailModeEnabled = {
				-- a singular setting
				DisplayName = "Low Detail mode",
				Description = "For low running PCs! Or maybe even Mobile?",
				--InitialValue = false,

				FramesAffectedLevel = "High",

				Type = "Toggle",
				OnChanged = function(Value: Value)
					print(Value, "LowDetails")
					EnvironmentController:ApplyLowDetails(not Value)
				end,

				Required = {},
			},
		}
	},
	
	Sound = {
		DisplayName = "Sound",
		Order = 2,
		Image = "",
		Settings = {
			VolumeMaster = {
				-- a singular setting
				DisplayName = "Master Volume",
				Description = "Sets loudness of the game overall",
				--InitialValue = 100,
				
				ValueRange = {
					Min = 0,
					Max = 100
				},
				
				Order = 1,

				FramesAffectedLevel = "None",

				Type = "Slider",
				OnChanged = function(Value: Value)
					print(Value)
					
					SoundServices.Master.Volume = Value/100
				end,

				Required = {},
			},
			VolumeMusic = {
				-- a singular setting
				DisplayName = "Music Volume",
				Description = "Sets loudness of music",
				--InitialValue = 50,
				
				Order = 2,
				
				ValueRange = {
					Min = 0,
					Max = 100
				},

				FramesAffectedLevel = "None",

				Type = "Slider",
				OnChanged = function(Value: Value)
					SoundServices.Master.Music.Volume = Value/200
				end,

				Required = {},
			},
			VolumePlayers = {
				-- a singular setting
				DisplayName = "Player SFX Volume",
				Description = "Sets loudness of sound effects relating to players like footsteps, dashes, shockwave",
				--InitialValue = 100,
				
				Order = 3,
				
				ValueRange = {
					Min = 0,
					Max = 100
				},

				FramesAffectedLevel = "None",

				Type = "Slider",
				OnChanged = function(Value: Value)
					SoundServices.Master.Players.Volume = Value/100
					
				end,

				Required = {},
			},
			VolumeEnvironment = {
				-- a singular setting
				DisplayName = "Environment SFX Volume",
				Description = "Sets loudness of sound effects relating to environment like lockers, vaults, doors",
				--InitialValue = 100,
				
				ValueRange = {
					Min = 0,
					Max = 100
				},
				
				Order = 4,

				FramesAffectedLevel = "None",

				Type = "Slider",
				OnChanged = function(Value: Value)
					SoundServices.Master.Instances.Volume = Value/100
					SoundServices.Master.Environment.Volume = Value/100
				end,

				Required = {},
			},
		}
	},
	
	Gameplay = {
		DisplayName = "Gameplay",
		Order = 3,
		Image = "",
		Settings = {
			CameraShakeEnabled = {
				-- a singular setting
				DisplayName = "Camera Shake",
				Description = "Turns on and off camera shaking",
				--InitialValue = true,

				FramesAffectedLevel = "None",

				Type = "Toggle",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
			
			BloodDisable = {
				-- a singular setting
				DisplayName = "Blood",
				Description = "Whether Blood particles are shown!",
				--InitialValue = true,

				FramesAffectedLevel = "None",

				Type = "Toggle",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
		}
	},
	
	Keybinds = {
		DisplayName = "Keybinds",
		Order = 4,
		Image = "",
		Settings = {
			Aim = {
				-- a singular setting
				DisplayName = "Aim",
				Description = "Gonna snipe you",
				--InitialValue = "",
				FramesAffectedLevel = "None",

				Type = "Keybind",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
			Harpoon = {
				-- a singular setting
				DisplayName = "Harpoon",
				Description = "watch my cook",
				--InitialValue = "",
				FramesAffectedLevel = "None",

				Type = "Keybind",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
			Skill1 = {
				-- a singular setting
				DisplayName = "Skill1",
				Description = "😎😎😎😎😎",
				--InitialValue = "",
				FramesAffectedLevel = "None",

				Type = "Keybind",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
			Skill2 = {
				-- a singular setting
				DisplayName = "Skill2",
				Description = "😎😎😎😎😎",
				--InitialValue = "",
				FramesAffectedLevel = "None",

				Type = "Keybind",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
			Skill3 = {
				-- a singular setting
				DisplayName = "Skill3",
				Description = "😎😎😎😎😎",
				--InitialValue = "",
				FramesAffectedLevel = "None",

				Type = "Keybind",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
			
			Skill4 = {
				-- a singular setting
				DisplayName = "Skill4",
				Description = "😎😎😎😎😎",
				--InitialValue = "",
				FramesAffectedLevel = "None",

				Type = "Keybind",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},
		}
	},
	
	Misc = {
		DisplayName = "Misc",
		Order = 5,
		Image = "",
		Settings = {
			DevelopersToggled = {
				-- a singular setting
				DisplayName = "Enable Dev Settings",
				Description = "😎😎😎😎😎",
				--InitialValue = false,
				
				FramesAffectedLevel = "None",

				Type = "Toggle",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {},
			},

			ShowHitboxes = {
				-- a singular setting
				DisplayName = "Show Hitboxes",
				Description = "For you nerds",
				--InitialValue = false,

				FramesAffectedLevel = "High",

				Type = "Toggle",
				OnChanged = function(Value: Value)
					print(Value)
				end,

				Required = {
					DevelopersToggled = true
				},
			},
		}
	}
}) :: { [string]: MySection } 