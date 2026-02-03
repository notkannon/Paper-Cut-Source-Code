--[[
TODO:

Make session disables:
- All of teacter attacks
- Makes student protected from damage

Also make session:
- Destroy when one of session members leaves from the game
- Destroy session when round ends
- any other cases destroys session also
]]

local server = shared.Server
local client = shared.Client

local requirements = server
	and server._requirements
	or client._requirements

-- requirements
local Enums = require(game.ReplicatedStorage.Enums)
local QTEResultEnum = Enums.QTEResultEnum
local MessagingEvent = script.Parent.Messaging

-- const
local NEW_QTE_CTX = 'new_qte'
local QTE_MESSAGE = 'msg_qte'

-- QTESession initial
local QTESession = {}
QTESession._objects = {}
QTESession.__index = QTESession


-- constructor
function QTESession.new(student_object, teacher_object, session_id)
	local QTEService = requirements.QTEService
	
	-- assertation
	if client then assert(session_id, '[Client] Client QTE session should be created with session_id') end
	--[[assert(not QTEService:GetSessionByMember(student_object.reference), 'Student already registered in other QTE session', student_object)
	assert(not QTEService:GetSessionByMember(teacher_object.reference), 'Teacher already registered in other QTE session', teacher_object)
	assert(student_object, 'No student player object provided')
	assert(teacher_object, 'No teacher object provided')]]
	
	local self = setmetatable({
		session_id = session_id or QTEService:GetNextSessionId(),
		student_object = student_object,
		teacher_object = teacher_object,
		
		created_at = os.clock(),
		runned_at = 0,
		running = false,
		
		clients_ready = 0,
		on_start_listener = nil,
		on_end_listener = nil,
		life_thread = nil,
		connections = {}
	}, QTESession)
	
	table.insert(
		QTESession._objects,
		self
	)
	
	print('Created new session', self:GetId())
	return self
end

-- returns true if running
function QTESession:IsRunning()
	return self.running
end

-- returns current session_id
function QTESession:GetId()
	return self.session_id
end

-- returns true if one of session members is equal given
function QTESession:HasMember(member: Player)
	return self.student_object.reference == member
		or self.teacher_object.reference == member
end

-- initial QTE method
function QTESession:InitServer()
	assert(server, 'Cannot call :InitServer() on client')
	
	
	--[[
	local student_object = self.student_object
	local teacher_object = self.teacher_object
	
	local student_character = student_object.Character
	local teacher_character = teacher_object.Character
	
	local student_model: Model = student_character.Instance
	local teacher_model: Model = teacher_character.Instance
	local student_humanoid: Humanoid = student_character:GetHumanoid()
	local teacher_humanoid: Humanoid = teacher_character:GetHumanoid()
	
	local teacher_pos: Vector3 = teacher_model.HumanoidRootPart.Position
	local student_pos: Vector3 = student_model.HumanoidRootPart.Position
	
	-- animation initial script
	student_model.HumanoidRootPart.Anchored = true
	teacher_model.HumanoidRootPart.Anchored = true
	
	teacher_model:PivotTo(CFrame.lookAt(
		Vector3.new(
			teacher_pos.X,
			student_pos.Y,
			teacher_pos.Z
		),
		Vector3.new(
			student_pos.X,
			teacher_pos.Y, -- keep teacher`t normalized direction
			student_pos.Z
		))
	)
	
	student_model:PivotTo(CFrame.lookAt(
		teacher_pos + teacher_model.HumanoidRootPart.CFrame.LookVector * 2,
		Vector3.new(
			teacher_pos.X,
			student_pos.Y, -- keep studen`t normalized direction
			teacher_pos.Z
		))
	)]]
end

-- removes all member from session and makes them able to move and keep playing
function QTESession:RemoveAllMembers()
	assert(server, 'Cannot call :RemoveAllMembers() on client')
end


function QTESession:InitClient()
	assert(client, 'Cannot call :InitClient() on server')
	self:ClientSendMessage('Ready') -- make sure the server about player created session locally
end

-- handles some message for session (message is any data) CLIENT
function QTESession:OnClientMessage(message)
	print(`[Client]`, self:GetId(), 'session message received:', message)
	
	if message == 'Started' then
		self:StartClient()
	elseif message == 'Completed' then
		warn('Session completed on client', self:GetId())
	end
end

-- handles some message for session (message is any data) SERVER
function QTESession:OnServerMessage(message)
	print(`[Server]`, self:GetId(), 'session message received:', message)
	if message == 'Ready' then
		self.clients_ready += 1
		if self.clients_ready == 1 then
			self:StartServer()
		end
	end
end

-- client sends message to server
function QTESession:ServerSendMessage(message: any)
	assert(server, 'Cannot call :ServerSendMessage() on client')
	MessagingEvent:FireAllClients(QTE_MESSAGE, self:GetId(), message)
end

-- client sends message to server
function QTESession:ClientSendMessage(message: any)
	assert(client, 'Cannot call :ClientSendMessage() on server')
	MessagingEvent:FireServer(QTE_MESSAGE, self:GetId(), message)
end

-- server: runs QTE session
function QTESession:StartServer()
	assert(server, 'Cannot call :StartServer() on client')
	assert(not self:IsRunning(), '[Server] Attempted to run QTE session again')
	
	self.runned_at = os.clock()
	self:ServerSendMessage('Started')
	
	-- spawning thread to complte session after some time
	local session_thread: thread
	session_thread = coroutine.resume(coroutine.create(function()
		self.life_thread = session_thread
		
		task.wait(3)
		
		-- removing session
		self:CompleteServer()
		coroutine.close(session_thread)
	end))
end

-- client runs QTE
function QTESession:StartClient()
	assert(client, 'Cannot call :StartClient() on server')
	assert(not self:IsRunning(), '[Client] Attempted to run QTE session again')
	
	self.runned_at = os.clock()
	
end

-- server results getting and cleaning up method
function QTESession:CompleteServer()
	assert(server, 'Cannot call :CompleteServer() on client')
	self:ServerSendMessage('Completed')
	self:Destroy()
end

-- full desctruction method
function QTESession:Destroy()
	print('Destroyed QTE session', self, 'with lifetime:', os.clock() - self.created_at)
	
	-- members unlock
	if server then
		if self.life_thread then
			coroutine.close(self.life_thread)
		end
		
		self:RemoveAllMembers()
	end
	
	-- dropping all connections
	for _, connection: RBXScriptConnection in pairs(self.connections) do
		connection:Disconnect()
	end
	
	-- removing from objects access
	table.remove(QTESession,
		table.find(QTESession,
			self
		)
	)
	
	-- cleaning up
	setmetatable(self, nil)
	table.clear(self)
end

-- complete
return QTESession