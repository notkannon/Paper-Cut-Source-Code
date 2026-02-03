--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Constants

local LOGGING_ENABLED = false

--//Variables

local Player = Players.LocalPlayer
local BaseStatusEffect = WCS.RegisterStatusEffect("BaseStatusEffect")

--//Types

type Metadata = {
	Duration: number,
	StartTimestamp: number,
	_trackTimestamps: boolean,
}

export type BaseStatusEffect = {
	
	--if status has this field then it will be displayed on player's hud with provided params
	DisplayData: {
		DisplayIcon: string,
		DisplayName: string,
	}?,
	
	FromRoleData: { string: any },
	GenericJanitor: Janitor.Janitor,
	IgnoreMutualTagged: boolean?,
	
	_Duration: number,
	_StartTimestamp: number,
	
	GetMetadata: (self: BaseStatusEffect) -> Metadata,
	GetEndTimestamp: (self: BaseStatusEffect) -> number,
	GetActiveDuration: (self: BaseStatusEffect) -> number,
	
} & WCS.StatusEffect

--//Methods

function BaseStatusEffect.GetActiveDuration(self: BaseStatusEffect)
	return self._Duration
end

function BaseStatusEffect.GetEndTimestamp(self: BaseStatusEffect)
	return self._StartTimestamp + self._Duration
end

function BaseStatusEffect.Start(self: BaseStatusEffect, duration: number?)
	
	self._Duration = duration or 0
	self._StartTimestamp = workspace:GetServerTimeNow()
	
	local Meta = {
		Duration = self._Duration,
		StartTimestamp = self._StartTimestamp,
		_trackTimestamps = true,
	} :: Metadata
	
	
	self:SetMetadata(TableKit.MergeDictionary(self:GetMetadata() or {}, Meta))
	
	--self.GenericJanitor:Add(self.Ended:Connect(function()
	--	local Meta = self:GetMetadata()
	--	if not Meta or not Meta.Duration then
	--		return
	--	end
		
	--	Meta = TableKit.DeepCopy(Meta)
	--	Meta.Duration = nil
		
	--	self:SetMetadata(Meta)
	--end))
	
	WCS.StatusEffect.Start(self, duration)
end

function BaseStatusEffect.OnConstruct(self: BaseStatusEffect)
	
	self.GenericJanitor = Janitor.new()
	
	self.Destroyed:Once(function()
		
		if not self.GenericJanitor.Destroy then
			return
		end
		
		self.GenericJanitor:Destroy()
	end)
	
	if RunService:IsClient() then
		
		local function OnMetaChanged(new: Metadata?)
			
			if not new or not new._trackTimestamps then
				return
			end
			
			self._Duration = new.Duration
			self._StartTimestamp = new.StartTimestamp
		end
		
		self.GenericJanitor:Add(self.MetadataChanged:Connect(OnMetaChanged))
		
		OnMetaChanged(self:GetMetadata())
	end
	
	if RunService:IsClient() then
		
		local DebugUi = Player
			:WaitForChild("PlayerGui")
			:FindFirstChild("Debug") :: typeof(game.StarterGui.Debug)
		
		if DebugUi then
			
			local Connection = self.Started:Connect(function()
				
				local label = DebugUi.StatusEffect.Content.label:Clone()
				
				label.Text = self.Name
				
				if self.Options and self.Options.Tag then 
					label.Text ..= ` ({self.Options.Tag})`
				end
				
				if self.GetAlpha then
					local BaseText = label.Text
					self.GenericJanitor:Add(RunService.Heartbeat:Connect(function(d)
						label.Text = BaseText .. string.format(" [%.1f%%]", self:GetAlpha() * 100)
					end))
				end
				
				label.Parent = DebugUi.StatusEffect.Content
				label.Visible = true
				label.Duration.Visible = false
				
				local duration = self:GetActiveDuration()
				
				if duration > 0 then
					
					label.Duration.Visible = true
					label.Duration.Size = UDim2.fromScale(1, 1)
					label.Duration:TweenSize(UDim2.fromScale(0, 1), "Out", "Linear", duration)
				end
				
				local function HandleRemoval()
					
					if not label then
						return
					end
					
					label:Destroy()
				end
				
				self.GenericJanitor:Add(label, "Destroy")
				if self.DestroyOnFadeOut then
					self.Destroyed:Once(function()
						label:Destroy()
					end)
				else
					self.Ended:Once(function() label:Destroy() end)
				end
			end)
			
			self.GenericJanitor:Add(Connection)
		end
	end
	
	--role config
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
	
	self.FromRoleData = RoleConfig.StatusesData[self.Name]
	
	if not self.FromRoleData and RunService:IsStudio() and LOGGING_ENABLED then
		warn(self.FromRoleData, `No StatusEffect { self.Name } data registered in role { RoleConfig.DisplayName }`)
	end
end

--//Returner

return BaseStatusEffect