local Client = shared.Client

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

-- requirements
local Gore = require(script.Gore)
local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)
local CharacterController = require(script.CharacterController)
local CharacterComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent.CharacterComponent)


--// INITIALIZATION
local ClientCharacter = setmetatable({}, CharacterComponent)
ClientCharacter.__index = ClientCharacter

-- client character object constructor
function ClientCharacter.new(instance: Model)
	local self = setmetatable(CharacterComponent.new(instance), ClientCharacter)

	-- initialize character object
	self:Init()
	
	-- initializing character for player
	self.Player.Character = self
	self.Player.CharacterChanged:Fire( self )

	-- initialize as local player`s character object
	if self.Player:IsLocalPlayer() then
		CharacterController:SetCharacterControls(self)
	end

	return self
end

--// METHODS
-- initial method override
function ClientCharacter:Init()
	-- gore
	self.Gore = Gore.new(self.Instance)
	self.Gore:Init()
	
	-- sprint
	self.Stamina = 100
	self.StaminaLastUsageTime = os.clock()
	self.StaminaRegenTime = 3
	self.StaminaChanged = Signal.new()

	self.StaminaConnection = RunService.Heartbeat:Connect(function(delta)
		if self.Stamina >= 100 or os.clock() - self.StaminaLastUsageTime < self.StaminaRegenTime then
			return
		end

		self.Stamina = math.clamp(self.Stamina + 1 * delta, 0, 100)
		self.StaminaChanged:Fire(self.Stamina)
	end)

	CharacterComponent.Init(self)
end

-- prompts server to load WCS character
function ClientCharacter:PromptWcsCharacterCreate()
	assert(not self.WcsCharacterObject, 'Already exists wcs character object for client character')
	self:SendMessageToServer('create_wcs_character')
end

-- prompts server to load local scripts
function ClientCharacter:PromptLoadLocalScripts()
	self:SendMessageToServer('load_local_scripts')
end


function ClientCharacter:GetStamina()
	return self.Stamina
end


function ClientCharacter:DrainStamina(amount: number)
	self.StaminaLastUsageTime = os.clock()
	self.Stamina = math.clamp(self.Stamina - amount, 0, 100)
	self.StaminaChanged:Fire(self.Stamina)
	return self.Stamina
end


function ClientCharacter:RegenStamina(amount: number)
	self.Stamina = math.clamp(self.Stamina + amount, 0, 100)
	self.StaminaChanged:Fire(self.Stamina)
	return self.Stamina
end

-- client character destruction
function ClientCharacter:Destroy()
	if self.WcsCharacterObject then
		self.WcsCharacterObject:Destroy()
	end
	
	self.StaminaConnection:Disconnect()
	CharacterComponent.Destroy(self)
end

return ClientCharacter