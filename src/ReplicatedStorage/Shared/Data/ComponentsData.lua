--[[

	Useful to keep balance-related values and settings of game components

]]
return table.freeze({
	
	Vaults = {
		
		Shared = {
			Interaction = {
				
			}
		},
		
		Window = {
			HoldDuration = {
				Killer = 2,
				Student = 4,
			}
		},
		
	},
	
	Doors = {
		
		Shared = {
			InteractionCooldown = 0.25,
			TeacherOpenTime = 0.75
		}
	},
	
	Hideouts = {
		Shared = {
			PanickingAccumulationLength = 17,
		}
	},
	
})