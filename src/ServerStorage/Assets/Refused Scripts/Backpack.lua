-- [[THIS MODULE SCRIPT IT'S NOT SAVING IT'S JUST SAVE THE TOOLS SO THAT CLIENT/SERVER CAN USE IT WITHOUT HACKING OR USING REMOTE]]

-- Service

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Items = ReplicatedStorage.Assets.Items

-- Imports
local EnumsType = require(ReplicatedStorage.Shared.Enums)


if RunService:IsServer() then
	--//Server
	
	--//Imports
	local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil


	--//Variables
	local Character = nil

	local Functions = {}
	local MaxHoldItems = 4

	local BackpackManager = {}
	BackpackManager.__index = BackpackManager

	local PlayerData = {}
	
	function BackpackManager.new()
		print("[Backpack | Server]: is Ready")

		
		Players.PlayerAdded:Connect(function(player: Player)
			
			PlayerData[player.UserId] = {
				Humanoid = nil,
				LocalPlayer = player,
				Character = nil,
				
				Actived = false,
				SaveStoreTools = {};
			}
			
			ServerRemotes.BackPack.SetCallback(function(player, args)
				
				BackpackManager:ReStore(player.UserId, args.someArrayOfNumbers)
			end)
			

			ServerRemotes.CanselTool.SetCallback(function()
				if not player.Character then return end
				if player.Character.Humanoid.Health <= 0 then return end

				player.Character:FindFirstChildOfClass("Tool"):Destroy()
			end)
			
			--// Actived Server
			BackpackManager:Server(player)
		end)
	end


	function BackpackManager:Server(LocalPlayer: Player)
		if PlayerData[LocalPlayer.UserId].Actived == true then return end
		PlayerData[LocalPlayer.UserId].Actived = false
		
		LocalPlayer.CharacterAdded:Connect(function(character: Model)
			Character = character			
			
			PlayerData[LocalPlayer.UserId].Humanoid = Character:WaitForChild("Humanoid")
			PlayerData[LocalPlayer.UserId].Character = Character

			
			BackpackManager:Defer(LocalPlayer)

			PlayerData[LocalPlayer.UserId].Humanoid.Died:Connect(function()
				-- save player store
				BackpackManager:ReStore(LocalPlayer.UserId)
			end)
			
		end)



	end


	function BackpackManager:IsActived(UserID: number)
		return PlayerData[UserID].Actived or false
	end


	function BackpackManager:ReStore(UserId: number, someArrayOfNumbers: {unknown})
		if not someArrayOfNumbers then return end
		PlayerData[UserId].SaveStoreTools = someArrayOfNumbers
	end


	function BackpackManager:Defer(LocalPlayer)
		if #PlayerData[LocalPlayer.UserId].SaveStoreTools == 0 then return end
		
		for i, Tool: number in pairs(PlayerData[LocalPlayer.UserId].SaveStoreTools) do
			if Tool == 0 then continue end
			
			local Tool2 = Items:FindFirstChild(EnumsType.Item_CodesID[tonumber(Tool)]):Clone()
			Tool2.Parent = LocalPlayer.Backpack
			
		end
	end
	

	function BackpackManager:GetEnumTool(Tool: string)

		return EnumsType.Item_CodesID[tostring(Tool)]
	end
	

	return {
		BackpackManager = BackpackManager,
		Functions = Functions,
	}


elseif RunService:IsClient() then
	--//Client
	
	--//Imports
	local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil

	--//Variables
	local LocalPlayer = Players.LocalPlayer
	local Character = nil

	local Functions = {
		ItemsPlayer = {}, -- functions (Add/Remove) new tool

	}
	
	local MaxHoldItems = 4
	
	local BackpackManager = {}
	BackpackManager.__index = BackpackManager
	BackpackManager.ClassName = "Backpack"
	
		
	--//Methods
	function BackpackManager.new()
		print("[Backpack | Client]: is Ready")

		local self = setmetatable({
			_ReplaceTool = nil, -- when tool equipped and unequipped so here it's add the last tool that the player equipped (For FIX Bug)
			_Items = { -- 0 it's mean it's nil
				0,
				0,
				0,
				0,

				-- gamepass
				0,
				0,
			}, -- items that save here 


			_Selected = 0, -- key selected

			_IsFreeze = false, -- if player was teacher so you can freeze the data so that can't get new tools by that
			_GetDateTime = os.clock(),

			_Actived = false,

			_SaveStoreTools = {};
		},BackpackManager)
		
		
		
		
		LocalPlayer.CharacterAdded:Connect(function(character: Model)
			Character = character
			
			self:SetBackpackPlayer()
			
			self.Humanoid = Character:WaitForChild("Humanoid")
			
			self:ClearItems() -- clear items (when player died so the restore can place the old items without add just replace it like Old = {1,1,0,0,0}, without clear {1,1,1,1,0} the player get double it)
			self.Humanoid.Died:Connect(function()
				-- save player store
				self:ReStore()
				self._Items = self._SaveStoreTools
				self:SetFreeze(true)
				
				return self
			end)
			
			
			Character.ChildRemoved:Connect(function(child: Instance)
				if child:IsA("Tool") and not child:IsDescendantOf(LocalPlayer.Backpack) and not self:IsFreezing() then
					
					print("[Client] Remove tool")
					self:RemoveTool(child.Name)
					
					if typeof(Functions.ItemsPlayer) == "function" then
						Functions.ItemsPlayer("Remove", tostring(child.Name))
					end
				elseif child:IsDescendantOf(LocalPlayer.Backpack) then
					self._ReplaceTool = child
					
					return self
				end
			end)
			
			
			LocalPlayer.Backpack.ChildRemoved:Connect(function(child: Instance)
				
				if child:IsA("Tool") and not child:IsDescendantOf(Character) and self._ReplaceTool ~= child and self._Items[self._Selected] == 0 and not self:IsFreezing() then
					print("[Client] Remove tool")
					self:RemoveTool()
					
					if typeof(Functions.ItemsPlayer) == "function" then
						Functions.ItemsPlayer("Add", child.Name)
					end
				end
			end)
			
			
			LocalPlayer.Backpack.ChildAdded:Connect(function(child: Instance) 
				if self._ReplaceTool ~= child  and child:GetAttribute("HotBar") == false and not self:IsFreezing() then

					print("[Client] New Tool")
					child:SetAttribute("HotBar", true)
					self:SetTool(child.Name) -- save the changes and add new tool into the list
					if typeof(Functions.ItemsPlayer) == "function" then -- send into client scripts
						Functions.ItemsPlayer("Add", child.Name)
					end
				end
			end)
			
			if self:IsFreezing() then
				task.delay(.25, function()
					-- freezing for just not let the restore place new tools
					
					self:SetFreeze(false)
				end)
			end
		end) 
		
		return self
	end
	
	function BackpackManager:DeleteTool()
		ClientRemotes.CanselTool.Fire()
	end

	
	-- get selected ui
	function BackpackManager:Seleted(key: number)
		self._Selected = (key or 0)
		
		return self
	end
	
	-- Restore the backpack so we can get old items
	function BackpackManager:ReStore()
		self._SaveStoreTools = self._Items
		ClientRemotes.BackPack.Fire({		
			someNumber = LocalPlayer.UserId,
			someArrayOfNumbers = self._SaveStoreTools
		})
		
		return self
	end
	
	-- Equipped items
	function BackpackManager:Equipped()
		if self._Selected == 0 then return end
		self.Humanoid:EquipTool(self._Items[self._Selected])
	end
	
	-- Unequipped Tools
	function BackpackManager:Unequipped()
		self.Humanoid:UnequipTools()
	end

	
	function BackpackManager:SetBackpackPlayer()
		assert(self._Items, "LocalPlayer is unfind in PLayersData")
		if self:IsFreezing(LocalPlayer) == true then return end
		
		for _, Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
			if not (Tool:IsA("Tool")) then continue end
			
			self:SetTool(Tool.Name)
		end
		
		for _, Tool in pairs(LocalPlayer.Character:GetChildren()) do
			if not (Tool:IsA("Tool")) then continue end

			self:SetTool(Tool.Name)
		end
	end
	
	-- get enum like (1 = "Book") or ("Book" = 1) 
	function BackpackManager:GetEnumTool(Tool: string)
		return EnumsType.Item_CodesID[tostring(Tool)]
	end

	function BackpackManager:GetItemsData()	
		
		return {
			Items = self._Items,
			HoldItems = #self._Items,
		}
	end



	function BackpackManager:ClearItems()	
		if self:IsFreezing(LocalPlayer) == true then return end

		for i = 1, 6, 1 do
			self._Items[i] = 0
		end
		
		if typeof(Functions.ItemsPlayer) == "function" then
			Functions.ItemsPlayer("Clear")
		end
	end


	function BackpackManager:Check(Tool: string) 

		local ToolID = self:GetEnumTool(Tool) -- get code id from enumtype
		local Many, Found = 0, false

		for i = 1, 6, 1 do
			if self._Items[i] == ToolID then 
				Many += 1
				Found = true
			end
		end

		return {
			Success = Found,
			ManyTool = Many
		}
	end
	
	function BackpackManager:IsFreezing()
		return self._IsFreeze
	end


	function BackpackManager:SetFreeze(ValueIndex: boolean)
		self._IsFreeze = (ValueIndex or false) 
		return self
	end
	

	function BackpackManager:SetTool(ToolName: string | number) 
		
		if self:IsFreezing(LocalPlayer) == true then return end
		if tonumber(self._Items[table.find(self._Items, 0)] or math.huge) > 4 then return end
		local Enums = 0
		if typeof(ToolName) == "string" then
			Enums = self:GetEnumTool(ToolName)
		else
			Enums = ToolName
		end
		
		self._Items[table.find(self._Items, 0)] = Enums
		self._GetDateTime = os.clock()
		
		return self
	end


	function BackpackManager:RemoveTool(RemoveIndex)
		if self:IsFreezing(LocalPlayer) == true then return end
		self._Items[RemoveIndex or self._Selected] = 0
		
		return self
	end
	
	function BackpackManager:RemovePlayer() -- left player

		self = nil
		return self
	end
	
	-- Return
	return {
		BackpackManager = BackpackManager,
		Functions = Functions,
	}
end