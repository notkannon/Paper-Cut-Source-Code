--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Slices = require(ReplicatedStorage.Shared.Slices)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local ServerRemotes = require(script.Parent.ServerRemotes)
local DefaultPlayerData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)

--//Types

type Data = {Data: {[string]: DefaultPlayerData.Data}}

--//Variables

local PrivateActions = {"ApplyRoleConfig"}
local Root: RootProducer = Reflex.combineProducers(Slices)
local Broadcaster: Reflex.Broadcaster = Reflex.createBroadcaster({
	
	producers = Slices,

	dispatch = function(player, playerActions)
		ServerRemotes.Dispatch.Fire(player, playerActions)
	end,
	
	--actions replication
	beforeDispatch = function(receiver: Player, action: Reflex.BroadcastAction)
		
		if table.find(PrivateActions, action.name) then
			return
		end
		
		return action
	end,
	
	--disabling hydration
	hydrateRate = -1,
	
	--initial state replication
	beforeHydrate = function(receiver: Player, data: Data)
		
		--immuting original data table
		local Draft = TableKit.DeepCopy(data) :: Data
		
		for PlayerName, PlayerData in pairs(Draft.Data) do
			
			if PlayerName == receiver.Name then
				continue
			end
			
			for key, val in pairs(PlayerData.Save) do
				if key == "ClientSettings" then
					PlayerData.Save[key] = {}
				end
			end
		end
		
		return Draft
	end,
})

--//Types

export type Selector = (state: RootState) -> any
export type RootState = Slices.States
export type RootActions = Slices.Actions
export type RootProducer = Reflex.Producer<RootState, RootActions>
export type PlayerSelector<A> = (playerName: string, ...A) -> Selector

--//Main

ServerRemotes.Start.SetCallback(function(player)
	Broadcaster:start(player)
end)

Root:applyMiddleware(
	
	Broadcaster.middleware,
	
	--:ApplyRole() action handler
	function(producer)

		return function(nextDispatch, actionName)

			return function(...)

				if actionName == "ApplyRoleConfig" then
					
					local PlayerName, Config = ...
					local Player = Players:FindFirstChild(PlayerName)
					
					--clients will recieve this event faster than Reflex actions was applied before, so we just use servr state to tell them actual info
					ServerRemotes.RebuildRoleConfigClient.FireAll({
						player = Player,
						params = {
							Role = Config.Name,
							Skin = Config.SkinName,
							Character = Config.CharacterName,
						}
					})
				end

				return nextDispatch(...)
			end
		end
	end
)

--//Returner

return Root :: RootProducer