local Client = shared.Client

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInput = game:GetService('UserInputService')
local Camera = workspace.CurrentCamera

-- requirements
local Util = require(ReplicatedStorage.Shared.Util)
local Enums = require(ReplicatedStorage.Enums)
local BaseCamera = require(script.Parent)
local SpringModule = require(ReplicatedStorage.Package.SpringModule)

-- springs
local PressureSpring = SpringModule:new(4, 290, 5, .98)

-- vars
local Presences = {
	Static = {
		Scale = .5,
		Speed = 1.45,

		GET = function(self)
			local t = tick() * self.Speed
			local scale = self.Scale
			
			local x = math.sin(t)
			local y = math.cos(t * 2) * .2
			local z = math.sin(t) * 2


			return CFrame.Angles(
				math.rad(x / 4 * scale),
				math.rad(y / 4 * scale),
				math.rad(z / 3 * scale)
			), Vector3.zero
		end},

	Movement = {
		Scale = .48,
		Speed = 13,

		GET = function(self)
			local Force: number = Client.Player.Character.Instance.Humanoid.WalkSpeed / 11
			local t = tick() * self.Speed * Force
			local scale = self.Scale * Force

			local bobX = (math.cos(t / 2) * .8)
			local bobY = (math.sin(t) * .8)

			return CFrame.Angles(
				bobY * .01 * scale,
				bobY * .01 * scale,
				bobX * .005 * scale
			), Vector3.new(
				bobX * scale,
				bobY * scale,
				bobX * scale
			)
		end},

	Running = {
		Scale = .27,
		Speed = 25,

		GET = function(self)
			--local Force: number = (Client.Player.Character:GetVelocity() * Vector3.new(1, 0, 1)).Magnitude / 16
			local t = tick() * self.Speed-- * Force
			local scale = self.Scale-- * forc

			local bobX = (math.cos(t / 2) * .8)
			local bobY = (math.sin(t) * .8)

			return CFrame.Angles(
				bobY * .03 * scale,
				bobX * .03 * scale,
				bobY * .003 * scale
			), Vector3.new(
				bobX * scale,
				bobY * scale,
				bobX * scale * .7
			)
		end}
}


--// INITIALIZATION
local CharacterCamera = BaseCamera.new()
CharacterCamera:Init()
CharacterCamera:SetActive(false)
CharacterCamera.Presences = Presences
CharacterCamera.Presence = Presences.Static

--// METHODS
function CharacterCamera:Init()
	BaseCamera.Init(self)
end

-- sets current camera animation presence
function CharacterCamera:SetPresence(input)
	local target
	
	for _, presence in pairs(Presences) do
		if presence == input then
			target = presence
			break
		end
	end
	
	assert(target, `Presence doesn't exists ({ target })`)
	
	-- presence changing
	CharacterCamera.Presence = target
end

-- overrides BaseCamera method
function CharacterCamera:SetActive(active: boolean)
	if active then
		-- binding camera to existing character
		Camera.CameraType = Enum.CameraType.Custom
		Camera.CameraSubject = Client.Player.Character:GetHumanoid()
	end
	
	-- virtual call
	BaseCamera.SetActive(CharacterCamera, active)
end

-- makes camera rotate down
function CharacterCamera:ApplyPressure(strength: number)
	PressureSpring:shove( Vector3.new(0, 1 * strength, 0) )
end

-- updates camera every frame
function CharacterCamera:Update(delta_time: number)
	local CharacterObject = Client.Player.Character
	
	-- disabling if character doesnt exists
	if not CharacterObject then
		CharacterCamera:SetActive(false)
		return
	end
	
	-- lol humanoid
	local Humanoid: Humanoid? = CharacterObject:GetHumanoid()

	local goal = CFrame.new()
	local PresenceOffset = Vector3.new(0, 0, -1)
	
	-- spring update
	local PressureSpringUpdate: Vector3 = PressureSpring:update(delta_time)
	
	-- getting end camera cframe to apply
	local angles, vec3 = self.Presence:GET()
	PresenceOffset = PresenceOffset + vec3
	goal *= angles
	
	-- getting humanoid camera offset relative head
	local Force: number = Client.Player.Character.Instance.Humanoid.WalkSpeed / 11 --CharacterObject.Instance.HumanoidRootPart.AssemblyLinearVelocity.Magnitude * (1/11)
	local SpeedScale: number = Util.Lerp(Force, 1, .8) -- just NOT use full value from 0 to inf, i need a bit of this
	local Offset: Vector3 = Vector3.zero
	
	local Root: BasePart = CharacterObject.Instance.HumanoidRootPart
	local Head: BasePart = CharacterObject.Instance.Head
	local Relative: CFrame = Root.CFrame:ToObjectSpace(Head.CFrame)
	Offset = Relative.Position - Vector3.new(0, 1.4, 0)
	
	-- interpolation
	Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp(Offset + PresenceOffset, 1/10)
	Camera.FieldOfView = Util.Lerp(Camera.FieldOfView, 70 * SpeedScale, 1/25)
	Camera.CFrame = Camera.CFrame:Lerp(Camera.CFrame * goal, 1/5)
		* CFrame.new(0, -PressureSpringUpdate.Y * 2.5, 0)
		* CFrame.Angles(-PressureSpringUpdate.Y, 0, 0)
end

return CharacterCamera