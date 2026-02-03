--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Utility = require(ReplicatedStorage.Shared.Utility)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local RandomUtility = require(ReplicatedStorage.Shared.Utility.Random)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Constants

local DAMAGE_ROTATE_SCALE = 0.1

--//Variables

local DoorDamage = Refx.CreateEffect("DoorDamage") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Instance: Highlight,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Model>
export type Effect = Refx.Effect<MyImpl, Fields, Model>

--//Methods

function DoorDamage.OnConstruct(self: Effect)
	self.DestroyOnEnd = true
end

function DoorDamage.OnStart(self: Effect, instance: Model)
	
	local DoorComponent = ComponentsUtility.GetComponentFromDoor(instance)
	local InitialCFrames = DoorComponent.InitialCFrames
	
	--sound playback
	SoundUtility.CreateTemporarySound(
		SoundUtility.GetRandomSoundFromDirectory(
			SoundUtility.Sounds.Instances.Doors.Damage
		)
	).Parent = instance.Root

	-- Проверяем наличие HingeA и HingeB перед анимацией
	local hingeA = instance:FindFirstChild("HingeA") and instance.HingeA.Door:FindFirstChild("Hinge")
	local hingeB = instance:FindFirstChild("HingeB") and instance.HingeB.Door:FindFirstChild("Hinge")

	-- Прерываем все текущие твины
	if hingeA then TweenUtility.ClearAllTweens(hingeA) end
	if hingeB then TweenUtility.ClearAllTweens(hingeB) end

	-- Добавляем случайное отклонение
	if hingeA then
		hingeA.CFrame *= CFrame.Angles(
			RandomUtility:NextNumber(-DAMAGE_ROTATE_SCALE, DAMAGE_ROTATE_SCALE),
			RandomUtility:NextNumber(-DAMAGE_ROTATE_SCALE, DAMAGE_ROTATE_SCALE),
			RandomUtility:NextNumber(-DAMAGE_ROTATE_SCALE, DAMAGE_ROTATE_SCALE)
		)
	end

	if hingeB then
		hingeB.CFrame *= CFrame.Angles(
			RandomUtility:NextNumber(-DAMAGE_ROTATE_SCALE, DAMAGE_ROTATE_SCALE),
			RandomUtility:NextNumber(-DAMAGE_ROTATE_SCALE, DAMAGE_ROTATE_SCALE),
			RandomUtility:NextNumber(-DAMAGE_ROTATE_SCALE, DAMAGE_ROTATE_SCALE)
		)
	end

	-- Плавный возврат в начальное положение
	if hingeA then
		TweenUtility.PlayTween(hingeA, TweenInfo.new(math.random(5, 15)/10, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {CFrame = InitialCFrames[hingeA]})
	end

	if hingeB then
		TweenUtility.PlayTween(hingeB, TweenInfo.new(math.random(5, 15)/10, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {CFrame = InitialCFrames[hingeB]})
	end
end

--//Returner

return DoorDamage