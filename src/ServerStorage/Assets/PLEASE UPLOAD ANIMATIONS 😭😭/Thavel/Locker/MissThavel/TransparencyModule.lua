local TransparencyModule = {}
TransparencyModule.EditableParts = {}


local function AddInstance(instance: Instance, transparency: number)
	if TransparencyModule.EditableParts[ instance ] then return end
	TransparencyModule.EditableParts[ instance ] = transparency or instance.Transparency
end

function TransparencyModule:Apply()
	local character: Model = script.Parent
	
	-- collecting parts to set their transparency
	for _, basepart: BasePart? in ipairs(script.Parent:GetDescendants()) do
		if not basepart:IsA('BasePart') then continue end
		if basepart.Transparency == 1 then continue end -- premanently transparent
		AddInstance( basepart )
	end
end

-- transparency set function
function TransparencyModule:SetTransparent(value: boolean)
	for basepart: BasePart, initial_value: number in pairs(TransparencyModule.EditableParts) do
		basepart.LocalTransparencyModifier = value and 1 or initial_value -- setting part transparency
	end
end

return TransparencyModule