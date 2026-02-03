local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local ItemWrapper = require(script.Parent)

-- Flashlight constructor initial
local Flashlight = setmetatable({}, ItemWrapper)
Flashlight.enum = Enums.ItemTypeEnum.Flashlight
Flashlight.__index = Flashlight

-- class effects
local ClassEffectEnable = require(ReplicatedStorage.Shared.Effects.Item.Flashlight.Enable)
local ClassEffectDisable = require(ReplicatedStorage.Shared.Effects.Item.Flashlight.Disable)


-- constructor
function Flashlight.new()
	local tool = game.ReplicatedStorage.Assets.Items.Flashlight:Clone()
	local self = setmetatable(ItemWrapper.new( tool ), Flashlight)
	-- nu uh
	self.Enabled = false
	self.LastActivate = 0
	
	self:Init()
	return self
end

-- initial book method
-- ItemWrapper:Init() --> Flashlight:Init() (it doesnt override .super :init)
function Flashlight:Init()
	local item = self:GetItem()
	local HandleMotor: Motor6D
	
	self.Equipped:Connect(function()
		-- connecting tool handle to arm
		local character: Model = item.Parent
		HandleMotor = character:FindFirstChild('Right Arm'):FindFirstChild('Handle')
		
		if not HandleMotor then
			HandleMotor = Instance.new('Motor6D', character:FindFirstChild('Right Arm'))
			HandleMotor.Part0 = HandleMotor.Parent
			HandleMotor.Name = 'Handle'
		end
		
		HandleMotor.Part1 = item.Base
	end)
	
	self.Unequipped:Connect(function()
		self:SetEnabled(false)
	end)
	
	self.Activated:Connect(function()
		if os.clock() - self.LastActivate < 1 then return end
		self.LastActivate = os.clock()
		
		-- applying enabled
		self:SetEnabled(not self.Enabled)
	end)
end


function Flashlight:SetEnabled(enabled: boolean) -- bitbitbitbit game:Destroy() :3
	-- inverting enabled
	if self.Enabled == enabled then return end -- no same calls
	self.Enabled = enabled

	-- effect applying
	if self.Enabled then
		ClassEffectEnable.new(self:GetItem()):Start(game.Players:GetPlayers())
	else ClassEffectDisable.new(self:GetItem()):Start(game.Players:GetPlayers()) end

	-- client messaging
	self:SendClientMessage('enabled',
		self.Enabled
	)
end


function Flashlight:OnClientMessage(sender: Player, ...)
	--[[print('Flashlight message just received!', ...)
	self:SendClientMessage('FLASHLIGHT SAYS WOMP WOMP')]]
end

return Flashlight