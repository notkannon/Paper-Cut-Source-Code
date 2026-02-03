local Enums = require(game.ReplicatedStorage.Enums).TauntsEnum

return {
	enum = Enums.BoogieDance,
	name = 'Boogie Dance',
	description = '',
	cost = 30,
	looped = true,
	animation = script.Keyframes,
	reference = script,
	
	Play = function(self)
		self.Player.Character:LoadAnimation(
			self.animation,
			self.name,
			1.25,
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
	
	--[[ methods (CLIENT ONLY)
	StartForCharacter = function(self, CharacterObject)
		assert( shared.Client, 'Method is only Client-sided' )
		
		-- loading new taunt animation to the character
		self:ConnectToEnded(CharacterObject:LoadAnimation(
			self.animation,
			self.name,
			1,
			self.looped,
			Enum.AnimationPriority.Action4
		), CharacterObject)
		
		-- prompting character to play animation
		CharacterObject:PlayAnimationOnce(
			CharacterObject.Animations[ self.name ]
		)
	end,
	
	
	ConnectToEnded = function(self, track: AnimationTrack, CharacterObject)
		track.Stopped:Once(function()
			self:CleanupForCharacter(CharacterObject)
		end)
	end,
	
	
	CleanupForCharacter = function(self, CharacterObject)
		assert( shared.Client, 'Method is only Client-sided' )
		
		-- prompting character to stop animation
		CharacterObject:StopAnimation(
			CharacterObject.Animations[ self.name ]
		)
	end,]]
}