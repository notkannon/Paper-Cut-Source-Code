--//Services

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--//Variables

local DebrisFolder = Workspace.Temp

--//Functions

local function Create(origin: CFrame, size: Vector3 | number, lifeTime: number?)
	local IsNumber = typeof(size) == "number"
	local Part = Instance.new("Part")

	Part.Name = "Debugger"
	Part.Material = Enum.Material.ForceField
	Part.Shape = IsNumber and Enum.PartType.Ball or Enum.PartType.Block
	Part.Size = IsNumber and Vector3.one * size or size
	Part.CFrame = origin
	Part.CanCollide = false
	Part.Anchored = true
	Part.Color = RunService:IsServer() and Color3.fromRGB(133, 255, 137) or Color3.fromRGB(125, 210, 255)
	Part.Transparency = 0.95
	Part.Parent = DebrisFolder

	if lifeTime then
		Debris:AddItem(Part, lifeTime)
	end

	return Part
end

local function Box(origin: CFrame, size: Vector3 | number, lifeTime: number?)
	return Create(origin, size, lifeTime)
end

local function Sphere(origin: CFrame, size: Vector3 | number, lifeTime: number?)
	local Size = typeof(size) == "Vector3" and size.Magnitude or size
	local Part = Create(origin, Vector3.one * size, lifeTime)
	
	Part.Shape = Enum.PartType.Ball
	
	return Part
end

local function Raycast(origin: Vector3, result: RaycastResult, lifeTime: number?)
	local Part = Instance.new("Part")
	Part.Name = "Debugger"
	Part.Material = Enum.Material.ForceField
	Part.Size = Vector3.new(0.1, 0.1, result.Distance)
	Part.CFrame = CFrame.new(origin, result.Position) * CFrame.new(0, 0, -result.Distance / 2)
	Part.CanCollide = false
	Part.Anchored = true
	Part.Color = Color3.fromRGB(255, 112, 112)
	Part.Transparency = 0.7
	Part.Parent = DebrisFolder

	if lifeTime then
		Debris:AddItem(Part, lifeTime)
	end

	return Part
end

--//Returner

return {
	Box = Box,
	Sphere = Sphere,
	Raycast = Raycast,
}