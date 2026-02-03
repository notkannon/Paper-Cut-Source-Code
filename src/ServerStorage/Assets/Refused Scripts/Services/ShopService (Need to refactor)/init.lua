--@YSH122331, @Edugamen_YT, JustYSH, DevEdugamen Version: 1.0.0
--from Cannon: guys, why this module wrote without components? Sure, lets leave it to future
--//Service

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local ClientRemote = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes)
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes)

--//Import

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local RoundSettings = require(ReplicatedStorage.Shared.Data.RoundSettings)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local CannonSellerModule = require(script:FindFirstChild("Cannon"))
local IkeSellerModule = require(script.Ike)

--//Varible

local LocalPlayer = Players.LocalPlayer
local Instances = SoundService.Master.Instances
local MusicTweenInfo = TweenInfo.new(.5)


local Musics = {
	Intermission = SoundService.Master.Music.Intermission,
	Shop = SoundService.Master.Music.Shop
}

local ShopService = {
	Door = workspace.Map.Shop.Door,
	Cannon = require(script.Cannon),

	SOUNDS_SHOP = {
		sound_close = Instances.Shop.shop_close,
		sound_open = Instances.Shop.shop_open
	}
}
ShopService.__index = ShopService



--//Functions

function PlayTrack(Track: string)
	
	CannonSellerModule:PlayTrack(Track)
	IkeSellerModule:PlayTrack(Track)
end

function Update(status: boolean)
	CannonSellerModule:Update(status)
	IkeSellerModule:Update(status)
end

--//Methods
function ShopService.new()
	
	local self = setmetatable({
		
		Player = LocalPlayer, -- Player
		Character = nil,
		
		hitbox = workspace.Map.Shop.Hitbox, -- type parent hitbox
		player_entered = false, -- type enter player hitbox
		Door = workspace.Map.Shop.Door,
		janitor = Janitor.new(),
		
		Active = {
			Value = true,
			TimeLimite = tick(),
		},
		Cooldown = {
			Tick = tick(),
			Value = 1,
		},
		
		InsideBox = false,
		EffectEmit = 15, -- when the shop closed there effect spawn
		TypeDoor = "opened",
		GetTouchingParts = {} :: {BasePart},
		OverlapParamsBox = OverlapParams.new()
	}, ShopService)
	
	self.OverlapParamsBox.FilterType = Enum.RaycastFilterType.Include
	self.OverlapParamsBox.FilterDescendantsInstances = {workspace.Characters}
	
	self:Init()
	return ShopService
end

function ShopService:IsActive()
	return self.Active.Value or false
end

function ShopService:SetSound( Sound: Sound,Tween: TweenInfo, PlaybackSpeed )
	assert(Sound, "The sound should be sent but it is missing. (one of the values null)")
	
	TweenUtility.PlayTween(
		Sound,
		Tween or MusicTweenInfo,
		{PlaybackSpeed = PlaybackSpeed or 0}
	)
end

function ShopService:AnimateDoor( State: boolean )
	
	if State then
		
		ShopService.SOUNDS_SHOP.sound_open:Play()

		local pos = Vector3.new(42.75, 11.5, 45.1)
		TweenUtility.PlayTween(ShopService.Door, TweenInfo.new(
			1,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out), {
				Position = pos
			}
		)
				
	else
		ShopService.SOUNDS_SHOP.sound_close:Play()

		local pos = Vector3.new(42.133, 6.143, 45.1)
		TweenUtility.PlayTween(ShopService.Door, TweenInfo.new(
			.45,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out), {
				Position = pos
			}
		)
		
		task.delay(.45, function()
			workspace.Map.Shop.Effect.ParticleEmitter:Emit(15)
		end)
		
	end
	
end


function ShopService:SetMusic( boolean: boolean )
	if boolean then
		self:SetSound( Musics.Shop, MusicTweenInfo, 1 )
		self:SetSound( Musics.Intermission, MusicTweenInfo, 0 )
	else
		self:SetSound( Musics.Shop, TweenInfo.new(3), 0 )
		self:SetSound( Musics.Intermission, MusicTweenInfo, 1 )
	end
end

function ShopService:Init()
	if not Musics.Shop.IsPlaying then Musics.Shop:Play() end
	
	self.janitor:Add(Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		self.Active.Value = (Lighting.ClockTime == RoundSettings.DaysTime.Night.ClockTime)
		
		if math.floor(Lighting.ClockTime) == math.floor(RoundSettings.DaysTime.Morning.ClockTime) then
			self.TypeDoor = "opened"
			ShopService:AnimateDoor( true )
			PlayTrack("opened")

			Musics.Shop.TimePosition = 0
			self.Active.TimeLimite = tick()
			PlayTrack("idling")
			
		elseif math.floor(Lighting.ClockTime) == math.floor(RoundSettings.DaysTime.Night.ClockTime) then
			self.TypeDoor = "closed"
			PlayTrack("closed")

			self.Active.TimeLimite = tick()
		end
		
	end))
	
	if RunService:IsClient() then
		local HitBox = coroutine.create(function()
			
			self.janitor:Add(RunService.Stepped:Connect(function()
				if math.abs(os.difftime(self.Cooldown.Tick, tick())) < self.Cooldown.Value then
					return
				end
				
				self.Cooldown.Tick = tick()
				self.GetTouchingParts = workspace:GetPartBoundsInBox(self.hitbox.CFrame, self.hitbox.Size, self.OverlapParamsBox)
				
				self.InsideBox = false
				self.Character = self.Player.Character or self.Player.CharacterAdded:Wait()
				
				if table.find(self.GetTouchingParts, self.Character.Head) then
					self.InsideBox = true
					
					CannonSellerModule:SetFollowTarget(self.Character.Head)
					CannonSellerModule:Update(true)
					
					if self:IsActive() then
						if self.TypeDoor == "opened" then
							self:SetMusic( true )
							
						elseif self.TypeDoor == "closed" then
							self:SetMusic( false )
							
						end
					end 
				else
					CannonSellerModule:SetFollowTarget(nil)
					self:SetSound( Musics.Shop, MusicTweenInfo, 0 )
					self:SetSound( Musics.Intermission, MusicTweenInfo, 1 )
				end
				
				
				
			end))

		end)
		
		local LookCamera = coroutine.create(function()

			self.janitor:Add(RunService.Stepped:Connect(function()
				
				if self.InsideBox == true then
					CannonSellerModule:SetFollowTarget(self.Character.Head)
					CannonSellerModule:Update(true)
				else
					CannonSellerModule:SetFollowTarget(nil)
					CannonSellerModule:Update(false)
				end
				
				if self:IsActive() then
					CannonSellerModule:Update(true)
				else
					CannonSellerModule:Update(false)
				end
			end))
		end)
		
		
		coroutine.resume(HitBox)
		coroutine.resume(LookCamera)
	end
end

return ShopService