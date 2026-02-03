local server = shared.Server
local client = shared.Client
local IS_CLIENT = client ~= nil

-- getting WCS module link
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillSets = ReplicatedStorage.Shared.Skill.SkillSets
local WCS = require(ReplicatedStorage.Package.wcs)

-- skills
local Hide = require(script.Hide)
local Jump = require(script.Jump)
local Sprint = require(script.Parent.shared.Sprint)
local Crouch = require(script.Crouch)

-- nuuh uh
return WCS.CreateMoveset('Student', {
	Sprint,
	Crouch,
	Jump,
	Hide
})