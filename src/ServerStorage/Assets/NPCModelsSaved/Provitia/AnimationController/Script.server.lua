local AnimationUtility = require(game.ReplicatedStorage.Shared.Utility.AnimationUtility)
AnimationUtility.QuickPlay(script.Parent, script:WaitForChild("Animation"), {
	Looped = true,
	Priority = Enum.AnimationPriority.Idle,
})