--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Jump = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Jump)
local Sprint = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Sprint)

--//Returner

return WCS.CreateMoveset("Spectator", { Sprint, Jump })