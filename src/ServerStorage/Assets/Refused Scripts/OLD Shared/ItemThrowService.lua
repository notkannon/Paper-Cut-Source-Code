local server = shared.Server
local client = shared.Client

-- declarations
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local MessagingEvent = script.Messaging
local BulletContainer

-- requirements
local requirements = server and server._requirements or client._requirements
local FastCastRedux = require(ReplicatedStorage.Package.FastCastRedux)
local ThrowCaster


-- service initial
local Initialized = false
local ThrowService = {}
ThrowService.simulations = {}
ThrowCaster = FastCastRedux.new() -- creating a new caster object

-- initial method
function ThrowService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	if client then
		-- creating a local bullet container
		BulletContainer = Instance.new('Folder', workspace)
		BulletContainer.Name = 'ThrownItemsContainer'
		
		--< VISUAL CASTER CONNECTIONS >
		ThrowCaster.LengthChanged:Connect(function(
			ActiveCast,
			lastPoint,
			rayDir,
			displacement,
			segmentVelocity,
			cosmeticBulletObject: BasePart)
			
			-- cosmetic object handling
			local trail: Trail = cosmeticBulletObject:FindFirstChildOfClass('Trail')
			if trail then trail.Enabled = true end
			cosmeticBulletObject.Anchored = true
			
			-- transform
			local pos = lastPoint + (rayDir * displacement)
			cosmeticBulletObject.CFrame = CFrame.new(
				CFrame.lookAt(pos, pos + rayDir).Position)
				* cosmeticBulletObject.CFrame.Rotation
				* CFrame.Angles(
					math.rad(1),
					math.rad(-1.5),
					math.rad(2)
				)
		end)
		
		-- client event message receiving
		MessagingEvent.OnClientEvent:Connect(function(context: string, ...)
			if context == 'visualize' then
				self:Simulate( ... )
			end
		end)
	elseif server then
		-- server event message receiving
		MessagingEvent.OnServerEvent:Connect(function(player: Player, ...)
			self:PromptThrow(player, ...)
		end)
	end
	
	-- we may use it here because we need access to current object
	ThrowCaster.RayHit:Connect(function(
		ActiveCast,
		RaycastResult: RaycastResult,
		segmentVelocity,
		cosmeticBulletObject: BasePart?)

		--[[local character_object_hit = CharacterModule.GetObjectByHitpart( RaycastResult.Instance )
		if not character_object_hit then return end
		local player_object = character_object_hit.Player]]
						
		if client then
			cosmeticBulletObject.Transparency = 1
			cosmeticBulletObject.ImpactParticle:Emit(11)
			
			local hitSound = game.SoundService.Master.Instances.Item.Throwable.hit:Clone()
			hitSound.Parent = cosmeticBulletObject
			hitSound:Play()
			
			game:GetService('Debris'):AddItem(cosmeticBulletObject, 5)
		end
		
		-- result handling
		--warn(`[{ client and 'Client' or 'Server' }] HITTED`, RaycastResult.Instance)
		self:HandleResult(RaycastResult)
	end)
end

-- returns a new fastcast behavior objecvt with unique setting for server/client
function ThrowService:GetFastcastBehavior(reference: BasePart?, filter: { Instance })
	local behavior = FastCastRedux.newBehavior()
	local raycastParams = RaycastParams.new()
	
	-- initializing fields
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { BulletContainer, table.unpack(filter) }
	raycastParams.IgnoreWater = true
	
	behavior.RaycastParams = raycastParams
	behavior.CosmeticBulletTemplate = client and reference -- client only
	behavior.CosmeticBulletContainer = BulletContainer
	
	--[[ piercing func
	behavior.CanPierceFunction = function(cast, result: RaycastResult?, segmentVelocity)
		if result.Instance.Transparency >= 0.5 then return true end
	end]]
	
	-- construct finish
	return behavior
end

-- handles fastcast real hit event
function ThrowService:HandleResult(result: RaycastResult)
	-- TODO: idk, make it gives player points if he hits silly teacher >:)
	if server then
		
		-- handling generator charging
		if result.Instance:HasTag('GeneratorHitbox') then
			print('Hit generator!')
		end
	end
end

-- creates a new simulation both sides
function ThrowService:Simulate(player: Player, tool: Tool, direction: Vector3, strength: number, origin: Vector3?)
	assert(typeof(tool) == 'Instance' and tool:IsA('Tool'), `Provided object is not tool ({ tool })`)
	
	-- getting reference object
	local data_module: ModuleScript? = tool:FindFirstChild('Data')
	if not data_module or not data_module:IsA('ModuleScript') then
		error('Provided item has no Data module inside')
		return
	end
		
	-- declarations
	local tool_data = require(data_module)
	local cosmetic_object_reference: BasePart?
	local initial_origin: Vector3? -- used to get origin on server
	local character_model: Model
	
	if client then -- getting a cosmetic bullet object reference
		cosmetic_object_reference = tool_data.reference:FindFirstChildWhichIsA('BasePart')
		
		-- getting player`s character model
		local player_object = requirements.ClientPlayer.GetObjectFromInstance(player)
		if player_object then character_model = player_object.Character.Instance
		else warn('[Client] Could not find character for player', player) end
		
	elseif server then
		-- getting player`s character model
		local player_object = requirements.ServerPlayer.GetObjectFromInstance(player)
		if player_object then character_model = player_object.Character.Instance
		else warn('[Server] Could not find character for player', player) end
	end
	
	-- getting initial origin for fastcast
	if character_model and not origin then
		local head: BasePart = character_model:FindFirstChild('Head')
		assert(head, 'Could not get .initial_origin for throw without Head instance')
		initial_origin = head.Position
	end
	
	if server then
		MessagingEvent:FireAllClients(
			'visualize',
			player,
			tool_data.reference,
			direction,
			strength,
			initial_origin
		)
	end
	
	-- getting new behavior and running new caster
	local behavior = self:GetFastcastBehavior(
		cosmetic_object_reference,
		{ character_model }
	)
	
	-- whoops, it may be here..
	behavior.Acceleration = Vector3.new(0, -20 - (151 - strength)/40, 0)
	
	-- call clients draw local throw simulation
	
	-- simulation
	local active_cast = ThrowCaster:Fire(
		initial_origin or origin,
		direction,
		strength,
		behavior
	)
end

-- client (throw: tool, direction, strength)--> server: simulate
function ThrowService:PromptThrow(player: Player, tool: Tool, direction: Vector3, strength: number)
	if client then
		-- client prompting to simulate
		MessagingEvent:FireServer(
			tool,
			direction,
			strength
		)
	elseif server then
		-- is item wrapper exists?
		local item_wrapper = requirements.ServerItems:GetItemFromInstance(tool)
		assert(item_wrapper, `Could not simulate throw. Item wrapper doesn't exists ({ tool })`)
		
		-- is player exists?
		local player_object = requirements.ServerPlayer.GetObjectFromInstance(player)
		assert(player_object, '[Server] Could not find character for player')
		
		self:Simulate(
			player,
			tool,
			direction,
			strength
		)
		
		-- destroying thrown item
		item_wrapper:Destroy()
	end
end

-- complete
return ThrowService