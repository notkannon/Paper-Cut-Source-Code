local Client = shared.Client

--// service

local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

--// requirements

local BaseControls = require(script.Parent.BaseControls)

--// Locals

local NumberToEnumSequence = {
	{1, Enum.KeyCode.One},
	{2, Enum.KeyCode.Two},
	{3, Enum.KeyCode.Three},
	{4, Enum.KeyCode.Four},
	{5, Enum.KeyCode.Five},
	{6, Enum.KeyCode.Six},
	{7, Enum.KeyCode.Seven},
	{8, Enum.KeyCode.Eight},
	{9, Enum.KeyCode.Nine},
	{0, Enum.KeyCode.Zero}
}

-- returns Enum.Keycode from number if exists
local function GetEnumFromNumber(number): Enum.KeyCode
	for _, s in ipairs(NumberToEnumSequence) do if s[1] == number then return s[2] end end
end

-- returns number from Enum.Keycode
local function GetNumberFromEnum(enum: Enum.KeyCode)
	for _, s in ipairs(NumberToEnumSequence) do if s[2] == enum then return s[1] end end
end


--// INITIALIZATION


local ComputerControls = BaseControls.new()
ComputerControls.Definition = 'Computer'


--// Controls functions


local function InitBackpackControls()
	local ClientBackpack = require(ReplicatedStorage.Client.ClientPlayer.ClientBackpack)
	
	-- keycode collecting
	local BackpackEnumKeys = {} :: { Enum.KeyCode }
	for _, Sequence in ipairs(NumberToEnumSequence) do
		table.insert(BackpackEnumKeys, Sequence[ 2 ])
	end

	-- backpack input handling
	UserInputService.InputBegan:Connect(function(InputObject: InputObject, IsGameProcessed: boolean)
		if not table.find(BackpackEnumKeys, InputObject.KeyCode) then
			return
		end
		
		local slot_index

		for _, Key in ipairs(BackpackEnumKeys) do
			if Key ~= InputObject.KeyCode then continue end
			if Key == Enum.KeyCode.Zero then
				slot_index = 10
				break
			end

			slot_index = GetNumberFromEnum( Key )
			break
		end

		-- getting target container
		local container = ClientBackpack:GetContainerById( slot_index )

		-- trying to set equipped
		if container then
			container:SetEquipped(
				not container.equipped
			)
		end
	end)
end


--// Entry point
function ComputerControls:Run()
	InitBackpackControls()
	BaseControls.Run(self)
end

return ComputerControls