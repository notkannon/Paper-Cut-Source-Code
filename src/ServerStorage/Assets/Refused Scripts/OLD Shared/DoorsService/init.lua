local server = shared.Server
local client = shared.Client

local requirements = server
	and server._requirements
	or client._requirements

-- declarations
local CollectionService = game:GetService('CollectionService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local MessagingEvent = script.Messaging

-- requirements
local DoorModule = require(script.Door)
local enumsModule = requirements.Enums
local PlayerComponent = server
	and requirements.ServerPlayer
	or requirements.PlayerComponent


-- DoorsService initial
local Initialized = false
local DoorsService = {}
DoorsService.doors = DoorModule._objects

-- initial method
function DoorsService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	for _, instance in ipairs(CollectionService:GetTagged('Door')) do
		if not instance:IsDescendantOf(workspace) then continue end
		DoorsService:NewDoor(instance)
	end
end

-- returns 1st door object with same instance (if exists)
function DoorsService:GetDoorByInstance( instance: Model? )
	return DoorsService:GetDoorById(instance:GetAttribute('Id'))
end

-- returns 1st door with same id (if exists)
function DoorsService:GetDoorById( door_id: string )
	for _, door_obj in ipairs(DoorsService.doors) do
		if door_obj:GetId() ~= door_id then continue end
		return door_obj
	end
end

-- new door init
function DoorsService:NewDoor( DoorInstance: Model )
	if DoorsService:GetDoorByInstance(DoorInstance) then return end
	
	-- creating new door object
	local NewDoor = DoorModule.new( DoorInstance )
	
	-- prompting all clients to initialize new door locally
	if server then
		MessagingEvent:FireAllClients('create',
			NewDoor:GetInstance()
		)
	end
	
	return NewDoor
end

-- replace ALL existing doors objects with their repared copies
function DoorsService:Regenerate()
	assert(server, 'Attempt to call :Regenerate() on client')
	print('Regenerating doors!')
	
	local old_objects = {}
	for _, door_obj in ipairs(DoorsService.doors) do
		table.insert(old_objects, door_obj)
	end
	
	-- we need to reset all doors
	for _, door_obj in ipairs(old_objects) do
		local IsDouble: boolean = door_obj:GetInstance():HasTag('Double')
		
		-- getting new instance reference for object
		local NewInstance: Model = game:GetService('ServerStorage').Server.Instances.Doors
			:FindFirstChild(IsDouble and 'Double' or 'Single')
			:Clone()
		
		NewInstance.Parent = door_obj:GetInstance().Parent
		NewInstance:PivotTo( door_obj:GetInstance().PrimaryPart.CFrame )
		DoorsService:NewDoor( NewInstance )
	end
	
	-- removing all old objects from raw
	for _, old_obj in ipairs(old_objects) do old_obj:Destroy() end
	table.clear(old_objects)
end

-- MESSAGING
if client then
	MessagingEvent.OnClientEvent:Connect(function(ctx: string, ...)
		if ctx == 'create' then
			-- locally initializing new door
			DoorsService:NewDoor(...)
			
		elseif ctx == 'destroy' then
			-- removing door from local table
			local door_obj = DoorsService:GetDoorById(...)
			assert(door_obj, 'No door object exists to destroy:', ...)
			
			-- destroying
			door_obj:Destroy()
		end
	end)
elseif server then
	MessagingEvent.OnServerEvent:Connect(function(player: Player, door_id: string, ctx: string, ...)
		if ctx == "Push" then
			local door_obj = DoorsService:GetDoorById(door_id)
			
			-- catching exception?
			if not door_obj then
				warn(`Door with id "{ door_id }" doesn't exist.`)
				return
			end
			
			-- will re-call function but on server-side
			door_obj:Push(player)
			
		--[[elseif ctx == "Slam" then
			local door_obj = DoorsService:GetDoorById(door_id)
			
			-- catching exception?
			if not door_obj then
				warn(`Door with id "{ door_id }" doesn't exist.`)
				return
			end
			
			-- will re-call function but on server-side
			door_obj:PromptSlam(player)
		elseif ctx == "Damage" then
			local door_obj = DoorsService:GetDoorById(door_id)
			local dmg_type = ...
			
			-- catching exception?
			if not door_obj then
				warn(`Door with id "{ door_id }" doesn't exist.`)
				return
			end
			
			-- will re-call function but on server-side
			print(player, dmg_type)
			door_obj:Damage(player, dmg_type)]]
		end
	end)
end

-- complete
return DoorsService