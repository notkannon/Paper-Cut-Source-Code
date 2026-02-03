--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local RolesData = require(ReplicatedStorage.Shared.Data.Roles)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)

--//Variables

local UIAssets = ReplicatedStorage.Assets.UI
local RolePreviewUI = BaseComponent.CreateComponent("RolePreviewUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	Hide: (self: Component) -> (),
	PreviewRole: (self: Component, role: string) -> (),
}

export type Fields = {

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "RolePreviewUI", Frame, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "RolePreviewUI", Frame, {}>

--//Methods

function RolePreviewUI.Hide(self: Component)
	
	local Glow = self.Instance:FindFirstChild("Glow") :: ImageLabel
	local Label = self.Instance:FindFirstChild("Label") :: TextLabel
	local RoleLabel = self.Instance:FindFirstChild("Role") :: TextLabel
	local IntroLabel = self.Instance:FindFirstChild("Intro") :: TextLabel
	
	self.ActiveJanitor:Cleanup()
	
	TweenUtility.ClearAllTweens(Glow)
	TweenUtility.ClearAllTweens(Label)
	TweenUtility.ClearAllTweens(RoleLabel)
	TweenUtility.ClearAllTweens(IntroLabel)
	TweenUtility.ClearAllTweens(Label.Frame)
	
	Glow.ImageTransparency = 1
	Label.TextTransparency = 1
	RoleLabel.TextTransparency = 1
	IntroLabel.TextTransparency = 1
	Label.Frame.BackgroundTransparency = 1
end

function RolePreviewUI.PreviewRole(self: Component, roleConfig: RolesData.Role)
	
	self:Hide()
	
	if PlayerController:IsSpectator() then
		return
	end
	
	if not roleConfig then
		return
	end
	
	self.Instance.Size = UDim2.fromScale(0.75, 0.5)
	
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.5, 0.3)
	})
	
	local Screen = self.Instance:FindFirstChild("Screen") :: Frame
	local Glow = self.Instance:FindFirstChild("Glow") :: ImageLabel
	local Label = self.Instance:FindFirstChild("Label") :: TextLabel
	local RoleLabel = self.Instance:FindFirstChild("Role") :: TextLabel
	local IntroLabel = self.Instance:FindFirstChild("Intro") :: TextLabel
	
	--intro sound
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.UI.RolePreview:FindFirstChild(roleConfig.Team.Name or "Killer")
	)
	
	--sharp black screen showing
	Screen.BackgroundTransparency = 0
	
	Glow.Visible = true
	Label.Visible = true
	RoleLabel.Visible = true
	IntroLabel.Visible = true
	Label.Frame.Visible = true
	
	RoleLabel.Text = roleConfig.RoleDisplayName
	IntroLabel.Text = roleConfig.Guide:upper()
	RoleLabel.TextColor3 = roleConfig.Team.Name == "Killer" and Color3.fromRGB(173, 35, 35) or Color3.fromRGB(39, 160, 173)
	Glow.ImageColor3 = roleConfig.Team.Name == "Killer" and Color3.fromRGB(108, 51, 51) or Color3.fromRGB(53, 107, 108)
	
	TweenUtility.PlayTween(Glow, TweenInfo.new(2), { ImageTransparency = 0.61 })
	TweenUtility.PlayTween(Label, TweenInfo.new(1), { TextTransparency = 0 })
	TweenUtility.PlayTween(RoleLabel, TweenInfo.new(1), { TextTransparency = 0 })
	TweenUtility.PlayTween(IntroLabel, TweenInfo.new(1), { TextTransparency = 0.5 })
	TweenUtility.PlayTween(Label.Frame, TweenInfo.new(1), { BackgroundTransparency = 0.5 })
	TweenUtility.PlayTween(Screen, TweenInfo.new(2), { BackgroundTransparency = 1 }, nil, 1)
	
	task.wait(3.5)
	
	self.ActiveJanitor:Add(TweenUtility.PlayTween(Glow, TweenInfo.new(1), { ImageTransparency = 1 }), "Cancel")
	self.ActiveJanitor:Add(TweenUtility.PlayTween(Label, TweenInfo.new(1.5), { TextTransparency = 1 }), "Cancel")
	self.ActiveJanitor:Add(TweenUtility.PlayTween(RoleLabel, TweenInfo.new(1.7), { TextTransparency = 1 }), "Cancel")
	self.ActiveJanitor:Add(TweenUtility.PlayTween(IntroLabel, TweenInfo.new(2), { TextTransparency = 1 }), "Cancel")
	self.ActiveJanitor:Add(TweenUtility.PlayTween(Label.Frame, TweenInfo.new(1.6), { BackgroundTransparency = 1 }), "Cancel")
end

function RolePreviewUI.OnConstructClient(self: Component, controller: any)
	BaseUIComponent.OnConstructClient(self, controller)

	self:SetEnabled(true)
	self:Hide()
	
	self.Janitor:Add(PlayerController.RoleConfigChanged:Connect(function(...)
		self:PreviewRole(...)
	end))
end

--//Returner

return RolePreviewUI