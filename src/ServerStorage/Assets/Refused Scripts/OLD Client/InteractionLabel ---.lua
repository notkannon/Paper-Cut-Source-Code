local ProximityPromptService = game:GetService('ProximityPromptService')
local InteractionService = require(game.ReplicatedStorage.Shared.InteractionService)
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

-- local requirements
local Signal = require(ReplicatedStorage.Package.Signal)
local Prompt = require(script.Prompt)
local Label = require(script.Label)

-- ClientProximity initial
local Initialized = false
local ClientProximity = {}
ClientProximity.enabled = true
ClientProximity.PromptShown = Signal.new()
ClientProximity._proximities = Prompt._objects

-- initial method
function ClientProximity:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- labels show connection
	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt, input: Enum.ProximityPromptInputType)
		-- creating label
		if prompt:HasTag('Label') then
			Label.new(prompt)
		else
			local Interaction = InteractionService:GetInteraction(prompt, true)
			if not Interaction:IsInteractableFor(game.Players.LocalPlayer) then return end
			Prompt.new( Interaction )
		end
	end)
	
	local updqate_time = 0
	
	RunService:BindToRenderStep('@proximity_render', Enum.RenderPriority.Camera.Value, function()
		if tick() - updqate_time < .3 then return end
		updqate_time = tick()
		
		for _, proximity in pairs(Prompt._objects) do
			proximity:Update()
		end
	end)
end

-- sets whole prompts show permissions
function ClientProximity:SetAllEnabled(enabled: boolean)
	ClientProximity.enabled = enabled
	
	if not enabled then
		-- removes all active prompts
		for _, proximity in pairs(Prompt._objects) do
			proximity.reference.Enabled = false
			proximity:Destroy()
		end
	else
		-- enables all prompts (its ok cuz anyway prompt will hide if its unavailable for local player)
		for _, proximity in ipairs(workspace:GetDescendants()) do
			if not proximity:IsA('ProximityPrompt') then continue end
			proximity.Enabled = true
		end
	end
end

-- complete
return ClientProximity