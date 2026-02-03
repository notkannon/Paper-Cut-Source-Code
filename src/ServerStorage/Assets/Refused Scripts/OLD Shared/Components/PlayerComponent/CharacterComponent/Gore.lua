type GoreTemp = {Phase: number, Model: BasePart?, Welds: { WeldConstraint? }}

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local DebrisService = game:GetService('Debris')

-- context
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

-- requirements
local GoreSettings = require(ReplicatedStorage.GlobalSettings.GoreSettings)
local SoundClient = require(ReplicatedStorage.Client.SoundClient)
local Enums = require(ReplicatedStorage.Enums)

-- debug
local DebugVisualizer = ReplicatedStorage.Client.GoreDebug
local DEBUG_ENABLED = true

-- var
local GoreSounds = SoundClient.Path.Players.Gore.Dismemberment.Obliterate
local GoreInstances = ReplicatedStorage.Assets.Gore
local GoreFleshInstances = GoreInstances.Flesh
local GoreLimbInstances = GoreInstances.Limbs
local GoreParticles = GoreInstances.Particle

local R6GoreBodyparts = {
	-- R6
	'Right Arm',
	'Left Arm',
	'Right Leg',
	'Left Leg',
	'Torso',
	'Head'
}


-- Initial
local Gore = {}
Gore._objects = {}
Gore.__index = Gore

-- constructor
function Gore.new( rig: Model )
	
	return self
end

-- initial method
function Gore:Init() end

--[[
function Gore:SetLocalRagdollEnabled(enabled: boolean)
	if not self.Character:IsLocalPlayer() then return end -- DONT DELETE
	local character: Model = self.Character.Instance
	local humanoid: Humanoid = self.Character:GetHumanoid()

	assert(character, 'Character doesn`t exists')
	assert(humanoid, 'Humanoid doesn`t exists')

	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType[enabled and 'Physics' or 'Running'])
	local torso: BasePart = self.Character:GetTorso()

	-- finding a ragdoll constraints created from server
	for _, joint: BallSocketConstraint? | Motor6D? in ipairs(torso:GetChildren()) do
		if joint:IsA('BallSocketConstraint') then joint.Enabled = enabled
		elseif joint:IsA('Motor6D') then joint.Enabled = not enabled end
	end
end]]





return Gore