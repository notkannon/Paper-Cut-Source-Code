--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

--//Types

export type ServiceImpl = {
	__index: ServiceImpl,
	
	GetName: () -> "LabelPromptService",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Service) -> boolean,
	
	new: (self: Service) -> AnyPrompt,
	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),
	
	IgnorePrompt: (self: AnyPrompt, Prompt: ProximityPrompt) -> (),
	Active: (self: AnyPrompt, Tagged: ProximityPrompt) -> nil,
	visiblity: (self: AnyPrompt, Prompt: ProximityPrompt, Shown: boolean) -> nil,
	
	FreezePrompt: (self: AnyPrompt, boolean: boolean) -> (),
	IsFreezePrompt: (self: AnyPrompt) -> number,
	
	Destroyed: (self: AnyPrompt) -> (),
}

export type InterfaceLabel = BillboardGui & {
	Arrow: ImageLabel,
	Sign: ImageLabel & {
		Detail: TextLabel
	},
}

export type PromptFields = {
	Janitor: Janitor.Janitor,
	

	
	instance: ProximityPrompt,

	PromptShown: Signal.Signal<AnyPrompt>,
	Destroyed: Signal.Signal<AnyPrompt>,
	TriggerEnded: Signal.Signal<AnyPrompt>,
	Triggered: Signal.Signal<AnyPrompt>,
	Changed: Signal.Signal<AnyPrompt>,

	PromptButtonHoldBegan: Signal.Signal<AnyPrompt>,
	PromptButtonHoldEnded: Signal.Signal<AnyPrompt>,

	Pose: {},
	
	CONTEXTUAL_ICONS: {Default: string, Clock: {Sun: string, Night: string}},
	LABEL_INITIAL_POSES: {{Arrow: {string}, Pose: UDim2}},
	
	Freeze: boolean,
	Proximities: ProximityPrompt,

	connections: {},
	
	Label_Tag: {ProximityPrompt},
	IgnoreProximity: {ProximityPrompt},
}

export type Service = typeof(setmetatable({} :: ProximityPrompt, {} :: AnyPrompt))

--//Returner

return nil