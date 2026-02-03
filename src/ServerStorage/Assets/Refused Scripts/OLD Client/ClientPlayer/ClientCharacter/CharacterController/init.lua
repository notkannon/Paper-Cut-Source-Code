-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local WCS = require(ReplicatedStorage.Package.wcs)
local Camera = require(ReplicatedStorage.Client.Camera)
local ClientWcsController = require(script.ClientWcsController)

--// INITIALIZATION
local CharacterController = {}
CharacterController.Character = nil

-- binds controls to character
local function BindToCharacter()
	-- character camera setup
	local CharacterCamera = Camera.Modes.Character
	CharacterCamera:SetActive( true )
	
	-- asserttion
	local Character = CharacterController.Character
	assert(Character, 'No character set for CharacterController')
	local Humanoid: Humanoid = Character:GetHumanoid()

	--// wcs character binding
	Character.Player.Character = Character

	-- assertation
	assert( not Character.WcsCharacterObject, 'WCS character object already exists in character' )
	assert( Character.Instance, 'No character exists to initialize WCS character object' )
	
	-- waiting for WCS character object
	WCS.Character.CharacterCreated:Once(function(WcsCharacterObject)
		Character.WcsCharacterObject = WcsCharacterObject
		ClientWcsController:Reset()
	end)
	
	-- promting server to create WCS character and load local scripts
	Character:PromptWcsCharacterCreate()
	Character:PromptLoadLocalScripts()
	
	-- health effects handling
	local old_health = Humanoid.Health
	Humanoid.HealthChanged:Connect(function(new_health)
		local Delta = old_health - new_health
		old_health = new_health
		
		-- player interface handling
		shared.Client._requirements.UI.gameplay_ui:OnHealthChanged(new_health, old_health)
		
		-- camera shake handling
		if Delta <= 0 then
			return
		end
		
		Camera:Shake(
			Delta / 100,
			Delta / 100
		)
	end)

	table.insert(Character._connections,
		Humanoid.Changed:Connect(function(property: string)
			if property == 'MoveDirection' then
				if Character:HumanoidMoving() then
					if Humanoid.WalkSpeed > 17 then
						CharacterCamera:SetPresence(CharacterCamera.Presences.Running)
					else CharacterCamera:SetPresence(CharacterCamera.Presences.Movement) end
					
					Character.Animator.Animations.Walk.Track:AdjustSpeed(Character:GetVelocity().Magnitude / 13)
					Character.Animator:PlayAnimation('Walk')
					Character.Animator:StopAnimation('Idling')
				else
					CharacterCamera:SetPresence(CharacterCamera.Presences.Static)
					Character.Animator:StopAnimation('Walk')
					Character.Animator:PlayAnimation('Idling')
				end
			end
		end)
	)
	
	local LastHeight = 0
	local JumpRaycastParams = RaycastParams.new()
	JumpRaycastParams.FilterDescendantsInstances = {workspace.Players}
	JumpRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	JumpRaycastParams.CollisionGroup = 'Players'
	
	table.insert(Character._connections,
		Humanoid.StateChanged:Connect(function(_, HumanoidState: Enum.HumanoidStateType)
			if HumanoidState == Enum.HumanoidStateType.Jumping then
				Character.Animator:PlayAnimation('Jump')
				
				task.wait(.2) -- lol that could be better
				LastHeight = Character.Instance.HumanoidRootPart.Position.Y

			elseif HumanoidState == Enum.HumanoidStateType.Freefall then
				Character.Animator:PlayAnimation('FreeFall')

			elseif HumanoidState == Enum.HumanoidStateType.Landed then
				local HeightDelta = LastHeight - Character.Instance.HumanoidRootPart.Position.Y
				
				if HeightDelta > 0 then
					local Volume = math.clamp(.01, .01, 1)
					Camera.Modes.Character:ApplyPressure( math.sqrt(Volume * 2) )
					Character.Sounds:PlaySound('Land', Volume * 5)
				end
				
				Character.Animator:PlayAnimation('Land')
				Character.Animator:StopAnimation('FreeFall')
			end
		end))
	
	-- clean up
	Character.Destroying:Once(function()
		CharacterCamera:SetActive( false )
		CharacterController.Character = nil
	end)
end

-- sets controls for current player`s character
function CharacterController:SetCharacterControls( Character )
	assert(Character, 'No character object provided')
	assert(Character.Player:IsLocalPlayer(), 'Given character object is not owned by local player')
	
	if Character == CharacterController.Character then
		warn(`Already set controls for given character:`, Character)
		return
	end
	
	CharacterController.Character = Character
	BindToCharacter()
end

return CharacterController