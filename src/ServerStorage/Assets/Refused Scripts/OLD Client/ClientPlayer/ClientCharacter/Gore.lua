type GoreTemp = {Phase: number, Model: BasePart?, Welds: { WeldConstraint? }}

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local DebrisService = game:GetService('Debris')

-- requirements
--local GoreComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent.CharacterComponent.Gore)
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


--// INITIALIZATION
local ClientGore = {}
ClientGore._objects = {}
ClientGore.__index = ClientGore

--// METHODS
-- constructor
function ClientGore.new( rig: Model )
	local self = setmetatable({
		Rig = rig,
		Temp = {},
		Active = false,

		_Connections = {}, -- a table to keep RBXConnectionSignal due gore active
	}, ClientGore)

	table.insert(
		self._objects,
		self)
	return self
end

-- initial client method
function ClientGore:Init()
	for _, Bodypart: BasePart in ipairs(self.Rig:GetChildren()) do
		if not Bodypart:IsA('BasePart') then continue end
		if not table.find(R6GoreBodyparts, Bodypart.Name) then continue end
		local OldHealth = Bodypart:GetAttribute('Health') or 100

		-- health connection
		Bodypart.AttributeChanged:Connect(function( attribute: string )
			if attribute ~= 'Health' then return end
			-- applying gore to health changed
			self:HandleBodypartGore(Bodypart,
				Bodypart:GetAttribute('Health'),
				OldHealth
			)

			-- old health getting
			OldHealth = Bodypart:GetAttribute('Health')
		end)

		self.Temp[ Bodypart ] = {}
	end
	
	-- health handling
	local Humanoid: Humanoid = self.Rig:FindFirstChildWhichIsA('Humanoid')
	local OldHealth = Humanoid.Health
	Humanoid.HealthChanged:Connect(function(health: number)
		self:OnHumanoidHealthChanged( health, OldHealth )
		OldHealth = health
	end)
end

-- applies gore model for bodybart from given data about damaged bodypart
function ClientGore:ApplyBodypartGoreModel(bodypart: BasePart, phase_index: number, available: { string? }, gore_settings: boolean?, health_value: number)
	local GoreTemp: GoreTemp = self.Temp[ bodypart ]
	local Rig: Model = self.Rig

	if not GoreTemp then return end
	local GoreModelName = available[ math.random(1, #available) ]

	if GoreTemp.Model then
		if gore_settings.OverridesGoreModels
			and phase_index ~= GoreTemp.Phase then

			GoreTemp.Model:Destroy()
			GoreTemp.Model = nil

		elseif phase_index == GoreTemp.Phase then
			return
		end
	end

	-- remember current gore phase
	GoreTemp.Phase = phase_index

	-- get random model reference for given bodypart
	local GoreModel: BasePart? = GoreLimbInstances:FindFirstChild(GoreModelName)
	assert(GoreModel, `Gore model with name "{ GoreModelName }" doesn't exists`)

	local TempModel = GoreModel:Clone()
	TempModel.CFrame = bodypart.CFrame

	local weld: WeldConstraint = Instance.new('WeldConstraint', TempModel)
	weld.Part0 = bodypart
	weld.Part1 = TempModel

	TempModel.Parent = bodypart
	TempModel.Limb.Color = bodypart.Color
	GoreTemp.Model = TempModel

	bodypart.LocalTransparencyModifier = 1 -- make bodypart transparent
	bodypart.Transparency = 1

	-- particles
	local bleeding_attachment: Attachment = GoreTemp.Model:FindFirstChild('bleeding', true)
	assert(bleeding_attachment, 'No bleeding attachment exists in gore:', GoreTemp.Model)

	for _, particle: ParticleEmitter in ipairs(GoreParticles.Bleeding:GetChildren()) do
		if bleeding_attachment:FindFirstChild(particle.Name) then continue end
		local new = particle:Clone()
		new.Parent = bleeding_attachment
		new.Enabled = true
	end

	-- huge effect of amputation
	for _, particle: ParticleEmitter in ipairs(GoreParticles.Amputate:GetChildren()) do
		if bleeding_attachment:FindFirstChild(particle.Name) then continue end
		local new = particle:Clone()
		new.Parent = bleeding_attachment
		new:Emit( 5 )
		DebrisService:AddItem(new, 5)
	end

	-- removing all accesories with this welding
	if gore_settings.AccessoryAttachmentRemove then
		for _, attachment_name: string in ipairs(gore_settings.AccessoryAttachmentRemove) do
			for _, descendant: Instance in ipairs(Rig:GetDescendants()) do
				local attachment: Attachment? = descendant:IsA('Attachment')
					and descendant.Name == attachment_name
					and descendant

				if not attachment then continue end

				if attachment.Parent.Parent:IsA('Accessory') then
					attachment.Parent.Parent:Destroy()
				end
			end
		end
	end

	-- clear texture
	if bodypart.Name == 'Head' then
		local face_instance: Decal? = bodypart:FindFirstChild('face')
		if face_instance then
			face_instance.Texture = ''
		end
	end

	-- trying to get shirt template reference to apply it to gore part
	local shirt_template: Decal? = TempModel:FindFirstChild('shirt_template', true)
	local pants_template: Decal? = TempModel:FindFirstChild('pants_template', true)

	if shirt_template then
		local shirt_instance = Rig:FindFirstChildWhichIsA('Shirt', true)

		if not shirt_instance then
			shirt_template.Texture = ''
		else
			local shirt_template_id = shirt_instance.ShirtTemplate
			shirt_template.Texture = shirt_template_id
		end

	elseif pants_template then
		local pants_instance = Rig:FindFirstChildWhichIsA('Pants', true)

		if not pants_instance then
			pants_template.Texture = ''
		else
			local pants_template_id = pants_instance.PantsTemplate
			pants_template.Texture = pants_template_id
		end
	end
end

-- handles bodypart which was damaged
function ClientGore:HandleBodypartGore(bodypart, health_value: number, old_health: number)
	local delta = old_health - health_value
	if delta <= 0 then return end

	-- gore debug visualizer
	if DEBUG_ENABLED then
		local Label: BillboardGui = bodypart:FindFirstChild(DebugVisualizer.Name)

		if not Label then
			Label = DebugVisualizer:Clone()
			Label.Parent = bodypart
		end

		Label.TextLabel.Text = health_value
		Label.TextLabel.TextColor3 = Color3.fromHSV(health_value/100 * .333, 1, 1)
	end

	local BodypartSettings = GoreSettings[ bodypart.Name ]
	assert('No bodypart settings exists for bodypart:', bodypart.Name)

	-- getting a current gore phase of damaged bodypart
	local bodypart_gore_phase = nil
	local _parse_phase = #BodypartSettings.Phases
	while _parse_phase > 1 do
		local phase = BodypartSettings.Phases[ _parse_phase ]

		if health_value <= phase[1] then
			bodypart_gore_phase = phase
			break
		end

		_parse_phase -= 1
	end

	-- ignore due not need to set any state
	if not bodypart_gore_phase then return end
	local _, phase_states, __ = table.unpack(bodypart_gore_phase)

	-- sound effects
	local Sound: Sound = GoreSounds:GetChildren()[ math.random(1, #GoreSounds:GetChildren()) ]:Clone()
	Sound.PlaybackSpeed = math.random(10, 15) / 12.5
	Sound.Volume = delta / 15

	SoundClient:PlaySoundIn(
		Sound, self.Rig.HumanoidRootPart
	)

	--[[if health_value <= 90 then -- makes bodypart bleeding --phase_states[1] == '_bleeding'
		--warn('BLEEDING')
		local bodypart: BasePart = self:GetBodypartByIndex(bodypart_index)
		--local bleeding_attachment: Attachment = GoreTemp.Model:FindFirstChild('bleeding', true)
		--assert(bleeding_attachment, 'No bleeding attachment exists in gore:', GoreTemp.Model)
		
		for _, particle: ParticleEmitter in ipairs(goreParticles.Bleeding:GetChildren()) do
			if bodypart:FindFirstChild(particle.Name) then continue end
			local new = particle:Clone()
			new.Parent = bodypart
			new.Enabled = true
		end
	end]]

	if phase_states[1] == '_amputate' then -- amputates bodypart
		--self:ApplyBodypartGoreStates(bodypart_index, phase_states)

	else -- sets bodypart gore model?
		local phase_index = table.find(
			BodypartSettings.Phases,
			bodypart_gore_phase
		)

		local extra_phase_states = {}
		if not phase_states[1] then
			for state, _ in pairs(phase_states) do
				table.insert(extra_phase_states, state)
			end

			self:ApplyBodypartGoreModel(
				bodypart,
				phase_index,
				extra_phase_states,
				BodypartSettings,
				health_value)
			return
		end

		self:ApplyBodypartGoreModel(
			bodypart,
			phase_index,
			phase_states,
			BodypartSettings,
			health_value)
	end

	--warn("HANDLED GORE:", bodyStateEnumToString[bodypart_index], health_value)
	--local character: Model = self.Character.Instance

	--[[local limb = limbInstances:FindFirstChild(bodypart.Name)
	local temp: BasePart = limb:GetChildren()[1]:Clone()
	local joint: Motor6D = character.Torso:FindFirstChild(limbToJoint[bodypart_index])
	
	temp.CFrame = bodypart.CFrame
	temp.Name = 'Gore' .. bodypart.Name
	temp.Parent = character
	joint.Part1 = nil
	joint.Enabled = false
	
	local weldConstraint = Instance.new('WeldConstraint', temp)
	weldConstraint.Part0 = bodypart
	weldConstraint.Part1 = temp
	weldConstraint.Enabled = true
	
	bodypart.CanCollide = true]]
end

-- creates a corpse from current character model
function ClientGore:MakeCorpse()
	self.Rig.Archivable = true
	
	local Corpse: Model = self.Rig:Clone()
	local Humanoid: Humanoid = Corpse:FindFirstChildWhichIsA('Humanoid')
	Corpse.Parent = workspace
	
	self.Rig.Archivable = false
	
	for _, basepart: BasePart in ipairs(Corpse:GetDescendants()) do
		if not basepart:IsA('BasePart') then continue end
		basepart.CollisionGroup = 'Player'
		basepart.CanCollide = true
	end
	
	for _, sound: Sound in ipairs(Corpse:GetDescendants()) do
		if not sound:IsA('Sound') then continue end
		sound:Stop()
	end
	
	local torso: BasePart = Corpse.Torso

	for _, joint: Motor6D? in ipairs(Corpse:GetDescendants()) do
		if not joint:IsA('Motor6D') then continue end
		local bis = Instance.new('BallSocketConstraint')
		bis.Parent = torso
		bis.Name = joint.Name .. '_ragdoll'

		local att0 = Instance.new('Attachment')
		local att1 = Instance.new('Attachment')
		att0.Parent = joint.Part0
		att1.Parent = joint.Part1
		att0.Name = joint.Name .. '_ragdoll_0'
		att1.Name = joint.Name .. '_ragdoll_1'
		att0.CFrame = joint.C0
		att1.CFrame = joint.C1

		bis.Attachment0 = att0
		bis.Attachment1 = att1
		bis.TwistLimitsEnabled = true
		bis.LimitsEnabled = true
		bis.UpperAngle = 45
		bis.TwistLowerAngle = -50
		bis.TwistUpperAngle = 50
		bis.MaxFrictionTorque = 100

		bis.Enabled = false
	end
	
	-- finding a ragdoll constraints created from server
	for _, joint: BallSocketConstraint? | Motor6D? in ipairs(torso:GetChildren()) do
		if joint:IsA('BallSocketConstraint') then joint.Enabled = true
		elseif joint:IsA('Motor6D') then joint.Enabled = false end
	end
	
	Humanoid.PlatformStand = true
	
	local Root: BasePart = Corpse.HumanoidRootPart
	Root.AssemblyLinearVelocity = self.Rig.HumanoidRootPart.AssemblyLinearVelocity
	Root.AssemblyAngularVelocity = self.Rig.HumanoidRootPart.AssemblyAngularVelocity
end
--[[
function Gore:DrawFlesh(Temp: GoreTemp, amount: number)
	--local bodypart: BasePart = self:GetBodypartByIndex(bodypart_index)
	--assert(bodypart, `Bodypart with index { bodypart_index } is not valid member of character`)

	-- getting a folder of flesh models
	local bleeding_attachment: Attachment = Temp.Model:FindFirstChild('bleeding')
	local flesh_instances = goreFleshInstances:FindFirstChild(Temp.Model.Parent.Name) or goreFleshInstances.Chunks

	for x = 1, amount or 1 do
		local flesh_instance: BasePart = flesh_instances:GetChildren()[math.random(1, #flesh_instances:GetChildren())]:Clone()
		flesh_instance.CFrame = bleeding_attachment.WorldCFrame
		flesh_instance.Size *= Vector3.new(
			math.random(5, 17)/10,
			math.random(5, 17)/10,
			math.random(5, 17)/10
		)

		flesh_instance.Parent = workspace.Temp
		flesh_instance.CollisionGroup = 'Gore'
		flesh_instance.Anchored = false
		flesh_instance.CanCollide = true
		flesh_instance.CanTouch = false
		flesh_instance.CanQuery = false
		flesh_instance.AssemblyLinearVelocity = RANDOM:NextUnitVector() * 10

		game:GetService('Debris'):AddItem(flesh_instance, 6)
	end
end]]


--[[
function Gore:UpdateBlood()
	local character: Model = self.Character.Instance
	local humanoid: Humanoid = self.Character:GetHumanoid()

	if not humanoid
		--or self.Character:GetHideout() -- don`t draw blood while player is hidden
	then return end

	local health: number = humanoid.Health

	if health > 0 and health < 90 and tick() - self.lastBloodEmitTime > math.clamp(health / humanoid.MaxHealth, .075, 1) then
		self.lastBloodEmitTime = tick()

		--EmitAmount(Origin: Vector3 | BasePart, Direction: Vector3, Amount: number)
		Gore.UpdateBloodFilter()
		bloodEmitter:UpdateSettings({ Filter = Gore._bloodFilter })
		bloodEmitter:EmitAmount(
			character.HumanoidRootPart.Position,
			RANDOM:NextUnitVector() - Vector3.new(0, -.05, 0),
			RANDOM:NextInteger(1, 3)
		)
	end
end]]

-- calls on humanoid.healthChanged event to set whole humanoid view
function ClientGore:OnHumanoidHealthChanged(new_health: number, old_health: number)
	local health_delta = old_health - new_health
	if health_delta <= 0 then return end

	print('[Gore] Humanoid damaged')
	
	if new_health <= 0 then
		self:MakeCorpse()
	end
--[[
	local currentCharacterSounds = self.characterSounds
	currentCharacterSounds:PlayRandomSound(
		Enums.CharacterSoundTypeEnum[ health_delta < 20 and 'GoreAmputate' or 'GoreDestroy' ],
		math.clamp(math.abs(health_delta) / 100, .25, .6)
	)]]
end


function ClientGore:Clear()
	for _, temp: GoreTemp in pairs(self.Temp) do
		if temp.Model then
			temp.Model:Destroy()
			temp.Model = nil
		end
	end
end


function ClientGore:Destroy()
	for _, connection: RBXScriptConnection in ipairs(self.connections) do
		connection:Disconnect() -- drops every connection
	end

	table.remove(ClientGore._objects,
		table.find(ClientGore._objects,
			self
		)
	)

	setmetatable(self, nil)
	table.clear(self)
end


return ClientGore