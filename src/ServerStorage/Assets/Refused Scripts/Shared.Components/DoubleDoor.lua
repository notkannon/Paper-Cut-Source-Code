--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports
local BaseDoor = require(ReplicatedStorage.Shared.Classes.Abstract.BaseDoor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local DoubleDoorEffect = require(ReplicatedStorage.Shared.Effects.Component.DoubleDoor)

--//Variables
local DoubleDoor = BaseComponent.CreateComponent("DoubleDoor", {
	tag = "DoubleDoor",
}, BaseDoor) :: Impl

--//Types
export type Impl = BaseDoor.Impl
export type Component = BaseDoor.Component

--//Methods
function DoubleDoor.OnConstructServer(self: Component)
	self.refxEffect = DoubleDoorEffect
	BaseDoor.OnConstructServer(self)
end

function DoubleDoor.OnConstructClient(self: Component)
	BaseDoor.OnConstructClient(self)
end

--//Returner
return DoubleDoor
