--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local EnumsType = require(ReplicatedStorage.Shared.Enums)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local Roles = require(ReplicatedStorage.Shared.Data.Roles)

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI

local DefferedTweenPlaybacks = {} :: { [Instance]: RBXScriptConnection? }

local SkillsUI = BaseComponent.CreateComponent("SkillsUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

type SkillState = {
	Debounce: boolean,
	IsActive: boolean,
}

type UISkillTab = {
	Skill: WCS.Skill | WCS.HoldableSkill,
	Instance: typeof(UIAssets.Misc.InventorySlot),
	Connections: { RBXScriptConnection },
	SkillRoleData: {
		Cooldown: number,
		--TODO: expand skill info
	},
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	_GetTabFromSkillString: (self: Component, skillName: string) -> UISkillTab?,
	
	_ProcessSkillEnded: (self: Component, skill: WCS.Skill) -> (),
	_ProcessSkillStarted: (self: Component, skill: WCS.Skill) -> (),
	_ProcessSkillCooldownFinished: (self: Component, skill: WCS.Skill) -> (),
	_ProcessSkillCharged: (self: Component, skill: WCS.Skill) -> (),
	_UpdateSkillTabForUses: (self: Component, skill: WCS.Skill) -> (),
	
	_InitTabs: (self: Component) -> (),
	_ClearTabs: (self: Component) -> (),
	_CreateTab: (self: Component, skill: WCS.Skill) -> (),
}

export type Fields = {
	
	Tabs: { UISkillTab },
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SkillsUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "SkillsUI", Frame & any, {}>

--//Functions

--local function GetInputStringFromSkill(skill: WCS.Skill, frame: GuiBase2d)
--	local InputController = Classes.GetSingleton("InputController")
--	local Bindings = InputController:GetBindsFromSkill(skill)
--	local String = InputController:GetStringsFromBindings(Bindings)[1]
	
--	return String, TextService:GetTextSize(String, 16, Enum.Font.BuilderSans, Vector2.new(math.huge, frame.AbsoluteSize.Y))
--end


local function ApplyRadialGradientRotation(scale: number, left: UIGradient, right: UIGradient, duration: number?)
	
	local Rotation = 360 * scale
	local RotationLeft = math.clamp(-(180 - Rotation), -180, 0)
	local RotationRight = math.clamp(-(360 - Rotation), -180, 0)
	
	TweenUtility.ClearAllTweens(left)
	TweenUtility.ClearAllTweens(right)
	
	if DefferedTweenPlaybacks[left] then
		DefferedTweenPlaybacks[left]:Disconnect()
		DefferedTweenPlaybacks[left] = nil
	end
	
	if DefferedTweenPlaybacks[right] then
		DefferedTweenPlaybacks[right]:Disconnect()
		DefferedTweenPlaybacks[right] = nil
	end
	
	if not duration or duration == 0 then
		left.Rotation = RotationLeft
		right.Rotation = RotationRight
		
	else
		local LinearTweenInfo = TweenInfo.new(duration / 2, Enum.EasingStyle.Linear)
		
		if Rotation > 180 then
			DefferedTweenPlaybacks[right] = TweenUtility.PlayTween(left, LinearTweenInfo, {Rotation = RotationLeft}).Completed:Once(function()
				TweenUtility.PlayTween(right, LinearTweenInfo, {Rotation = RotationRight})
			end)
		else
			DefferedTweenPlaybacks[left] = TweenUtility.PlayTween(right, LinearTweenInfo, {Rotation = RotationRight}).Completed:Once(function()
				TweenUtility.PlayTween(left, LinearTweenInfo, {Rotation = RotationLeft})
			end)
		end
	end
end

--//Methods

function SkillsUI._GetTabFromSkillString(self: Component, skillName: string)
	for _, Tab in ipairs(self.Tabs) do
		if Tab.Skill.Name == skillName then
			return Tab
		end
	end
end

function SkillsUI._UpdateSkillTabForUses(self: Component, skill: WCS.Skill, compensateOne: boolean?)
	local Tab = self:_GetTabFromSkillString(skill.Name)
	local MaxUses = skill.FromRoleData.MaxUses :: number?
	
	--uses remained
	if MaxUses then

		local Remained = skill.CurrentUses
		if compensateOne then
			Remained -= 1
		end

		Tab.Instance.Uses.Text = Remained

		if Remained <= 0 then

			Tab.Instance.Uses.TextTransparency = 0.7
			Tab.Instance.Input.TextTransparency = 0.7
			Tab.Instance.Input.Icon.ImageTransparency = 0.7

			Tab.Instance.Left.Icon.ImageTransparency = 0.15
			Tab.Instance.Right.Icon.ImageTransparency = 0.15
			Tab.Instance.IconBackLayer.ImageTransparency = .95
		else
			
			Tab.Instance.Uses.TextTransparency = 0
			Tab.Instance.Input.TextTransparency = 0
			Tab.Instance.Input.Icon.ImageTransparency = 0
			Tab.Instance.Left.Icon.ImageTransparency = 0
			Tab.Instance.Right.Icon.ImageTransparency = 0
			Tab.Instance.IconBackLayer.ImageTransparency = 0.9
			
		end
	end
end

function SkillsUI._ProcessSkillStarted(self: Component, skill: WCS.Skill)
	
	local Tab = self:_GetTabFromSkillString(skill.Name)
	local State = skill:GetState()
	
	self.Janitor:Remove("CooldownCounter")
	
	if State.MaxHoldTime then
		ApplyRadialGradientRotation( 1,
			Tab.Instance.Left.Icon.Value,
			Tab.Instance.Right.Icon.Value
		)
		
		ApplyRadialGradientRotation( 0,
			Tab.Instance.Left.Icon.Value,
			Tab.Instance.Right.Icon.Value,
			State.MaxHoldTime
		)
		
	else
		ApplyRadialGradientRotation( 0,
			Tab.Instance.Left.Icon.Value,
			Tab.Instance.Right.Icon.Value
		)
	end
	
	self:_UpdateSkillTabForUses(skill, true)
end

function SkillsUI._ProcessSkillCooldownFinished(self: Component, skill: WCS.Skill)
	
	local MaxUses = skill.FromRoleData.MaxUses :: number?
	local Remained = skill.CurrentUses
	
	--skip ready animation
	if Remained and Remained == 0 then
		return
	end
	
	local Tab = self:_GetTabFromSkillString(skill.Name)
	local Instance = Tab.Instance
	
	--clean cd countdown connection
	if Tab.Connections.Countdown then
		
		Tab.Connections.Countdown:Disconnect()
		Tab.Connections.Countdown = nil
	end
	
	TweenUtility.ClearAllTweens(Instance)
	TweenUtility.ClearAllTweens(Instance.CDShade)
	TweenUtility.ClearAllTweens(Instance.Cooldown)
	
	Instance.BackImage.ImageColor3 = Color3.new(1, 1, 1)
	Instance.BackImage.ImageTransparency = 0
	
	TweenUtility.PlayTween(
		Instance.BackImage,
		TweenInfo.new(0.4),
		{
			ImageColor3 = Color3.new(0, 0, 0),
			ImageTransparency = 0.9,
		}
	)
	
	TweenUtility.PlayTween(
		Instance.CDShade,
		TweenInfo.new(0.3),
		{ ImageTransparency = 1, }
	)
	
	TweenUtility.PlayTween(
		Instance.Cooldown,
		TweenInfo.new(0.3),
		{ TextTransparency = 1, }
	)
end

function SkillsUI._ProcessSkillEnded(self: Component, skill: WCS.Skill)
	
	local Tab = self:_GetTabFromSkillString(skill.Name)
	local MaxUses = skill.FromRoleData.MaxUses :: number?
	local Remained = MaxUses and skill.CurrentUses or nil
	local Instance = Tab.Instance
	
	--clean cd countdown connection
	if Tab.Connections.Countdown then

		Tab.Connections.Countdown:Disconnect()
		Tab.Connections.Countdown = nil
	end
	
	TweenUtility.ClearAllTweens(Instance.CDShade)
	TweenUtility.ClearAllTweens(Instance.Cooldown)

	--skip charge animation
	if Remained and Remained == 0 then
		
		ApplyRadialGradientRotation( 1,
			Tab.Instance.Left.Icon.Value,
			Tab.Instance.Right.Icon.Value
		)
		
		return
	end
	
	if skill.FromRoleData.Cooldown then 
	
		local Time = math.max(0, (skill:GetDebounceEndTimestamp() or 0) - workspace:GetServerTimeNow())
		local Checkpoint = os.clock() + Time
		
		TweenUtility.PlayTween(
			Instance.CDShade,
			TweenInfo.new(0.3),
			{ ImageTransparency = 0.6, }
		)

		TweenUtility.PlayTween(
			Instance.Cooldown,
			TweenInfo.new(0.3),
			{ TextTransparency = 0, }
		)
		
		--countdown connection
		Tab.Connections.Countdown = RunService.RenderStepped:Connect(function()
			
			local Remains = math.clamp(Checkpoint - os.clock(), 0, Time)

			if Remains >= 11 then
				-- целые числа (без .0)
				Instance.Cooldown.Text = tostring(math.round(Remains))
			else
				-- дробные числа (всегда с .x, даже если .0)
				Instance.Cooldown.Text = string.format("%.1f", math.floor(Remains * 10 + 0.5) / 10)
			end
			
		end)
		
		if not skill.FromRoleData.Charge then 
			ApplyRadialGradientRotation( 0,
				Tab.Instance.Left.Icon.Value,
				Tab.Instance.Right.Icon.Value
			)
			
			ApplyRadialGradientRotation( 1,
				Tab.Instance.Left.Icon.Value,
				Tab.Instance.Right.Icon.Value,
				Time
			)
		end
	end
end

function SkillsUI._ProcessSkillCharged(self: Component, skill: WCS.Skill, newCharge: number)
	local Tab = self:_GetTabFromSkillString(skill.Name)
	
	local ChargePercent = newCharge / skill.FromRoleData.Charge.MaxCharge
	
	if skill.CurrentUses == skill.MaxUses then
		ChargePercent = 1
	end
	
	ApplyRadialGradientRotation(ChargePercent,
		Tab.Instance.Left.Icon.Value,
		Tab.Instance.Right.Icon.Value
	)
end

function SkillsUI._CreateTab(self: Component, skill: WCS.Skill)
	
	local PlayerController = Classes.GetSingleton("PlayerController")
	local InputController = Classes.GetSingleton("InputController")
	
	local RoleConfig = PlayerController:GetRoleConfig() :: Roles.Role?
	local SkillRoleData = RoleConfig.SkillsData[skill.Name]
	
	if not SkillRoleData or not SkillRoleData.Order then
		return
	end
	
	local InputContext = InputController:GetContextFromSkill(skill)
	
	local Instance = UIAssets.Misc.SkillTab:Clone()
	Instance.Parent = self.Instance.Content
	Instance.LayoutOrder = SkillRoleData.Order
	Instance.Left.Icon.Image = SkillRoleData.Image or Instance.Left.Icon.Image
	Instance.Right.Icon.Image = SkillRoleData.Image or Instance.Right.Icon.Image
	Instance.IconBackLayer.Image = SkillRoleData.Image or Instance.IconBackLayer.Image
	
	local OriginalSize = Instance.Input.Size
	
	--hiding uses amount label
	if not SkillRoleData.MaxUses or SkillRoleData.MaxUses == 1 then
		Instance.Uses.Visible = false
	else
		Instance.Uses.Text = SkillRoleData.MaxUses
	end
	
	
	local function UpdateSkillKeybinds()
		--local Input, SizeOffset = GetInputStringFromSkill(skill, Instance.Input)
		Instance.Input.Text = ""
		--Instance.Input.Size = OriginalSize + UDim2.fromOffset(SizeOffset.X or 0 - 15, 0)
		--print(skill.Name, InputController:GetImageIdFromSkill(skill))
		local Override = InputController._SkillInputHandlerOverrides[ skill:GetName() ] or nil
		local Binds = InputController:GetKeybindsFromContext( Override and Override.SkillName or InputContext )
		local InputName = InputController:GetStringsFromBindings(Binds, {PrefixPlatform = true, MouseFormatStyle = "MNum"})[1]
		
		local Image = InputController:GetImageIdFromString(InputName)
		
		Instance.Input.Icon.Image = Image
		Instance.Input.Icon.Visible = true
	end

	self.Janitor:Add(InputController.ContextChanged:Connect(function(context)
		if InputContext ~= context then
			return
		end
		
		UpdateSkillKeybinds()
	end))
	
	self.Janitor:Add(InputController.DeviceChanged:Connect(function(new)
		UpdateSkillKeybinds()
	end))
	
	UpdateSkillKeybinds()
	
	local Tab = {
		Skill = skill,
		Instance = Instance,
		SkillRoleData = SkillRoleData,
		
		Connections = {
			self.Janitor:Add(skill.StateChanged:Connect(function(newState: SkillState, oldState: SkillState)
				if not oldState.IsActive and newState.IsActive then
					self:_ProcessSkillStarted(skill) -- on skill started
					
				elseif (oldState.IsActive and not newState.IsActive)
					or (not oldState.Debounce and newState.Debounce) then
					
					self:_ProcessSkillEnded(skill) -- on skill ended or cooldowned
					
				elseif oldState.Debounce and not newState.Debounce then
					self:_ProcessSkillCooldownFinished(skill) -- on skill cooldown ended
				end
			end)),
			self.Janitor:Add(skill.Charged:Connect(function(newAmount: number)
				self:_ProcessSkillCharged(skill, newAmount)
			end)),
			self.Janitor:Add(skill.UsesChanged:Connect(function(newUses: number)
				self:_UpdateSkillTabForUses(skill)
			end))
		}
	} :: UISkillTab
	
	ApplyRadialGradientRotation( 1,
		Instance.Left.Icon.Value,
		Instance.Right.Icon.Value
	)
	
	table.insert(self.Tabs, Tab)
	
	self:_UpdateSkillTabForUses(skill)
	
	return Tab
end

function SkillsUI._ClearTabs(self: Component)
	for _, Instance: Instance in ipairs(self.Instance.Content:GetChildren()) do
		if Instance:IsA("UIListLayout") then
			continue
		end
		
		Instance:Destroy()
	end
	
	for _, Tab in ipairs(self.Tabs) do
		for _, Connection: RBXScriptConnection in pairs(Tab.Connections) do
			Connection:Disconnect()
		end
		
		table.clear(Tab)
	end
	
	table.clear(self.Tabs)
end

function SkillsUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	local WCSCharacter = WCS.Character.GetLocalCharacter()
	
	self.Tabs = {}
	
	self:_ClearTabs()
	self:SetEnabled(true)
	
	for _, Skill in ipairs(WCSCharacter:GetSkills()) do
		--print("WCSCharacter", Skill)
		self:_CreateTab(Skill)
	end

	self.Janitor:Add(WCSCharacter.SkillAdded:Connect(function(skill)
		
		if self:_GetTabFromSkillString(skill.Name) then
			return
		end
		
		repeat task.wait() until skill._Constructed

		--print("Janitor contruct", skill.Name)

		self:_CreateTab(skill)
	end))
end

--//Returner

return SkillsUI