--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseObjective = require(ReplicatedStorage.Shared.Components.Abstract.BaseObjective)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local Utility = require(ReplicatedStorage.Shared.Utility)
local UIAssets = ReplicatedStorage.Assets.UI

local TestPaperEffect = require(ReplicatedStorage.Shared.Effects.Specific.Objectives.TestPaper)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
--local Reflex = if RunService:IsClient() then require(ReplicatedStorage.Client.Components.UIAssignable.Objectives.TestPapers.Reflex) else nil

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes)


--//Variables

local LocalPlayer = Players.LocalPlayer
local TestPaper = BaseComponent.CreateComponent("TestPaper", {
	
	tag = "PaperTestObjective",
	isAbstract = false,
	defaults = {
		
	},

}, BaseObjective) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseObjective.MyImpl)),
	
	OnConstruct: (self: Component, any...) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
	
	ServeNextSubObjective: (self: Component) -> (),
	_InitSubObjectives: (self: Component) -> ()
} & BaseObjective.MyImpl

export type Fields = {
	_CompletedSubObjectives: number,
	_TotalSubObjectives: number,
	_InternalStartCallback: SharedComponent.ServerToClient<number>,
	_InternalSubObjectiveCallback: SharedComponent.ClientToServer<number, string>,
	_SubObjectiveNames: table<string>
} & BaseObjective.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "TestPaper", BasePart, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "TestPaper", BasePart, any...>

--//Methods

function TestPaper.ServeCurrentSubObjective(self: Component)
	assert(RunService:IsClient())
	
	self:UpdateProgressBar()
	
	
	local NextSubObjective = self.SubObjectives[self._CompletedSubObjectives+1]
	assert(NextSubObjective)
	
	--print('serving subobjective', self._CompletedSubObjectives)
	
	
	NextSubObjective:Show()
	NextSubObjective:Start()
end

function TestPaper.UpdateProgressBar(self: Component) -- ReplicatedStorage\Client\uic
	self.UI:UpdateProgress(self._CompletedSubObjectives/self._TotalSubObjectives)
end

function TestPaper.OnConstruct(self: Component)
	self.Cooldown = 5 -- 5 seconds CD if you fail/cancel
	self.DestroyDelay = 5 -- instance remains for 5 seconds after success, then dies
	
	self._CompletedSubObjectives = 0
	self._TotalSubObjectives = 5
	self.IsSoloObjective = true
	
	-- scary SharedComponent magic
	BaseObjective.OnConstruct(self, {
		Sync = { "_CompletedSubObjectives", "_SubObjectiveNames" },
		SyncOnCreation = true
	})
	
	self._InternalStartCallback = self:CreateEvent(
		"InternalStartCallback",
		"Reliable",
		
		function(...) return typeof(...) == "Instance" end
	)
	
	self._InternalSubObjectiveCallback = self:CreateEvent(
		"InternalSubObjectiveCallback",
		"Reliable",
		
		function(...) return typeof(...) == "number" end,
		function(...) return typeof(...) == "string" end
	)
	
	--interaction stuff
	Utility.ApplyParams(self.Interaction.Instance, {
		
		ActionText = "Take the test",
		HoldDuration = 0,
		RequiresLineOfSight = true,
		MaxActivationDistance = 11,
		
	} :: ProximityPrompt)
end

function TestPaper.HandleSubObjectiveCompletion(self: Component, subObjective: Component, player: Player, state: BaseObjective.ObjectiveCompletionState)
	BaseObjective.HandleSubObjectiveCompletion(self, player, subObjective, state)
	
	subObjective:Hide()
	
	print('sending ', self._CompletedSubObjectives + 1, state)
	self._InternalSubObjectiveCallback.Fire(self._CompletedSubObjectives + 1, state)
	
	
	if state == "Cancelled" or state == "Failed" then
		self:PromptComplete(state)
	elseif state == "Success" then 
		self._CompletedSubObjectives += 1
		-- cleaning old stuff - done in BaseMinigame already
		--local OldSubObjective = self.SubObjectives[self._CompletedSubObjectives] 
		--if not OldSubObjective:IsDestroyed() and not OldSubObjective:IsDestroying() then
		--	OldSubObjective:Destroy()
		--end
		
		if self._CompletedSubObjectives < self._TotalSubObjectives then
			SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.CorrectAnswer)
			self:ServeCurrentSubObjective()
		else
			self:PromptComplete("Success")
		end
	end
end

function TestPaper.AddPlayer(self: Component, player: Player)
	BaseObjective.AddPlayer(self, player)
	--task.defer(function()
	--print('called start callback')
	self._InternalStartCallback.Fire(player, self.Instance)
	--end)
end

function TestPaper._InitSubObjectives(self: Component)
	assert(RunService:IsClient())
	print('init subobjectives')
	
	local UIController = Classes.GetSingleton("UIController")
	local ObjectivesUI = UIController:GetInterface("ObjectivesUI")

	--totally fine to have it all on client, i think
	for i = 1, self._TotalSubObjectives do
		
		-- TODO: remake properly once all minigames are done
		local ImplString = self._SubObjectiveNames[i] .. "TestPaperUI"

		local Component = ObjectivesUI:AddMinigameComponent(self, ImplString)
		--print(Component, 'component')
		self:RegisterSubObjective(Component)
	end
end

function TestPaper.OnConstructServer(self: Component)
	BaseObjective.OnConstructServer(self)
	
	local ObjectivesService = Classes.GetSingleton("ObjectivesService")
	
	
	-- randomizing minigames
	local MinigamesOrder = {"Maze", "Reflex", "ShapeSort", "Memory", "TilePuzzle"}
	local Starters = table.clone(MinigamesOrder)
	table.remove(Starters, table.find(Starters, "Reflex"))
	
	local Starter = Starters[math.random(1, #Starters)]
	table.remove(MinigamesOrder, table.find(MinigamesOrder, Starter))
	
	local FinalOrder = {Starter}
	
	Utility.ShuffleTable(MinigamesOrder)
	
	while #FinalOrder < self._TotalSubObjectives do
		table.insert(FinalOrder, MinigamesOrder[1])
		table.remove(MinigamesOrder, 1)
	end
	
	self._SubObjectiveNames = FinalOrder
	
	
	
	--creating a long effect proxy
	self.Janitor:Add(
		
		TestPaperEffect.new(self.Instance),
		"Destroy",
		"Effect"
		
	):Start(Players:GetPlayers())
	
	--adding players
	self.Janitor:Add(self.Interaction.Started:Connect(function(Player)
		
		--check if player already has objective
		if ObjectivesService:PlayerHasObjective(Player) then
			return
		end
		
		self:AddPlayer(Player)
	end))
	
	self.Janitor:Add(self.Completed:Connect(function(_, status)
		
		
		if status == "Success" then

			SoundUtility.CreateTemporarySoundAtPosition(
				self.Instance.Position,
				SoundUtility.Sounds.UI.Objectives.Success
			)
			self.Janitor:Get("Effect"):MarkSolved()

		elseif status == "Failed" then

			SoundUtility.CreateTemporarySoundAtPosition(
				self.Instance.Position,
				SoundUtility.Sounds.UI.Objectives.Fail
			)
			
			self.Janitor:Get("Effect"):MarkFailed()
		end
	end))
	
	local ProxyService = Classes.GetSingleton("ProxyService")
	self._InternalSubObjectiveCallback.On(function(player: Player, subobjectiveNumber: number, state: BaseObjective.ObjectiveCompletionState)
		print(player, subobjectiveNumber, state)
		
		if state == "Success" then
			self._CompletedSubObjectives = subobjectiveNumber
			print('server recognized objective', self._CompletedSubObjectives, 'has been completed')
			
			-- there is a separate reward for finishing the objective, so lets not do it for the last one
			if subobjectiveNumber < self._TotalSubObjectives then
				ProxyService:AddProxy("SubObjectiveCompleted"):Fire(player, subobjectiveNumber, state)
			end
		end
	end)
end

function TestPaper.OnConstructClient(self: Component)
	BaseObjective.OnConstructClient(self)
	
	print('testpaper constructed client') -- boo 
	
	self.Janitor:Add(self._InternalStartCallback.On(function(instance: Instance)
		if instance ~= self.Instance then
			return
		end
		
		self:SyncClient()
		print(self._CompletedSubObjectives)
		
		if not self.SubObjectives or #self.SubObjectives == 0 then
			self:_InitSubObjectives()
		end
		
		--client cancel conditions
		self.Janitor:Add(RunService.Stepped:Connect(function()

			local Character = LocalPlayer.Character
			local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
			local RootPart = Humanoid and Humanoid.RootPart

			if not RootPart then
				return
			end
			
			if not self.Interaction.Instance then
				return
			end

			--distance check
			if (self.Instance.Position - RootPart.Position).Magnitude <= self.Interaction.Instance.MaxActivationDistance then
				return
			end

			self:PromptComplete("Cancelled")
			self.Janitor:Remove("DistanceCheckSteps")

		end), nil, "DistanceCheckSteps")
		
		if not self.UI then
			local UIController = Classes.GetSingleton("UIController")
			local ObjectivesUI = UIController:GetInterface("ObjectivesUI")

			local UIImpl = self:GetName() .. "UI"

			if ObjectivesUI.Instance then
				print("ui context:", ComponentsManager.Get(ObjectivesUI.Instance.TestPaperUI, UIImpl))
				self.UI = ComponentsManager.Get(ObjectivesUI.Instance.TestPaperUI, UIImpl) or UIController:RegisterInterface(ObjectivesUI.Instance.TestPaperUI, UIImpl, UIController, self)
			else
				warn("Failed to init TestPaperUI! No instance found for ObjectivesUI")
				return
			end
		end

		-- starting test
		self.UI:Show()
		self:ServeCurrentSubObjective()
	end))
	
	self.Janitor:Add(self.Completed:Connect(function(plr, state)
		print(self.UI)
		
		self.UI:Hide()
		
		self.Janitor:Remove("DistanceCheckSteps")

		local CurrentSubObjective = self.SubObjectives[self._CompletedSubObjectives+1]

		if CurrentSubObjective and CurrentSubObjective._InProgress then
			CurrentSubObjective:PromptComplete("Cancelled")
		end
	end))
	
	self.Janitor:Add(ClientRemotes.MatchServiceStartLMS.On(function()
		if self.UI then
			print('removing', self.UI)
			self.UI:Hide()
		end
	end))
end

--//Returner

return TestPaper