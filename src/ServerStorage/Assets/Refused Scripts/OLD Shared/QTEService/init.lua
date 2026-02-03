--[[TODO:
# QTE
## implementation
- QTE service is both a client and a server at once. The server processes the main information and only the server can register a new `Session` object
- Session is an object that stores the states of the current QTE participants (student and student), and waits for a callback from both.
 If there is no callback from any side within a few seconds (`3`?) then the outcome is determined automatically by the **strength** of the
 interaction of both participants

## Outcomes
1. The student has great strength --> breaks out with minimal losses (gets invulnerability for a few seconds), the teacher gets a camp and a cd for all attacks
2. The teacher has great power --> the student dies, the animation of the finisher (finishing) is played. The teacher gets a hp buff
3. The forces are equal (triggered in all other unforeseen cases) --> the same animation as in the first outcome, but with different debuffs
]]

local server = shared.Server
local client = shared.Client

local requirements = server
	and server._requirements
	or client._requirements

-- declarations
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local MessagingEvent = script.Messaging

-- requirements
local enumsModule = requirements.Enums
local Session = require(script.Session)
local PlayerComponent = server
	and requirements.ServerPlayer
	or requirements.PlayerComponent

-- const
local NEW_QTE_CTX = 'new_qte'
local QTE_MESSAGE = 'msg_qte'

-- service initial
local Initialized = false
local QTEService = {}
QTEService.sessions = {}


function QTEService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	if client then
		--print('[Client] QTE service inited')
	elseif server then
		--print('[Server] QTE service inited')
	end
end

-- returns first session with given member (Player)
function QTEService:GetSessionByMember(member: Player)
	for _, object in pairs(Session._objects) do
		if object:HasMember(member) then
			return object
		end
	end
end

-- returns first session with given session_id
function QTEService:GetSessionById(session_id: number)
	for _, object in pairs(Session._objects) do
		if object:GetId() == session_id then
			return object
		end
	end
end

-- gets id for new session
function QTEService:GetNextSessionId()
	local last_session_id = 0

	for _, object in pairs(Session._objects) do
		if object.session_id > last_session_id then
			last_session_id = object.session_id
		end
	end

	return last_session_id + 1
end

-- session construct
function QTEService:CreateSession(student_object, teacher_object, session_id: number?)
	--assert(teacher_object:IsKiller(), `Provided teacher player object should be teacher ({ teacher_object })`)
	--assert(not student_object:IsKiller(), `Provided student player object should be student ({ student_object })`)
	
	-- creating new session object
	local session = Session.new(
		student_object,
		teacher_object,
		session_id
	)
	
	if server then
		MessagingEvent:FireAllClients(
			NEW_QTE_CTX,
			nil, --session.teacher_object.reference,
			nil, --session.student_object.reference,
			session:GetId()
		)
		
		-- running session
		session:InitServer()
		
	elseif client then
		-- client session initialize
		session:InitClient()
	end
	
	return session
end


-- NETWORKING / UPDATING
if client then
	-- SERVER --> client messages connection
	MessagingEvent.OnClientEvent:Connect(function(context, ...)
		if context == NEW_QTE_CTX then
			local teacher_player: Player, student_player: Player, session_id: number = ...
			
			-- objects getting
			local teacher_object = PlayerComponent.GetObjectFromInstance(teacher_player)
			local student_object = PlayerComponent.GetObjectFromInstance(student_player)
			
			-- new client QTE initialization
			QTEService:CreateSession(
				teacher_object,
				student_player,
				session_id
			)
			
		elseif context == QTE_MESSAGE then
			local session_id, message = ...
			local sessionObject = QTEService:GetSessionById(session_id)
			
			-- error handling
			if not sessionObject then
				warn(`[Client] Session with session_id "{ session_id }" doesn't exists.`)
				return
			end
			
			-- client session object message handling
			sessionObject:OnClientMessage(message)
		end
	end)
elseif server then
	Players.PlayerRemoving:Connect(function(player_removing)
		local sessionObject = QTEService:GetSessionByMember(player_removing)
		if not sessionObject then return end
		
		-- one of session member leaves, we should complete session with void result
		sessionObject:CompleteServer()
	end)
	
	-- CLIENT --> server messages connection
	MessagingEvent.OnServerEvent:Connect(function(player, context, ...)
		if context == QTE_MESSAGE then
			local session_id, message = ...
			local sessionObject = QTEService:GetSessionById(session_id)
			
			-- error handling
			if not sessionObject then
				warn(`[Server] Session with session_id "{ session_id }" doesn't exists.`)
				return
			end
			
			-- server session object message handling
			sessionObject:OnServerMessage(message)
		end
	end)
end

-- complete
return QTEService