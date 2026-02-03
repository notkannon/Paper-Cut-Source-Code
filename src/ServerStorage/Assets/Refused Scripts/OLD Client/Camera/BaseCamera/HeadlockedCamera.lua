local Client = shared.Client

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInput = game:GetService('UserInputService')
local Camera = workspace.CurrentCamera

-- requirements
local Util = require(ReplicatedStorage.Shared.Util)
local Enums = require(ReplicatedStorage.Enums)
local BaseCamera = require(script.Parent)


--// INITIALIZATION
local HeadlockedCamera = BaseCamera.new()
HeadlockedCamera:Init()
HeadlockedCamera:SetActive(false)

--// METHODS
-- overrides BaseCamera method
function HeadlockedCamera:SetActive(active: boolean)
	if active then
		-- camera entry properties
		Camera.CameraType = Enum.CameraType.Scriptable
	end
	
	-- virtual call
	BaseCamera.SetActive(HeadlockedCamera, active)
end

-- updates camera every frame
function HeadlockedCamera:Update(delta_time: number)
	local CharacterObject = Client.Player.Character
	
	-- detecting if no character
	if not CharacterObject then
		HeadlockedCamera:SetActive(false)
		return
	end

	-- lol humanoid
	local Humanoid: Humanoid? = CharacterObject:GetHumanoid()
	local torso_instance: BasePart = CharacterObject.Instance.Torso

	local camera_fixed_cf = torso_instance.CFrame * CFrame.new(0, 2, 0)
	local camera_fixed_pos = camera_fixed_cf.Position

	local from_mouse = CFrame.lookAt(camera_fixed_pos, camera_fixed_pos + Client._requirements.Camera:GetMouseDirection())
	Camera.CFrame = Camera.CFrame:Lerp(camera_fixed_cf:Lerp(from_mouse, 1/5), 1/5) -- applying smooth changes
end

return HeadlockedCamera