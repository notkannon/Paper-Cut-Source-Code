--//Service

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ComponentTypes = require(ServerScriptService.Server.Types.ComponentTypes)
local BaseDestroyable = require(ReplicatedStorage.Shared.Classes.Abstract.BaseDestroyable)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local FinisherData = require(ReplicatedStorage.Shared.Data.FinisherData)

local HandledStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Handled)
local MarkedForDeathStatus = require(ReplicatedStorage.Shared.Combat.Statuses.MarkedForDeath)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local MatchService = require(ServerScriptService.Server.Services.MatchService)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)

--//Constants

local R6_BODYPART_TO_M6D = {
	["Head"] = "Neck",
	["Right Arm"] = "Right Shoulder",
	["Left Arm"] = "Left Shoulder",
	["Left Leg"] = "Legt Hip",
	["Right Leg"] = "Right Hip",
}

--//Variables

local HandlerObjects = {} :: { Handler? }
local FinisherHandler = BaseDestroyable.CreateClass("FinisherHandler") :: MyImpl

--//Type

export type Fields = {

	IsRunning: boolean,

	Killer: Player,
	Victim: Player,

} & BaseDestroyable.Fields

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseDestroyable.MyImpl) ),

	new: (killer: Player, victim: Player) -> Handler,
	Run: (self: Handler) -> (),
	Destroy: (self: Handler) -> (),

	_InitConnections: (self: Handler) -> (),
}

export type Handler = typeof(setmetatable({} :: Fields, {} :: MyImpl))


--//Functions

local function CreateColliderPart(part: BasePart)
	
	local originalMassless = part.Massless

	-- Создаем коллайдер
	local collider = Instance.new("Part")
	collider.Name = "BodyPartCollider"
	collider.Size = part.Size * 1.8  -- Делаем немного больше оригинала
	collider.Shape = Enum.PartType.Ball  -- Сохраняем оригинальную форму
	collider.Transparency = 1
	collider.Anchored = false
	collider.CanCollide = true  -- Включаем коллизии
	collider.Massless = false   -- Важно для физики
	collider.CollisionGroup = "Players"
	collider.Material = Enum.Material.Neon

	-- Настраиваем физические свойства
	collider.CustomPhysicalProperties = PhysicalProperties.new(
		0.5,  -- Плотность (плотность человеческой плоти)
		0.3,  -- Коэффициент трения
		0.5   -- Коэффициент упругости
	)

	-- Позиционируем коллайдер
	collider.CFrame = part.CFrame

	-- Прикрепляем коллайдер к части
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = collider
	weld.Parent = collider

	-- Настраиваем оригинальную часть
	part.CanCollide = true  -- Отключаем коллизии у оригинальной части
	part.Massless = originalMassless

	collider.Parent = part.Parent
	collider:SetNetworkOwner(nil)  -- Только на сервере

	-- Возвращаем коллайдер для возможного дальнейшего использования
	return collider
end

--//Methods

function FinisherHandler._InitConnections(self: Handler)

	--listening to unexpected cases to forcely stop this cutscene

	--death listening
	self.Janitor:Add(MatchService.PlayerDied:Connect(function(player)

		if player == self.PlayerSeek
			or player == self.PlayerHiding then

			self:Destroy()
		end
	end))

	--character removal listening (also player leaving)
	self.Janitor:Add(PlayerService.CharacterRemoved:Connect(function(_, player)

		if player == self.PlayerSeek
			or player == self.PlayerHiding then

			self:Destroy()
		end
	end))

	--detecting round ended thing
	self.Janitor:Add(MatchService.MatchEnded:Once(function(round)
		self:Destroy()
	end))
end

function FinisherHandler.Run(self: Handler)

	if self.IsRunning then
		return
	end

	self.IsRunning = true
	
	--getting finisher config for killer and victim depending on roles (different animations?)
	local KillerRole = MatchService:GetPlayerRoleString(self.Killer)
	local VictimRole = MatchService:GetPlayerRoleString(self.Victim)
	
	local FinisherConfig = FinisherData[KillerRole][VictimRole]
	
	--extracting wcs characters
	local VictimWCSCharacter = WCS.Character.GetCharacterFromInstance(self.Victim.Character)
	local KillerWCSCharacter = WCS.Character.GetCharacterFromInstance(self.Killer.Character)
	
	--making these guys invincible
	self.Janitor:Add(HandledStatus.new(VictimWCSCharacter, "HeadLocked")):Start()
	self.Janitor:Add(HandledStatus.new(KillerWCSCharacter, "HeadLocked")):Start()
	
	--victim will die after finisher ends
	self.Janitor:Add(MarkedForDeathStatus.new(VictimWCSCharacter), nil, "VictimTempAlive"):Start()
	
	--need to:
	--a. Play animations
	--b. probably sounds
	--c. killing victim player (permanently)
	
	--posing
	
	local killerChar = KillerWCSCharacter.Instance :: Model
	local victimChar = VictimWCSCharacter.Instance :: Model
	local killerRoot = killerChar:FindFirstChild("HumanoidRootPart") :: BasePart
	local victimRoot = victimChar:FindFirstChild("HumanoidRootPart") :: BasePart
	local killerPos = killerRoot.Position
	local victimPos = victimRoot.Position
	local distanceBetween = 2
	local killerHeight = 2.1
	
	--anchoring
	killerRoot.Anchored = true
	victimRoot.Anchored = true
	killerRoot.AssemblyLinearVelocity = Vector3.zero
	victimRoot.AssemblyLinearVelocity = Vector3.zero
	
	--grounding killer
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Characters, workspace.Temp}
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.RespectCanCollide = true
	
	local GroundResult = workspace:Raycast(killerPos, Vector3.new(0, -10, 0), Params)
	
	if GroundResult then
		
		--grounding
		killerChar:PivotTo(
			CFrame.new(killerPos.X, GroundResult.Position.Y + killerHeight + killerRoot.Size.Y/2, killerPos.Z)
				* killerChar:GetPivot().Rotation
		)
		
		--updating killer's position
		killerPos = killerRoot.Position
	end
	
	local VictimPosIgnoreY = Vector3.new(
		victimPos.X,
		killerPos.Y,
		victimPos.Z
	)
	
	--facing killer to victim
	killerChar:PivotTo(CFrame.lookAt(killerPos, VictimPosIgnoreY))
	
	local victimTargetPos = killerPos + killerRoot.CFrame.LookVector * distanceBetween
	
	--facing victim to killer + placing him at fixed distance
	victimChar:PivotTo(CFrame.lookAt(victimTargetPos, killerPos))
	
	--Animations
	
	--killer
	local KillerAnimation = self.Janitor:Add(
		AnimationUtility.QuickPlay(
			killerChar:FindFirstChildWhichIsA("Humanoid"),
			FinisherConfig.Animations.Killer, {
				Looped = false,
				Priority = Enum.AnimationPriority.Action4
			}
		)
	)
	
	--Student
	local StudentAnimation = self.Janitor:Add(
		AnimationUtility.QuickPlay(
			victimChar:FindFirstChildWhichIsA("Humanoid"),
			FinisherConfig.Animations.Student, {
				Looped = false,
				Priority = Enum.AnimationPriority.Action4
			}
		)
	)
	
	--sound playback
	local Sounds = SoundUtility.Sounds.Players.Gore.Finishers:FindFirstChild(KillerRole)
	local FinisherSound = Sounds and Sounds:FindFirstChild(VictimRole) or Sounds:FindFirstChild("Student") :: Sound
	
	--playback
	if FinisherSound then
		SoundUtility.CreateTemporarySoundAtPosition(
			killerPos,
			FinisherSound
		)
	end
	
	--ripping bodyparts
	self.Janitor:Add(StudentAnimation:GetMarkerReachedSignal("Rip"):Connect(function(bodypartName: string)

		local Bodypart = victimChar:FindFirstChild(bodypartName) :: BasePart
		
		if not Bodypart then
			return
		end
		
		local Motor = victimChar
			:FindFirstChild("Torso")
			:FindFirstChild(R6_BODYPART_TO_M6D[bodypartName]) :: Motor6D
		
		Motor:Destroy()
		
		Bodypart.AssemblyLinearVelocity *= 10
		
		CreateColliderPart(Bodypart)
	end))
	
	--corpse creation
	self.Janitor:Add(StudentAnimation:GetMarkerReachedSignal("Corpse"):Connect(function()
		
		--marking for death after success animation playback
		if not self.Janitor:Get("VictimTempAlive") then
			return
		end
		
		self.Janitor:Get("VictimTempAlive").IsDead = true
		self.Janitor:Remove("VictimTempAlive") -- killing Student
	end))
	
	--calculating max duation of the cutscene
	local Duration = math.max(
		StudentAnimation.Length,
		KillerAnimation.Length
	)
	
	--unanchoring
	self.Janitor:Add(function()
		
		if killerRoot then
			killerRoot.Anchored = false
		end
		
		if victimRoot then
			victimRoot.Anchored = false
		end
	end)
	
	--destroy after animation ends
	self.Janitor:Add(task.delay(Duration, function()
		
		--finalize with destruction
		self:Destroy()
	end))
end

function FinisherHandler.OnConstructServer(self: Handler, killer: Player, victim: Player)

	self.IsRunning = false

	assert(killer.Character, "No character exists for killer player")
	assert(victim.Character,"No character exists for victome player")

	self.Killer = killer
	self.Victim = victim
	
	print("Created finisher!", victim, killer)

	self:_InitConnections()
end

--//Returner

return {
	new = FinisherHandler.new,
}