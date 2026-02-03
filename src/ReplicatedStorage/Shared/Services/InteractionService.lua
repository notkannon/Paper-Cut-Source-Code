--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local BaseInteraction = require(ReplicatedStorage.Shared.Components.Abstract.BaseInteraction)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local InputController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.InputController) or nil

--//Variables

local InteractionService = Classes.CreateSingleton("InteractionService") :: Impl
InteractionService.InteractionHidden = Signal.new()
InteractionService.InteractionShown = Signal.new()
InteractionService.InteractionEnded = Signal.new()
InteractionService.InteractionStarted = Signal.new()
InteractionService.InteractionHoldEnded = Signal.new()
InteractionService.InteractionHoldStarted = Signal.new()

--//Types

export type Impl = {
	__index: Impl,

	new: () -> Service,
	IsImpl: (self: Service) -> boolean,
	GetName: () -> "InteractionService",
	GetExtendsFrom: () -> nil,
}

export type Fields = {
	InteractionHidden: Signal.Signal<BaseInteraction.Component>,
	InteractionShown: Signal.Signal<BaseInteraction.Component>,
	InteractionEnded: Signal.Signal<BaseInteraction.Component, Player>,
	InteractionStarted: Signal.Signal<BaseInteraction.Component, Player>,
	InteractionHoldEnded: Signal.Signal<BaseInteraction.Component, Player>,
	InteractionHoldStarted: Signal.Signal<BaseInteraction.Component, Player>,
}

export type Service = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function InteractionService.OnConstruct(self: Service)
	ComponentsManager.ComponentAdded:Connect(function(component: Interaction.Component)
		if not Classes.InstanceOf(component, BaseInteraction) then
			return
		end
		
		if RunService:IsClient() then
			component.Janitor:Add(component.Shown:Connect(function()
				self.InteractionShown:Fire(component)
			end))
			
			component.Janitor:Add(component.Hidden:Connect(function()
				self.InteractionHidden:Fire(component)
			end))
		end
		
		-- no .Started .Ended .HoldStarted .HoldEnded events
		if not Classes.InstanceOf(component, Interaction) then
			return
		end
		
		component.Janitor:Add(component.Started:Connect(function(...)
			self.InteractionStarted:Fire(component, ...)
		end))
		
		component.Janitor:Add(component.Ended:Connect(function(...)
			self.InteractionEnded:Fire(component, ...)
		end))
		
		component.Janitor:Add(component.HoldStarted:Connect(function(...)
			self.InteractionHoldStarted:Fire(component, ...)
		end))
		
		component.Janitor:Add(component.HoldEnded:Connect(function(...)
			self.InteractionHoldEnded:Fire(component, ...)
		end))
	end)
end

--[[

	WHY BAD IDEA?
	
prompts will just be overriden by UserInputType input like mouse and etc. without keycodes 

]]

--function InteractionService.OnConstructClient(self: Service)
	
--	--input things
--	local ConnectionJanitor
--	local CurrentInteraction
	
--	self.InteractionShown:Connect(function(interaction)
		
--		CurrentInteraction = interaction
		
--		--resetting keycodes
--		interaction.Instance.ClickablePrompt = false
--		interaction.Instance.KeyboardKeyCode = Enum.KeyCode.Unknown
--		interaction.Instance.GamepadKeyCode = Enum.KeyCode.Unknown
		
--		--if prompt has switched to another
--		if ConnectionJanitor then
			
--			ConnectionJanitor:Destroy()
--			ConnectionJanitor = nil
--		end
		
--		--creating new janitor
--		ConnectionJanitor = Janitor.new()
		
--		ConnectionJanitor:Add(InputController.ContextStarted:Connect(function(context)
			
--			if context ~= "Interaction" then
--				return
--			end
			
--			print("Prompting to hold start")
--			interaction.Instance:InputHoldBegin()
--		end))
		
--		ConnectionJanitor:Add(InputController.ContextEnded:Connect(function(context)

--			if context ~= "Interaction" then
--				return
--			end
			
--			print("Prompting to hold end")
--			interaction.Instance:InputHoldEnd()
--		end))
--	end)
	
--	self.InteractionHidden:Connect(function(interaction)
		
--		--removing old janitor
--		if CurrentInteraction == interaction then
			
--			ConnectionJanitor:Destroy()
--			ConnectionJanitor = nil
--			CurrentInteraction = nil
--		end
--	end)
--end

--//Returner

local Singleton = InteractionService.new()
return Singleton :: Service