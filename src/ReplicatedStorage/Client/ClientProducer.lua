--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Reflex = require(ReplicatedStorage.Packages.Reflex)
local ClientSlices = RunService:IsClient() and require(ReplicatedStorage.Shared.Slices.ClientSlices)
local ClientRemotes = RunService:IsClient() and require(script.Parent.ClientRemotes)

--//Variables

local Player = Players.LocalPlayer

local Root: RootProducer = Reflex.combineProducers(ClientSlices)
local Receiver: Reflex.BroadcastReceiver = Reflex.createBroadcastReceiver({
	start = function()
		ClientRemotes.Start.Fire()
	end,
})

--//Types

export type RootProducer = Reflex.Producer<RootState, RootActions>
export type RootState = ClientSlices.States
export type RootActions = ClientSlices.Actions
export type Selector = (state: RootState) -> any
export type PlayerSelector<A> = (playerName: string, ...A) -> Selector
-- dont look this, instead use it, bcause u wont see the funcion in the module \ ed
--//Functions

local function GetReflexData<S>(selector: PlayerSelector<S>?, ...)
	return if selector then Root:getState(selector(Player.Name, ...)) else Root:getState().Data[Player.Name]
end

--//Main

ClientRemotes.Dispatch.SetCallback(function(actions)
	Receiver:dispatch(actions)
end)

Root:applyMiddleware(
	Receiver.middleware
)

--//Returner

return {
	Root = Root :: RootProducer,
	GetReflexData = GetReflexData,
}