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
		Hinge = model.Hinge.CFrame
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

	local open_front_tween = TweenService:Create(model.Hinge, tweenInfoOpen, {CFrame = initial_cframe * frontOpened})
	local open_back_tween = TweenService:Create(model.Hinge, tweenInfoOpen, {CFrame = initial_cframe * backOpened})
	local close_tween = TweenService:Create(model.Hinge, tweenInfoClose, {CFrame = initial_cframe})

	local tweens = {
		open_front = open_front_tween,
		open_back = open_back_tween,
		close = close_tween
	}

	task.defer(function()
		local force = model:GetAttribute("HitForce")
		local dir = model:GetAttribute("HitDirection")

		local slammed = model:GetAttribute("Slammed")
		local broken = model:GetAttribute("Broken")

		if instant then
			model.Hinge.CFrame = initial_cframe
				* ((dir == "Front") and frontOpened or backOpened)
			return
		end

		if opened then
			self.sounds.open:Play()
			tweens[ 'open_' .. ((dir == "Front") and 'front' or 'back') ]:Play()
		else
			tweens.close:Play()
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
	
	local initial_cframes = self.anim_data
	local initial_cframe = initial_cframes.Hinge
	
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
	else
		RunService:UnbindFromRenderStep('door_' .. self:GetId())
		Animate.Animate(self, false, false)
		return
	end
end

-- animates door damaged
function Animate.AnimateDamage(self)
	local Model: Model = self:GetInstance()
	local Hinge: BasePart = Model.Hinge
	
	self.sounds.damage[ math.random(1, 3) ]:Play()
	
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

-- animates door break
function Animate.AnimateBreak(self)
	local Model: Model = self:GetInstance()
	local Direction = self:GetForceDir() == 'Front' and -1 or 1
	
	
end

return Animate