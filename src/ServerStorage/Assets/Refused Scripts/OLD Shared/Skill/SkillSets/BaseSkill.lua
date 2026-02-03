--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Imports

local WCS = require(ReplicatedStorage.Package.wcs)

--//Variables

local BaseSkill = WCS.RegisterSkill("BaseSkill")

--//Methods
function BaseSkill:ShouldStartClient()
	return true
end

function BaseSkill:GetData(): SkillData
	return self.Data or {
		Name = 'Unknown',
		Visible = false,
		Cooldown = 0,
		Description = '...',
		DisplayOrder = 0,
	}
end

--//Returner

return BaseSkill