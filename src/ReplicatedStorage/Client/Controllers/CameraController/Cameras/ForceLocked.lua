--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseCamera = require(ReplicatedStorage.Client.Classes.BaseCamera)

--//Types

export type Impl = {
	__index: typeof(setmetatable({} :: Impl, {} :: BaseCamera.Impl)),

	new: (controller: {any}) -> Singleton,
}

export type Fields = {
} & BaseCamera.Fields

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Variables

local ForceLockedCamera = BaseCamera.CreateCamera("ForceLockedCamera") :: Impl

--//Methods

function ForceLockedCamera.OnStart(self: Singleton)

end

function ForceLockedCamera.OnUpdate(self: Singleton, deltaTime: number)

end

--//Returner

return ForceLockedCamera