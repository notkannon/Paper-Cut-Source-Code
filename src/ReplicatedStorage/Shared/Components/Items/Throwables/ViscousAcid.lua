--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerSciptService = game:GetService("ServerScriptService")

--//Imports

local ItemsData = require(ReplicatedStorage.Shared.Data.Items)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local BaseThrowable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseThrowable)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local ViscousAcidPuddleEffect = require(ReplicatedStorage.Shared.Effects.Specific.Components.Items.ViscousAcidPuddle)
local ViscousAcidImpactEffect = require(ReplicatedStorage.Shared.Effects.Specific.Components.Items.ViscousAcidImpact)

--//Variables

local ItemRelatedAssets = ReplicatedStorage.Assets.Items.Related.ViscousAcid
local ViscousAcidItem = BaseComponent.CreateComponent("ViscousAcidItem", {
	
	isAbstract = false,
	
}, BaseThrowable) :: BaseThrowable.Impl

--//Methods

function ViscousAcidItem:OnFlightStart(instance: BasePart, janitor: any, userData: { any })
	BaseThrowable:OnFlightStart(instance, janitor, userData)
	
	local Alignment = instance:FindFirstChild("Alignment")
	
	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = instance
		Alignment.Name = "Alignment"
	end
	
	local Velocity = instance:FindFirstChildWhichIsA("LinearVelocity") :: LinearVelocity?
	
	if not Velocity then
		Velocity = Instance.new("LinearVelocity")
		Velocity.Parent = instance
		Velocity.MaxForce = 2000
		Velocity.Attachment0 = Alignment
		Velocity.VectorVelocity = userData.Direction * math.max(0.3, userData.Strength) * 110
		Velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	end
	
	local Gravity = math.clamp(1 - userData.Strength, 0.3, 1)

	janitor:Add(RunService.Stepped:Connect(function(_, deltaTime)
		
		instance.AssemblyAngularVelocity = Vector3.one * instance.AssemblyLinearVelocity.Magnitude / 15

		Velocity.VectorVelocity = Vector3.new(
			Velocity.VectorVelocity.X,
			Velocity.VectorVelocity.Y - Gravity * deltaTime,
			Velocity.VectorVelocity.Z
		)
	end))
end

function ViscousAcidItem:OnHit(raycastResult: RaycastResult, playerHit: Player?)
	
	if RunService:IsServer() then
		
		ViscousAcidImpactEffect.new(raycastResult.Position):Start(Players:GetPlayers())
		
		if RunService:IsStudio() then
			
			local Att = Instance.new("Attachment")
			Att.Parent = workspace.Terrain
			Att.Visible = true
			Att.WorldPosition = raycastResult.Position
			
			Debris:AddItem(Att, 10)
		end
		
		local RaycastParams = RaycastParams.new()
		RaycastParams.FilterDescendantsInstances = {workspace.Temp, workspace.Characters}
		RaycastParams.RespectCanCollide = true
		RaycastParams.CollisionGroup = "Projectiles"
		RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local Area = ItemRelatedAssets.SlowingArea:Clone()
		local GroundCheckOrigin = raycastResult.Position + (playerHit and Vector3.zero or raycastResult.Normal * Area.Size.X / 2)
		local Ground = workspace:Raycast(GroundCheckOrigin, Vector3.yAxis * -10)
		
		if not Ground then
			return
		end
		
		if RunService:IsStudio() then
			
			local Att2 = Instance.new("Attachment")
			Att2.Parent = workspace.Terrain
			Att2.Visible = true
			Att2.WorldPosition = Ground.Position
			
			Debris:AddItem(Att2, 10)
		end
		
		
		--creating slowing area for a while
		local AreaPosition = Ground.Position + Vector3.yAxis * Area.Size.Z / 2
		
		Area.Parent = workspace
		Area.CFrame = CFrame.lookAlong(
			AreaPosition,
			Vector3.new(0,1,0) -- USED TO BE "Ground.Normal" // Changed by Orangish
		)
		
		ViscousAcidPuddleEffect.new(CFrame.lookAlong(Ground.Position, Ground.Normal)):Start(Players:GetPlayers())
		
		--cleanup
		task.delay(15, function()
			if Area then
				Area:Destroy()
			end
		end)
	end
end

--//Returner

return ViscousAcidItem