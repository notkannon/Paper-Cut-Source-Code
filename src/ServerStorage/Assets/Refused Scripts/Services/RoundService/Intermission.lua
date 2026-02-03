--//Services

local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local BaseRound = require(ServerScriptService.Server.Components.Abstract.BaseRound)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)

--//Variables

local Intermission = BaseRound.CreateRound("Intermission") :: RoundTypes.RoundImpl<nil, nil, "Intermission">

--//Types

export type Round = RoundTypes.Round<nil, nil, "Intermission">

--//Methods

function Intermission.OnConstruct(self: Round)
	self.Requirements = { "Round" }
	self.DefaultRound = true
	--self.Rou 
end

--//Returner

return Intermission
