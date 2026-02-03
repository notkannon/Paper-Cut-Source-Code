local server = shared.Server
local client = shared.Client

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')


-- Cmdr Initial table
local Initialized = false
local CmdrInitial = {}

-- initial method
function CmdrInitial:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	if server then
		-- cmdr server initial
		local Cmdr = server:Require(ReplicatedStorage.Package.Cmdr)
		Cmdr:RegisterHooksIn(ReplicatedStorage.Shared.Cmdr.Hooks)
		Cmdr:RegisterTypesIn(ReplicatedStorage.Shared.Cmdr.Types)

		-- commands parse
		for _, command in ipairs(ReplicatedStorage.Shared.Cmdr.Commands.Admin:GetChildren()) do Cmdr:RegisterCommandsIn( command ) end
		for _, command in ipairs(ReplicatedStorage.Shared.Cmdr.Commands.Interface:GetDescendants()) do Cmdr:RegisterCommandsIn( command ) end
		
	elseif client then
		-- client cmdr initial
		client:Require(ReplicatedStorage.CmdrClient)
			:SetActivationKeys({
				Enum.KeyCode.F2,
				Enum.KeyCode.F3
			})
	end
end

return CmdrInitial