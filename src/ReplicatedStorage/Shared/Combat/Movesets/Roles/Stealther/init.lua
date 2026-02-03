--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Vault = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Vault)
local Sprint = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Sprint)
local ConcealedPresence = require(script.ConcealedPresence)

--//Returner

return WCS.CreateMoveset("Stealther", { Sprint, Vault, ConcealedPresence })