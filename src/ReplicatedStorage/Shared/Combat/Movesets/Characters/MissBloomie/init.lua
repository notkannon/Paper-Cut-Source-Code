--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Locate = require(script.Locate)
local Stealth = require(script.Stealth)
local BloomieAttack = require(script.BloomieAttack)
local Sprint = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Sprint)

--//Returner

return WCS.CreateMoveset( "MissBloomie", { Sprint, BloomieAttack, Stealth, Locate })