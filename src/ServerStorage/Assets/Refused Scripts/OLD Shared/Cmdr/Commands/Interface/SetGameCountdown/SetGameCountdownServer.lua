-- handler initial
return function(_, countdown: number)
	local server = shared.Server
	local GameModule = server._requirements.GameModule
	
	-- set
	GameModule:SetCountdown( countdown )

	-- formatted output
	return `Game Countdown was set to {countdown}.`
end