--//Services

local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Returner

return {
	
	ServerSize = 15,
	TestersAllowed = true,
	
	TestersBlackListItems = {
		"Gun",
		"Orange"
	},
	
	Whilelist = {
		86820925,
		2398728392,
		1170336308,
		1470339219,
		3380720578,
		3062164049,
		9207356174,
		1484139518 -- selkie
	},
	
	Preloading = {
		AllowedClassNames = {
			"Decal",
			"Sound",
			"Texture",
			"MeshPart",
			"Animation",
			--"ImageLabel",
			"ImageButton",
		},
		AssetsPreloadFrom = {
			Workspace,
			StarterGui,
			SoundService,
			ReplicatedFirst,
			ReplicatedStorage,
		},
	},
	Classes = {
		ToggleClassesConstructionLogging = false,
		ToggleComponentsConstructionLogging = false,
	},
	Cmdr = {
		PermissionLevels = {
			[50] = "Tester",
			[100] = "Moderator",
			[200] = "Administrator",
			[255] = "Operator",
		},
		
		PassedUserIds = {
			
			[1484139518] = 200, --BruhMohment
			[380836263] = 100, --pofyr
			[2398728392] = 255, -- Edugamen_YT
			[1470339219] = 255, --true_cannon
			[4146430584] = 100, --NotMirrox
			[3380720578] = 255, --YSH122331
			[1170336308] = 255, -- ProvitiaYT
			[3062164049] = 200, --nurgament
			[86820925] = 255, -- Orangeboy527
			[9207356174] = 255, -- Ed MultiAccount
		},
		
		PassedGroupRoles = {
			Testers = 50,
			Tester = 50
		},
		
		RequiredPermissionLevels = {
			Round = 50,
			RoleConfig = 50,
			Effects = 200,
			Admin = 200,
			Items = 50,
		}
	},
	Group = {
		RoleColors = {
			Admin = "b6ce42",
			Extra = "ff81b7",
			Interface = "96d05e",
		},
	},
}
