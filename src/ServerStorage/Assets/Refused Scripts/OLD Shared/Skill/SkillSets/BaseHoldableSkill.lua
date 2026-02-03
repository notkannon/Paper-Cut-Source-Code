--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Imports

local WCS = require(ReplicatedStorage.Package.wcs)

--//Variables

local BaseHoldableSkill = WCS.RegisterHoldableSkill("BaseHoldableSkill")

--//Methods

function BaseHoldableSkill:ShouldStartClient()
	return not self:GetState().IsActive
end

function BaseHoldableSkill:GetData()
	return self.Data or {}
end

--//Returner

return BaseHoldableSkill