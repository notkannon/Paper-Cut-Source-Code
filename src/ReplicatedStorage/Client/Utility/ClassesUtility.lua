--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Promise = require(ReplicatedStorage.Packages.Promise)
local Classes =  require(ReplicatedStorage.Shared.Classes)

--//Functions

local function PromiseSingletonsConstructed()
	local Amount = #Classes.GetAllSingletonConstructors()
	local Current = #Classes.GetAllSingletons()
	
	if Current == Amount then
		return
	end
	
	return Promise.new(function(resolve)
		
		local Connection: RBXScriptConnection
		
		Connection = Classes.SingletonConstructed.Connect(function()
			
			if #Classes.GetAllSingletons() < Amount then
				return
			end
			
			Connection:Disconnect()
			
			resolve()
		end)
		
	end):andThen(function()
		
		return Promise.resolve()
		
	end):await()
end

--//Returner

return {
	PromiseSingletonsConstructed = PromiseSingletonsConstructed,
}