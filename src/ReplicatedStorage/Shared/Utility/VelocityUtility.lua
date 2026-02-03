--[[
	Responsible for applying body forces to objects

	Examples: Humanoid knockback, Item throwing, etc.
--]]

--//Services

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Utility = require(script.Parent)

local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil

--//Types

export type BodyVelocityParams = {
	MaxForce: Vector3?,
	P: number?,
	Velocity: Vector3?,
}

export type BodyAngularVelocityParams = {
	AngularVelocity: Vector3?,
	MaxTorque: Vector3?,
	P: number?,
}

export type BodyGyroParams = {
	CFrame: CFrame?,
	D: number?,
	MaxTorque: Vector3?,
	P: number?,
}

export type BodyForceParams = {
	Force: Vector3?,
}

export type BodyThrustParams = {
	Force: Vector3?,
	Location: Vector3?,
}

--//Functions

local function ApplyBodyMover(instanceType: string, part: BasePart, params: { [string]: any }, lifeTime: number?)
	local NewVelocity = Instance.new(instanceType)
	Utility.ApplyParams(NewVelocity, params)

	if lifeTime then
		Debris:AddItem(NewVelocity, lifeTime)
	end

	NewVelocity.Parent = part
	return NewVelocity
end

local function ApplyBodyVelocity(part: BasePart, params: BodyVelocityParams, lifeTime: number?): BodyVelocity
	return ApplyBodyMover("BodyVelocity", part, params, lifeTime)
end

local function ApplyAngularVelocity(part: BasePart, params: BodyAngularVelocityParams, lifeTime: number?): BodyAngularVelocity
	return ApplyBodyMover("BodyAngularVelocity", part, params, lifeTime)
end

local function ApplyBodyGyro(part: BasePart, params: BodyGyroParams, lifeTime: number?): BodyGyro
	return ApplyBodyMover("BodyGyro", part, params, lifeTime)
end

local function ApplyBodyForce(part: BasePart, params: BodyForceParams, lifeTime: number?): BodyForce
	return ApplyBodyMover("BodyForce", part, params, lifeTime)
end

local function ApplyBodyThrust(part: BasePart, params: BodyThrustParams, lifeTime: number?): BodyThrust
	return ApplyBodyMover("BodyThrust", part, params, lifeTime)
end

local function ApplyImpulse(part: BasePart, impulse: Vector3, isAngular: boolean?)
	local NetworkOwner = part:GetNetworkOwner()

	if NetworkOwner and RunService:IsServer() then
		ServerRemotes.ApplyImpulse.Fire(NetworkOwner, {
			part = part,
			impulse = impulse,
			isAngular = isAngular,
		})
	else
		if isAngular then
			part:ApplyAngularImpulse(impulse)
		else
			part:ApplyImpulse(impulse)
		end
	end
end

--//Returner

return {
	ApplyBodyVelocity = ApplyBodyVelocity,
	ApplyAngularVelocity = ApplyAngularVelocity,
	ApplyBodyGyro = ApplyBodyGyro,
	ApplyBodyForce = ApplyBodyForce,
	ApplyBodyThrust = ApplyBodyThrust,
	ApplyImpulse = ApplyImpulse,
}
