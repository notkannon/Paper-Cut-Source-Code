--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)
local InteractionComponent = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)

local ObjectiveSolvingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.ObjectiveSolving)

local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
--local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

local BaseObjective = require(ReplicatedStorage.Shared.Components.Abstract.BaseObjective)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)


--//Variables

local LocalPlayer = Players.LocalPlayer
local TestPaperUI = BaseComponent.CreateComponent("TestPaperUI", { isAbstract = false, }, BaseUIComponent) :: Impl

--//Types

export type ObjectiveCompletionState = "Success" | "Failed" | "Cancelled"

type ObjectiveState = {
	Players: { Player? },
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl)),

	--CreateEvent: BaseUIComponent.CreateEvent<Component>,
	
	OnConstruct: (self: Component, options: BaseUIComponent.BaseUIComponentConstructOptions?) -> (),
	Hide: (self: Component) -> (),
	Show: (self: Component) -> (),
	UpdateProgress: (self: Component, value: number) -> ()
}

export type Fields = {
	ParentObjective: BaseObjective,
	CurrentProgress: number,
	_Enabled: boolean,
	ProgressBar: Frame,
	FillBar: Frame
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "TestPaperUI", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "TestPaperUI", Instance, any...>

--//Methods

function TestPaperUI.Show(self: Component)
	self.Instance.Visible = true
	self._Enabled = true
	
	self.Instance.CancelHint.TextTransparency = 1
	TweenUtility.ClearAllTweens(self.Instance.CancelHint)
	TweenUtility.PlayTween(self.Instance.CancelHint, TweenInfo.new(3, Enum.EasingStyle.Cubic), {TextTransparency = 0})
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.UI.Objectives.Start
	)
	
	local InputController = Classes.GetSingleton("InputController")
	
	local function UpdateKeyString()
		
		local String = InputController:GetStringsFromContext("Cancel")[1]
		self.Instance.CancelHint.Text = string.format("Press %s to cancel solving", String)
	end
	
	UpdateKeyString()
	
	self.Janitor:Add(InputController.DeviceChanged:Connect(UpdateKeyString), nil, "KeyStringUpdater")
end

function TestPaperUI.Hide(self: Component)
	self.Instance.Visible = false
	self._Enabled = false
	
	self.Janitor:Remove("KeyStringUpdater")
end

function TestPaperUI.UpdateProgress(self: Component, value: number)
	TweenUtility.PlayTween(self.FillBar.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {Offset = Vector2.new(0, 1 - value)})
end

function TestPaperUI.OnConstructClient(self: Component, uiController: unknown, testPaperComponent: Component, ...)
	BaseUIComponent.OnConstructClient(self, uiController, ...)
	
	self._Enabled = false
	self.CurrentProgress = 0
	
	self.ProgressBar = self.Instance.ProgressBar
	self.FillBar = self.ProgressBar.Fill
	
	self.ParentObjective = testPaperComponent
	
	self:Hide()
	self.Janitor:Add(RolesManager.PlayerRoleConfigChanged:Connect(function() self:Hide() end))
end

--//Returner

return TestPaperUI