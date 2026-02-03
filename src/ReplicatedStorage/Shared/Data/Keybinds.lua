--//Runtimer
return table.freeze({
	Aim = {
		Gamepad = { Enum.KeyCode.ButtonL2 },
		Keyboard = { Enum.UserInputType.MouseButton2 },
	},

	Harpoon = {
		Gamepad = {
			Enum.KeyCode.ButtonR2,
		},
		Keyboard = {
			Enum.UserInputType.MouseButton1,
		},
	}, -- ig its done :skull:
	Jump = {
		Gamepad = {Enum.KeyCode.ButtonA},
		Keyboard = {Enum.KeyCode.Space}
	},

	Cancel = {
		Gamepad = {Enum.KeyCode.ButtonA},
		Keyboard = {Enum.KeyCode.Space}
	},

	Sprint = {
		Keyboard = { Enum.KeyCode.LeftShift },
		Gamepad = { Enum.KeyCode.ButtonL3 }
	},

	Skill1 = {
		Gamepad = { Enum.KeyCode.ButtonR2 },
		Keyboard = { Enum.UserInputType.MouseButton1 },
	},

	Skill2 = {
		Gamepad = { Enum.KeyCode.ButtonY },
		Keyboard = { Enum.KeyCode.Q },
	},

	Skill3 = {
		Gamepad = { Enum.KeyCode.ButtonB },
		Keyboard = { Enum.KeyCode.R },
	},

	Skill4 = {
		Gamepad = { Enum.KeyCode.ButtonL2 }, -- note: placeholder bind
		Keyboard = { Enum.KeyCode.T },
	},

	Inventory = {
		Gamepad = {
			Enum.KeyCode.DPadLeft,
			Enum.KeyCode.DPadUp,
			Enum.KeyCode.DPadRight,
			Enum.KeyCode.ButtonB,
		},
		Keyboard = {
			Enum.KeyCode.One,
			Enum.KeyCode.Two,
			Enum.KeyCode.Three,
			Enum.KeyCode.Four,
			Enum.KeyCode.Five,
			Enum.KeyCode.Six,
			Enum.KeyCode.Seven,
			Enum.KeyCode.Eight,
			Enum.KeyCode.Nine,
			Enum.KeyCode.Zero,
			Enum.UserInputType.MouseWheel,
			Enum.KeyCode.F,
		},
	},

	-- ok so we have the context defined
	-- cool, but we still need inputhandler :thumbsup:
	Interaction = {
		Gamepad = { Enum.KeyCode.ButtonX, },
		Keyboard = { Enum.KeyCode.E, },
	},

	DropItem = {
		Gamepad = { Enum.KeyCode.ButtonB },
		Keyboard = { Enum.KeyCode.F }
	},

	UseItem = {
		Gamepad = { Enum.KeyCode.ButtonR2 },
		Keyboard = { Enum.UserInputType.MouseButton1 }
	},
}) 