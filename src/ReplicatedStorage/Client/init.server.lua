--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local Refx = require(ReplicatedStorage.Packages.Refx)
local Utility = require(ReplicatedStorage.Shared.Utility)
local SmartBone = require(ReplicatedStorage.Packages.SmartBone)
local ClientRemotes = require(script.ClientRemotes)
local ClassesUtility = require(ReplicatedStorage.Client.Utility.ClassesUtility)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local WCSClient = WCS.CreateClient()

--//Init

Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })

Utility.AddPaths(ReplicatedStorage.Client)
Utility.AddPaths(ReplicatedStorage.Shared)

ComponentsManager.Start()

Refx.Register(ReplicatedStorage.Shared.Effects)
Refx.Start()

WCSClient:RegisterDirectory(ReplicatedStorage.Shared.Combat.Movesets)
WCSClient:RegisterDirectory(ReplicatedStorage.Shared.Combat.Statuses)
WCSClient:Start()

ClassesUtility.PromiseSingletonsConstructed()

--if not RunService:IsStudio() then
--	SmartBone.Start()
--end

--ClientRemotes.LoadedConfirmed.SetCallback(function(Player)
	
--end)

--skipping preloading in studio
--if RunService:IsStudio() then
--	ClientRemotes.Loaded:Fire()
--end