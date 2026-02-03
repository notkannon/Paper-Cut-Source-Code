local client = shared.Client
assert( client, 'Attempt to require client module' )

-- requirements
local Util = client._requirements.Util
local RunServuce = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

local Sprites = {
	Eye = {
		normal = 'rbxassetid://17433329088',
		scared = 'rbxassetid://17433607370',
		blink = 'rbxassetid://17433424318',
	},

	Face = {
		normal = 'rbxassetid://17433357367',
		smile = 'rbxassetid://17433741537',
		pain = 'rbxassetid://17433530136',
	}
}

local headInitial = CFrame.new(0, 1.025, 0.048)


-- class initial
local Cannon = {} do
	Cannon.__index = Cannon
	Cannon._objects = {}
	
	function Cannon.new()
		local rig: Model = workspace.Map.Shop.Sellers:FindFirstChild('Cannon')
		local eye_template: BasePart = rig:FindFirstChild('Eye')
		local face_template: BasePart = rig:FindFirstChild('Face')
		
		assert( eye_template, 'No Eye part was found in provided rig' )
		assert( eye_template, 'No Face part was found in provided rig' )
		
		local self = setmetatable({
			rig = rig,
			eye = eye_template,
			face = face_template,
			
			last_blink_time = 0,
			next_blink_delay = 1,
			current_face = nil,
			
			tweens = {
				face_change = TweenService:Create(face_template, TweenInfo.new(.05, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, true), {Size = face_template.Size * Vector3.new(1.3, 1.3, 1)}),
				eye_change = TweenService:Create(eye_template, TweenInfo.new(.05, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, true), {Size = eye_template.Size * Vector3.new(1.3, 1.3, 1)}),
			},
			
			tracks = {},
			
			time_offset = 0 -- could be used to make unsynchronized animations
		}, Cannon)
		
		table.insert(
			self._objects,
			self)
		self:Init()
		return self
	end
end

-- loading animations to the rig
function Cannon:Init()
	local animator: Animator = self.rig.Humanoid.Animator
	local tracks = self.tracks
	
	tracks.idling = animator:LoadAnimation(script.Idling)
	tracks.closed = animator:LoadAnimation(script.Closed)
	tracks.closed.Priority = Enum.AnimationPriority.Action4
	
	self:PlayTrack( 'idling' )
end


function Cannon:PlayTrack( name: string )
	if name == 'closed' then
		self.tracks.idling:Stop()
		self.tracks.closed:Play()
		self.tracks.closed.Stopped:Once(function()
			self:ApplyFace( nil )
		end)
		
		-- animation keyframe reached event connect
		self.tracks.closed:GetMarkerReachedSignal('face'):Once(function() self:ApplyFace('smile') end)
		self.tracks.closed:GetMarkerReachedSignal('door'):Once(function() client._requirements.ShopService:AnimateDoor( true ) end)
		
	elseif name == 'idling' then
		self.tracks.idling:Play()
		
	elseif name == 'opened' then
		self:ApplyFace('smile')
		self.tracks.idling:Play()
		self.tracks.closed:Play( nil, nil, -1 )
		self.tracks.closed.Stopped:Once(function()
			self:ApplyFace( nil )
		end)
	end
end


function Cannon:ApplyFace( name: string )
	local face: BasePart = self.face
	local eye: BasePart = self.eye
	local face_img: Decal = face.Img
	local eye_img: Decal = eye.Img
	
	if name == 'blink' then
		if self.current_face then return end
		self.tweens.eye_change:Play()
		eye_img.Texture = Sprites.Eye.blink
		
		self.tweens.eye_change.Completed:Once(function()
			eye_img.Texture = Sprites.Eye.normal
		end)
		
	elseif name == 'smile' then
		self.current_face = 'smile'
		self.tweens.eye_change:Play()
		self.tweens.face_change:Play()
		eye_img.Texture = Sprites.Eye.blink
		face_img.Texture = Sprites.Face.smile
	else
		self.current_face = nil
		face_img.Texture = Sprites.Face.normal
	end
end


function Cannon:ApplyEmote()
	
end


function Cannon:SetFollowTarget( target: BasePart? )
	if not target then
		self.follow_target = nil
		return
	end
	
	assert( target:IsA('BasePart'), 'Provided follow part is not BasePart' )
	self.follow_target = target
end


function Cannon:Update()
	if tick() - self.last_blink_time > self.next_blink_delay then
		self.last_blink_time = tick()
		self.next_blink_delay = math.random(7, 17)/7.5
		
		self:ApplyFace( 'blink' )
	end
	
	local upper_torso: BasePart = self.rig.UpperTorso
	local neck: Motor6D = upper_torso.Head
	
	if self.follow_target then
		local target_cf: CFrame = self.follow_target.CFrame
		local neck_cf: CFrame = upper_torso.CFrame * headInitial
		local look_at = CFrame.lookAt(neck_cf.Position, target_cf.Position)
		
		local to_object_space = headInitial:Lerp( neck_cf:ToObjectSpace( look_at ), 1/2 )
		neck.C0 = neck.C0:Lerp(headInitial * to_object_space.Rotation, 1/15)
	else
		neck.C0 = neck.C0:Lerp(headInitial, 1/15)
	end
end

return Cannon.new()