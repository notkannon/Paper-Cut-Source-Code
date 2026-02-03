if script.Parent ~= game.Players.LocalPlayer.Character then script:Destroy() end

local character: Model = script.Parent
local hrp: BasePart = character:WaitForChild('Head')
local BodyGyro: BodyGyro = hrp:WaitForChild('@fly_BodyGyro')
local BodyPosition: BodyPosition = hrp:WaitForChild('@fly_BodyPosition')

local camera = workspace.CurrentCamera
local humanoid: Humanoid = character:WaitForChild('Humanoid')


game:GetService("RunService").Stepped:Connect(function()
	local pos = (humanoid.MoveDirection.Magnitude > 0 and humanoid.MoveDirection.Unit or Vector3.zero)
	BodyGyro.CFrame = camera.CFrame.Rotation
	BodyPosition.Position = (camera.CFrame + pos).Position
end)