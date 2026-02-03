--[[

	Sprint input handler

]]

--//Services

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


--//Imports

local DefaultKeybinds = require(ReplicatedStorage.Shared.Data.Keybinds)
local InputHandler = require(ReplicatedStorage.Client.Controllers.InputController.InputHandler)

--//Returner

return {
	Create = function(controller, options)
		local self = InputHandler.new(controller, options)
		
		self.IgnoreOnEnd = false
		self.StartWhileActive = true
		
		self.Keybinds = self.Controller:GetKeybindsFromContext(self.Context)
		
		function self:ShouldProcessInput(input: InputObject)
			
			if self:IsKeyboard() then
				return input.KeyCode == self.Keybinds.Keyboard[1]
			else
				return (input.KeyCode == self.Keybinds.Gamepad[1] or input.KeyCode == Enum.KeyCode.Thumbstick1) --and input.UserInputType == Enum.UserInputType.Gamepad1 -- нужно ли уточнять геймпад?
			end
		end
		
		function self:OnInputChanged(input)
			
			if self:IsGamepad()
				--and input.UserInputType == Enum.UserInputType.Gamepad1
				and input.KeyCode == Enum.KeyCode.Thumbstick1 then
				
				local magnitude = math.sqrt(input.Position.X^2 + input.Position.Y^2)

				if magnitude > 0.9 then
					--self:Start() -- autostart behavior
				else
					self:End()
				end
			end
		end
		
		return self
	end,
}