--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseCamera = require(ReplicatedStorage.Client.Classes.BaseCamera)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local Promise = require(ReplicatedStorage.Packages.Promise)

--//Types

export type Impl = {
	__index: typeof(setmetatable({} :: Impl, {} :: BaseCamera.Impl)),

	new: (controller: {any}) -> Singleton,
}

export type Fields = {
	CurrentIndex: number,
} & BaseCamera.Fields

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Variables

local Camera = workspace.CurrentCamera
local ResultAttachedCamera = BaseCamera.CreateCamera("ResultAttachedCamera") :: Impl

--//Methods

function ResultAttachedCamera.OnConstruct(self: Singleton)
	self.CurrentIndex = 0
end

function ResultAttachedCamera.OnStart(self: Singleton)
	local Map = workspace:FindFirstChild("Map") :: Model
	local Views = Map.Views :: Folder
	if #Views:GetChildren() == 0 then
		return
	end
	
	local RandomCinematic = Views:GetChildren()[math.random(1, #Views:GetChildren())] :: Folder
	if #RandomCinematic:GetChildren() == 0 then
		return
	end
	
	local function getSortedPoints()
		local Points = {}

		for _, Point in ipairs(RandomCinematic:GetChildren()) do
			table.insert(Points, Point)
		end

		table.sort(Points, function(a, b)
			local na = tonumber(a.Name:match("%d+")) or 0
			local nb = tonumber(b.Name:match("%d+")) or 0
			return na < nb
		end)

		return Points
	end

	local function CinematicPointTo(From: Part, To: Part, Duration: number)
		local TweenInfo = TweenInfo.new(Duration, Enum.EasingStyle.Linear)
		
		-- perserving the angle of the camera is looking at
		local StartCFrame = CFrame.new(From.Position) * CFrame.Angles(Camera.CFrame:ToEulerAnglesXYZ())
		Camera.CFrame = StartCFrame
		
		local LookAtCFrame = CFrame.new(From.Position, To.Position)
		
		self.Janitor:AddPromise(Promise.new(function(resolve, reject)
			self.Janitor:Add(TweenUtility.TweenStep(TweenInfo, function(t)
				-- calculate position as a usual tween
				local NewPos = From.CFrame:Lerp(To.CFrame, t).Position
				
				-- we want camera to always take <=0.25 seconds to rotate
				local AbsoluteTime = t * Duration
				local RotateTime = 0.25
				
				local RotationAlpha = math.max(t, AbsoluteTime)/RotateTime
				local TrueRotationAlpha = TweenService:GetValue(RotationAlpha, Enum.EasingStyle.Quad, Enum.EasingDirection.In) -- we can apply different easing style to rotation

				-- so we adjust angle much faster, depending on that
				local aX, aY, aZ = StartCFrame:Lerp(LookAtCFrame, math.clamp(TrueRotationAlpha, 0, 1)):ToEulerAnglesXYZ()

				-- build final CFrame and apply to camera
				local FinalCFrame = CFrame.new(NewPos) * CFrame.Angles(aX, aY, aZ)
				Camera.CFrame = FinalCFrame
			end, resolve))
		end)):expect()
		
	end
	
	local Points = getSortedPoints()
	local Count = #Points
	
	local function getDistances()
		local Total = 0

		for i = 1, #Points - 1 do
			Total += (Points[i].Position - Points[i + 1].Position).Magnitude
			--print("Cinematic Sequences Points")
			--print(`Point {i}: {Points[i].Position}\n Point {i+1}: {Points[i + 1].Position}`)
		end

		return Total
	end

	if Count <= 0 then
		return
	end
	
	--setting variables
	local TotalDistance = getDistances()
	local StartFrame = Points[1].CFrame :: Part
	
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = StartFrame
	
	
	-- use timeofloop
	--local TimeOfLoop = 45 -- show all points in 45 seconds
	--local Speed = TotalDistance / TimeOfLoop
	
	-- or just constant speed
	local Speed = 10
	
	-- separate thread so the function is non-blocking
	-- and can be turned off with janitor
	self.Janitor:Add(task.spawn(function()
		for i = 2, Count do
			local Point = Points[i]
			local LastPoint = Points[i - 1]
			local NextPoint = Points[i]
			local Distance = (LastPoint.Position - Point.Position).Magnitude -- dear chatgpt, help me?

			local Duration = Distance / Speed
			--print(`Distance: {Distance}, Duration: {Duration}`)

			CinematicPointTo(LastPoint, Point, Duration)
			--print(`Moving to point {i} - {Point.Name} - {Distance} - {Duration}`)
			
			if self.Janitor.CurrentlyCleaning then
				break
			end -- on lobby, when its end the result phase, we cant rotate the camera :skull: and the janitor doesnt clean up, or well this still will run but doesnt destroy it :evilcat:
		end
	end))
	
end

function ResultAttachedCamera.OnEnd(self: Singleton)
	Camera.CameraType = Enum.CameraType.Custom
	self.Janitor:Cleanup() --idk if will works :skull:
end

--//Returner

return ResultAttachedCamera