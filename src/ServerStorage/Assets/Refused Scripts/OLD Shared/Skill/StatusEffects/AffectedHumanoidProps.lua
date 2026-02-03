--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Package.wcs)

--//Variables

local AffectedHumanoidProps = WCS.RegisterStatusEffect("AffectedHumanoidProps")

--//Methods

function AffectedHumanoidProps.OnConstruct(self, humanoidData: WCS.HumanoidDataProps)
	self:SetHumanoidData(humanoidData)
end

--//Returner

return AffectedHumanoidProps