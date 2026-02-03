-- //Service
--[[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- //Import

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local Classes = require(ReplicatedStorage.Shared.Classes)

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local PromptTypes = RunService:IsServer() and require(ServerScriptService.Server.Types.PromptTypes)
local RoundService = RunService:IsServer() and require(ServerScriptService.Server.Services.RoundService)

local Interactable = BaseComponent.GetNameComponents().Interactable

-- //Varible

local ClockManager: PromptType.Service = Classes.CreateSingleton("BaseClock") :: PromptType.ServiceImpl

-- //Method 

function ClockManager.OnConstruct(self: PromptTypes.Service)
	
	self.ClockParent = workspace.Map.Clock
	self.CurrentCountdown = script.Parent
	self.Tag = CollectionService:GetTagged("Label")
	
	self.Ended = false
--	self.RoundStats = RunService:IsServer() and RoundService.GetRoundActivationState()
end

function ClockManager.OnChange(self: PromptTypes.Service, Prompt: ProximityPrompt)	
	if self.Ended or self.RoundStats == "Loading" then
		self.Ended = false
	--	self.RoundStats = RunService:IsServer() and RoundService.GetRoundActivationState()
	end
	
	local clock = Prompt:FindFirstAncestorOfClass("Model")
	clock.PrimaryPart.minute.C0 *= CFrame.Angles(0, 0, -math.pi / 60)
	
	SoundUtility.CreateTemporarySoundAtPosition(clock.PrimaryPart.Position, {
		SoundId = SoundService.Master.Instances.Clock.SoundId,
		Volume = .1,
	})
	
	local secondsLeft = (self.CurrentCountdown:GetAttribute("CurrentCountdown") or 0)
	local minutes = math.floor(math.fmod(secondsLeft, 3600) / 60)	
	
	if minutes == 0 and secondsLeft == 0 then
		self.Ended = true
	end
	
	Prompt.ActionText = tostring("Round") .. ": ".. tostring(string.format("%02dm : %02ds",minutes,secondsLeft % 60))
end

function ClockManager.OnConstructClient(self: PromptTypes.Service)	
	
	for _, PromptLabel in pairs(self.Tag) do
		if not PromptLabel:IsA("ProximityPrompt") then continue end
		if not PromptLabel:IsDescendantOf(self.ClockParent) then continue end
		
		local Info = Interactable.OnConstruct({
			Instance = PromptLabel,
			Janitor = Janitor.new()
		})
		
		print(Info)
		Interactable.OnConstructClient(Info)
--		self.RoundStats = RoundService.GetRoundActivationState()
		self.CurrentCountdown:GetAttributeChangedSignal("CurrentCountdown"):Connect(function() self:OnChange( PromptLabel ) end)
	end
end

--//Return

local Singleton = ClockManager.new()
return Singleton

--]]

return 0