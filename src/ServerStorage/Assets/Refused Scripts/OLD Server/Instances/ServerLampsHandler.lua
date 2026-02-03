-- simple state handler, works with attributes lol
local LampsHandler = {}

-- interaction handle
function LampsHandler:HandleInteraction( model: Model, player: Player )
	local source: BasePart? = model:FindFirstChild('Source')
	assert(source, `No "Source" basepart exists in lamp { model }`)
	
	-- attrubute setting
	model:SetAttribute('Enabled',
		not model:GetAttribute('Enabled')
	)
end

-- complete
return LampsHandler