--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseStudentData = require(ReplicatedStorage.Shared.Data.Roles.Student)

--//Variables

local Assets = ReplicatedStorage.Assets

--//Returner

return table.freeze(TableKit.DeepReconcile({
	
	Icon = "rbxassetid://72215827673764",
	DisplayName = "Medic",
	MovesetName = "Medic", -- wcs moveset name
	Description = "Compassionate, caring, helpful. Many words used to describe the kind of help Medics can offer to the team. Though reliant on others taking the heat, they’ll always be there to tend to your wounds",
	
	SkillsData = {

		--Sprint = {
		--	StaminaLossPerSecond = 9,
		--	AnimationSpeedScale = 0.92,
		--	Animation = Assets.Animations.Student.Skills.Sprint,
		--	WalkSpeed = 30,
		--	Cooldown = 1,
		--},

		--Vault = {
		--	Animation = Assets.Animations.Student.Skills.Vault,

		--	Cooldown = 2.5,
		--	StaminaLoss = 10,
		--	DetectDistance = 8,
		--},
		
		PatchUp = {
			
			Order = 1,
			Image = "rbxassetid://85647802399330",
			
			MaxUses = 2,
			Cooldown = 45,
			
			Hitbox = {
				Type = "Box",
				Size = Vector3.new(4.5, 5, 7),
				Offset = Vector3.new(0, 0, -3.5),
			},
			
			MaxHeal = 50,
			HealPerSecond = 5,
			MinHealthRequired = 50, -- player with higher health will be ignored(?)
			SelfHealEfficiency = 2/3, -- this multiplies MaxHeal by this number if medic is performing a self-heal
			SelfHealSpeed = 2/3, -- this multiplies HealPerSecond by this number if medic is performing a self-heal
			
			Animations = {
				
				Healer = ReplicatedStorage.Assets.Animations.Student.Misc.MedicHeal.Medic, -- medic itself
				Target = ReplicatedStorage.Assets.Animations.Student.Misc.MedicHeal.Target, -- the one who being healed
				
				HealerStart = ReplicatedStorage.Assets.Animations.Student.Misc.MedicHeal.MedicStart,
				TargetStart = ReplicatedStorage.Assets.Animations.Student.Misc.MedicHeal.TargetStart,
			},
		}
	},
	
	PassivesData = {
	
		EmpathicConnection = {
			MaxHealthDetect = 50, --if player's health less than this valaue then he will be highlighted
		},
	},
	
}, BaseStudentData))