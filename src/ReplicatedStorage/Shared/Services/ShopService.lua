--// Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptStorage = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

--// Imports

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Classes = require(ReplicatedStorage.Shared.Classes)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local CharactersData = require(ReplicatedStorage.Shared.Data.Characters)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local PlayerService = RunService:IsServer() and require(ServerScriptStorage.Server.Services.PlayerService) or nil

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)

local ServerProducer = RunService:IsServer() and require(ServerScriptStorage.Server.ServerProducer) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptStorage.Server.ServerRemotes) or nil
local ClientProducer = RunService:IsClient() and require(ReplicatedStorage.Client.ClientProducer) or nil
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil

--// Variables

local ShopService = Classes.CreateSingleton("ShopService", false) :: Singleton

--// Constants


local CharacterTypes: {CharacterType} = {"Anomaly", "Student", "Teacher"}
local MAX_BUY_ITEM_SLOTS = 3

--// Types

export type CharacterType = "Anomaly" | "Teacher" | "Student"
export type ItemType = "Throwable" | "Consumable" | "Usable"
export type BuyPurchasedType = "Item" | "Character" 

export type PlayerItemType = {
	Spawned: boolean,
	Items: {[string]: string}
}

export type MyImpl = {
	__index: MyImpl,
	
	GetName: () -> "ShopService",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Singleton) -> boolean,
	
	GetCharacterType: (self: Singleton, Character: string) -> CharacterType,
	GetItemType: (self: Singleton, Item: string) -> ItemType,

	IsCharacterOwned: (self: Singleton, Player: Player, Character: string, promisify: boolean?) -> boolean,
	IsSkinOwned: (self: Singleton, Player: Player, Character: string, Skin: string, promisify: boolean?) -> boolean,
	IsPlayerStateLoaded: (self: Singleton, Player: Player) -> boolean,
	
	GetPlayerOwned: (self: Singleton, Player: Player, promisify: boolean?) -> { [string]: {string} },
	GetCurrentCharacter: (self: Singleton,  Player: Player, SearchTo: CharacterType, promisify: boolean?) -> string,
	GetCurrentSkin: (self: Singleton, Player: Player, Character: string, promisify: boolean?) -> string,
	
	SetCharacter: (self: Singleton, Player: Player, Character: string) -> (),
	SetSkin: (self: Singleton, Player: Player, Character: string, Skin: string) -> (),
	
	BuyCharacter: (self: Singleton, Player: Player, Character: string) -> (),
	BuySkin: (self: Singleton, Player: Player, Character: string, Skin: string) -> (),
	BuyItem: (self: Singleton, Player: Player, Item: string) -> (),
	
	new: () -> Singleton,
	OnConstruct: (self: Singleton) -> (),
	OnConstructServer: (self: Singleton) -> (),
	OnConstructClient: (self: Singleton) -> (),
}

export type Fields = {
	Janitor: Janitor.Janitor,
	
	-- Signals
	PlayerOwnedChanged: Signal.Signal<Player, { [string]: {string} }>,
	PlayerCharacterChanged: Signal.Signal<Player, string>,
	PlayerSkinChanged: Signal.Signal<Player, string, string>,
	
	-- Tables
	PlayerItemsSaved: { [string]: PlayerItemType }, -- PlayerName|Items
}

export type Singleton = typeof(setmetatable({} :: Fields, {} :: MyImpl))

--// Methdos

function ShopService.GetCharacterType(self: Singleton, Character: string)
	local CharacterData = CharactersData[Character]

	if not CharacterData then
		return
	end
	
	local IntendedRole = CharacterData.IntendedRole or "Student"
	return IntendedRole
end

function ShopService.IsCharacterOwned(self: Singleton, Player: Player, Character: string, promisify: boolean?)
	local PlayerOwned = self:GetPlayerOwned(Player, promisify)
	
	local function _InternalHandler(value)
		if not value then
			return false
		end

		local Saved = value[Character]
		return Saved ~= nil
	end
	
	if promisify then
		return PlayerOwned:andThen(_InternalHandler)
	else
		return _InternalHandler(PlayerOwned)
	end
end

function ShopService.IsSkinOwned(self: Singleton, Player: Player, Character: string, Skin: string, promisify: boolean?)
	local CharacterOwned = self:IsCharacterOwned(Player, Character, promisify)
	
	local function _InternalHandler(value)
		if not value then
			return false
		end

		local PlayerOwned = self:GetPlayerOwned(Player)
		if not PlayerOwned then
			return false
		end
		
		local Character = PlayerOwned[Character]
		if not Character then
			return false
		end
		-- raw state is Owned = {Char = {"Skin1", "Skin2"}} :think:
		--print(Character, Skin, " IsSkinOwned()")
		local Saved = table.find(Character, Skin)
		return Saved ~= nil
	end
	
	if promisify then
		return CharacterOwned:andThen(_InternalHandler)
	else
		return _InternalHandler(CharacterOwned)
	end
end

function ShopService.SelectorWaitWrap(self: Singleton, Selector, Player: Player)
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	
	return if self:IsPlayerStateLoaded(Player) then Promise.resolve(Producer:getState(Selector)) else Producer:wait(Selector)
end

function ShopService.IsPlayerStateLoaded(self: Singleton, Player: Player)
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	local RawPlayerState = Producer:getState().Data[Player.Name]

	return RawPlayerState and typeof(RawPlayerState) == "table" and #TableKit.Keys(RawPlayerState) > 0 or false
end

function ShopService.GetPlayerOwned(self: Singleton, Player: Player, promisify: boolean?) 
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	local Selector = Selectors.SelectOwnedCharacters(Player.Name)
	
	local SelectorOwned = if promisify then self:SelectorWaitWrap(Selector, Player) else Producer:getState(Selector)

	return SelectorOwned
end

function ShopService.GetCurrentCharacter(self: Singleton, Player: Player, SearchTo: CharacterType, promisify: boolean?)
	if SearchTo == "Teacher" then
		return promisify and Promise.resolve(nil) or nil
	end
	
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	
	local Selector = Selectors.SelectCharacter(Player.Name, SearchTo)
	local Character = if promisify then self:SelectorWaitWrap(Selector, Player) else Producer:getState(Selector)
	
	return Character
end

function ShopService.GetCurrentSkin(self: Singleton, Player: Player, Character: string, promisify: boolean?) 
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	local Selector = Selectors.SelectSkin(Player.Name, Character)
	local Skin =  if promisify then self:SelectorWaitWrap(Selector, Player) else Producer:getState(Selector)
	
	return Skin
end

function ShopService.SetCharacter(self: Singleton, Player: Player, Character: string)
	if not RunService:IsServer() then
		return
	end
	
	local IsCharacterOwned = self:IsCharacterOwned(Player, Character)
	local CharacterType = self:GetCharacterType(Character)
	
	if CharacterType == "Teacher" then
		return
	end
	
	if not IsCharacterOwned then
		return
	end
	
	if self:GetCurrentCharacter(Player, CharacterType) == Character then
		print("[ShopService]: Same Character to: "..Player.Name, " Character: ", Character)
		return
	end
	
	ServerProducer.SetCharacter(Player.Name, CharacterType, Character)
	self.PlayerCharacterChanged:Fire(Player, Character)
	print("[ShopService]: Player: ", Player.Name, " Equipped Character: ", Character)
end

function ShopService.SetSkin(self: Singleton, Player: Player, Character: string, Skin: string)
	if not RunService:IsServer() then
		return
	end
	
	local IsCharacterOwned = self:IsCharacterOwned(Player, Character)
	if not IsCharacterOwned then
		print("[ShopService]: You Doesnt Have Character Owned ".. Character)
		return
	end
	
	if self:GetCurrentSkin(Player, Character) == Skin then
		print("[ShopService]: Same Skin to: "..Player.Name, " Skin: ", Skin)
		return
	end
	
	-- Checker if u have default but somereason u doesnt have it :skull:
	local IsDefault = Skin == "Default"
	if IsDefault then
		ServerProducer.SetSkin(Player.Name, Character, "Default")
		print("[ShopService]: Player: ", Player.Name, " Equipped Skin: Default, okay?")
		return
	end
	
	local IsSkinOwned = self:IsSkinOwned(Player, Character, Skin)
	if not IsSkinOwned then
		print("[ShopService]: You Doesnt Have Skin Owned ".. Skin)
		return
	end
	
	local CharacterType = self:GetCharacterType(Character)
	if CharacterType ~= "Teacher" then
		local CurrentCharacter = self:GetCurrentCharacter(Player, CharacterType)
		if CurrentCharacter ~= Character then
			print("[ShopService]: You Cant Equip Skin On Character You Dont Have Equipped")
			return
		end
	end
	
	ServerProducer.SetSkin(Player.Name, Character, Skin)
	self.PlayerSkinChanged:Fire(Player, Character, Skin)
	print("[ShopService]: Player: ", Player.Name, " Equipped Skin: ", Skin)
end

function ShopService.BuyCharacter(self: Singleton, Player: Player, Character: string)
	if not RunService:IsServer() then
		return
	end
	
	local IsCharacterOwned = self:IsCharacterOwned(Player, Character)
	if IsCharacterOwned then
		print("[ShopService]: Player:", Player.Name, "already owns character", Character)
		return
	end
	
	local Points = ServerProducer:getState(Selectors.SelectStats(Player.Name)).Points
	local Price = CharactersData[Character].Cost
	
	if not Points or not Price then
		warn("[ShopService]: Invalid points/price: Points:", Points, "Price:", Price)
		return
	end
	
	local CanPurchase = Points >= Price
	if not CanPurchase then
		print("[ShopService]: Player:", Player.Name, "doesn't have enough points to buy", Character)
		return
	end
	
	ServerProducer.UpdatePlayerStats(
		Player.Name,
		"Points",
		Points - Price
	)
	
	ServerProducer.UpdateOwnedCharacter(
		Player.Name,
		Character
	)
	
	-- this is a bad remote, it triggers before reflex works
	--ServerRemotes.ShopServiceBuyConfirm.Fire(Player, {
	--	Type = "Character",
	--	Data = {
	--		Character = Character,
	--		Skin = "Default",
	--		ItemName = "",
	--		Amount = 0
	--	}
	--})
	
	print("[ShopService]: Purchase Successful of: ", Character, " Owner: ", Player.Name)
end

function ShopService.BuySkin(self: Singleton, Player: Player, Character: string, Skin: string)
	if not RunService:IsServer() then
		return
	end
	
	local IsCharacterOwned = self:IsCharacterOwned(Player, Character)
	if not IsCharacterOwned then
		return
	end
	
	local IsSkinOwned = self:IsSkinOwned(Player, Character, Skin)
	if IsSkinOwned then
		return
	end
	
	local Points = ServerProducer:getState(Selectors.SelectStats(Player.Name)).Points
	local Price = CharactersData[Character].Cost

	if not Points or not Price then
		warn("[ShopService]: Invalid points/price: Points:", Points, "Price:", Price)
		return
	end
	
	local CanPurchase = Points >= Price
	if not CanPurchase then
		return
	end
	
	local SkinList = TableKit.DeepCopy(ServerProducer:getState(Selectors.SelectOwnedSkins(Player.Name, Character)))
	if table.find(SkinList, Skin) then
		return
	end
	
	table.insert(SkinList, Skin)
	--print(SkinList)

	ServerProducer.UpdatePlayerStats(
		Player.Name,
		"Points",
		Points - Price
	)
	
	ServerProducer.UpdateOwnedSkins(
		Player.Name,
		Character,
		SkinList
	)

	print("[ShopService]: Purchased Successful to: ", Skin, " Owner: ", Player.Name)
end

function ShopService.BuyItem(self: Singleton, Player: Player, Item: string)
	assert(RunService:IsServer())
	
	local CurrentItemsSize = #TableKit.Values(self.PlayerItemsSaved[Player.Name].Items)
	if CurrentItemsSize >= MAX_BUY_ITEM_SLOTS then
		print("[ShopService]: bro?, what are u doing?? y cant buy")
		return
	end
	
	local Points: number = ServerProducer:getState(Selectors.SelectStats(Player.Name)).Points
	local Cost: number = 0
	
	if not Points then
		warn("[ShopService]: Invalid points: Points:", Points)
		return
	end

	
	for ItemName, ItemData in ItemsData do
		local SubPrefix = string.gsub(ItemName, "Throwable", "")
		if SubPrefix == Item then
			Cost = ItemData.Cost
			break
		end
	end
	
	if Points <= Cost then
		print("[ShopService]: not enough points")
		return
	end
	
	ServerProducer.UpdatePlayerStats(
		Player.Name,
		"Points",
		Points - Cost
	)
	
	self.PlayerItemsSaved[Player.Name].Items[tostring(Item..(CurrentItemsSize+1))] = Item
	print("[ShopService]: Purchased Successful to:", Item, " Owner: ", Player.Name)
end

function ShopService.OnConstruct(self: Singleton)
	self.Janitor = Janitor.new()
	self.PlayerOwnedChanged = self.Janitor:Add(Signal.new())
	self.PlayerCharacterChanged = self.Janitor:Add(Signal.new())
	self.PlayerSkinChanged = self.Janitor:Add(Signal.new())
	
	self.PlayerItemsSaved = {}
end

function ShopService.OnConstructServer(self: Singleton)

	self.Janitor:Add(Players.PlayerAdded:Connect(function(Player)
		self.PlayerItemsSaved[Player.Name] = {
			Spawned = false,
			Items = {}
		}
	end))
	
	self.Janitor:Add(Players.PlayerRemoving:Connect(function(Player)
		self.PlayerItemsSaved[Player.Name] = nil
	end))

	self.Janitor:Add(ServerRemotes.ShopServiceBuy.On(function(Player: Player, Data)
		--print(Data)
		if Data.Type == "Character" then
			self:BuyCharacter(Player, Data.Data.Character)
			self:BuySkin(Player, Data.Data.Character, "Default")
		elseif Data.Type == "Skin" then
			if Data.Data.Skin == "" then
				return
			end
		
			self:BuySkin(Player, Data.Data.Character, Data.Data.Skin)
		else
			self:BuyItem(Player, Data.Data.ItemName)
		end
	end))
	
	self.Janitor:Add(ServerRemotes.ShopServiceChangeSelected.SetCallback(function(Player, Data)
		--print(Data)
		self:SetCharacter(Player, Data.Character)
		self:SetSkin(Player, Data.Character, Data.Skin)
	end))
end

function ShopService.OnConstructClient(self: Singleton)
	self.Janitor:Add(ClientProducer.Root:subscribe(Selectors.SelectOwnedCharacters(Players.LocalPlayer.Name, function(Data)
		--print('changing to', Data)
		self.PlayerOwnedChanged:Fire(Players.LocalPlayer, Data)
	end)))
	
	for _, CharacterType in CharacterTypes do
		if CharacterType == "Teacher" then
			continue
		end
		self.Janitor:Add(ClientProducer.Root:subscribe(Selectors.SelectCharacter(Players.LocalPlayer.Name, CharacterType), function(Data)
			self.PlayerCharacterChanged:Fire(Players.LocalPlayer, Data)
		end))
	end
end

--// Returner

local Singleton = ShopService.new()
return Singleton