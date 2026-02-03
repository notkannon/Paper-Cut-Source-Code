--//Services

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local RoleSelectionComponent = require(ReplicatedStorage.Shared.Components.Matchmaking.RoleSelection)
local Characters = require(ReplicatedStorage.Shared.Data.Characters)
local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local UIRelated = require(ReplicatedStorage.Shared.Data.UiRelated)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local UIAssets = ReplicatedStorage.Assets.UI
local RoleSelectionUI = BaseComponent.CreateComponent("RoleSelectionUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),

	BuildCards: (self: Component, roles: { string }) -> (),
	UpdateCards: (self: Component, state: { [string]: { Player } }) -> (),
}

export type Fields = {

	Cards: { [string]: Frame },
	Selection: RoleSelectionComponent.Component,

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "RoleSelectionUI", Frame, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "RoleSelectionUI", Frame, {}>

--//Functions

local function getThumbnail(Name: string): string
	
	local Image = "rbxassetid://13488010891"
	
	
	if UIRelated.ImageTextures.SelectionThumbnails.Maps[Name] then
		
		Image = UIRelated.ImageTextures.SelectionThumbnails.Maps[Name]
		
	elseif Characters[Name] or Roles[Name] then
		
		local Asigned = Characters[Name] or Roles[Name]
		Image = Asigned.Thumbnail or Asigned.Icon
	end

	return Image
end

--//Methods

function RoleSelectionUI.BuildCards(self: Component, roles: { string })
	
	self.Cards = {}
	
	for Name, _ in pairs(roles) do
		local Data = self.Selection.Roles[Name]
		local Card = self.Janitor:Add(UIAssets.Misc.RoleSelectionCard:Clone())
		Card.Parent = self.Instance.Container.Cards
		Card.Modal = true
		Card.Size = UDim2.fromScale(Card.Size.X.Scale, 0)
	
		Card.SectionTitle.Text = Name
		Card.Thumbnail.Image = getThumbnail(Name)
		Card.Titles.Amount.Text = `0/{Data.MaxPlayers}`
		Card.Timer.UIGradient.Offset = Vector2.new(0, 0)
		
		TweenUtility.PlayTween(Card, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(Card.Size.X.Scale, 1)
		})
		
		if self.Selection.Duration then
			TweenUtility.PlayTween(Card.Timer.UIGradient, TweenInfo.new(self.Selection.Duration, Enum.EasingStyle.Linear), {
				Offset = Vector2.new(0, 1)
			})
		end
		
		self.Janitor:Add(Card.MouseButton1Click:Connect(function()
			self.Selection:PromptSelect(Name)
		end))
		
		self.Cards[Name] = Card
	end
end

function RoleSelectionUI.UpdateCards(self: Component, state: { [string]: { Player } })

	for RoleString, Card in pairs(self.Cards) do
		local Data = self.Selection.Roles[RoleString]
		
		Card.SectionTitle.Text = RoleString
		Card.Titles.Amount.Text = `{ #state[RoleString] }/{ Data.MaxPlayers }`
		
		for _, Child in ipairs(Card.Players:GetChildren()) do
			
			if not Child:IsA("TextLabel")
				or not Child.Visible then
				
				continue
			end
			
			Child:Destroy()
		end
		
		for _, Player in ipairs(state[RoleString]) do
			local prefab = Card.Players:FindFirstChild("PlayerName")
			local Label = prefab:Clone()
			
			Label.Text = Player.Name
			Label.Parent = Card.Players
			Label.Visible = true
		end
	end
end

function RoleSelectionUI.OnConstructClient(self: Component, controller: any, selection: RoleSelectionComponent.Component)
	BaseUIComponent.OnConstructClient(self, controller)

	self.Instance.Visible = true
	self.Instance.Claimed.Text = selection.CustomTitle

	self.Cards = {}
	self.Selection = selection

	self.Janitor:Add(function()
		self.Selection = nil
		self.Instance.Visible = false
	end)
	
	self:BuildCards(selection.Roles)

	self.Janitor:Add(selection.SelectionChanged.On(function(newState)
		self:UpdateCards(newState)
	end))
end

--//Returner

return RoleSelectionUI