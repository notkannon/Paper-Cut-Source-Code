local client = shared.Client

-- declarations
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Refx = require(ReplicatedStorage.Package.refx)
Refx.Register(ReplicatedStorage.Shared.Effects)

-- EffectsController initial
local EffectsController = {}

-- refx client initial
function EffectsController:Init()
	Refx.Start()
end

return EffectsController