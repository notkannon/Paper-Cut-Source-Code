--//Services

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)

local SoundUtlity = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Variables

local PreloaderRig
local AssetService = Classes.CreateSingleton("AssetService") :: Impl
AssetService.AssetPreloaded = Signal.new()
AssetService.PreloadCompleted = Signal.new()

--//Types

export type Impl = {
	__index: Impl,

	IsImpl: (self: Service) -> boolean,
	GetName: () -> "AssetService",
	GetExtendsFrom: () -> nil,

	new: () -> Service,
	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),
	
	WaitUntilCompleted: (self: Service) -> (),
	GetAssetsToPreload: (self: Service) -> { Instance },
	
	_PreloadAssets: (self: Service) -> (),
	_PreprocessAsset: (self: Service, asset: Instance) -> (),
}

export type Fields = {
	Preloaded: boolean,
	Preloading: boolean,
	
	AssetPreloaded: Signal.Signal<number, number, Instance?>,
	PreloadCompleted: Signal.Signal<>,
}

export type Service = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Functions

local function CreateAnimationPreloader(): Instance
	local Rig = Instance.new("Model")
	local Humanoid = Instance.new("Humanoid")
	local RootPart = Instance.new("Part")
	
	RootPart.Parent = Rig
	Rig.PrimaryPart = RootPart
	Humanoid.Parent = Rig
	
	Rig.Parent = workspace
	Rig:PivotTo(CFrame.new(Vector3.one * 100000))
	
	return Rig
end

function AssetService.GetAssetsToPreload(self: Service)
	local AssetsToPreload = {}

	for _, Service in ipairs(GlobalSettings.Preloading.AssetsPreloadFrom) do
		for _, Asset in ipairs(Service:GetDescendants()) do
			if not table.find(GlobalSettings.Preloading.AllowedClassNames, Asset.ClassName) then
				continue
			end

			if table.find(AssetsToPreload, Asset) then
				continue
			end

			table.insert(AssetsToPreload, Asset)
		end
	end

	return AssetsToPreload
end

--//Methods

function AssetService._PreprocessAsset(self: Service, asset: Instance)
	
	if asset:IsA("Animation") then
		
		AnimationUtility.QuickPlay(
			PreloaderRig.Humanoid,
			asset,
			{
				Looped = false
			}
		)
	end
end

function AssetService._PreloadAssets(self: Service)
	assert(not self.Preloaded, "Already preloaded assets")
	assert(not self.Preloading, "Assets preloading already started")
	
	self.Preloading = true
	
	local Packet = GetAssetsToPreload()
	local Amount = #Packet
	local Preloaded = 0
	
	for _, Asset in ipairs(Packet) do
		self:_PreprocessAsset(Asset)
	end
	
	if RunService:IsClient() then
		for _, Asset in ipairs(Packet) do
			ContentProvider:PreloadAsync({ Asset })
			Preloaded += 1
			
			self.AssetPreloaded:Fire(Preloaded, Amount, Asset)
		end
	end
	
	self.Preloaded = true
	self.PreloadCompleted:Fire()
end

function AssetService.WaitUntilCompleted(self: Service)
	return self.Preloaded or self.PreloadCompleted:Wait()
end

function AssetService.OnConstruct(self: Service)
	self.Preloaded = false
	self.Preloading = false
	
	--PreloaderRig = CreateAnimationPreloader()
	
	--ThreadUtility.UseThread(self._PreloadAssets, self)
end

--//Returner

local Singleton = AssetService.new()
return Singleton :: Service