local client = shared.Client
local requirements = client._requirements

-- service
local RunService = game:GetService('RunService')
local UserInput = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requiremens
local ProceduralPresets = require(script.Parent.ProceduralPresets)
local SpringModule = require(ReplicatedStorage.Package.SpringModule)

-- var
local OldFrame = CFrame.new()
local SwaySpring = SpringModule.new()

-- const
local PI = math.pi
local RSHOULDER_INITIAL = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local LSHOULDER_INITIAL = CFrame.new(-1, 0.5, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)

-- StudentViewmodel initial
local StudentViewmodel = {}
StudentViewmodel.enabled = false


function StudentViewmodel:SetEnabled( enabled: boolean )
	if enabled == StudentViewmodel.enabled then return end
	local CharacterObject = client.Player.Character
	
	-- undinding if character doesnt exists
	if not CharacterObject then
		RunService:UnbindFromRenderStep('@viewmodel')
		return
	end
	
	local character: Model = CharacterObject.Instance
	local humanoid: Humanoid = CharacterObject:GetHumanoid()
	
	-- warning
	if not character or not humanoid then
		warn('Can`t change viewmodel due character or humanoid doesn`t exists')
		return
	end
	
	-- enabling
	StudentViewmodel.enabled = enabled
	local ArmJoint: Motor6D
	local LArmJoint: Motor6D

	local is_r6 = humanoid.RigType == Enum.HumanoidRigType.R6
	local is_r15 = humanoid.RigType == Enum.HumanoidRigType.R15

	-- getting different arm joinst by humanoid.RigType
	if is_r6 then
		local torso = character.Torso
		ArmJoint = torso:FindFirstChild('Right Shoulder')
		LArmJoint = torso:FindFirstChild('Left Shoulder')
	end

	if not enabled then
		if is_r6 then
			ArmJoint.C0 = RSHOULDER_INITIAL
			LArmJoint.C0 = LSHOULDER_INITIAL
		end
		
		RunService:UnbindFromRenderStep('@viewmodel')
		return
	end

	RunService:BindToRenderStep('@viewmodel', Enum.RenderPriority.Last.Value, function(delta_time)
		if not character then 
			RunService:UnbindFromRenderStep('@viewmodel')
			return
		end
		
		local MouseDelta = UserInput:GetMouseDelta()
		local pos: Vector3 = CharacterObject:GetPosition()
		local ProceduralFrame: CFrame
		
		-- getting offset for movement
		if CharacterObject:HumanoidMoving() then
			ProceduralFrame = ProceduralPresets.Movement(
				math.sqrt(humanoid.WalkSpeed) * 4.5, .3
			)
		else -- getting offset for idling
			ProceduralFrame = ProceduralPresets.Idle(3, .5)
		end

		SwaySpring:shove( Vector3.new(-MouseDelta.X / 500, MouseDelta.Y / 200, 0) )
		local upd: Vector3 = SwaySpring:update(delta_time)

		local relative = workspace.CurrentCamera.CFrame --CFrame.lookAt(RightArm.Position, RightArm.Position + workspace.CurrentCamera.CFrame.LookVector)
		local a = relative:ToObjectSpace(ArmJoint.Parent.CFrame):Inverse()

		local goal = a * CFrame.new(1, -1.3, 0) * CFrame.Angles(0, is_r6 and PI/2 or 0, 0)--RC0 * CFrame.fromEulerAnglesXYZ(_z, _y, _x) * CFrame.new(0, -.5, 0)
		ArmJoint.C0 = ArmJoint.C0:Lerp(goal * CFrame.new(upd.X, upd.Y, upd.Y), 1) * OldFrame

		local a = relative:ToObjectSpace(LArmJoint.Parent.CFrame):Inverse()
		local goal = a * CFrame.new(-1, -1.3, 0) * CFrame.Angles(0, is_r6 and -PI/2 or 0, 0)
		LArmJoint.C0 = LArmJoint.C0:Lerp(goal * CFrame.new(upd.X, upd.Y, upd.Y), 1) * OldFrame
		
		-- smooth presets interpolation
		OldFrame = OldFrame:Lerp(ProceduralFrame, 1/5)
	end)
end

-- complete
return StudentViewmodel