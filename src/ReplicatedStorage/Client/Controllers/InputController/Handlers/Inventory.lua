--[[

	Inventory input handler

]]

--//Services

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local DefaultKeybinds = require(ReplicatedStorage.Shared.Data.Keybinds)
local Enums = require(ReplicatedStorage.Shared.Enums)
local Signal = require(ReplicatedStorage.Packages.Signal)
local InputHandler = require(ReplicatedStorage.Client.Controllers.InputController.InputHandler)

--//Types

type Handler = InputHandler.Object & {
	
	--Dropped: Signal.Signal<>,
	Scrolled: Signal.Signal<number>,
	Selected: Signal.Signal<number>,
	
	_ScrollIndex: number,
}

--//Returner

return {
	Create = function(controller, context): Handler
		local self = InputHandler.new(controller, {Context = context}) :: Handler
		
		--self.Dropped = self.Janitor:Add(Signal.new())
		self.Scrolled = self.Janitor:Add(Signal.new())
		self.Selected = self.Janitor:Add(Signal.new())
		
		self.IgnoreOnEnd = true
		self._ScrollIndex = 0

		function self:ShouldProcessInput(input: InputObject)
			
			if self:IsKeyboard() then
				
				return InputHandler.ShouldProcessInput(self, input)
				
			elseif self:IsGamepad() then
				
				return InputHandler.ShouldProcessInput(self, input)
					and input.UserInputType == Enum.UserInputType.Gamepad1
			end
			
			--TODO: make available for other devices? (sensor - UI buttons on screen, gamepad - no cuz scrolling)
		end
		
		--remove this one
		function self:OnInputEnded() end
		
		function self:OnInputBegan(input: InputObject)
			
			if self:IsKeyboard() then
				
				--if input.KeyCode == Enum.KeyCode.F then
					--self.Dropped:Fire()
					--return
				--end

				local SlotIndex = Enums.NumberCodes[input.KeyCode.Name]
				
				if not SlotIndex then
					return
				end

				self.Selected:Fire(SlotIndex)
				
			elseif self:IsGamepad() then
				
				--if input.KeyCode == Enum.KeyCode.ButtonB then
					--self.Dropped:Fire()
					--return
				--end
				
				local SlotIndex
				
				if input.KeyCode == Enum.KeyCode.DPadLeft then
					
					SlotIndex = 1
					
				elseif input.KeyCode == Enum.KeyCode.DPadUp then
					
					SlotIndex = 2
					
				elseif input.KeyCode == Enum.KeyCode.DPadRight then
					
					SlotIndex = 3
				end
				
				if not SlotIndex then return end
				
				self.Selected:Fire(SlotIndex)
			end
		end
		
		function self:OnInputChanged(input: InputObject)
			
			if self:IsKeyboard() then
				
				if input.UserInputType ~= Enum.UserInputType.MouseWheel then
					return
				end
				
				self.Scrolled:Fire((input.Position.Z > 0) and 1 or -1)
			end
		end

		return self
	end,
}