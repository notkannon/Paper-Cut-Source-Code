--//Services

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports


local WCS = require(ReplicatedStorage.Packages.WCS)
local Cmdr = require(ReplicatedStorage.Packages.Cmdr)
local Utility = require(ReplicatedStorage.Shared.Utility)
local ServerRemotes = require(script.ServerRemotes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local List = {}

local WCSServer = WCS.CreateServer()

--//Init

WCSServer:RegisterDirectory(ReplicatedStorage.Shared.Combat.Movesets)
WCSServer:RegisterDirectory(ReplicatedStorage.Shared.Combat.Statuses)
WCSServer:Start()

Cmdr:RegisterCommandsIn(ReplicatedStorage.Shared.Cmdr.Commands)
Cmdr:RegisterHooksIn(ReplicatedStorage.Shared.Cmdr.Hooks)
Cmdr:RegisterTypesIn(ReplicatedStorage.Shared.Cmdr.Types)

Utility.AddPaths(ServerScriptService.Server)
Utility.AddPaths(ReplicatedStorage.Shared)

ComponentsManager.Start()
