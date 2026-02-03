--//Services

local RunService = game:GetService("RunService")
local PhysicsService = game:GetService('PhysicsService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local CollisionGroupService: Impl = Classes.CreateSingleton("CollisionGroupService") :: Impl

--//Types

export type Impl = {
	__index: Impl,
	
	GetName: () -> "CollisionGroupService",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Service) -> boolean,

	new: () -> Service,
	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),
}

export type Fields = {}

export type Service = typeof(setmetatable({} :: Fields, CollisionGroupService :: Impl))

--//Functions

local function RegisterCollisionGroup(name: string, collides_with_itself: boolean, collide_with: { string }, cant_collide_with: { string })
	
	PhysicsService:RegisterCollisionGroup(name)
	PhysicsService:CollisionGroupSetCollidable(name, name, collides_with_itself and true or false)
	
	if collide_with then
		
		for _, Group: string in ipairs(collide_with) do
			
			PhysicsService:CollisionGroupSetCollidable(name, Group, true)
		end
	end
	
	if cant_collide_with then
		
		for _, Group: string in ipairs(cant_collide_with) do
			
			PhysicsService:CollisionGroupSetCollidable(name, Group, false)
		end
	end
end

--//Methods

function CollisionGroupService.OnConstruct(self: Service)
	
	RegisterCollisionGroup("Players", false, {"Default"})
	RegisterCollisionGroup("Doors", false, {}, {"Default"})
	RegisterCollisionGroup("Items", true, {"Default", "Doors"}, {"Players"})
	RegisterCollisionGroup("Projectiles", false, {"Default", "Doors"})
	RegisterCollisionGroup("KillerBlocks", false, {"Default"}, {"Players", "Doors", "Items"})
	RegisterCollisionGroup("InvisibleWalls", true, {"Default", "Players"}, {"Projectiles", "Doors", "Items"}) -- used to constraint movement
end

--//Returner

local Singleton = CollisionGroupService.new()
return Singleton