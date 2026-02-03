--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Spray = require(script.Spray)
local Vault = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Vault)
local Sprint = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Sprint)

--//Returner

return WCS.CreateMoveset("Troublemaker", { Sprint, Vault, Spray })