local client = shared.Client
local requirements = client._requirements

-- paths
local camera = workspace.CurrentCamera
local RunService = game:GetService('RunService')
local UserInput = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local animations = ReplicatedStorage.Assets.Animations.Viewmodel
--local Referece = ReplicatedStorage.Assets.Viewmodel.MissThavel

-- requiremens
local SpringModule = require(ReplicatedStorage.Package.SpringModule)
local ProceduralPresets = require(script.Parent.Parent.ProceduralPresets)

-- const
local OFFSET = CFrame.new(0, -1, -1)
local PI = math.pi

-- spring initial
local SwaySpring = SpringModule.new()
local MovementSpring = SpringModule.new() -- applying when character changes Y position

-- TeacherViewmodel initial
local TeacherViewmodel = {}
TeacherViewmodel._objects = {}
TeacherViewmodel.__index = TeacherViewmodel

-- constructor
function TeacherViewmodel.new(reference: Model, animations)
	local self = setmetatable({
		Instance = reference:Clone(),
		PreviousCFrame = CFrame.new(),
		Animator = nil,
		Enabled = false
	}, TeacherViewmodel)
	
	table.insert(
		TeacherViewmodel._objects,
		self)
	return self
end

-- initial method method
function TeacherViewmodel:Init()
	self.Animator = self.Instance
		:FindFirstChildOfClass('AnimationController')
		:FindFirstChildOfClass('Animator')
end

-- viewmodel enabling function
function TeacherViewmodel:SetEnabled( enabled: boolean )
	if enabled == self.Enabled then return end

	local CharacterObject = client.Player.Character
	if not CharacterObject then return end

	local character: Model = CharacterObject.Instance
	local humanoid: Humanoid = CharacterObject:GetHumanoid()

	-- enabling
	self.Instance.Parent = enabled and workspace or nil
	TeacherViewmodel.Enabled = enabled

	-- disabling
	if not enabled then
		RunService:UnbindFromRenderStep('@viewmodel')
		return
	else
		--[[for _, AttackAnimation: Animation in ipairs(animations.MissBloomie.Attacks:GetChildren()) do
			table.insert(Attacks, Animator:LoadAnimation(AttackAnimation))
		end]]

		local IdleTrack = self.Animator:LoadAnimation(animations.MissBloomie.Idle)
		IdleTrack.Looped = true
		IdleTrack:Play()
	end

	-- rendering connection
	RunService:BindToRenderStep('@viewmodel', Enum.RenderPriority.Camera.Value + 2, function(...)
		if not character then TeacherViewmodel:SetEnabled( false ) return end
		self:Update(...)
	end)
end


function TeacherViewmodel:TestAttack() end

-- viewmodel update function
function TeacherViewmodel:Update(delta_time: number)
	local MouseDelta = UserInput:GetMouseDelta()

	-- viewmodel-to-character bindings
	local CharacterObject = client.Player.Character
	local humanoid: Humanoid = CharacterObject:GetHumanoid()
	local ProceduralFrame: CFrame

	-- getting offset for movement
	if CharacterObject:HumanoidMoving() then
		ProceduralFrame = ProceduralPresets.Movement(
			math.sqrt(humanoid.WalkSpeed) * 4.5, .3
		)
	else -- getting offset for idling
		ProceduralFrame = ProceduralPresets.Idle(3, .5)
	end

	-- spring applying
	SwaySpring:shove( Vector3.new(-MouseDelta.X / 500, MouseDelta.Y / 200, 0) )
	local SpringUpdate: Vector3 = SwaySpring:update(delta_time)

	-- offsets applying
	self.Instance.PrimaryPart.CFrame = camera.CFrame
		* OFFSET
		* CFrame.new(SpringUpdate.X, SpringUpdate.Y, 0)
		* self.PreviousCFrame

	-- smooth presets interpolation
	self.PreviousCFrame = self.PreviousCFrame:Lerp(ProceduralFrame, 1/5)
end

return TeacherViewmodel