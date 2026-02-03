--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local ItemService = RunService:IsServer() and require(ServerScriptService.Server.Services.ItemService) or nil

--//Variables

local MischievousHeadstartPassive = BaseComponent.CreateComponent("MischievousHeadstart", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),

	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {

} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "MischievousHeadstartPassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "MischievousHeadstartPassive", PlayerTypes.Character>

--//Methods

function MischievousHeadstartPassive.OnEnabledServer(self: Component)
	local Success, InventoryComponent = ComponentsManager.Await(self.Player.Backpack, "InventoryComponent"):await()
	if Success and InventoryComponent then
		InventoryComponent:Add(ItemService:CreateItem("ThrowableBook", true), true)
	else
		warn(`Failed to load InventoryComponent: {InventoryComponent}`)
	end
end

function MischievousHeadstartPassive.OnConstruct(self: Component, enabled: boolean?)
	BasePassive.OnConstruct(self)
	self.Permanent = true
	print(self:GetName(), 'has started')
end

--//Returner

return MischievousHeadstartPassive