local Client = shared.Client

-- service
local RunService = game:GetService('RunService')
local UserInput = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- var
local PlayerInstance = game.Players.LocalPlayer
local Viewmodels = ReplicatedStorage.Client.Viewmodels
local Camera = require(ReplicatedStorage.Client.Camera)

-- const
local PI = math.pi

-- CharacterView initial
local CharacterView = {}
CharacterView.is_first_person = false
CharacterView.is_third_person = false
CharacterView.current_viewmodel = nil
CharacterView.TransparencyModule = nil
CharacterView.autorotate_enabled = true
CharacterView.body_transparency_initial = {}

-- connecting viewmodels
CharacterView.viewmodels = {
	Student = require(Viewmodels.Student),
	MissThavel = require(Viewmodels.MissBloomie.MissThavel),
	MissBloomie = require(Viewmodels.MissBloomie.MissBloomie),
}

-- initial method
function CharacterView:Init()
	Client.PlayerAdded:Once(function(Player)
		-- connections
		UserInput.InputBegan:Connect(function(i, p)
			if p then return end
			if i.KeyCode == Enum.KeyCode.V then
				CharacterView:SetFirstPersonEnabled(not CharacterView.is_first_person)
				CharacterView:SetThirdPersonEnabled(not CharacterView.is_third_person)
			end
		end)
		
		-- Player died connection
		Player.CharacterChanged:Connect(function( Character )
			if not Character then
				-- Player died or despawned
				CharacterView:SetCurrentViewmodel( nil )
			else
				-- new character object binded
				CharacterView:Reset()
			end
		end)
	end)
end

-- returns true if Camera in first person
function CharacterView:IsCameraFirstPerson()
	return PlayerInstance.CameraMode == Enum.CameraMode.LockFirstPerson
end

-- reset current view
function CharacterView:Reset()
	local Player = Client.Player
	local CharacterObject = Player.Character
	assert(CharacterObject, 'No character exists to reset first person')
	
	-- setting current viewmodel
	CharacterView:SetCurrentViewmodel( Player.Role.moveset_name )
	
	-- resetting
	CharacterView.TransparencyModule = nil
	CharacterView.is_first_person = false
	CharacterView.is_third_person = true
	CharacterView:SetFirstPersonEnabled( true )
	CharacterView:SetThirdPersonEnabled( false )
	CharacterView:SetAutorotateEnabled( false )
end

-- sets value that describes humanoid`s autorotate
function CharacterView:SetAutorotateEnabled(enabled: boolean)
	self.autorotate_enabled = enabled
end

-- returns viewmodel object if exists
function CharacterView:GetCurrentViewmodel()
	return CharacterView.current_viewmodel
end

-- sets current viewmodel for table to operate with it
function CharacterView:SetCurrentViewmodel( viewmodel_name: string )
	if CharacterView:GetCurrentViewmodel() then
		CharacterView:GetCurrentViewmodel():SetEnabled( false )
	end
	
	CharacterView.current_viewmodel = CharacterView.viewmodels[ viewmodel_name ]
end


function CharacterView:ApplyTransparencyModule( value: boolean )
	local CharacterObject = Client.Player.Character
	local character: Model = CharacterObject.Instance
	assert(character, 'No character exists to set body`s transparency')
		
	if CharacterView.TransparencyModule then
		CharacterView.TransparencyModule:SetTransparent( value )
	else warn(`No transparency module exists for character { character }. Don't you forgot to create it?`)
	end
end

--[[
function CharacterView:SetAccessoryTransparent( value: boolean )
	local CharacterObject = Client.local_character
	local character: Model = CharacterObject.Instance
	assert(character, 'No character exists to set accessory`s transparency')
	
	for _, instance: BasePart|Accessory in ipairs(character:GetDescendants()) do
		if (instance:IsA('BasePart') and instance.Name == 'Head')
			or (instance:IsA('Decal') and instance.Name == 'face')
			or instance.Parent:IsA('Accessory')
		then
			instance.LocalTransparencyModifier = value and 1 or 0
		end
	end
end]]

-- sets THIRD person enabled
function CharacterView:SetThirdPersonEnabled( value: boolean )
	if value == CharacterView.is_third_person then
		--warn('Third person already', value and 'enabled' or 'disabled')
		return
	end
	
	local CharacterObject = Client.Player.Character
	if not CharacterObject then return end
	
	local character: Model = CharacterObject.Instance
	local humanoid: Humanoid = CharacterObject:GetHumanoid()

	-- stoop here if we cant find character
	if not character or not humanoid then return end
	
	-- enabling autorotate
	humanoid.AutoRotate = true
	self:SetAutorotateEnabled( true )
	
	-- changing value
	CharacterView.is_third_person = value
	
	-- Camera fix in third person
	if value then
		PlayerInstance.CameraMode = Enum.CameraMode.Classic
		PlayerInstance.CameraMinZoomDistance = 10
		PlayerInstance.CameraMaxZoomDistance = 10
	end
end

-- sets FIRST person enabled
function CharacterView:SetFirstPersonEnabled( value: boolean )
	if value == CharacterView.is_first_person then
		warn('First person already', value and 'enabled' or 'disabled')
		return
	end
	
	local CharacterObject = Client.Player.Character
	if not CharacterObject then return end
	
	local character: Model = CharacterObject.Instance
	local humanoid: Humanoid = CharacterObject:GetHumanoid()

	-- stop here if we cant find character
	if not character or not humanoid then
		warn('No character or humanoid exists to change first person view')
		return
	end
	
	if value then
		PlayerInstance.CameraMode = Enum.CameraMode.LockFirstPerson
		
		-- getting transparency module (if exists)
		local TransparencyModule = character:FindFirstChild('TransparencyModule')
		self.TransparencyModule = require( TransparencyModule )
		self.TransparencyModule:Apply()
	end
	
	-- viewmodel enabling
	if CharacterView:GetCurrentViewmodel() then
		CharacterView:GetCurrentViewmodel():SetEnabled( value )
	end
	
	-- first person enabling
	CharacterView.is_first_person = value
	CharacterView:ApplyTransparencyModule( value )
	
	-- frame update unbinding
	RunService:UnbindFromRenderStep('@firstperson')
	
	-- binding
	if value then
		RunService:BindToRenderStep('@firstperson', Enum.RenderPriority.Camera.Value, function()
			-- unbinding when character removes
			if not Client.Player.Character then
				CharacterView:SetFirstPersonEnabled( false )
				return
			end
			
			-- applying
			CharacterView:ApplyRotation()
		end)
	end
end

-- per-frame dirst person update
function CharacterView:ApplyRotation()
	local CharacterObject = Client.Player.Character
	if not CharacterObject then return end
	
	local character: Model = CharacterObject.Instance
	local humanoid: Humanoid = CharacterObject:GetHumanoid()
	
	-- stoop here if we cant find character
	if not character or not humanoid then return end
	
	-- disabling humanoid autorotate
	humanoid.AutoRotate = false
	
	-- (pass custom autorotate code if was force disabled)
	if not self.autorotate_enabled then return end
	
	local humanoidRootPart: BasePart = character.HumanoidRootPart
	local _3, camY, _1 = Camera.Instance.CFrame:ToOrientation()
	local _4, rootY, _2 = humanoidRootPart.CFrame:ToOrientation()
	
	-- applying custom autorotate
	humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.CFrame.Position)
		* humanoidRootPart.CFrame.Rotation:Lerp(CFrame.Angles(0, camY, 0), 1/5)
end

-- complete
return CharacterView