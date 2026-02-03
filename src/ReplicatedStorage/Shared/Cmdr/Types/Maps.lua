--//Variables

local Names = {
	"Camping",
	"School"
}

--//Returner

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("mapNames", registery.Cmdr.Util.MakeEnumType("MapNames", Names))
end