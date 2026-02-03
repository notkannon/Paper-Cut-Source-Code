--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local Classes = require(ReplicatedStorage.Shared.Classes)

local EnumsType = require(ReplicatedStorage.Shared.Enums)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local SlotBorderImageIDs = {
	--"rbxassetid://18679546100",
	--"rbxassetid://18679561682",
	"rbxassetid://115666418658063"
}

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI

local InventoryUI = BaseComponent.CreateComponent("InventoryUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

type UIInventorySlot = {
	Slot: {
		Index: number,
		Instance: Tool?,
		Component: BaseComponent.Component?,
		Connections: {RBXScriptConnection }
	},
	
	Instance: typeof(UIAssets.Misc.InventorySlot),
	Connections: { RBXScriptConnection }
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	GetSlotFromTool: (self: Component, instance: Tool) -> UIInventorySlot,
	GetSlotFromIndex: (self: Component, index: number) -> UIInventorySlot,
	OnItemAdded: (self: Component, index: number, instance: Tool) -> (),
	OnItemRemoved: (self: Component, index: number, instance: Tool) -> (),
	OnItemEquipped: (self: Component, index: number, instance: Tool) -> (),
	OnItemUnequipped: (self: Component, index: number, instance: Tool) -> (),
	OnItemCooldowned: (self: Component, index: number, instance: Tool) -> (),
	
	ShowItemDescription: (self: Component, slot: UIInventorySlot) -> (),

	_InitSlots: (self: Component) -> (),
	_ClearSlots: (self: Component) -> (),
	_CreateSlot: (self: Component, slot: UIInventorySlot) -> (),
	_ConnectInventoryEvents: (self: Component) -> (),
}

export type Fields = {
	
	Slots: { UIInventorySlot },
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "InventoryUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "InventoryUI", Frame & any, {}>

--//Methods

function InventoryUI.GetSlotFromTool(self: Component, instance: Tool)
	for _, Slot in ipairs(self.Slots) do
		if Slot.Slot.Instance ~= instance then
			continue
		end
		
		return Slot
	end
end

function InventoryUI.GetSlotFromIndex(self: Component, index: number)
	for _, Slot in ipairs(self.Slots) do
		if Slot.Slot.Index ~= index then
			continue
		end

		return Slot
	end
end

function InventoryUI.ShowItemDescription(self: Component, slot: UIInventorySlot)
	
	--used for re-rendering guide list in real time
	local function RenderGuide(guideTemplate: string, context: string) : string
		
		local InputController = Classes.GetSingleton("InputController")
		local BindStrings = InputController:GetStringsFromContext(context, { MouseFormatStyle = "Abbreviate" })
		
		return string.format(guideTemplate, table.unpack(BindStrings))
	end
	
	local data = slot.Slot.Component.Data
	local Guides = {RenderGuide("%s to drop", "DropItem")}
	
	for _, GuideString in ipairs(data.Guides) do
		table.insert(Guides, GuideString)
	end
	
	if #Guides == 1 then
		table.insert(Guides, "MISSING_GUIDE")
	end
	
	TweenUtility.ClearAllTweens(self.Instance.CurrentItem)
	TweenUtility.PlayTween(self.Instance.CurrentItem, TweenInfo.new(3), {TextTransparency = 1}, nil, 2)
	
	self.Instance.CurrentItem.Text = (data.Name or "Unnamed"):upper()
	self.Instance.CurrentItem.TextTransparency = 0
	
	for _, Label: TextLabel in ipairs(self.Instance.Content.Guides:GetChildren()) do
		if not Label:IsA("TextLabel") then
			continue
		end
		
		Label.Text = ""
	end
	
	for Index, Guide in ipairs(Guides) do
		local Label = self.Instance.Content.Guides:FindFirstChild("guide" .. Index) :: TextLabel?
		if not Label then
			continue
		end
		
		TweenUtility.ClearAllTweens(Label)
		TweenUtility.PlayTween(Label, TweenInfo.new(3), {TextTransparency = 1}, nil, 2)
		if type(Guide) == "string" then
			Label.Text = Guide
		else
			Label.Text = RenderGuide(Guide.Text, Guide.ContextBind)
		end
		Label.TextTransparency = .7
	end
end

function InventoryUI.OnItemCooldowned(self: Component, index: number, instance: Tool)
	
	local Data = self:GetSlotFromIndex(index)
	local State = Data.Slot.Component:GetState() :: { Cooldowned: boolean, CooldownDuration: number }
	local Slot = Data.Instance
	
	local function ProcessHide()
		TweenUtility.ClearAllTweens(Slot.Indicator)
		TweenUtility.PlayTween(Slot.Indicator, TweenInfo.new(.3), {
			BackgroundTransparency = 1
		} :: Frame)
	end

	Data.Slot.Component.Janitor:Add(ProcessHide, nil, "RemoveIndicatorConnection")
	
	if not State.Cooldowned then
		ProcessHide()
	else
		TweenUtility.ClearAllTweens(Slot.Indicator)
		
		Slot.Indicator.BackgroundTransparency = .8
		Slot.Indicator.Size = UDim2.fromScale(1, 1)
		
		TweenUtility.PlayTween(Slot.Indicator, TweenInfo.new(State.CooldownDuration, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			
		} :: Frame, function(status)
			if status ~= Enum.TweenStatus.Completed then
				return
			end
			
			ProcessHide()
			
			Data.Slot.Component.Janitor:Remove("RemoveIndicatorConnection")
		end)
	end
end

function InventoryUI.OnItemAdded(self: Component, index: number, instance: Tool, data: {[string] : any})
	
	local SlotInstance = self:GetSlotFromIndex(index).Instance
	
	TweenUtility.ClearAllTweens(SlotInstance.Thumbnail)
	
	SlotInstance.Thumbnail.Image = data.Icon or "rbxassetid://11622919444"
	SlotInstance.Thumbnail.ImageTransparency = .7
end

function InventoryUI.OnItemRemoved(self: Component, index: number, instance: Tool, data: {[string] : any})
	
	self:OnItemUnequipped(index, instance)
	
	local SlotInstance = self:GetSlotFromIndex(index).Instance
	
	TweenUtility.ClearAllTweens(SlotInstance.Thumbnail)
	TweenUtility.PlayTween(SlotInstance.Thumbnail, TweenInfo.new(.15), {ImageTransparency = 1})
end

function InventoryUI.OnItemEquipped(self: Component, index: number, instance: Tool)
	
	local Slot = self:GetSlotFromIndex(index)
	local SlotInstance = Slot.Instance
	
	self:ShowItemDescription(Slot)
	
	TweenUtility.ClearAllTweens(SlotInstance.Index)
	TweenUtility.ClearAllTweens(SlotInstance.Thumbnail)
	TweenUtility.ClearAllTweens(SlotInstance.Thumbnail.Frame)
	
	SlotInstance.Index.TextTransparency = 0.3
	SlotInstance.ImageIndex.ImageTransparency = 0
	SlotInstance.Thumbnail.ImageTransparency = 0
	SlotInstance.Thumbnail.Frame.ImageTransparency = 0.3
	
	SlotInstance.Thumbnail.Frame:TweenSize(UDim2.fromScale(1.1, 1.1), "Out", "Back", 0.13, true)
end

function InventoryUI.OnItemUnequipped(self: Component, index: number, instance: Tool)
	
	local Slot = self:GetSlotFromIndex(index).Instance
	
	TweenUtility.ClearAllTweens(Slot.Index)
	TweenUtility.ClearAllTweens(Slot.Thumbnail)
	TweenUtility.ClearAllTweens(Slot.Thumbnail.Frame)
	
	TweenUtility.PlayTween(Slot.Index, TweenInfo.new(0.1), {TextTransparency = .7})
	TweenUtility.PlayTween(Slot.ImageIndex, TweenInfo.new(0.1), {ImageTransparency = .25})
	TweenUtility.PlayTween(Slot.Thumbnail, TweenInfo.new(0.1), {ImageTransparency = .7})
	TweenUtility.PlayTween(Slot.Thumbnail.Frame, TweenInfo.new(0.1), {ImageTransparency = .8})
	
	Slot.Thumbnail.Frame:TweenSize(UDim2.fromScale(1.3, 1.3), "Out", "Sine", .2, true)
end

function InventoryUI._CreateSlot(self: Component, slot: UIInventorySlot)
	
	local Instance = UIAssets.Misc.InventorySlot:Clone()
	
	Instance.Parent = self.Instance.Content
	--Instance.Thumbnail.Frame.Image = SlotBorderImageIDs[math.random(1, #SlotBorderImageIDs)]
	Instance.Thumbnail.Image = ""
	
	Instance.Index.Text = slot.Slot.Index
	Instance.LayoutOrder = slot.Slot.Index
	
	Instance.Indicator.Visible = true
	Instance.Indicator.BackgroundTransparency = 1
	Instance.Indicator.Size = UDim2.fromScale(1, 1)
	
	slot.Instance = Instance
end

function InventoryUI._ClearSlots(self: Component)
	
	for _, Instance: Instance in ipairs(self.Instance.Content:GetChildren()) do
		
		if Instance:IsA("UIListLayout") or Instance.Name == "Guides" then
			continue
		end
		
		Instance:Destroy()
	end
	
	for _, Slot in ipairs(self.Slots) do
		
		for _, Connection: RBXScriptConnection in ipairs(Slot.Connections) do
			Connection:Disconnect()
		end
		
		table.clear(Slot)
	end
	
	table.clear(self.Slots)
end

function InventoryUI._InitSlots(self: Component)
	
	self:_ClearSlots()
	
	local InventoryComponent = ComponentsManager.Get(Player.Backpack, "ClientInventoryComponent")
	
	for _, Slot in ipairs(InventoryComponent.Slots) do
		
		local UISlot = {
			Slot = Slot,
			Instance = nil,
			Connections = {}
		}
		
		table.insert(self.Slots, UISlot)
		
		self:_CreateSlot(UISlot)
	end
end

function InventoryUI._ConnectInventoryEvents(self: Component, inventory: BaseComponent.Component)
	
	self:_InitSlots()
	self:SetEnabled(true)
	
	for _, Slot in ipairs(inventory.Slots) do
		
		if not Slot.Component then
			continue
		end
		
		self:OnItemAdded(
			Slot.Index,
			Slot.Instance,
			Slot.Component.Data
		)
	end
	
	self.Janitor:Add(inventory.ItemAdded:Connect(function(...)
		self:OnItemAdded(...)
	end))
	
	self.Janitor:Add(inventory.ItemRemoved:Connect(function(...)
		self:OnItemRemoved(...)
	end))
	
	self.Janitor:Add(inventory.ItemEquipped:Connect(function(...)
		self:OnItemEquipped(...)
	end))
	
	self.Janitor:Add(inventory.ItemUnequipped:Connect(function(...)
		self:OnItemUnequipped(...)
	end))
	
	self.Janitor:Add(inventory.ItemStateChanged:Connect(function(...)
		self:OnItemCooldowned(...)
	end))
	
	
	-- localisation of Index labels
	
	local InputController = Classes.GetSingleton("InputController")
	
	local function UpdateIndexKeybinds()
		for SlotIndex, UISlot in ipairs(self.Slots) do
			local RawString = InputController:GetStringsFromContext("Inventory")[SlotIndex]
			
			local TextLabel = UISlot.Instance.Index
			local ImageLabel = UISlot.Instance.ImageIndex
			TextLabel.Visible = InputController:IsKeyboard()
			ImageLabel.Visible = not TextLabel.Visible
			
			if InputController:IsKeyboard() then
				TextLabel.Text = RawString
			else
				ImageLabel.Image = InputController:GetImageIdFromString(RawString)
			end
		end
	end
	
	UpdateIndexKeybinds()
	
	self.Janitor:Add(InputController.DeviceChanged:Connect(function(new)
		UpdateIndexKeybinds()
	end))
end

function InventoryUI.OnConstructClient(self: Component, controller, inventory)
	BaseUIComponent.OnConstructClient(self, controller)
	
	self.Slots = {}
	self.Instance.CurrentItem.TextTransparency = 1

	for _, Label: TextLabel in ipairs(self.Instance.Content.Guides:GetChildren()) do
		
		if not Label:IsA("TextLabel") then
			continue
		end

		Label.Text = ""
		Label.TextTransparency = 1
	end

	self:SetEnabled(false)
	self:_ConnectInventoryEvents(inventory)
end

--//Returner
return InventoryUI