local client = shared.Client
assert( client, 'Attempt to require client module' )

-- requirements
local Util = client._requirements.Util
local RunServuce = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

local Sprites = {
	Eye = {
		normal = 'rbxassetid://17442985322',
		scared = 'rbxassetid://17433607370',
		blink = 'rbxassetid://17442985444',
		sleep = 'rbxassetid://17443782797',
	},

	Face = {
		normal = 'rbxassetid://17433357367',
		smile = 'rbxassetid://17433741537',
		pain = 'rbxassetid://17433530136',
		sleep_mouth_closed = 'rbxassetid://17443796436',
		sleep_mouth_opened = 'rbxassetid://17443772473'
	}
}


local headInitial = CFrame.new(0, 1.025, 0.048)


-- class initial
local Ike = {} do
	Ike.__index = Ike
	Ike._objects = {}
	
	function Ike.new()
		local rig: Model = workspace.Map.Shop.Sellers:FindFirstChild('Ike')
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
			
			connections = {},
			tracks = {},
			
			time_offset = 0 -- could be used to make unsynchronized animations
		}, Ike)
		
		table.insert(
			self._objects,
			self)
		self:Init()
		return self
	end
end

-- loading animations to the rig
function Ike:Init()
	local animator: Animator = self.rig.Humanoid.Animator
	local tracks = self.tracks
	
	tracks.idling = animator:LoadAnimation(script.Idling)
	tracks.closed = animator:LoadAnimation(script.Closed)
	tracks.closed.Priority = Enum.AnimationPriority.Action4
	
	self:PlayTrack( 'idling' )
end


function Ike:PlayTrack( name: string )
	if name == 'closed' then
		self.tracks.idling:Stop()
		self.tracks.closed:Play()
		
		self:ApplyFace('pain')
		self.tracks.closed.Stopped:Once(function()
			self:ApplyFace( nil )
		end)
		
		-- animation keyframe reached event connect
		self.tracks.closed:GetMarkerReachedSignal('face'):Once(function() self:ApplyFace('ngaahh') end)
		
	elseif name == 'idling' then
		self.tracks.idling:Play()
		
		for _, conn: RBXScriptConnection? in ipairs(self.connections) do
			conn:Disconnect()
		end
		
		local a: RBXScriptConnection = self.tracks.idling:GetMarkerReachedSignal('face1'):Connect(function() self:ApplyFace('face1') end)
		local b: RBXScriptConnection = self.tracks.idling:GetMarkerReachedSignal('face2'):Connect(function() self:ApplyFace('face2') end)
		table.insert(self.connections, a)
		table.insert(self.connections, b)
	end
end


function Ike:ApplyFace( name: string )
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
		
	elseif name == 'pain' then
		self.current_face = 'pain'
		self.tweens.eye_change:Play()
		self.tweens.face_change:Play()
		eye_img.Texture = Sprites.Eye.normal
		face_img.Texture = Sprites.Face.pain
		
	elseif name == 'ngaahh' then
		self.current_face = 'ngaahh'
		self.tweens.eye_change:Play()
		eye_img.Texture = Sprites.Eye.scared
		face_img.Texture = Sprites.Face.pain
		
	elseif name == 'face1' then
		self.current_face = 'face1'
		self.tweens.face_change:Play()
		eye_img.Texture = Sprites.Eye.sleep
		face_img.Texture = Sprites.Face.sleep_mouth_opened
		
	elseif name == 'face2' then
		self.current_face = 'face2'
		self.tweens.face_change:Play()
		eye_img.Texture = Sprites.Eye.sleep
		face_img.Texture = Sprites.Face.sleep_mouth_closed
	else
		self.current_face = nil
		face_img.Texture = Sprites.Face.normal
	end
end


function Ike:ApplyEmote()
	
end


function Ike:SetFollowTarget( target: BasePart? )
	if not target then
		self.follow_target = nil
		return
	end
	
	assert( target:IsA('BasePart'), 'Provided follow part is not BasePart' )
	self.follow_target = target
end


function Ike:Update()
	--[[if tick() - self.last_blink_time > self.next_blink_delay then
		self.last_blink_time = tick()
		self.next_blink_delay = math.random(7, 17)/7.5
		
		self:ApplyFace( 'blink' )
	end]]
	
	--[[local upper_torso: BasePart = self.rig.UpperTorso
	local neck: Motor6D = upper_torso.Head
	
	if self.follow_target then
		local target_cf: CFrame = self.follow_target.CFrame
		local neck_cf: CFrame = upper_torso.CFrame * headInitial
		local look_at = CFrame.lookAt(neck_cf.Position, target_cf.Position)
		
		local to_object_space = headInitial:Lerp( neck_cf:ToObjectSpace( look_at ), 1/2 )
		neck.C0 = neck.C0:Lerp(headInitial * to_object_space.Rotation, 1/15)
	else
		neck.C0 = neck.C0:Lerp(headInitial, 1/15)
	end]]
end

return Ike.new()