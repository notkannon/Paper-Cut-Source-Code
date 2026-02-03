-- imports
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TweenService = game:GetService("TweenService")

-- refs
local Mouse: Mouse = game.Players.LocalPlayer:GetMouse()
local Camera: Camera = workspace.CurrentCamera

-- requirements
local CameraShakerModule = require(ReplicatedStorage.Package.CameraShaker)
local Util = require(ReplicatedStorage.Shared.Util)
local CameraShaker


-- class initial
local DefaultTweenConfig = {
	Time = 0.3,
	EasingStyle = Enum.EasingStyle.Linear,
	EasingDirection = Enum.EasingDirection.In,
}

local DestinedFov = workspace.CurrentCamera.FieldOfView
local Initialized = false
local Tween: Tween?
local ClientCamera = {}
ClientCamera.Modes = {}
ClientCamera.Instance = Camera


-- initial method

function ClientCamera:GetDestinedFov()
	return DestinedFov
end

function ClientCamera:ChangeFov(value: number, method: "Increment" | "Set", tweenConfig)
	if tweenConfig and Tween then
		Tween:Cancel()
		Tween = nil
	end

	DestinedFov = (method == "Increment" and DestinedFov + value) or value

	if not tweenConfig then
		Camera.FieldOfView = DestinedFov
		return
	end

	tweenConfig = Util.Reconcile(tweenConfig, DefaultTweenConfig)

	Tween = TweenService:Create(Camera, TweenInfo.new(tweenConfig.Time, tweenConfig.EasingStyle, tweenConfig.EasingDirection), {
		FieldOfView = DestinedFov,
	})

	Tween:Play()
	Tween.Completed:Once(function()
		Tween = nil
	end)
end


function ClientCamera:Init()
	if Initialized then return end
	ClientCamera._Initialized = true
	Initialized = true
	
	-- TODO: fix Camera shaker doing fucking insane trips when FPS frops
	CameraShaker = CameraShakerModule.new(
		Enum.RenderPriority.Camera.Value + 1,
		function( shaker_cframe: CFrame )
			Camera.CFrame *= shaker_cframe
		end
	)
	
	CameraShaker:Start()
	
	-- cameras initial
	ClientCamera.Modes.Headlocked = require(script.BaseCamera.HeadlockedCamera)
	ClientCamera.Modes.Character = require(script.BaseCamera.CharacterCamera)
end

-- returns direction from Camera to Mouse on screen
function ClientCamera:GetMouseDirection()
	local x, y = Mouse.X, Mouse.Y
	local ray_dir = Camera:ScreenPointToRay(x, y, 1).Direction
	return ray_dir
end

-- custom Mouse hit function
function ClientCamera:GetMouseHit( depth: number?, instance: boolean? )
	depth = depth or 1000
	local ray_dir = self:GetMouseDirection()
	
	-- raycast
	local raycast_params = RaycastParams.new()
	raycast_params.FilterType = Enum.RaycastFilterType.Exclude
	raycast_params.IgnoreWater = true
	raycast_params.FilterDescendantsInstances = {
		workspace.CurrentCamera,
		shared.Client.local_character.Instance
	}
	
	local result = workspace:Raycast(
		Camera.CFrame.Position,
		ray_dir * depth,
		raycast_params
	)
	
	if result then
		return instance and result.Instance or result.Position
	else return Camera.CFrame.Position + Camera.CFrame.LookVector * depth end
end

-- shakes Camera with given options
function ClientCamera:Shake(scale: number?, duration_scale: number?, preset_name: string?)
	duration_scale = duration_scale or 1
	scale = scale or 1

	local shake_instance = CameraShaker.Presets[ preset_name or 'Explosion' ]
	shake_instance.fadeOutDuration = duration_scale * shake_instance.fadeOutDuration
	shake_instance.Magnitude = scale * shake_instance.Magnitude
	CameraShaker:Shake( shake_instance )
end

return ClientCamera