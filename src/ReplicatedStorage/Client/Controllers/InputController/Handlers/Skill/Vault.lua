--[[

	Skill input handler

]]

--//Services

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local InputHandler = require(ReplicatedStorage.Client.Controllers.InputController.InputHandler)

--//Returner

return {
	Create = function(controller, options)
		
		local self = InputHandler.new(controller, options)
		
		self.IgnoreOnEnd = true
		
		function self:ShouldProcessInput(input: InputObject)
			return false
		end

		function self:ShouldStart()
			return true
		end
		
		--vault is like jump but we do some checks before do it
		self.Janitor:Add(UserInputService.JumpRequest:Connect(function()
			self:Start()
			self:End()
		end))

		return self
	end,
}