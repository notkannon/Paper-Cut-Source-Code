--//Imports

local Anomaly = require(script.Anomaly)
local Teacher = require(script.Teacher)
local Spectator = require(script.Spectator)

local Medic = require(script.Student.Medic)
local Runner = require(script.Student.Runner)
local Troublemaker = require(script.Student.Troublemaker)
local Stealther = require(script.Student.Stealther)

--//Types

export type Role =
	typeof(Medic)
	& typeof(Runner)
	& typeof(Stealther)
	& typeof(Troublemaker)
	& typeof(Spectator)
	& typeof(Teacher)
	& typeof(Anomaly)

export type Roles = {
	
	Spectator: typeof(Spectator),
	Teacher: typeof(Teacher),
	Anomaly: typeof(Anomaly),
	
	Medic: typeof(Medic) & Role,
	Runner: typeof(Runner) & Role,
	Troublemaker: typeof(Troublemaker) & Role,
	Stealther: typeof(Stealther) & Role,
}

--//Returner

return table.freeze({
	
	Spectator = Spectator,
	Teacher = Teacher,
	Anomaly = Anomaly,
	
	Medic = Medic,
	Runner = Runner,
	Stealther = Stealther,
	Troublemaker = Troublemaker,
	
}) :: Roles