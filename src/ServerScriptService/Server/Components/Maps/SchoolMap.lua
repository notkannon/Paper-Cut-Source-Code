--//Service

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local Type = require(ReplicatedStorage.Packages.Type)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseMap = require(ServerScriptService.Server.Components.Abstract.BaseMap)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local SchoolMap = BaseComponent.CreateComponent("SchoolMap", {

	tag = "SchoolMap",
	isAbstract = false,

}, BaseMap) :: Impl

--//Types

export type MyImpl = BaseMap.MyImpl
export type Fields = BaseMap.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SchoolMap", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "SchoolMap", Instance, any...>

--//Returner

--function SchoolMap.OnConstructServer(self: Component)
--	BaseMap.OnConstructServer(self)
--end

--function SchoolMap.OnDestroy(self: Component)
--	print("School map destroyed!")
--end

return SchoolMap