--//Services

local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local BaseRound = require(ServerScriptService.Server.Components.Abstract.BaseRound)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)

--//Variables

local Intermediate = BaseRound.CreateRound("Intermediate") :: RoundTypes.RoundImpl<nil, nil, "Intermediate">

--//Types

export type Round = RoundTypes.Round<nil, nil, "Intermediate">

--//Methods

function Intermediate.OnConstruct(self: Round)
	self.Requirements = { "Intermission" }
end

--//Returner

return Intermediate