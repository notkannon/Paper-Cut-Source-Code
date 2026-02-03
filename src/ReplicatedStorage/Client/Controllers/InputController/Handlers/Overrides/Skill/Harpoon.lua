--[[

	Skill input override handler
	Useful in cases when you want to change default user input behavior while some skill exists

]]

--//Services

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local InputHandler = require(ReplicatedStorage.Client.Controllers.InputController.InputHandler)
local Keybinds = require(ReplicatedStorage.Shared.Data.Keybinds)

--//Returner

return {
	SkillName = "Harpoon",
	
	Create = function(controller, context)
		local self = InputHandler.new(controller, {Context = context, Priority = 2})
		
		--self.Keybinds = self.Controller:GetKeybindsFromContext(self.Context)
		self.SkillName = "Harpoon"
		self.IgnoreOnEnd = true
		
		function self:Start()
			InputHandler.Start(self)
		end
		
		function self:ShouldProcessInput(input: InputObject)
			local EnumType = tostring(self.Keybinds.Keyboard[1]):split(".")[2]
			if self:IsKeyboard() then
				
				--print(self.Keybinds.Keyboard[1], self.Controller:IsContextActive("Aim"), "Harpoon Handler")
				
				return self.Controller:IsContextActive("Aim") 
					and input[EnumType] == self.Keybinds.Keyboard[1]
			elseif self:IsGamepad() then
				return self.Controller:IsContextActive("Aim") and input.KeyCode == self.Keybinds.Gamepad[1] -- ButtonL2
			end
		end
		
		return self
	end,
}