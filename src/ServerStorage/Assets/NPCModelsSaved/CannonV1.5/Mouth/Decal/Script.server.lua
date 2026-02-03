local Face = {
	Blink = "rbxassetid://78280507586629",
	Normal = {
		"rbxassetid://123786079337381",
		"rbxassetid://111105875164942",
		"rbxassetid://135929185159411",
		"rbxassetid://106171666825177"
	},
}

script.Parent.Parent.Parent.Humanoid.Animator:LoadAnimation(script.Animation):Play()

local IsBlinking = false
local CurrentFace = Face.Normal[1]

task.spawn(function()
	while task.wait(math.random(3, 30) / 10) do
		
		CurrentFace = Face.Normal[math.random(1, #Face.Normal)]
		
		if IsBlinking then
			continue
		end
		
		script.Parent.Texture = CurrentFace
	end
end)

while task.wait(math.random(3, 30) / 10) do
	script.Parent.Texture = Face.Blink
	IsBlinking = true
	
	task.wait(0.2)
	
	IsBlinking = false
	script.Parent.Texture = CurrentFace
end