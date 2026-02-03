--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local ActionsUI = BaseComponent.CreateComponent("ActionsUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	DisplayAction: (self: Component, content: string, duration: number?) -> (),
	
	_GetAllLabels: (self: Component) -> { TextLabel },
	_ConnectEvents: (self: Component) -> (),
}

export type Fields = {
	
	Instance: TextLabel,
	UIController: any,
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ActionsUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ActionsUI", Frame & any, {}>

--//Methods

function ActionsUI.DisplayAction(self: Component, content: string, duration: number?)
	
	local OldLabels = self:_GetAllLabels()
	
	for _, Label in ipairs(OldLabels) do
		Label.Parent = nil
	end
	
	local NewLabel = UIAssets.Misc.ActionLabel:Clone()
	NewLabel.Parent = self.Instance.Content
	NewLabel.Text = content
	NewLabel.Rotation = 2
	
	TweenUtility.PlayTween(NewLabel, TweenInfo.new(1.5), { Rotation = 0, TextTransparency = 1 }, function()
		if NewLabel then
			NewLabel:Destroy()
		end
	end, duration or 3)
	
	for _, Label in ipairs(OldLabels) do
		Label.Parent = self.Instance.Content
	end
end

function ActionsUI._GetAllLabels(self: Component)
	local Labels = {}
	
	for _, Instance: Instance in ipairs(self.Instance.Content:GetChildren()) do

		if Instance:IsA("UIListLayout") then
			continue
		end

		table.insert(Labels, Instance)
	end
	
	return Labels
end

function ActionsUI._ConnectEvents(self: Component)
	
	--points award events
	ClientRemotes.PointsAwarded.On(function(args)
		
		self:DisplayAction(args.message)
	end)
end

function ActionsUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	for _, Instance: Instance in ipairs(self:_GetAllLabels()) do
		Instance:Destroy()
	end
	
	self:_ConnectEvents()
end

--//Returner

return ActionsUI