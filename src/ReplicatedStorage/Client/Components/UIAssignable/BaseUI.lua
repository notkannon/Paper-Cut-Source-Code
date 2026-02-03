--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local BaseUI = BaseComponent.CreateComponent("BaseUI", { isAbstract = false }) :: Impl

--//Types

export type UIConstructorOptions = {
	
}

export type MyImpl = {
	__index: MyImpl,
	
	IsEnabled: (self: Component) -> boolean,
	--GetParent: (self: Component) -> Component?,
	--GetChildren: (self: Component) -> { Component? },
	--GetAncestors: (self: Component) -> { Component? },
	--GetDescendants: (self: Component) -> { Component? },
	--IsAncestorOf: (self: Component, component: Component) -> boolean,
	--IsDescendantOf: (self: Component, component: Component) -> boolean,
	--FindFirstChild: (self: Component, name: string, useMatch: boolean?) -> Component?,
	
	SetEnabled: (self: Component, value: boolean) -> (),
	--GetInterfaceData: (self: Component) -> { any },
	OnEnabledChanged: (self: Component, value: boolean) -> (),
	
	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
	Controller: unknown,
	--ShouldToggleInChain: boolean,
	--ChainableDescendantsToggle: boolean,
	
	ActiveJanitor: Janitor.Janitor,
	EnabledChanged: Signal.Signal<boolean>,
	
	_Enabled: boolean,
	--_SavedEnabled: boolean,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseUI", Frame & {}, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseUI", Frame & {}, {}> 

--//Methods

--@override
function BaseUI.OnEnabledChanged(self: Component, value: boolean)
	self.Instance.Visible = value or false
end

--function BaseUI.GetInterfaceData(self: Component)
--	return self.Controller:GetInterfaceData(self)
--end

function BaseUI.IsEnabled(self: Component)
	return self._Enabled
end

function BaseUI.SetEnabled(self: Component, value: boolean)
	assert(typeof(value) == "boolean")
	
	self._SavedEnabled = value
	
	if self._Enabled == value then
		return
	end
	
	if self._Enabled then
		self.ActiveJanitor:Cleanup()
	end
	
	self._Enabled = value
	self.EnabledChanged:Fire(value)
	self:OnEnabledChanged(value)
end

--function BaseUI.IsAncestorOf(self: Component, component: unknown)
--	return component:IsDescendantOf(self)
--end

--function BaseUI.IsDescendantOf(self: Component, component: unknown)
	
--	--shouldn't check if already has no ancestors
--	if not self:GetInterfaceData().Parent then
--		return
--	end
	
--	--recursively ancestry parsing
--	local function ParseAncestor(ancestor: { any })
		
--		if table.find(ancestor.Children, self) then
--			return true
			
--		elseif ancestor.Parent then
--			--recycling
			
--			return ParseAncestor(
--				self.Controller:GetInterfaceData(
--					ancestor.Parent
--				)
--			)
--		end
--	end
	
--	--results
--	return ParseAncestor(
--		self.Controller:GetInterfaceData(
--			component
--		)
--	) or false
--end

--function BaseUI.GetAncestors(self: Component)
	
--	--recursively parsing ancestry
--	local function FindAncestor(subject: { any }, list)
		
--		list = list or {}
		
--		if not subject.Parent then
--			return list
			
--		else
			
--			FindAncestor(self.Controller:GetInterfaceData(subject), list)
			
--			table.insert(list, subject.Parent)
--		end
--	end
	
--	return FindAncestor(
--		self:GetInterfaceData()
--	)
--end

--function BaseUI.GetDescendants(self: Component)
	
--	--recursively parsing descendants
--	local function ParseChild(child: { any }, list)
		
--		list = list or {}
		
--		if #child.Children == 0 then
--			return list
			
--		else
--			for _, Child in ipairs(child.Children) do
				
--				ParseChild(self.Controller:GetInterfaceData(Child), list)
				
--				table.insert(list, Child)
--			end
--		end
--	end
	
--	return ParseChild(
--		self:GetInterfaceData()
--	)
--end

--function BaseUI.GetChildren(self: Component)
--	local InterfaceData = self:GetInterfaceData()
--	return InterfaceData and InterfaceData.Children or {}
--end

--function BaseUI.GetParent(self: Component)
--	local InterfaceData = self:GetInterfaceData()
--	return InterfaceData and InterfaceData.Parent or nil
--end

--function BaseUI.FindFirstChild(self: Component, name: string, useMatch: boolean?)

--	for _, Child: Component in ipairs(self:GetInterfaceData()) do
		
--		if Child.GetName() == name or (useMatch and Child.GetName():match(name)) then
			
--			return Child
--		end
--	end
--end

--function BaseUI._ConnectEvents(self: Component)
	
--	--toggle detection
--	self.Janitor:Add(self.Controller.InterfaceEnabledChanged:Connect(function(component, value)
		
--		if not self.ShouldToggleInChain then
--			return
--		end
		
--		-- Если родитель существует, то событие будет вызвано для всех потомков
--		if component:IsAncestorOf(self) then
--			self:SetEnabled(component:IsEnabled() and self._SavedEnabled)
--		end
--	end))
--end

function BaseUI.OnConstructClient(self: Component, uiController: unknown, options: UIConstructorOptions?)
	
	self._Enabled = nil
	--self._SavedEnabled = nil
	--self.ShouldToggleInChain = true
	--self.ChainableDescendantsToggle = true
	
	self.Controller = uiController
	self.ActiveJanitor = self.Janitor:Add(Janitor.new())
	self.EnabledChanged = self.Janitor:Add(Signal.new())
	
	--applying options
	if options then
		
	end
	
	self:SetEnabled(true)
	--self:_ConnectEvents()
end

--//Returner

return BaseUI