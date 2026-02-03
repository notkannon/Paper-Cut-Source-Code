local client = shared.Client
local requirements = client._requirements
local ItemThrowService = require(game.ReplicatedStorage.Shared.ItemThrowService)

-- objects
local tool = script.Parent
local replicatedStorage = game:GetService('ReplicatedStorage')
local event = replicatedStorage.Replication:WaitForChild('ItemEvent')

-- requirements

-- vars
local released = false
local is_hold = false
local throw_strength = 0

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
	local animations = game.ReplicatedStorage.Assets.Animations.Items.Throwable

	--animation: Animation, name: string, speed: number, looped: boolean, priority: Enum.AnimationPriority
	animation_tracks.prepare = local_character:LoadAnimation(animations.ItemThrowPrepare, nil, 1, false, Enum.AnimationPriority.Action4)
	animation_tracks.idle = local_character:LoadAnimation(animations.ItemThrowIdle, nil, 1, true, Enum.AnimationPriority.Action3)
	animation_tracks.throw = local_character:LoadAnimation(animations.ItemThrow, nil, 1, false, Enum.AnimationPriority.Action4)
end)


tool.Unequipped:Connect(function()
	local animation_tracks = animation_tracks

	if not is_hold then return end
	connections:DropConnection('animation_release')
	connections:DropConnection('render')

	is_hold = false

	animation_tracks.prepare:Stop()
	animation_tracks.idle:Stop()

	-- ui
	local mainGameUI = shared.Client._requirements.UI
	local cursorUI = mainGameUI.cursor
	cursorUI:ActionChargeSetVisible( false )
end)


tool.Activated:Connect(function()
	local animation_tracks = animation_tracks

	if released then return end
	if is_hold then return end

	is_hold = true

	animation_tracks.idle:Play()
	animation_tracks.prepare:Play()

	-- ui
	local mainGameUI = shared.Client._requirements.UI
	local cursorUI = mainGameUI.cursor
	cursorUI:ActionChargeSetVisible( true )

	-- frame update
	connections:DropConnection('render')
	connections:AddConnection(game:GetService('RunService').RenderStepped:Connect(function()
		throw_strength = 1 - math.abs(math.sin(tick() * 3))
		cursorUI:ActionChargeSetValue( throw_strength )
	end), 'render')
end)


tool.Deactivated:Connect(function()
	local animation_tracks = animation_tracks

	if released then return end
	if not is_hold then return end

	-- ui
	local mainGameUI = shared.Client._requirements.UI
	local cursorUI = mainGameUI.cursor
	cursorUI:ActionChargeSetVisible( false )

	animation_tracks.prepare:Stop()
	animation_tracks.idle:Stop()
	animation_tracks.throw:Play()

	connections:DropConnection('render')
	connections:AddConnection(animation_tracks.throw:GetMarkerReachedSignal('Throw'):Connect(function()
		released = true
		game.SoundService.Master.Instances.Item.Throwable.throw:Play()

		-- replication
		ItemThrowService:PromptThrow(
			nil, -- no need provide player
			tool,
			workspace.CurrentCamera.CFrame.LookVector,
			math.clamp(150 * throw_strength, 30, 150)
		)
	end), 'animation_release')
end)