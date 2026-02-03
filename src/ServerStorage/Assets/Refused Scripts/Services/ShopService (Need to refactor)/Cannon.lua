

-- requirements
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
		local eye_template = rig:FindFirstChild('Eye') 
		local face_template = rig:FindFirstChild('Face') :: BasePart
		
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
			
			if self.tracks.idling.IsPlaying then
				self.tracks.idling:Stop()
			end
		end)
		
		-- animation keyframe reached event connect
		self.tracks.idling:Stop()

		self.tracks.closed:GetMarkerReachedSignal('face'):Once(function() self:ApplyFace('smile') end)
		self.tracks.closed:GetMarkerReachedSignal('door'):Once(function() require(script.Parent):AnimateDoor( false ) end)
		
	elseif name == 'idling' then
		if game.Lighting:GetSunDirection().Y < 0 then return end
		self.tracks.idling:Play()
		self:ApplyFace( nil )

	elseif name == 'opened' then
		self:ApplyFace('smile')
		self.tracks.idling:Stop()
		self:ApplyFace( nil )

		self.tracks.closed:Play( nil, nil, -1 )
		self.tracks.closed.Stopped:Connect(function()
			self:ApplyFace( "normal" )
			self:PlayTrack("idling")
		end)
	end
end


function Cannon:ApplyFace( name: string )
	local face = self.face :: BasePart
	local eye = self.eye :: BasePart
	local face_img = face.Img :: Decal
	local eye_img = eye.Img :: Decal
	
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
	elseif name == "normal" then
		self.current_face = 'normal'
		eye_img.Texture = Sprites.Eye.normal
		face_img.Texture = Sprites.Face.normal
	
	else
		self.current_face = nil
		face_img.Texture = Sprites.Face.normal
	end
end


function Cannon:ApplyEmote()
	
end


function Cannon:SetFollowTarget( target: BasePart? )
	if not target then
		--Reset the head (0, 90, 0)
		self.follow_target = nil
		local upper_torso = self.rig.UpperTorso :: BasePart
		local neck = upper_torso.Head :: Motor6D
		neck.C0 = headInitial
		return
	end
	
	assert( target:IsA('BasePart'), 'Provided follow part is not BasePart' )
	self.follow_target = target
	--follow the player head
end


function Cannon:Update(update: boolean)
	if not self.rig then return end
	if update then
		if tick() - self.last_blink_time > self.next_blink_delay then
			self.last_blink_time = tick()
			self.next_blink_delay = math.random(7, 17)/7.5

			self:ApplyFace( 'blink' )
		end

		local upper_torso = self.rig.UpperTorso :: BasePart
		local neck = upper_torso.Head :: Motor6D

		if self.follow_target then
			local target_cf: CFrame = self.follow_target.CFrame
			local neck_cf: CFrame = upper_torso.CFrame * headInitial
			local look_at = CFrame.lookAt(neck_cf.Position, target_cf.Position)

			local to_object_space = headInitial:Lerp( neck_cf:ToObjectSpace( look_at ), 1/2 )
			neck.C0 = neck.C0:Lerp(headInitial * to_object_space.Rotation, 1/15)
		else
			neck.C0 = neck.C0:Lerp(headInitial, 1/15)
		end
	else
		if self.follow_target then
			--Reset the head (0, 90, 0)
			local upper_torso = self.rig.UpperTorso :: BasePart
			local neck = upper_torso.Head :: Motor6D
			neck.C0 = neck.C0:Lerp(headInitial, 1/15)
		end
	end
end

return Cannon.new()