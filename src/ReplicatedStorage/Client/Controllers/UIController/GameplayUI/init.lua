--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local Classes = require(ReplicatedStorage.Shared.Classes)
local Utility = require(ReplicatedStorage.Shared.Utility)
local EnumsType = require(ReplicatedStorage.Shared.Enums)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local StatusesUI = require(script.StatusesUI)
local ObjectivesUI = require(script.ObjectivesUI)
local CharacterStatsUI = require(script.CharacterStatsUI)
local ComboUIComponent = require(script.ComboUI)
local SkillsUIComponent = require(script.SkillsUI)
local ActionsUIComponent = require(script.ActionsUI)
local InventoryUIComponent = require(script.InventoryUI)
local ItemChargeUIComponent = require(script.ItemChargeUI)
local TeammatesListUI = require(script.TeammateListUI)
local HideoutUI = require(script.HideoutUI)
local HealingActUI = require(script.HealingAct)

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI.Misc

local GameplayUI = BaseComponent.CreateComponent("GameplayUI", { isAbstract = false }, BaseUIComponent) :: Component

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),

	OnConstructClient: (self: Component, any...) -> (),

	_InitTimer: (self: Component) -> (),
	_InitActions: (self: Component) -> (),
	_InitMiscellaneous: (self: Component) -> (),
}

export type Fields = {
	SkillsUI: SkillsUIComponent.Component,
	InventoryUI: InventoryUIComponent.Component,
	InteractionUI: InteractionUIComponent.Component,

	CharacterComponent: any,

} & BaseUIComponent.Fields

export type Component = BaseComponent.Component<MyImpl, Fields, "GameplayUI", Frame & any, {}>

--//Functions

local function FormatSecondsToMS(seconds)
	local Minutes = math.floor(seconds / 60)
	local Seconds = seconds % 60

	return string.format("%02d:%02d", Minutes, Seconds)
end

--//Methods

function GameplayUI.OnEnabledChanged(self: Component, value: boolean)
	return --doing nothing
end

function GameplayUI._InitMisc(self: Component)
	
	local function CreateHealingUI(component: BaseComponent.Component)

		local Frame = UIAssets.Healing:Clone()
		Frame.Parent = self.Instance.Misc

		--registery
		component.Janitor:Add(
			self.Controller:RegisterInterface(
				Frame,
				HealingActUI,
				self.Controller,
				component
			)
		)
	end
	
	ComponentsManager.ComponentAdded:Connect(function(component)
		
		if component.GetName() ~= "HealingAct" then
			return
		end
		
		CreateHealingUI(component)
	end)
end

function GameplayUI._InitTimer(self: Component)
	
	local Timer = self.Instance.Top.Timer :: Frame
	local TimerLabel = Timer:FindFirstChild("Time") :: TextLabel
	local StatusLabel = Timer:FindFirstChild("Status") :: TextLabel
	
	local function OnCountdownStepped(countdown, reason)
		
		local BaseThumbnailColor = countdown <= 30
			and Color3.fromRGB(126, 35, 54)
			or Color3.fromRGB(76, 93, 107)
		
		local BaseLabelColor = countdown <= 30
			and Color3.fromRGB(226, 114, 116)
			or Color3.fromRGB(112, 142, 150)
		
		local ThumbnailColor
		local LabelColor
		
		if not reason or reason == "CountdownStep" then
			
			-- nothing xd
			
		elseif reason == "ObjectiveSolved" then
			
			ThumbnailColor = Color3.fromRGB(38, 88, 25)
			LabelColor = Color3.fromRGB(71, 135, 68)
			
		elseif reason == "StudentDied" then
			
			ThumbnailColor = Color3.fromRGB(90, 11, 12)
			LabelColor = Color3.fromRGB(172, 32, 34)
		end
		
		Timer.Thumbnail.ImageColor3 = ThumbnailColor or BaseThumbnailColor
		TimerLabel.TextColor3 = LabelColor or BaseLabelColor
		
		if countdown <= 30 then
			TimerLabel.Size = UDim2.fromScale(0.3, 1)
		end
		
		TimerLabel.Rotation = 5
		TimerLabel.Text = FormatSecondsToMS(countdown)
		
		local TI = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local TI2 = TweenInfo.new(1, Enum.EasingStyle.Quad)

		TweenUtility.PlayTween(TimerLabel, TI, {
			Size = UDim2.fromScale(0.3, 0.9),
			Rotation = 0,
			TextColor3 = BaseLabelColor
		})
		
		if ThumbnailColor then
			
			print('special case', TimerLabel.TextColor3)
			
			TweenUtility.PlayTween(Timer.Thumbnail, TI2, {ImageColor3 = BaseThumbnailColor})
			TweenUtility.PlayTween(TimerLabel, TI2, {TextColor3 = BaseLabelColor})
		end
	end

	local function OnStatusChanged(name: "Round" | "Intermission", isEnded: boolean)
		
		if isEnded then
			return
		end

		StatusLabel.Text = name
	end

	MatchStateClient.MatchEnded:Connect(function(...) OnStatusChanged(..., true) end)
	MatchStateClient.MatchStarted:Connect(function(...) OnStatusChanged(..., false) end)
	MatchStateClient.CountdownStepped:Connect(OnCountdownStepped)

	if MatchStateClient.CurrentPhase then
		
		OnStatusChanged(MatchStateClient.CurrentPhase)
		OnCountdownStepped(MatchStateClient.Countdown)
	end
end

function GameplayUI._InitActions(self: Component)
	
	ClientRemotes.PlayerActionApplied.SetCallback(function(actionMessage: string)
		
		local Label = UIAssets.ActionLabel:Clone()
		Label.Parent = self.Instance.Actions.Content
		Label.Text = actionMessage

		Debris:AddItem(Label, 5)

		Label.TextTransparency = 1
		Label.ZIndex = 100
		TweenUtility.PlayTween(Label, TweenInfo.new(0.15), {TextTransparency = 0})

		task.wait(3)

		TweenUtility.PlayTween(Label, TweenInfo.new(2), {TextTransparency = 1})
	end)
end

function GameplayUI._ConnectSkills(self: Component)
	
	local SkillsFrame = UIAssets.Skills
	local VaultFrame = self.Instance.Misc.Vault :: Frame
	
	local InputController = Classes.GetSingleton("InputController")
	
	local function GetKeyString()
		return InputController:GetStringsFromContext("Jump")[1]
	end
	
	local VaultPromptJanitor = Janitor.new()
	
	local function HideVault(skill: WCS.Skill)
		VaultPromptJanitor:Cleanup()
		
		TweenUtility.PlayTween(VaultFrame.Icon, TweenInfo.new(0.15), { ImageTransparency = 1 } :: ImageLabel)
		TweenUtility.PlayTween(VaultFrame.Action, TweenInfo.new(0.15), { TextTransparency = 1 } :: TextLabel)
		TweenUtility.PlayTween(VaultFrame.Icon.Glow, TweenInfo.new(0.15), { ImageTransparency = 1 } :: ImageLabel)
		TweenUtility.PlayTween(VaultFrame.Action.Key, TweenInfo.new(0.15), { BackgroundTransparency = 1, TextTransparency = 1 } :: TextLabel)
		TweenUtility.PlayTween(VaultFrame.ErrorMessage, TweenInfo.new(0.15), { BackgroundTransparency = 1, TextTransparency = 1 } :: TextLabel)
	end

	local function ShowVault(skill: WCS.Skill)
		-- update each time it's shown because of possible platform update
		VaultFrame.Action.Key.Text = GetKeyString()
		local StaminaCost = skill.FromRoleData.StaminaLoss
		local Character = Player.Character
		
		if not Character then
			return
		end
		
		local Stamina = ComponentsManager.Get(Character, "Stamina")
		local StaminaValue = Stamina:Get()
		local EnoughStamina = StaminaValue >= StaminaCost and 1 or 0
		
		TweenUtility.PlayTween(VaultFrame.Icon, TweenInfo.new(0.5), { ImageTransparency = 0 } :: ImageLabel)
		TweenUtility.PlayTween(VaultFrame.Action, TweenInfo.new(1), { TextTransparency = 0 } :: TextLabel)
		TweenUtility.PlayTween(VaultFrame.Icon.Glow, TweenInfo.new(0.9), { ImageTransparency = 0.8 } :: ImageLabel)
		TweenUtility.PlayTween(VaultFrame.Action.Key, TweenInfo.new(1), { BackgroundTransparency = 0, TextTransparency = 0 } :: TextLabel)
		TweenUtility.PlayTween(VaultFrame.ErrorMessage, TweenInfo.new(1), { TextTransparency = EnoughStamina } :: TextLabel)
		
		VaultPromptJanitor:Add(Stamina.Changed:Connect(function(new, old)
			local EnoughStamina = new >= StaminaCost and 1 or 0
			TweenUtility.PlayTween(VaultFrame.ErrorMessage, TweenInfo.new(.2), { TextTransparency = EnoughStamina } :: TextLabel)
		end))
		
		VaultPromptJanitor:Add(InputController.DeviceChanged:Connect(function()
			VaultFrame.Action.Key.Text = GetKeyString()
		end))
	end
	
	
	--initial
	HideVault()
	self.Janitor:Add(HideVault)
	
	--should be called when vault skill adds
	local function ConnectVaultSkill(skill: WCS.Skill)
		
		while not skill.VaultSelected do
			task.wait()
		end
		
		-- :(
		if skill:IsDestroyed() then
			return
		end
		
		skill.VaultSelected:Connect(function(instance)
			if instance then
				ShowVault(skill)
			else
				HideVault(skill)
			end
		end)
		
	end
	
	--creation
	local function CreateSkillsUI(character: WCS.Character)
		
		local Frame = SkillsFrame:Clone()
		Frame.Parent = self.Instance

		--registery
		local Component = self.Controller:RegisterInterface(
			Frame,
			SkillsUIComponent,
			self.Controller
		)
		
		--removal
		WCS.Character.CharacterDestroyed:Once(function()
			
			ComponentsManager.Remove(
				Component.Instance,
				Component.GetName()
			)
			
			Frame:Destroy()
			
			HideVault()
		end)
		
		--Vault
		
		local VaultSkill = character:GetSkillFromString("Vault")
		
		if VaultSkill then
			ConnectVaultSkill(VaultSkill)
		else
			
			local Connection
			
			Connection = character.SkillAdded:Connect(function(skill)
				
				if skill:GetName() == "Vault" then
					
					ConnectVaultSkill(skill)
					Connection:Disconnect()
				end
			end)
			
			character.SkillRemoved:Connect(function(skill)
				if skill:GetName() == "Vault" then
					HideVault()
					Connection:Disconnect()
				end
			end)
		end
	end

	
	WCS.Character.CharacterCreated:Connect(CreateSkillsUI)

	local WCSCharacter = WCS.Character.GetLocalCharacter()

	if WCSCharacter then
		CreateSkillsUI(WCSCharacter)
	end
end

function GameplayUI._ConnectInventory(self: Component)

	local InventoryFrame = UIAssets.Inventory
	local InventoryComponent = ComponentsManager.Get(Player.Backpack, "ClientInventoryComponent")

	--creation
	local function CreateInventoryUI(component: BaseComponent.Component)

		local Frame = component.Janitor:Add(InventoryFrame:Clone())
		Frame.Parent = self.Instance

		--registery
		component.Janitor:Add(
			self.Controller:RegisterInterface(
				Frame,
				InventoryUIComponent,
				self.Controller,
				component
			)
		)
	end

	--inventory stuff
	ComponentsManager.ComponentAdded:Connect(function(component: BaseComponent.Component)

		if component:GetName() ~= "ClientInventoryComponent" then
			return
		end

		CreateInventoryUI(component)
	end)
	
	--already registered
	if InventoryComponent then
		CreateInventoryUI(InventoryComponent)
	end
end

function GameplayUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self:_ConnectSkills()
	self:_ConnectInventory()
	
	self.Controller:RegisterInterface(self.Instance.Statuses, StatusesUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.Objectives, ObjectivesUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.Actions, ActionsUIComponent, self.Controller)
	self.Controller:RegisterInterface(self.Instance.Misc.Combo, ComboUIComponent, self.Controller)
	self.Controller:RegisterInterface(self.Instance.TeammatesList, TeammatesListUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.CharacterStats, CharacterStatsUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.Misc.HideoutPanicking, HideoutUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.Misc.ItemCharge, ItemChargeUIComponent, self.Controller)

	self:_InitMisc()
	self:_InitTimer()
	self:_InitActions()
end

--//Returner
return GameplayUI