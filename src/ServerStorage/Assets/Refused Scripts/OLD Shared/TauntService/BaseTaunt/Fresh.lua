local Enums = require(game.ReplicatedStorage.Enums).TauntsEnum

return {
	enum = Enums.Fresh,
	name = 'Fresh',
	description = '',
	cost = 40,
	looped = true,
	animation = script.Keyframes,
	reference = script,

	Play = function(self)
		self.Player.Character:LoadAnimation(
			self.animation,
			self.name,
			1,
			self.looped,
			Enum.AnimationPriority.Action4
		)

		self.Player.Character:PlayAnimationOnce(
			self.Player.Character.Animations[ self.name ]
		)
	end,

	Stop = function(self)
		self.Player.Character:StopAnimation(
			self.Player.Character.Animations[ self.name ]
		)
	end,
}