local Enums = require(game.ReplicatedStorage.Enums).TauntsEnum

return {
	enum = Enums.BloxyCola,
	name = 'Bloxy Cola',
	description = '',
	cost = 40,
	looped = false,
	animation = script.Keyframes,
	reference = script,

	Play = function(self)
		local Character = self.Player.Character
		
		-- creating a bloxy cola stuff
		local bloxyCola = game.ReplicatedStorage.Assets.TauntStuff["Bloxy Cola"]:Clone()
		bloxyCola.Weld.Part0 = Character.Instance:FindFirstChild('Right Arm')
		bloxyCola.Parent = Character.Instance
		self:AddStuff( bloxyCola, 'Can' )
		
		local track: AnimationTrack = Character:LoadAnimation(
			self.animation,
			self.name,
			1,
			self.looped,
			Enum.AnimationPriority.Action4
		)
		
		-- thread for sounds
		game:GetService('RunService').RenderStepped:Once(function()
			task.wait(1.3)
			
			if not bloxyCola then return end
			bloxyCola.OpenSound:Play()
			
			task.wait(.7)
			
			if not bloxyCola then return end
			bloxyCola.DrinkSound:Play()
		end)

		Character:PlayAnimationOnce(
			self.Player.Character.Animations[ self.name ]
		)
	end,

	Stop = function(self)
		self:ClearStuff()
		
		self.Player.Character:StopAnimation(
			self.Player.Character.Animations[ self.name ]
		)
	end,
}