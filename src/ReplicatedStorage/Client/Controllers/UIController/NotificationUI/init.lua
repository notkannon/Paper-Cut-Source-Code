--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--local AchievementsUI = require(script.Achievements)
local RoundResultsUI = require(script.RoundResults)
local PreparingUI = require(script.PreparingUI)
local RolePreviewUI = require(script.RolePreviewUI)
local RoleSelectionUI = require(script.RoleSelection)

--//Variables

local NotificationUI = BaseComponent.CreateComponent("NotificationUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	_ConnectComponentEvents: (self: Component) -> (),
}

export type Fields = {
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "NotificationUI", Frame, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "NotificationUI", Frame, {}>

--//Methods

function NotificationUI._ConnectComponentEvents(self: Component)
	
	--role selection init
	ComponentsManager.ComponentAdded:Connect(function(component)
		
		if component.GetName() ~= "RoleSelection" then
			return
		end
		
		--registery
		component.Janitor:Add(
			
			self.Controller:RegisterInterface(
				
				self.Instance.RoleSelection,
				RoleSelectionUI,
				self.Controller,
				component
			)
		)
	end)
end

function NotificationUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self.Instance.RoleSelection.Visible = false
	self.Instance.PreparingFrame.Visible = true
	
	self:_ConnectComponentEvents()
	
	--initializing child UIs
	self.Controller:RegisterInterface(self.Instance.RolePreview, RolePreviewUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.PreparingFrame, PreparingUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.RoundResults, RoundResultsUI, self.Controller)
end

--//Returner

return NotificationUI
