--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local PlayerController = require(script.Parent.PlayerController)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ClientCharacterComponent = require(ReplicatedStorage.Client.Components.ClientCharacterComponent)

--//Variables

local Viewmodels = {}

local ActiveSkills = {}
local ActiveStatuses = {}
local MutualExclisivesSkills = {}
local MutualExclusivesStatuses = {"Hidden", "Downed", "Handled", "Physics"}

local ViewmodelController: Impl = Classes.CreateSingleton("ViewmodelController") :: Impl

--//Types

export type Impl = {
	__index: Impl,

	GetName: () -> "ViewmodelController",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Singleton) -> boolean,

	ToggleViewmodel: (self: Singleton, value: boolean) -> (),
	ApplyViewmodelFromRole: (self: Singleton, role: string) -> (),

	new: () -> Singleton,
	OnConstruct: (self: Singleton) -> (),
	OnConstructServer: (self: Singleton) -> (),
	OnConstructClient: (self: Singleton) -> (),
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Viewmodel: any,
	CharacterComponent: ClientCharacterComponent.Component,

	_RenderViewModelFromRole: RBXScriptConnection,
}

export type Singleton = typeof(setmetatable({} :: Fields, ViewmodelController :: Impl))

--//Methods

function ViewmodelController.ToggleViewmodel(self: Singleton, value: boolean)
	if not self.Viewmodel then
		return
	end
	
	self.Viewmodel:SetEnabled(value)
end

function ViewmodelController.ApplyViewmodelFromRole(self: Singleton, role: string)
	self.CharacterComponent = PlayerController.CharacterComponent
	
	local ViewmodelImpl = Viewmodels[role]
	if not ViewmodelImpl then
		return
	end
	
	self.Viewmodel = ComponentsManager.Add(ViewmodelImpl._DefaultInstance, ViewmodelImpl)
end

function ViewmodelController.OnConstructClient(self: Singleton)
	self.Janitor = Janitor.new()
	
	local function HandleViewmodelToggle()
		if not self.Viewmodel then
			return
		end
		
		if #ActiveSkills > 0 or #ActiveStatuses > 0 then
			self:ToggleViewmodel(false)
		else
			self:ToggleViewmodel(true)
		end
	end
	
	local function HandleViewmodelComponentRemove()
		local ViewmodelImpl = Viewmodels[self.Viewmodel._Role]
		ComponentsManager.Remove(ViewmodelImpl._DefaultInstance, ViewmodelImpl)
		
		self.Viewmodel = nil
		self.Janitor:Cleanup()
	end
	
	PlayerController.CharacterAdded:Connect(function(component)
		local role = PlayerController:GetRoleConfig().DisplayName
		
		if self.Viewmodel and self.Viewmodel.Role ~= role then
			HandleViewmodelComponentRemove()
			return
		end
		
		self:ApplyViewmodelFromRole(role)
		
		if self.Viewmodel then
			self:ToggleViewmodel(true)
		end
		
		self.Janitor:Add(component.WCSCharacter.SkillStarted:Connect(function(skill)
			if table.find(MutualExclisivesSkills, skill:GetName()) then
				table.insert(ActiveSkills, skill:GetName())
				HandleViewmodelToggle()
			end
		end))
		
		self.Janitor:Add(component.WCSCharacter.SkillEnded:Connect(function(skill)
			if table.find(MutualExclisivesSkills, skill:GetName()) then
				table.remove(ActiveSkills, table.find(ActiveSkills, skill:GetName()))
				HandleViewmodelToggle()
			end
		end))
		
		self.Janitor:Add(component.WCSCharacter.StatusEffectStarted:Connect(function(status)
			if table.find(MutualExclusivesStatuses, status.Name) then
				table.insert(ActiveStatuses, status.Name)
				HandleViewmodelToggle()
			end
		end))
		
		self.Janitor:Add(component.WCSCharacter.StatusEffectEnded:Connect(function(status)
			if table.find(MutualExclusivesStatuses, status.Name) then
				table.remove(ActiveStatuses, table.find(ActiveStatuses, status.Name))
				HandleViewmodelToggle()
			end
		end))
	end)
	
	PlayerController.CharacterRemoved:Connect(function()
		if not self.Viewmodel then
			return
		end
		
		HandleViewmodelComponentRemove()
	end)
	
	for _, Module in ipairs(script.Viewmodels:GetChildren()) do
		local Source = require(Module) :: BaseComponent.BaseImpl
		Viewmodels[Source._Role] = Source
	end
end

--//Returner

local Singleton = ViewmodelController.new()
return Singleton