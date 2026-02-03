local client = shared.Client
local requirements = client._requirements
local ItemThrowService = require(game.ReplicatedStorage.Shared.ItemThrowService)

-- objects
local tool = script.Parent
local ItemId = tool:GetAttribute('Id')
local replicatedStorage = game:GetService('ReplicatedStorage')
local event = replicatedStorage.Replication:WaitForChild('ItemEvent')

-- requirements

-- vars
local released = false

local animation_tracks = {} :: { AnimationTrack }
local connections = {} do
	function connections:AddConnection( signal: RBXScriptConnection, name: string )
		self:DropConnection( name )
		self[ name ] = signal
	end
	
	function connections:DropConnection( name: string )
		if self[ name ] then
			self[ name ]:Disconnect()
		end
	end
end



tool.Equipped:Connect(function()
	local local_character = client.local_character
	if not local_character.Instance then return end
	if connections.animation_release then return end

	local animation_tracks = animation_tracks
	local animations = game.ReplicatedStorage.Assets.Animations.Items.Firework

	--animation: Animation, name: string, speed: number, looped: boolean, priority: Enum.AnimationPriority
	animation_tracks.release = local_character:LoadAnimation(animations.Release, nil, 1, false, Enum.AnimationPriority.Action4)
	animation_tracks.equip = local_character:LoadAnimation(animations.Equip, nil, 1, false, Enum.AnimationPriority.Action4)
	animation_tracks.idle = local_character:LoadAnimation(animations.Idle, nil, 1, true, Enum.AnimationPriority.Action3)
end)


tool.Unequipped:Connect(function()
	local animation_tracks = animation_tracks
	animation_tracks.idle:Stop()
end)


tool.Activated:Connect(function()
	local animation_tracks = animation_tracks
	if released then return end
	
	animation_tracks.idle:Play()
	animation_tracks.release:Play()
	
	event:FireServer(
		ItemId,
		'Firework context'
	)
end)