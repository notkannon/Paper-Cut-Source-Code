--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseDoor = require(ReplicatedStorage.Shared.Classes.Abstract.BaseDoor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SingleDoorEffect = require(ReplicatedStorage.Shared.Effects.Component.SingleDoor)

--//Variables

local SingleDoor = BaseComponent.CreateComponent("SingleDoor", {
	tag = "SingleDoor",
}, BaseDoor) :: Impl

--//Types

export type Impl = BaseDoor.Impl
export type Component = BaseDoor.Component

--//Methods

function SingleDoor.OnConstructServer(self: Component)
	self.refxEffect = SingleDoorEffect
	BaseDoor.OnConstructServer(self)
end

----//Returner

--return SingleDoor
return {}
