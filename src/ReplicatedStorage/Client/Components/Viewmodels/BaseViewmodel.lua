--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Constants

local MutualExclisivesSkills = {}
local MutualExclusivesStatuses = {
	"HiddenLeaving",
	"HiddenComing",
	"Hidden",
	"Downed",
	"Handled",
	"Physics",
}

--//Variables

local BaseViewmodel = BaseComponent.CreateComponent("BaseViewmodel", { isAbstract = true }) :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
	
	OnUpdate: (self: Component, deltaTime: number) -> (),
	OnEnabledChanged: (self: Component, enabled: boolean) -> (),
	
	_BindRenderSteps: (self: Component) -> (),
	_UnbindRenderSteps: (self: Component) -> (),
}

export type Fields = {
	Instance: PlayerTypes.Character,
	Enabled: boolean,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseViewmodel", PlayerTypes.Character, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseViewmodel", PlayerTypes.Character, {}> 

--//Methods

--@override
function BaseViewmodel.OnEnabledChanged(self: Component, enabled: boolean) end
--@override
function BaseViewmodel.OnUpdate(self: Component, deltaTime: number) end


function BaseViewmodel.OnConstructClient(self: Component)
	
	local CharacterComponent = ComponentsManager.Await(self.Instance, "ClientCharacterComponent"):expect()
	
	self.Enabled = true
	
	local ActiveSkills = {}
	local ActiveStatuses = {}
	
	local function HandleViewmodelToggle()
		
		local Enabled = #ActiveSkills == 0 and #ActiveStatuses == 0
		
		if self.Enabled == Enabled then
			return
		end
		
		self.Enabled = Enabled
		
		if Enabled then
			self:_BindRenderSteps()
		else
			self:_UnbindRenderSteps()
		end
		
		self:OnEnabledChanged(Enabled)
	end
	
	self.Janitor:Add(CharacterComponent.WCSCharacter.SkillStarted:Connect(function(skill)
		if table.find(MutualExclisivesSkills, skill:GetName()) then
			table.insert(ActiveSkills, skill:GetName())
			HandleViewmodelToggle()
		end
	end))

	self.Janitor:Add(CharacterComponent.WCSCharacter.SkillEnded:Connect(function(skill)
		if table.find(MutualExclisivesSkills, skill:GetName()) then
			table.remove(ActiveSkills, table.find(ActiveSkills, skill:GetName()))
			HandleViewmodelToggle()
		end
	end))

	self.Janitor:Add(CharacterComponent.WCSCharacter.StatusEffectStarted:Connect(function(status)
		if table.find(MutualExclusivesStatuses, status.Name) then
			table.insert(ActiveStatuses, status.Name)
			HandleViewmodelToggle()
		end
	end))

	self.Janitor:Add(CharacterComponent.WCSCharacter.StatusEffectEnded:Connect(function(status)
		if table.find(MutualExclusivesStatuses, status.Name) then
			table.remove(ActiveStatuses, table.find(ActiveStatuses, status.Name))
			HandleViewmodelToggle()
		end
	end))
	
	self.Janitor:Add(function()
		self._UnbindRenderSteps()
		table.clear(ActiveSkills)
		table.clear(ActiveStatuses)
	end)
end

function BaseViewmodel._UnbindRenderSteps(self: Component)
	RunService:UnbindFromRenderStep("ClientViewmodelRenderSteps")
end

function BaseViewmodel._BindRenderSteps(self: Component)
	RunService:BindToRenderStep("ClientViewmodelRenderSteps", Enum.RenderPriority.Last.Value - 1 , function(...)
		
		if not self.Enabled then
			return
		end

		self:OnUpdate(...)
	end)
end

--//Returner

return BaseViewmodel