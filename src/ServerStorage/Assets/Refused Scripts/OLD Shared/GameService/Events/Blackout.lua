-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)

-- declarations
local Players = game:GetService('Players')
local GameService
local Attributes = {
	CHARGE = 'Charge'
}

--// Variables
local Server = shared.Server
local Client = shared.Client
local Shared = Server or Client
local requirements = Shared._requirements

-- BlackoutEvent initial
local BlackoutEvent = {}

-- initial method
function BlackoutEvent:Init()
	GameService = requirements.GameModule
	
	if Server then
		-- server attribute set
		script:SetAttribute(Attributes.CHARGE, 100)
		
	elseif Client then
		script.AttributeChanged:Connect(function( attribute: string )
			if attribute == Attributes.CHARGE then
				-- on gnerator charge changed
			end
		end)
	end
end

-- lol we really feeding it o-o
function BlackoutEvent:Feed(item)
end

-- returns current generator charge amount
function BlackoutEvent:GetGeneratorCharge(): number
	return script:GetAttribute(Attributes.CHARGE)
end

-- (server) sets current charge for generator
function BlackoutEvent:SetGeneratorCharge(value: number)
	assert(Server, 'Attempted to call :SetGeneratorCharge() on client')
	script:SetAttribute(Attributes.CHARGE, math.clamp(value, 0, 100))
end

-- updates whole logic every sec
function BlackoutEvent:Update()
	assert(Server, 'Attempted to call :Update() on client')
	
	-- charging out
	local Charge = BlackoutEvent:GetGeneratorCharge()
	BlackoutEvent:SetGeneratorCharge(Charge - 1)
end

-- complete
return BlackoutEvent