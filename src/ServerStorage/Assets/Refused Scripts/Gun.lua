--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local InteractionService = require(ReplicatedStorage.Shared.Services.InteractionService)
local MetallicImpactEffect = require(ReplicatedStorage.Shared.Effects.MetallicImpact)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Variables

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local GunItem = BaseComponent.CreateComponent("GunItem", {
	
	isAbstract = false,
	defaults = {
		FireRate = 11,
	},
	
}, BaseItem) :: BaseItem.Impl

--//Types

export type Fields = {
	
	Muzzle: Attachment,
	
	Attributes: {
		FireRate: number,
	} & BaseItem.ItemAttributes,
	
	_InternalShootEvent: SharedComponent.ClientToServer<Vector3, Vector3>,
	
} & BaseItem.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseItem.Impl)),
	
	CreateEvent: SharedComponent.CreateEvent,
	
	Shoot: (self: Component, origin: Vector3, direction: Vector3) -> (),
	EmitShoot: (self: Component) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool>

--//Methods

function GunItem.Shoot(self: Component, origin: Vector3, direction: Vector3)
	
	local Owner = self:GetOwner() :: Player
	
	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterDescendantsInstances = {Owner.Character, workspace.Temp}
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.RespectCanCollide = true
	RaycastParams.IgnoreWater = true
	
	local Result = workspace:Raycast(origin, direction * 1000, RaycastParams)
	
	if not Result then
		return
	end
	
	local Instance = Result.Instance:FindFirstAncestorWhichIsA("Model")
	local Player = Players:GetPlayerFromCharacter(Instance)
	
	--anim playback
	self.ShootAnimation:Play()
	
	if not Player then
		
		MetallicImpactEffect.new(CFrame.lookAlong(Result.Position, Result.Normal))
			:Start(Players:GetPlayers())
	else
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(Player.Character)
		
		if not WCSCharacter then
			return
		end
		
		WCSCharacter:TakeDamage({
			Source = {
				Name = "Gun",
				Player = Owner,
				Character = WCS.Character.GetCharacterFromInstance(Owner.Character)
			},
			
			Damage = 7
		})
	end
end

function GunItem.EmitShoot(self: Component)
	
	--getting frst free sound
	for _, Sound: Sound in ipairs(self.Handle:GetChildren()) do
		
		if not Sound:IsA("Sound") or Sound.IsPlaying then
			continue
		end
		
		Sound:Play()
		
		break
	end
	
	for _, Descendant in ipairs(self.Handle:GetDescendants()) do
		
		if Descendant:IsA("ParticleEmitter") then
			
			Descendant:Emit(1)
			
		elseif Descendant:IsA("PointLight") then
			
			Descendant.Enabled = true
			
			self.Janitor:Add(task.delay(0.05, function()
				
				if not Descendant then
					return
				end
				
				Descendant.Enabled = false
			end))
		end
	end
end

function GunItem.OnAssumeStartClient(self: Component)
	
	local LastShoot = os.clock()
	
	self.ActiveJanitor:Add(RunService.Heartbeat:Connect(function()
		
		if os.clock() - LastShoot < 1 / self.Attributes.FireRate then
			return
		end
		
		LastShoot = os.clock()
		
		--request to shoot
		self._InternalShootEvent.Fire(
			Camera.CFrame.Position,
			Camera.CFrame.LookVector
		)
	end))
end

function GunItem.OnEquipClient(self: Component)
	self.EquipJanitor:Add(AnimationUtility.QuickPlay(LocalPlayer.Character.Humanoid, self.Instance:FindFirstChild("Hold"), {
		Looped = true,
		Priority = Enum.AnimationPriority.Action3,
	}), "Stop")
end

function GunItem.OnEquipServer(self: Component)
	
	self.ShootAnimation = AnimationUtility.QuickPlay(self.Player.Character.Humanoid, self.Instance:FindFirstChild("Shoot"), {
		Looped = false,
		Priority = Enum.AnimationPriority.Action4,
		PlaybackOptions = {
			Weight = 1000,
		}
	})
end

function GunItem.OnConstructClient(self: Component)
	BaseItem.OnConstructClient(self)
	
end

function GunItem.OnConstructServer(self: Component)
	BaseItem.OnConstructServer(self)
	
	--shooting events connection
	self._InternalShootEvent.On(function(player, cameraPosition, direction)
		
		--only while active
		if not self.Active then
			return
		end
		
		self:Shoot(cameraPosition, direction)
		self:EmitShoot()
	end)
end

function GunItem.OnConstruct(self: Component)
	BaseItem.OnConstruct(self)
	
	self.Muzzle = self.Handle:FindFirstChild("Muzzle")
	
	for x = 1, 30 do
		local Sound = self.Handle:FindFirstChild("Shoot"):Clone() :: Sound
		Sound.Parent = self.Handle
	end
	
	self.Muzzle:FindFirstChild("Flash").Enabled = false
	
	self._InternalShootEvent = self:CreateEvent(
		"InternalShootEvent",
		"Reliable",
		function(...) return typeof(...) == "Vector3" end,
		function(...) return typeof(...) == "Vector3" end
	)
end

--//Returner

return GunItem