local TweenService = game:GetService('TweenService')
local RunService = game:GetService("RunService")
local soundService = game:GetService("SoundService")

local tweenInfoClose = TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local tweenInfoOpen = TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local frontOpened = CFrame.Angles(0, math.rad(-100), 0)
local backOpened = CFrame.Angles(0, math.rad(100), 0)

local DOOR_SMOOTHNESS_INTERPOLATION = .5
local DOOR_MAX_OPEN_ANGLE = 100
local SLAM_WAVE_SPEED = 3
local SLAM_WAVE_TIME = 3

-- method container
local Animate = {}

-- initial data collection
function Animate.GetInitialData(model: Model)
	return {
		Hinge = model.Hinge.CFrame,
		Hinge2 = model.Hinge2.CFrame
	}
end

-- animates door
function Animate.Animate(self, instant: boolean?, override: boolean?)
	local model: Model = self:GetInstance()
	local opened: boolean = self:IsOpened()
	
	if override ~= nil then
		opened = override
	end
	
	local initial_cframes = self.anim_data
	local initial_cframe = initial_cframes.Hinge
	local initial_cframe2 = initial_cframes.Hinge2

	local open_front_tween = TweenService:Create(model.Hinge, tweenInfoOpen, {CFrame = initial_cframe * frontOpened})
	local open_back_tween = TweenService:Create(model.Hinge, tweenInfoOpen, {CFrame = initial_cframe * backOpened})
	local open_front_tween2 = TweenService:Create(model.Hinge2, tweenInfoOpen, {CFrame = initial_cframe2 * backOpened})
	local open_back_tween2 = TweenService:Create(model.Hinge2, tweenInfoOpen, {CFrame = initial_cframe2 * frontOpened})
	local close_tween = TweenService:Create(model.Hinge, tweenInfoClose, {CFrame = initial_cframe})
	local close_tween2 = TweenService:Create(model.Hinge2, tweenInfoClose, {CFrame = initial_cframe2})

	local tweens = {
		open_front = open_front_tween,
		open_back = open_back_tween,
		close = close_tween,
		open_front2 = open_front_tween2,
		open_back2 = open_back_tween2,
		close2 = close_tween2
	}

	task.defer(function()
		local force = model:GetAttribute("HitForce")
		local dir = model:GetAttribute("HitDirection")

		local slammed = model:GetAttribute("Slammed")
		local broken = model:GetAttribute("Broken")

		if instant then
			model.Hinge.CFrame = initial_cframe
				* ((dir == "Front") and frontOpened or backOpened)
			model.Hinge2.CFrame = initial_cframe2
				* ((dir == "Front") and backOpened or frontOpened) -- reversing rotation angle for 2nd door

			return
		end

		if opened then
			self.sounds.open:Play()
			tweens[ 'open_' .. ((dir == "Front") and 'front' or 'back') ]:Play()
			tweens[ 'open_' .. ((dir == "Front") and 'front2' or 'back2') ]:Play()
		else
			tweens.close:Play()
			tweens.close2:Play()
			tweens.close.Completed:Once(function(a)
				if a == Enum.PlaybackState.Completed then
					self.sounds.close:Play()
				end
			end)
		end
	end)
end

-- animates slam
function Animate.AnimateSlam(self, delta_time)
	local model: Model = self:GetInstance()
	local slam_animation_pos = (SLAM_WAVE_TIME - math.clamp(tick() - self.slammed_time, 0, SLAM_WAVE_TIME)) / SLAM_WAVE_TIME
	
	local hinge_1 = model.Hinge
	local hinge_2 = model.Hinge2
	
	local initial_cframes = self.anim_data
	local initial_cframe = initial_cframes.Hinge
	local initial_cframe2 = initial_cframes.Hinge2
	
	-- animating smooth wave-look door rotating with fade
	if slam_animation_pos > 0 then
		-- 1st door animation
		hinge_1.CFrame = hinge_1.CFrame:Lerp(
			initial_cframe *
				CFrame.Angles(0,
					math.rad(math.sin(tick() * SLAM_WAVE_SPEED)
						* DOOR_MAX_OPEN_ANGLE * (self:GetForceDir() == "Front" and -1 or 1))
					* slam_animation_pos, 0),
			delta_time / DOOR_SMOOTHNESS_INTERPOLATION
		)
		
		-- 2nd door animation
		hinge_2.CFrame = hinge_2.CFrame:Lerp(
			initial_cframe2 *
				CFrame.Angles(0,
					math.rad(math.sin(tick() * SLAM_WAVE_SPEED)
						* DOOR_MAX_OPEN_ANGLE * (self:GetForceDir() == "Front" and 1 or -1))
					* slam_animation_pos, 0),
			delta_time / DOOR_SMOOTHNESS_INTERPOLATION
		)
	else
		RunService:UnbindFromRenderStep('door_' .. self:GetId())
		Animate.Animate(self, false, false)
		return
	end
end


function Animate.AnimateDamage(self)
	local Model: Model = self:GetInstance()

	self.sounds.damage[ math.random(1, 3) ]:Play()

	local Hinges = { Model.Hinge, Model.Hinge2 }
	for _, Hinge: BasePart in ipairs(Hinges) do
		local Weld: Weld = Hinge:FindFirstChildOfClass('Weld')
		Weld.C1 = CFrame.Angles(
			math.random(-30, 30) / 270,
			math.random(-30, 30) / 270,
			math.random(-30, 30) / 270
		)

		TweenService:Create(
			Weld,
			TweenInfo.new(math.random(2, 3)/4),
			{C1 = CFrame.new()}
		):Play()
	end
end


function Animate.AnimateBreak(self)
	local Model: Model = self:GetInstance()
	local Direction = self:GetForceDir() == 'Front' and -1 or 1

	self.sounds.destroy:Play()

	local Hinges = { Model.Hinge, Model.Hinge2 }
	for _, Hinge: BasePart in ipairs(Hinges) do
		local temp = Hinge:Clone()
		temp.Parent = Model
		temp.Anchored = false
		temp.Door.CanCollide = true
		temp.Door.CollisionGroup = 'Door'
		Hinge:Destroy()

		local Velocity = Instance.new('BodyVelocity')
		Velocity.Velocity = Model.Root.CFrame.LookVector * 50 * Direction + Random.new():NextUnitVector() * 7
		Velocity.MaxForce = Vector3.one * 30000
		Velocity.Parent = temp
		Velocity.P = 70

		local Angular = Instance.new('BodyAngularVelocity')
		Angular.AngularVelocity = Random.new():NextUnitVector() * 40
		Angular.MaxTorque = Vector3.one * 300
		Angular.Parent = temp
		Angular.P = 40

		game:GetService('Debris'):AddItem(Velocity, .3)
		game:GetService('Debris'):AddItem(Angular, .3)
		game:GetService('Debris'):AddItem(temp, 7)

		task.delay(5, function()
			for _, part: BasePart? in ipairs(temp:GetDescendants()) do
				if not part:IsA('BasePart') then continue end
				TweenService:Create(part, TweenInfo.new(2), {Transparency = 1}):Play()
			end
		end)
	end
end

return Animate