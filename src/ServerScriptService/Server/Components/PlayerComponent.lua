--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)
local ServerProducer = require(ServerScriptService.Server.ServerProducer)
local DefaultPlayerData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentTypes = require(ServerScriptService.Server.Types.ComponentTypes)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local PlayerComponent = BaseComponent.CreateComponent("PlayerComponent", {
	ancestorWhitelist = { Players },
}) :: ComponentTypes.PlayerImpl

--//Methods

function PlayerComponent.GetReflexData<S>(
	self: ComponentTypes.PlayerComponent,
	selector: ServerProducer.PlayerSelector<S>?,
	...: any
)
	return if selector
		then ServerProducer:getState(selector(self.Instance.Name, ...))
		else ServerProducer:getState().Data[self.Instance.Name]
end

function PlayerComponent.GetRoleConfig(self: ComponentTypes.PlayerComponent, role: string?)
	return RolesManager:GetPlayerRoleConfig(self.Instance)
end

function PlayerComponent.GetRoleString(self: ComponentTypes.PlayerComponent)
	return self:GetReflexData(Selectors.SelectRole)
end

function PlayerComponent.GetPlayerStats(self: ComponentTypes.PlayerComponent)
	return self:GetReflexData(Selectors.SelectPlayerStats)
end

function PlayerComponent.IsLoaded(self: ComponentTypes.PlayerComponent)
	return self._IsLoaded
end

function PlayerComponent.IsRespawning(self: ComponentTypes.PlayerComponent)
	return self._IsRespawning
end

function PlayerComponent.IsSpectator(self: ComponentTypes.PlayerComponent)
	return self:GetRoleString() == "Spectator"
end

function PlayerComponent.IsStudent(self: ComponentTypes.PlayerComponent)
	return self:GetRoleConfig().Team.Name == "Student"
end

function PlayerComponent.IsKiller(self: ComponentTypes.PlayerComponent)
	return self:GetRoleConfig().Team.Name == "Killer"
end

function PlayerComponent.GetChance(self: ComponentTypes.PlayerComponent, group: "Default" | "Anomaly")
	return self:GetReflexData(Selectors.SelectChance, group)
end

function PlayerComponent.SetChance(self: ComponentTypes.PlayerComponent, group: "Default" | "Anomaly", value: number)
	ServerProducer.UpdateChance(self.Instance.Name, group, value)
end

function PlayerComponent.Despawn(self: ComponentTypes.PlayerComponent)
	
	ComponentsManager.Remove(self.Instance.Backpack, "InventoryComponent")
	ComponentsManager.Remove(self.Instance.Character, "CharacterComponent")
	
	if not self.Instance.Character then
		return
	end
	
	--removing all character-related instances
	self.Instance.Character:Destroy()
	self.Instance.Character = nil
end

-- respawns player (reset his character)
function PlayerComponent.Respawn(self: ComponentTypes.PlayerComponent)
	
	local RoleConfig = self:GetRoleConfig()
	
	assert(self:IsLoaded(), `Cannot process respawn for player { self.Instance } because he wasn't loaded`)
	assert(RoleConfig, `Cannot respawn player { self.Instance } without applied role`)
	
	self._IsRespawning = true
	
	self:Despawn()
	
	task.wait(0.15) -- DONT REMOVE 🙏
	
	--avoiding to continue respawn flow when player is removed
	if self:IsDestroying()
		or self:IsDestroyed() then
		
		return
	end
	
	--character handling
	
	local CharacterMorph = RoleConfig.CharacterData.MorphInstance
	
	if CharacterMorph then
		
		local Character = CharacterMorph:Clone()
		Character.Name = self.Instance.Name
		self.Instance.Character = Character
		
	elseif self:IsSpectator() then	--spectators had their own roblox avatars
		
		self.Instance:LoadCharacter()
		
	else
		error(`Attempted to set player's morph from role { RoleConfig.Name }, but no morph available`)
	end
end

--role config related

function PlayerComponent.ApplyRoleConfig(self: ComponentTypes.PlayerComponent, shouldSpawn: boolean?)
	
	--spawn by default
	shouldSpawn = if shouldSpawn ~= nil then shouldSpawn else true
	
	RolesManager:_ApplyPlayerRoleConfig(self.Instance)
	
	--role config is strictly related to player's character. Different config = different character.
	--Or despawn if no need to respawn first
	if shouldSpawn then
		self:Respawn()
	else
		self:Despawn()
	end
end

function PlayerComponent.ResetCharacterMockData(self: ComponentTypes.PlayerComponent)
	
	--removing mock data on internal updates
	ServerProducer.SetMockData(self.Instance.Name, "MockCharacter", "")
	ServerProducer.SetMockData(self.Instance.Name, "MockSkin", "")
end

function PlayerComponent.SetCharacter(self: ComponentTypes.PlayerComponent, character: string, groupname: string)
	ServerProducer.SetCharacter(self.Instance.Name, groupname, character)
end

function PlayerComponent.SetRole(self: ComponentTypes.PlayerComponent, role: string)
	
	--role still the same
	if role == self:GetRoleString() then
		return
	end
	
	ServerProducer.SetRole(self.Instance.Name, role)
end

--not relate to data replication. Just displays player's stats temporary
function PlayerComponent._InitLeaderstats(self: ComponentTypes.PlayerComponent)
	
	local Leaderstats = Instance.new("Folder")
	Leaderstats.Parent = self.Instance
	Leaderstats.Name = "leaderstats"
	
	--connecting some values
	local function ChangeValue(name, value)
		
		local InstanceValue = Leaderstats:FindFirstChild(name)
		
		if not InstanceValue then
			
			InstanceValue = Instance.new("IntValue")
			InstanceValue.Parent = Leaderstats
			InstanceValue.Name = name
		end
		
		InstanceValue.Value = value
	end
	
	--connecting
	self.Janitor:Add(ServerProducer:subscribe(Selectors.SelectChance(self.Instance.Name, "Default"), function(chance)
		ChangeValue("Teacher Chance", chance)
	end))
	
	self.Janitor:Add(ServerProducer:subscribe(Selectors.SelectChance(self.Instance.Name, "Anomaly"), function(chance)
		ChangeValue("Anomaly Chance", chance)
	end))
	
	ChangeValue("Teacher Chance", self:GetChance("Default"))
	ChangeValue("Anomaly Chance", self:GetChance("Anomaly"))
end

function PlayerComponent._InitCharacter(self: ComponentTypes.PlayerComponent)

	local function HandleCharacterAdded(instance)

		ComponentsManager.Add(instance, "CharacterComponent", self)

		self._IsRespawning = false
	end

	self.Janitor:Add(self.Instance.CharacterAdded:Connect(HandleCharacterAdded))
	self.Janitor:Add(self.Instance.CharacterRemoving:Connect(function(character)
		ComponentsManager.Remove(character, "CharacterComponent")
	end))

	if self.Instance.Character then

		self.Janitor:Add(
			task.spawn(
				HandleCharacterAdded,
				self.Instance.Character
			)
		)
	end
end

function PlayerComponent._InitInventory(self: ComponentTypes.PlayerComponent)

	local function HandleInventoryComponentRemove()
		ComponentsManager.Remove(self.Instance.Backpack, "InventoryComponent")
	end

	local function HandleInventoryComponentAdd()
		
		--removing inventory before adding new
		HandleInventoryComponentRemove()

		if not self:GetRoleConfig().HasInventory then
			return
		end
		
		local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(self.Instance.Character)
		local InventoryComponent = ComponentsManager.Add(self.Instance.Backpack, "InventoryComponent")
		
		--removing on death
		InventoryComponent.Janitor:Add(
			CharacterComponent.Humanoid.Died:Once(function()
				CharacterComponent.Janitor:Remove("InventoryRemoveTask")
			end)
		)
		
		--removing on character component remove
		CharacterComponent.Janitor:Add(HandleInventoryComponentRemove, true, "InventoryRemoveTask")
	end

	self.Janitor:Add(
		PlayerService.CharacterAdded:Connect(function(character)
			
			if character ~= self.Instance.Character then
				return
			end
			
			HandleInventoryComponentAdd()
		end)
	)

	if ComponentsManager.Get(self.Instance.Character, "CharacterComponent") then
		self.Janitor:Add(task.spawn(HandleInventoryComponentAdd))
	end
end

function PlayerComponent._InitProfile(self: ComponentTypes.PlayerComponent)
	return Promise.new(function(resolve)
		PlayerService.LoadProfile(self.Instance)
			:andThen(function(profile)
				self.Janitor:Add(ServerProducer:subscribe(Selectors.SelectPlayerData(self.Instance.Name, "Save"), function(data)
					if not data then
						return
					end

					profile.Data = data
				end))

				self.Janitor:Add(function()
					profile:Release()
				end)

				resolve(profile.Data)
			end)
			:catch(function()
				resolve(TableKit.DeepCopy(DefaultPlayerData.Save))
			end)
	end)
end

function PlayerComponent.OnConstruct(self: ComponentTypes.PlayerComponent)
	
	self.ProfileData = self.Janitor:AddPromise(self:_InitProfile()):expect()
	self.RoleConfigChanged = self.Janitor:Add(Signal.new())
	
	ServerProducer.SetPlayerData(self.Instance.Name, {
		Save = TableKit.DeepCopy(self.ProfileData),
		Dynamic = TableKit.DeepCopy(DefaultPlayerData.Dynamic),
	})

	self:_InitLeaderstats()
	self:_InitInventory()
	self:_InitCharacter()
	
	self.Janitor:Add(ServerRemotes.ClientSettingSaveRequest.On(function(Player, Data)
		if Player ~= self.Instance then
			return
		end
		
		print(Player, Data)
		
		ServerProducer.UpdatePlayerSettings(
			Player.Name,
			Data
		)
	end))
	
	self.Janitor:Add(ServerProducer:subscribe(Selectors.SelectRoleConfig(self.Instance.Name), function(config)
		
		self.Instance.Team = config and config.Team or self.Instance.Team
		self.RoleConfigChanged:Fire(config)
	end))
end

function PlayerComponent.OnDestroy(self: ComponentTypes.PlayerComponent)
	ServerProducer.DeletePlayerData(self.Instance.Name)
end

--//Returner

return PlayerComponent