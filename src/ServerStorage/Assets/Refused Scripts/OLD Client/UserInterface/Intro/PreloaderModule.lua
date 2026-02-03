type Asset = Texture | Decal | ImageLabel | ImageButton | MeshPart | Animation | Sound
local contentProvider = game:GetService('ContentProvider')
local AnimationPreloaderRig = workspace:WaitForChild('Temp').AnimationsPreloader

local allowed_types = {
	'Decal',
	'Texture',
	'ImageLabel',
	'ImageButton',
	'Animation',
	'MeshPart',
	'Sound'
}

local service_to_parse = {
	game.Workspace,
	game.ReplicatedStorage,
	game.ReplicatedFirst,
	game.SoundService,
	game.StarterGui,
}

local Preloader = {} do
	Preloader.__index = Preloader
	
	function Preloader.new()
		return setmetatable({
			assetsToPreload = {},
			assetsPreloaded = 0,
			isPreloaded = false
		}, Preloader)
	end
end


function Preloader:GetAssetsToPreload()
	for _, service in ipairs(service_to_parse) do
		for _, asset: Asset? in ipairs(service:GetDescendants()) do
			if not table.find(allowed_types, asset.ClassName) then continue end
			if table.find(self.assetsToPreload, asset) then continue end
			table.insert(self.assetsToPreload, asset)
		end
	end
end


function Preloader:Skip()
	self.isPreloaded = true
end


function Preloader:Run(function_on_asset_preloaded: any?)
	self:GetAssetsToPreload()
	print('assets to preload -', #self.assetsToPreload)
	
	while self.assetsPreloaded < #self.assetsToPreload
		and not self.isPreloaded do
		
		local asset: Asset = self.assetsToPreload[self.assetsPreloaded + 1]
		contentProvider:PreloadAsync({ asset })
		self.assetsPreloaded += 1
		
		-- if animation then we should preload it by this way
		if asset:IsA('Animation') then
			AnimationPreloaderRig
				:FindFirstChildOfClass('Humanoid')
				:LoadAnimation(asset):Play()
		end
		
		function_on_asset_preloaded(self.assetsPreloaded)
	end
end

return Preloader.new()