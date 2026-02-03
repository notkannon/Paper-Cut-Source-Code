--//Service

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

--//Import

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local RoundService = RunService:IsServer() and require(ServerScriptService.Server.Services.RoundService)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local WCS = require(ReplicatedStorage.Packages.WCS)

local Interactable = BaseComponent.GetNameComponents().Interactable

--//Variables
local Animations = ReplicatedStorage.Assets.Animations.Locker
local TeacherAnimations = ReplicatedStorage.Assets.Animations.Teacher
local LockerAssets = ReplicatedStorage.Assets.Locker
local LockerMaster = SoundService.Master.Instances.Locker

local CONTEXTUAL_ICONS = table.freeze({
	Default = 'rbxassetid://18190296811',
	Clock = {
		Sun = 'rbxassetid://18189157731',
		Night = "rbxassetid://18189157476"
	},
})

local BaseSoundEffect = {
	Enter = LockerMaster.Enter.SoundId,
	Leave = LockerMaster.Leave.SoundId
}

local Clock = BaseComponent.CreateComponent("Clock", {
	tag = "Clock",

	predicate = function(Instance: Instance)
		if not Instance:IsA("ProximityPrompt") then
			return false
		end
		
		local DefaultModel = Instance:FindFirstAncestorOfClass("Model")
		
		if not DefaultModel then
			return false
		end
		
		return true
	end,
}) :: Impl


--//Type
export type ClockModel = Model & {
	Border: BasePart & {
		Label: ProximityPrompt,
		minute: Weld,
	},
	
	Face: BasePart,
	Hour_Hand: BasePart,
	Lines: BasePart,
	
	minute: BasePart & {
		Minute_Hand: BasePart,
	}
}

export type Fields = {
	ClockModel: ClockModel,
	DefaultRound: string
}

export type Impl = BaseComponent.ComponentImpl<nil, Fields, "Clock", ProximityPrompt, {}>
export type Component =
	BaseComponent.Component<nil, Fields, "Clock", ProximityPrompt, {}>
& typeof(setmetatable({} :: Interactable.Fields, {} :: Interactable.MyImpl))

--//Methods
function Clock.OnConstruct(self: Component)
	self.ClockModel = self.Instance:FindFirstAncestorOfClass("Model") :: ClockModel
	self.DefaultRound = "Round"	
	
	Interactable.OnConstruct(self)
end

function Clock.OnConstructClient(self: Component)	
	self.Janitor:Add(Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		local SunDirection: Vector3 = Lighting:GetSunDirection()
		local Image = SunDirection.Y < 0 and CONTEXTUAL_ICONS.Clock.Night or CONTEXTUAL_ICONS.Clock.Sun

		if not self.Proximities then
			return
		end

		self.Proximities.Sign.Image = Image
	end))
	
	Interactable.OnConstructClient(self)
end

function Clock.OnConstructServer(self: Component)
	self.Janitor:Add(RoundService.RoundActivationTime:Connect(function(CurrectTime: number)
		local minutes = math.floor(math.fmod(CurrectTime, 3600) / 60)	

		if minutes == 0 and CurrectTime == 0 then
			self.DefaultRound = RoundService:GetRoundActivationState()
		end

		self.Instance.ObjectText = tostring(self.DefaultRound) .. ": ".. tostring(string.format("%02dm : %02ds",minutes,CurrectTime % 60))
		
		self.ClockModel.PrimaryPart.minute.C0 *= CFrame.Angles(0, 0, -math.pi / 60)
		SoundUtility.CreateTemporarySoundAtPosition(self.ClockModel.PrimaryPart.Position, {
			SoundId = SoundService.Master.Instances.Clock.SoundId,
			Volume = .1,
		})
	end))
	
	Interactable.OnConstructServer(self)
end

--//Return
return Clock