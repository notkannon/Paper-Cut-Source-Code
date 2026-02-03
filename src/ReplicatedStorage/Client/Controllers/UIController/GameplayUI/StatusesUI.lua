--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local StatusEffectDisplayData = require(ReplicatedStorage.Shared.Data.StatusEffectDisplayData)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)

--//Variables

local LocalPlayer = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local StatusesUI = BaseComponent.CreateComponent("StatusesUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	_ConnectStatusEffectEvents: (self: Component) -> (),
}

export type Fields = {

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "StatusesUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "StatusesUI", Frame & any, {}>

--//Methods

function StatusesUI.CreateStatusCard(self: Component, statusEffect: WCS.StatusEffect)
	
	local DisplayData = StatusEffectDisplayData[statusEffect.Name]

	--no display data for status
	if not DisplayData then
		return
	end
	
	local Connection = statusEffect.Started:Connect(function()
		
		--initials
		
		local Card = UIAssets.Misc.StatusCard:Clone()
		
		Card.Parent = self.Instance.Content
		Card.Value.Offset = Vector2.zero
		Card.StatusName.Value.Offset = Vector2.zero
		Card.Visible = true
		
		Card.ImageTransparency = 1
		Card.Icon.ImageTransparency = 1
		Card.StatusName.TextTransparency = 1
		
		TweenUtility.PlayTween(Card, TweenInfo.new(0.2), {ImageTransparency = 0})
		TweenUtility.PlayTween(Card.Icon, TweenInfo.new(0.2), {ImageTransparency = 0})
		TweenUtility.PlayTween(Card.StatusName, TweenInfo.new(0.2), {TextTransparency = 0})

		--applying visuals
		local RoleDisplay = DisplayData.Roles and DisplayData.Roles[PlayerController:GetRoleString()]

		Card.StatusName.Text = (RoleDisplay and RoleDisplay.Name or DisplayData.Default.Name or "Unknown status"):upper()
		Card.Icon.Image = RoleDisplay and RoleDisplay.Icon or DisplayData.Default.Icon or ""

		local duration = statusEffect:GetActiveDuration()

		if duration > 0 then

			--tweening bars

			TweenUtility.PlayTween(Card.Value, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
				Offset = Vector2.new(1, 0)
			})

			TweenUtility.PlayTween(Card.StatusName.Value, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
				Offset = Vector2.new(1, 0)
			})
		end
		
		local Removing = false
		
		--removal thing hehe
		local function Remove()
			
			if not Card or Removing then
				return
			end
			
			Removing = true
			
			TweenUtility.PlayTween(Card, TweenInfo.new(0.5), {ImageTransparency = 1})
			TweenUtility.PlayTween(Card.Icon, TweenInfo.new(0.5), {ImageTransparency = 1})
			TweenUtility.PlayTween(Card.StatusName, TweenInfo.new(0.5), {TextTransparency = 1})
			
			task.wait(0.5)
			
			if Card then
				Card:Destroy()
			end
		end

		--removal
		statusEffect.Ended:Once(Remove)
		statusEffect.GenericJanitor:Add(Remove)
	end)
	
	--FUCK, WHY SHOULD I DO SUCH TRASH THINGS
	while not statusEffect.GenericJanitor do
		task.wait()
	end
	
	--bruh
	if statusEffect:IsDestroyed() then
		return
	end
	
	--listening to started
	statusEffect.GenericJanitor:Add(Connection)
end

function StatusesUI._ConnectStatusEffectEvents(self: Component)
	
	--handling statuses adding
	local function OnStatusEffectAdded(statusEffect: WCS.StatusEffect)
		self:CreateStatusCard(statusEffect)
	end
	
	--handling character adding
	local function OnWCSCharacterAdded(wcsCharacter: WCS.Character)
		
		local Connection = wcsCharacter.StatusEffectAdded:Connect(OnStatusEffectAdded)
		
		--removal
		wcsCharacter.Destroyed:Once(function()
			Connection:Disconnect()
		end)
	end

	--initials
	
	WCS.Character.CharacterCreated:Connect(OnWCSCharacterAdded)
	
	local WCSCharacter = WCS.Character.GetLocalCharacter()
	
	if WCSCharacter then
		OnWCSCharacterAdded(WCSCharacter)
	end
end

function StatusesUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self:_ConnectStatusEffectEvents()
end

--//Returner

return StatusesUI