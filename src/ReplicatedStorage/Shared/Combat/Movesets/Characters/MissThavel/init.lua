--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Dash = require(script.Dash)
local Flair = require(script.Flair)
local Sprint = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Sprint)
local ThavelAttack = require(script.ThavelAttack)

--//Returner

return WCS.CreateMoveset("MissThavel", { Sprint, ThavelAttack, Dash, Flair })