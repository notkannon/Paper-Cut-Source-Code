-- service
local RunService = game:GetService('RunService')


-- BaseCamera initial
local BaseCamera = {}
BaseCamera._objects = {}
BaseCamera.__index = BaseCamera

local Client = shared.Client

-- constructor
function BaseCamera.new()
	local self = setmetatable({
		Active = false
	}, BaseCamera)
	
	table.insert(
		self._objects,
		self)
	return self
end


function BaseCamera:Init() end
function BaseCamera:Update() end

-- sets current camera active (if true, disables other cameras)
function BaseCamera:SetActive(active: boolean)
	if active == self.Active then return end
	if active then
		-- disabling others
		for _, Camera in ipairs(BaseCamera._objects) do
			Camera:SetActive(false)
		end
		
		self.Active = true
		
		-- render connection
		RunService:BindToRenderStep('@Camera',
			Enum.RenderPriority.Camera.Value + 1,
			function(...) self:Update(...) end
		)
	else
		-- attempt to unbind camera from render
		self.Active = false
		RunService:UnbindFromRenderStep('@Camera')
	end
end

return BaseCamera