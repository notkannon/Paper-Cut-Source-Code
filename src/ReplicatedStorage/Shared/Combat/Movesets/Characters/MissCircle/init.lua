--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
--local Aim = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Aim)
local Attack = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Attack)
local Sprint = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Sprint)
local Harpoon = require(script.Harpoon)
local Shockwave = require(script.Shockwave)

--//Returner

return WCS.CreateMoveset("MissCircle", { Sprint, Attack, Harpoon, Shockwave })