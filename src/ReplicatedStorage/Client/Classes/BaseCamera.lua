--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

--//Types

export type Impl = {
	__index: Impl,
	
	Name: "BaseCamera",
	IsImpl: (self: BaseCamera) -> boolean,
	GetName: () -> string,
	
	OnEnd: (self: BaseCamera) -> (),
	OnStart: (self: BaseCamera) -> (),
	PreUpdate: (self: BaseCamera, deltaTime: number) -> (),
	AfterUpdate: (self: BaseCamera, deltaTime: number) -> (),
	OnConstruct: (self: BaseCamera) -> (),
}

export type Fields = {
	Active: boolean,
	Janitor: Janitor.Janitor,
	Controller: {any},
	MouseBehavior: Enum.MouseBehavior?,
}

export type BaseCamera = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Variables

local BaseCamera = Classes.CreateClass("BaseCamera", true) :: Impl

--//Functions

local function CreateCamera(name: string) : BaseCamera
	local Camera = Classes.CreateSingleton(name, false, BaseCamera)
	
	function Camera.new(controller: {any})
		assert(not Classes.ClassTables.Singletons[Camera.GetName()], `{ Camera.GetName() } camera singleton already exists`)
		
		local self = setmetatable({}, Camera)
		Classes.ClassTables.Singletons[Camera.GetName()] = self
		
		return self:_Constructor(controller) or self
	end

	return Camera
end

--//Methods

function BaseCamera._Constructor(self: BaseCamera, controller: {any})
	self.Active = false
	self.Janitor = Janitor.new()
	self.Controller = controller
	self.MouseBehavior = Enum.MouseBehavior.Default
	
	self:OnConstruct()
	
	Classes.SingletonConstructed:Fire(self)
end

function BaseCamera.OnEnd(self: BaseCamera) end

function BaseCamera.OnStart(self: BaseCamera) end

function BaseCamera.PreUpdate(self: BaseCamera, deltaTime: number) end

function BaseCamera.AfterUpdate(self: BaseCamera, deltaTime: number) end

function BaseCamera.OnConstruct(self: BaseCamera) end

--//Returner

return {
	CreateCamera = CreateCamera,
}