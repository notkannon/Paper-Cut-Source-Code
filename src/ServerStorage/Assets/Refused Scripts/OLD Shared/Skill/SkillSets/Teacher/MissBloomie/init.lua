local server = shared.Server
local client = shared.Client
local IS_CLIENT = client ~= nil

-- getting WCS module link
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WCS = require(ReplicatedStorage.Package.wcs)

local TeacherSkillSets = ReplicatedStorage.Shared.Skill.SkillSets.Teacher
local SharedSkills = TeacherSkillSets.shared

-- skills
local Attack = require(SharedSkills.Attack)
local Sprint = require(TeacherSkillSets.Parent.shared.Sprint)
--local HeavyAttack = require(script.HeavyAttack)
--local Locate = require(script.Locate)

-- initial
local MissBloomieMoveset = WCS.CreateMoveset('MissBloomie', {
	Sprint,
	Attack,
	--HeavyAttack,
	--Locate
})

return MissBloomieMoveset