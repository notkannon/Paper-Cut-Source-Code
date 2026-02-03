--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Vault = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Vault)
local Sprint = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Sprint)
local Evade = require(script.Evade)
--local Jump = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Jump)
--local Lockup = require(script.Lockup)

--//Returner

return WCS.CreateMoveset("Runner", { Sprint, Vault, Evade })