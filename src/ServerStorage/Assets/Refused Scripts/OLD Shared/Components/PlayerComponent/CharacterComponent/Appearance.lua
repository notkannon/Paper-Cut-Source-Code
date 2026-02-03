local Client = shared.Client
local Server = shared.Server
local Network = script.Network

-- const
local PI = math.pi
local RATE = 1/7 -- updates per sec

-- service
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Util = require(ReplicatedStorage.Shared.Util)


-- character Appearance initial
local Appearance = {}
Appearance._objects = {}
Appearance.__index = Appearance

--// STATIC
-- returns first Appearance from player`s instance
function Appearance.GetAppearanceFromPlayer(player_instance: Player)
	for _, appearance in ipairs(Appearance._objects) do
		if appearance.Character.Player.Instance == player_instance then
			return appearance
		end
	end
end

--// METHODS
-- constructor
function Appearance.new( Character )
	assert(not Appearance.GetAppearanceFromPlayer(Character.Player.Instance), 'Already created appearance for character')
	
	local self = setmetatable({
		Character = Character,
		Active = false,
		
		_LastUpdate = os.clock()
	}, Appearance)
	
	table.insert(
		Appearance._objects,
		self)
	return self
end

-- sets appearance replication and applying active
function Appearance:SetActive(active: boolean)
	if self.Active == active then return end
	self.Active = active
	
	-- player client-only applying
	if not Client then return end
	if not self.Character.Player:IsLocalPlayer() then return end
	
	if active then
		-- connecting to render step
		RunService:BindToRenderStep(
			'@CharacterAppearance',
			Enum.RenderPriority.Character.Value,
			function() self:Share() end
		)
	else
		-- dropping connection to render
		RunService:UnbindFromRenderStep('@CharacterAppearance')
	end
end

-- applies appearance to character object/instance
function Appearance:Apply(data)
	-- some client applies for character model
	local Character: Model = self.Character.Instance
	local Humanoid: Humanoid = Character.Humanoid
	
	-- Head rotation update (cosmetic) (r6)
	local Torso: BasePart = Character:FindFirstChild('Torso') or Character.UpperTorso
	local Head: BasePart = Character.Head
	local Joint: Motor6D = Torso.Neck

	local root = CFrame.new(0, 1, 0) * CFrame.Angles(PI/2, PI, 0)
	local relative = CFrame.lookAt(Head.Position, Head.Position + data.LookVector):ToObjectSpace(Torso.CFrame)
	local toObject = relative:Inverse() * CFrame.Angles(PI/2, PI, 0)

	local goal = CFrame.new(0, 1, 0) * toObject.Rotation
	TweenService:Create(Joint, TweenInfo.new(.5), {C0 = root:Lerp(goal, .5)}):Play()
	
	-- need to fix teacher`s head otation
	if Humanoid.RigType == Enum.HumanoidRigType.R15 then
		if not self.NeckC1 then self.NeckC1 = Joint.C1 end
		Joint.C1 = self.NeckC1 * CFrame.Angles(PI/2, -PI, 0)
	end
end

-- Client: prompts server to share appearance
-- Server: prompts all client (excluding sender) to apply appearance
function Appearance:Share(data_to_share)
	if not self.Active then return end
	
	-- rate checking
	if os.clock() - self._LastUpdate < RATE then return end
	self._LastUpdate = os.clock()
	
	-- handling
	if Client then
		if not self.Character.Player:IsLocalPlayer() then return end
		
		local ClientData = { LookVector = workspace.CurrentCamera.CFrame.LookVector }
		Network:FireServer( ClientData ) -- sharing with others
		self:Apply( ClientData ) -- applying locally (no delay)
		
	elseif Server then
		assert(data_to_share, 'Data argument is required on server')
		local Player: Player = self.Character.Player.Instance
		
		-- sharing appearance to all (excluding owner player)
		for _, Member: Player in ipairs(Util.GetPlayersExcluding(Player)) do
			Network:FireClient(Member, Player, data_to_share)
		end
	end
end

-- Appearance destruction
function Appearance:Destroy()
	self:SetActive(false)
	
	table.remove(Appearance._objects,
		table.find(Appearance._objects,
			self
		)
	)
	
	setmetatable(self, nil)
	table.clear(self)
end


--// NETWORKING
if Client then
	Network.OnClientEvent:Connect(function(target: Player, ...)
		local TargetAppearance = Appearance.GetAppearanceFromPlayer(target)
		if not TargetAppearance then return end
		
		-- Appearance applying
		TargetAppearance:Apply(...)
	end)
	
elseif Server then
	Network.OnServerEvent:Connect(function(sender: Player, data)
		local TargetAppearance = Appearance.GetAppearanceFromPlayer(sender)
		if not TargetAppearance then  return end
		
		-- sharing
		TargetAppearance:Share(data)
	end)
end

return Appearance