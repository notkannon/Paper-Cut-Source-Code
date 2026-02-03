local RS = game:GetService("ReplicatedStorage")
local DefaultPlayerData = require(RS.Shared.Data.DefaultPlayerData)

--//Variables

local Names = {}

for k, v in DefaultPlayerData.Save do
	if k == "Stats" then
		for statK, statV in v do
			table.insert(Names, `Stats.{statK}`)
		end
	else
		table.insert(Names, k)
	end
end


--//Returner

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("statsType", registery.Cmdr.Util.MakeEnumType("statsType", Names))
end