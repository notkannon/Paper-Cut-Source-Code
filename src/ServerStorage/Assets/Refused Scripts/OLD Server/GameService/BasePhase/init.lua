type BasePhase = {
	time_length: number,
	name: string,
	enum: number,
	
	Stop: any,
	Start: any,
	CanStart: any,
	CanContinue: any
}

local BasePhase = {}
BasePhase._objects = {}
BasePhase.__index = BasePhase

-- constructor
function BasePhase.new()
	local self = setmetatable({
		time_length = nil :: number,
		running = nil :: boolean,
		name = nil :: string,
		enum = nil :: number,
	}, BasePhase)
	
	table.insert(
		self._objects,
		self
	)
	
	return self
end

function BasePhase:Stop() end
function BasePhase:Start() end
function BasePhase:CanStart(): boolean end
function BasePhase:CanContinue(): boolean end
function BasePhase:GetEnum(): number return self.enum end
function BasePhase:IsRunning(): boolean return self.running end
function BasePhase:SetRunning(value: boolean) self.running = value end

-- complete
return BasePhase