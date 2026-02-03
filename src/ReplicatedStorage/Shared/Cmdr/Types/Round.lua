--//Variables

local Names = {
	"Round",
	"Intermission"
}

--//Returner

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("roundNames", registery.Cmdr.Util.MakeEnumType("RoundNames", Names))
end