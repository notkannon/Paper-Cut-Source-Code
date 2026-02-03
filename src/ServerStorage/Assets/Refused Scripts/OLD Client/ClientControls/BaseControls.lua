local BaseControls = {}
BaseControls._objects = {}
BaseControls.__index = BaseControls

-- constructor
function BaseControls.new()
	local self = setmetatable({
		Definition = 'Unknown',
		Enabled = false,
		
		_Connections = {}
	}, BaseControls)
	return self
end


function BaseControls:AddConnection(connection: RBXScriptConnection, name: string)
	self._Connections[ name ] = connection
end


function BaseControls:RemoveConnection(name)
	self._Connections[ name ]:Disconnect()
end


function BaseControls:Run()
	print(self.Definition, 'controls running!')
end

return BaseControls