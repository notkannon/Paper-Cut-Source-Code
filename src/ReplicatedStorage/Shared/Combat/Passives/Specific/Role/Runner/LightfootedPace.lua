--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)
local TerrorController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.EnvironmentController.TerrorController) or nil

local ModifiedStaminaLoss = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaLoss)

--//Variables

local LightfootedPace = BaseComponent.CreateComponent("LightfootedPace", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),
}

export type Fields = {

} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "LightfootedPace", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "LightfootedPace", PlayerTypes.Character>

--//Methods

function LightfootedPace.OnEnabledClient(self: Component)
	local Config = self:GetConfig()
	
	local UpdateJanitor = Janitor.new()
	
	local function Update()
		print(TerrorController:GetCurrentLayerId())
		local InTerror = TerrorController:GetCurrentLayerId() ~= nil

		if InTerror then
			UpdateJanitor:Cleanup()
		else
			UpdateJanitor:Add(task.delay(Config.Delay, function()
				local WCSCharacter = WCSUtility.PromiseCharacterAdded(self.Instance):expect()

				local Effect = UpdateJanitor:Add(ModifiedStaminaLoss.new(WCSCharacter, "Multiply", Config.StaminaLossMultiplier,
					{
						FadeInTime = Config.FadeIn,
						FadeOutTime = Config.FadeOut
					}
					), "Destroy")
				
				Effect:Start()
			end))
		end
	end
	
	self.Janitor:Add(TerrorController.LayerChanged:Connect(Update))
	Update()
end

function LightfootedPace.OnConstruct(self: Component, enabled: boolean?)
	BasePassive.OnConstruct(self)
	self.Permanent = true
end

--//Returner

return LightfootedPace