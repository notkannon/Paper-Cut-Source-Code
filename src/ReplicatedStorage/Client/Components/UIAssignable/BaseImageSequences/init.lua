--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local BaseImageSequences = BaseComponent.CreateComponent("BaseImageSequences", { isAbstract = true }) :: Impl

--//Types
export type MyImpl = {
	__index: MyImpl,
	
	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
	SequenceObject: {string},
	Delay: number,
	reverseOnFinished: boolean,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseImageSequences", ImageLabel>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseImageSequences", ImageLabel>

--//Methdos

function BaseImageSequences.OnConstructClient(self: Component)
	if not self.SequenceObject then
		return
	end

	local Index = 1
	local Direction = 1 -- 1 = Forward, -1 = Backward
	local LastUpdate = os.clock()
	local TotalFrames = #self.SequenceObject

	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		if os.clock() - LastUpdate < self.Delay then
			return
		end

		LastUpdate = os.clock()
		Index += Direction

		-- Cambia dirección si estamos al final o al inicio
		if self.reverseOnFinished then
			if Index >= TotalFrames then
				Index = TotalFrames
				Direction = -1
			elseif Index <= 1 then
				Index = 1
				Direction = 1
			end
		else
			if Index > TotalFrames then
				Index = 1
			end
		end

		self.Instance.Image = self.SequenceObject[Index]
	end))
end

--//Returner

return BaseImageSequences
