--[[

could handle every player purchases types (gamepasses, developer products, badges and etc.)

]]

-- service
local MarketplaceService = game:GetService('MarketplaceService')


-- MonetizationManager initial
local Initialized = false
local MonetizationService = {}
MonetizationService.gamepasses = {
	--{string = 'AdditionalBackpackSlots', asset = 825125726},
	--{string = 'Alice', asset = 824670744}
}

-- initial method
function MonetizationService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	for _, gamepass_module: ModuleScript in ipairs(script.Gamepasses:GetChildren()) do
		table.insert(MonetizationService.gamepasses, require(gamepass_module))
	end
	
	MarketplaceService.ProcessReceipt = function(...)
		MonetizationService:HandleProcessReceipt(...)
	end
end


function MonetizationService:GetGamepassFromSource(source: string|number)
	for _, gamepass in pairs(self.gamepasses) do
		if gamepass.asset == source or gamepass.string == source then
			return gamepass
		end
	end
end

function MonetizationService:CallGamepass( player: Player, source: string|number )
	for _, gamepass in pairs(self.gamepasses) do
		if gamepass.asset == source or gamepass.string == source then
			gamepass:Handle( player )
		end
	end
end

function MonetizationService:ForEachOwned( player: Player, callback: any )
	for _, gamepass in pairs(self.gamepasses) do
		if MonetizationService:PlayerHasGamepass( player, gamepass.asset ) then
			callback( gamepass.asset )
		end
	end
end

function MonetizationService:PlayerHasGamepass(player: Player, source: string|number)
	local gamepass = MonetizationService:GetGamepassFromSource(source)
	assert(gamepass, `No gamepass with any of source "{ source }" exists`)
	
	return MarketplaceService:UserOwnsGamePassAsync(
		player.UserId,
		gamepass.asset
	)
end

-- handle in-game player purchases
function MonetizationService:HandleProcessReceipt(...)
	-- uh
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- complete
return MonetizationService