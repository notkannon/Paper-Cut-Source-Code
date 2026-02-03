--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseAppearance = require(ReplicatedStorage.Shared.Components.Abstract.BaseAppearance)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Constants

local TRANSPARENT_NAMES = {
	"Head",
	"Eyes",
	"Side",
	"Mouth",
	"Hair",
	"Cone",
	"Crown",
}

local TRANSPARENT_ACCESSORY_TYPES = {
	Enum.AccessoryType.Hat,
	Enum.AccessoryType.Hair,
	Enum.AccessoryType.Face,
	Enum.AccessoryType.Eyebrow,
	Enum.AccessoryType.Eyelash,
	Enum.AccessoryType.Neck,
}

--//Constants

local MAX_FOOTPRINTS_LEN = 30
local FOOTPRINT_THRESHOLD_DISTANCE = 1

local FOOTPRINT_RAYCAST_PARAMS = RaycastParams.new()
FOOTPRINT_RAYCAST_PARAMS.FilterDescendantsInstances = {workspace.Characters, workspace.Temp}
FOOTPRINT_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
FOOTPRINT_RAYCAST_PARAMS.CollisionGroup = "Players"
FOOTPRINT_RAYCAST_PARAMS.RespectCanCollide = true

--//Variables

local StudentAppearance = BaseComponent.CreateComponent("StudentAppearance", {
	isAbstract = false
}, BaseAppearance) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseAppearance.MyImpl)),
	
	Footprints: { {CFrame: CFrame, Timestamp: number} }
}

export type Fields = {
	
	FootprintAdded: Signal.Signal<CFrame>,
	
} & BaseAppearance.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "StudentAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "StudentAppearance", PlayerTypes.Character>

--//Methods

function StudentAppearance.CreateFootstep(self: Component)
	
	local Sound = BaseAppearance.CreateFootstep(self)
	
	if not Sound then
		return
	end
	
	Sound.PlaybackSpeed *= 2
	
	--footprints
	local Footprint = workspace:Raycast(
		self.Humanoid.RootPart.Position,
		Vector3.new(0, -10, 0),
		FOOTPRINT_RAYCAST_PARAMS
	)

	--storing player's new footprint position
	if Footprint then
		
		--removing last footprint
		if #self.Footprints >= MAX_FOOTPRINTS_LEN then
			table.remove(self.Footprints, #self.Footprints)
		end
		
		--distance check
		if self.Footprints[1] then
			
			local Distance = (self.Footprints[1].CFrame.Position - Footprint.Position).Magnitude
			
			--too near
			if Distance < FOOTPRINT_THRESHOLD_DISTANCE then
				return Sound
			end
		end
		
		local FootprintData = {
			CFrame = CFrame.lookAlong(Footprint.Position, Footprint.Normal),
			Timestamp = os.clock(),
		}
		
		table.insert(self.Footprints, 1, FootprintData)
		
		self.FootprintAdded:Fire(FootprintData.CFrame)
	end
	
	return Sound
end

function StudentAppearance.IsDescendantTransparent(self: Component, descendant: Instance)
	
	if not self:IsLocalPlayer() then
		return false
	end
	
	return table.find(TRANSPARENT_NAMES, descendant.Name) or descendant.Parent:IsA("Accessory")
		and table.find(TRANSPARENT_ACCESSORY_TYPES, descendant.Parent.AccessoryType)
end

function StudentAppearance.OnConstructClient(self: Component)
	BaseAppearance.OnConstructClient(self)
	
	self.Footprints = {}
	self.FootprintAdded = self.Janitor:Add(Signal.new())
end

--//Returner

return StudentAppearance