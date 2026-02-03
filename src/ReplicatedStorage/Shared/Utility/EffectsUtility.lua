--[[
	Responsible for helping in the effects handling
--]]

--//Service

local Debris = game:GetService("Debris")

--//Functions

local function EmitDescendants(instance: Instance, ignoreEmitterAttributes: boolean?, amount: number?)
	for _, Emitter in ipairs(instance:GetDescendants()) do
		if not Emitter:IsA("ParticleEmitter") then
			continue
		end

		if ignoreEmitterAttributes then
			Emitter:Emit(amount or Emitter.Rate)
			continue
		end

		local Duration = Emitter:GetAttribute("EmitDuration")
		local Count = Emitter:GetAttribute("EmitCount")
		local Delay = Emitter:GetAttribute("EmitDelay")

		if Duration and Duration > 0 then
			Emitter.Enabled = true
			task.delay(Duration, function()
				Emitter.Enabled = false
			end)
			continue
		end

		if Delay and Delay > 0 then
			task.delay(Delay, function()
				Emitter:Emit(amount or Count or Emitter.Rate)
			end)
		else
			Emitter:Emit(amount or Count or Emitter.Rate)
		end
		
	end
end

local function ToggleEmitDescendantsEffect(instance: Instance, amount: number?)
	local MaxLifetime = 0
	
	for _, Emitter in ipairs(instance:GetDescendants()) do
		if not Emitter:IsA("ParticleEmitter") then
			continue
		end
		
		local Duration = Emitter:GetAttribute("EmitDuration")
		local Count = Emitter:GetAttribute("EmitCount")
		local Delay = Emitter:GetAttribute("EmitDelay")

		local CountEmit = amount or Count or Emitter.Rate
		

		if Duration and Duration > 0 then
			Emitter.Enabled = true
			task.delay(Duration, function()
				Emitter.Enabled = false
			end)
			continue
		end
		
		
		if Delay and Delay > 0 then
			task.delay(Delay, function()
				Emitter:Emit(CountEmit)
			end)
		else
			Emitter:Emit(CountEmit)
		end
				
		Debris:AddItem(Emitter, Emitter.Lifetime.Max)
		MaxLifetime = MaxLifetime < Emitter.Lifetime.Max and Emitter.Lifetime.Max or MaxLifetime
	end
	
	Debris:AddItem(instance, MaxLifetime)
end

local function ToggleEmitEffect(instance: Instance, Particle: ParticleEmitter, amount: boolean)
	local Effect = Particle:Clone()
	Effect.Parent = instance
	
	Effect:Emit(amount)
	
	Debris:AddItem(Effect, Effect.Lifetime.Max)
	return Effect
end

local function ToggleEmitters(instance: Instance, state: boolean, time: number?)
	for _, Emitter in ipairs(instance:GetDescendants()) do
		if not Emitter:IsA("ParticleEmitter") then
			continue
		end

		Emitter.Enabled = state

		if time then
			task.delay(time, function()
				Emitter.Enabled = not state
			end)
		end
	end
end

local function CalculateMaxLifetime(instance: Instance)
	local MaxLifetime = instance:IsA("ParticleEmitter") and instance.Lifetime.Max or 0

	for _, Emitter in ipairs(instance:GetDescendants()) do
		if not Emitter:IsA("ParticleEmitter") then
			continue
		end
		
		MaxLifetime = math.max(MaxLifetime, Emitter.Lifetime.Max)
	end

	return MaxLifetime
end

local function EmitParticlesInWorldSpace(at: Vector3|CFrame, emitters: { ParticleEmitter }, amount: number?)
	local Attachment = Instance.new("Attachment")
	Attachment.Parent = workspace.Terrain
	Attachment.WorldCFrame = typeof(at) == "Vector3" and CFrame.new(at) or at
	
	local MaxLifetime = 0
	
	for _, Emitter: ParticleEmitter in ipairs(emitters) do
		local New = Emitter:Clone()
		New.Enabled = false
		New.Parent = Attachment
		New:Emit(amount or Emitter.Rate)
		
		MaxLifetime = math.max(MaxLifetime, New.Lifetime.Max)
	end
	
	task.delay(MaxLifetime, Attachment.Destroy, Attachment)
end

--//Returner

return {
	ToggleEmitters = ToggleEmitters,
	EmitDescendants = EmitDescendants,
	ToggleEmitEffect = ToggleEmitEffect,
	CalculateMaxLifetime = CalculateMaxLifetime,
	EmitParticlesInWorldSpace = EmitParticlesInWorldSpace,
	ToggleEmitDescendantsEffect = ToggleEmitDescendantsEffect,
}