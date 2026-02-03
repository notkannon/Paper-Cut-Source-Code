local client = shared.Client

-- declarations
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Signal = require(ReplicatedStorage.Package.Signal)
local WCS = require(ReplicatedStorage.Package.wcs)


local UI
local SkillsUI
local Backpack

-- private fields
local private = {
	bind_by_skill_string = {
		Dash = {
			Enum.KeyCode.E
		},
		
		Attack = {
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.Touch,
			Enum.UserInputType.Gamepad1
		},
	},
	
	skills_binded = {},
	old_moveset = nil,
	
	connections = {
		moveset_changed = nil :: RBXScriptConnection,
		destroyed = nil :: RBXScriptConnection
	}
}

-- ClientWcsController initial
local ClientWcsController = {}
ClientWcsController.SkillEnded = Signal.new()
ClientWcsController.SkillStarted = Signal.new()
ClientWcsController.SkillChanged = Signal.new()


function ClientWcsController:Init()
	UI = client._requirements.UI
	SkillsUI = UI.gameplay_ui.skills_ui
	
	-- WCS client initial
	local WCSClient = WCS.CreateClient()
	
	WCSClient:RegisterDirectory(ReplicatedStorage.Shared.Skill.SkillSets)
	WCSClient:RegisterDirectory(ReplicatedStorage.Shared.Skill.StatusEffects)
	WCSClient:Start()
end


function ClientWcsController:Reset()
	local WcsCharacter = client.Player.Character.WcsCharacterObject
	assert( WcsCharacter, 'No WCSCharacter exists to reset bindings' )
	
	-- reset all controller states
	self:Cleanup()
	
	-- connections
	self:_OnMovesetChange( nil, WcsCharacter:GetMoveset() )
	private.connections.moveset_changed = WcsCharacter.MovesetChanged:Connect(function( ... )
		self:_OnMovesetChange( ... )
	end)
	
	private.connections.destroyed = WcsCharacter.Destroyed:Connect(function()
		self:Cleanup()
	end)
end

-- used to prompt skill object to :Start() trigger
function ClientWcsController:PromptSkill( skill_name, ... )
	local WcsCharacter = client.Player.Character.WcsCharacterObject
	assert( WcsCharacter, 'No WCSCharacter exists to handle control bindings' )
	
	local skill_object = WcsCharacter:GetSkillFromString( skill_name )
	if not skill_object then warn('No skill registered in character:', skill_name) return end
	
	-- prompting skill start with some data
	skill_object:Start(...)
end


function ClientWcsController:BindControlsToMoveset( moveset_name: string )
	if not moveset_name then
		for _, skill in ipairs(private.skills_binded) do
			for _, connection: RBXScriptConnection? in pairs(skill) do
				if typeof(connection) == 'RBXScriptConnection' then
					connection:Disconnect()
				end
			end
		end
		
		table.clear(private.skills_binded)
		return
	end
	
	local WcsCharacter = client.Player.Character.WcsCharacterObject
	
	local function Bind(skill_object)
		SkillsUI:BindSkill( skill_object )
		table.insert(
			private.skills_binded, {
				name = skill_object.Name,
				ended = skill_object.Ended:Connect(function(...)				ClientWcsController.SkillEnded:Fire(skill_object.Name, ...) end),
				started = skill_object.Started:Connect(function(...)			ClientWcsController.SkillStarted:Fire(skill_object.Name, ...) end),
				state_changed = skill_object.StateChanged:Connect(function(...) ClientWcsController.SkillChanged:Fire(skill_object.Name, ...) end)
			}
		)
	end
	
	-- ui interaction
	
	private.connections.skill_added = WcsCharacter.SkillAdded:Connect(Bind)
	for _, skill_object in ipairs(WcsCharacter:GetSkills()) do
		Bind(skill_object)
	end
end
 

function ClientWcsController:_OnMovesetChange( _, new_moveset )
	if private.old_moveset then
		private.old_moveset = nil -- forbidding old
	end
	
	if new_moveset then
		private.old_moveset = new_moveset
	end
	
	self:BindControlsToMoveset( new_moveset )
end

-- removes all old-WcsCharacter connections from controller
function ClientWcsController:Cleanup()
	self:_OnMovesetChange() -- triggering with nil args to unbind
	SkillsUI:ResetSlots() -- ui resetting
	
	-- connection reset

	if private.connections.skill_added then
		private.connections.skill_added:Disconnect()
	end
	if private.connections.moveset_changed then
		private.connections.moveset_changed:Disconnect()
		private.connections.moveset_changed = nil
	end
end


return ClientWcsController