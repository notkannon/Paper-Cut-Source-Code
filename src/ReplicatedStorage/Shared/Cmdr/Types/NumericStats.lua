--//Variables

local Names = {
	"Points",
	"Wins",
	"Kills",
	"Deaths",
}


--//Returner

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("numericStatsType", registery.Cmdr.Util.MakeEnumType("NumericStatsType", Names))
end