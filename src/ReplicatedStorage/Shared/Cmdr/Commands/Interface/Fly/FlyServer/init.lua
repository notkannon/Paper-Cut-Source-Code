return function (_, players: { Player }, context)
	-- velocity initial
	for _, player in ipairs(players) do
		local character: Model = player.Character
		if not character or not character:FindFirstChild('HumanoidRootPart') then continue end
		
		local hrp: BasePart = character.Head
		local BodyGyro: BodyGyro? = hrp:FindFirstChild('@fly_BodyGyro')
		local BodyPosition: BodyPosition? = hrp:FindFirstChild('@fly_BodyPosition')
		
		if not BodyPosition then
			BodyPosition = Instance.new('BodyPosition')
			BodyPosition.Name = '@fly_BodyPosition'
			BodyPosition.MaxForce = Vector3.zero
			BodyPosition.Parent = hrp
			BodyPosition.P = 10000
			BodyPosition.D = 10
		end
		
		if not BodyGyro then
			BodyGyro = Instance.new("BodyGyro") -- Body Gyro that determines your rotation
			BodyGyro.Name = '@fly_BodyGyro'
			BodyGyro.MaxTorque = Vector3.zero
			BodyGyro.Parent = hrp
		end
		
		-- enabling
		BodyGyro.MaxTorque = Vector3.one * (context and 40000 or 0)
		BodyPosition.MaxForce = Vector3.one * (context and 40000 or 0)
		
		-- removing old fly script
		if character:FindFirstChild('@fly') then
			character:FindFirstChild('@fly').Enabled = false
			character:FindFirstChild('@fly'):Destroy()
		end
		
		-- worker enabling
		
		if context then
			local worker = script["@fly"]:Clone()
			worker.Parent = character
			worker.Enabled = true
		end
	end
	
	return `Fly { context } for { #players } players.`
end
