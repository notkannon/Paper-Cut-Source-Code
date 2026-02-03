--// Services

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

--// Imports

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local CharactersData = require(ReplicatedStorage.Shared.Data.Characters)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ShopService = require(ReplicatedStorage.Shared.Services.ShopService)
local TemplateService = require(ReplicatedStorage.Shared.Services.TemplateService)
local CameraController = require(ReplicatedStorage.Client.Controllers.CameraController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local Utility = require(ReplicatedStorage.Shared.Utility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local MusicUtility = require(ReplicatedStorage.Client.Utility.MusicUtility)

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local ClientProducer = require(ReplicatedStorage.Client.ClientProducer)

local CharactersPassive = require(script.CharactersPassive)

--// Types

export type ScreenType = "Items" | "Characters"
export type CharacterType = "Student" | "Anomaly" | "Teacher" | "Faculty"
export type TabTypes = CharacterType & "Items"

export type SkinPreview = {
	
	Name: string,
	DisplayName: string,
	Icon: string,
	Thumbnail: string,
	Description: string,
	Cost: number,

	IsOwned: boolean,
	IsEquipped: boolean,
}

export type CharacterPreview = {
	
	Name: string,
	DisplayName: string,
	Description: string,
	Icon: string,
	Cost: number,
	Thumbnail: string,
	CharacterType: CharacterType,

	Skins: {[string]: SkinPreview},
	Passive:{ [string]: { [string]: CharactersPassive.DataType } },

	IsOwned: boolean,
	IsEquipped: boolean,
}

export type ItemPreview = {
	
	Name: string,
	DisplayName: string,
	Description: string,
	Type: string,
	Icon: string,
	Cost: number,
	Characteristics: {string},
}

export type FacultyPreview = {
	Name: string,
	DisplayName: string,
	Description: string,
	Icon: string,
	Cost: number,
	Thumbnail: string,
	Type: "Faculty",
	
	Passive:{ [string]: { [string]: CharactersPassive.DataType } },
	IsOwned: boolean,
}


export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl)),

	AddItem: (self: Component, Item: string) -> (),
	RemoveItem: (self: Component, Item: string) -> (),
	ClearItems: (self: Component) -> (),
	
	ShowSkinPreview: (self: Component, Skin: SkinPreview) -> (),

	UpdateItemPreview: (self: Component) -> (),
	UpdateCharacterPreview: (self: Component, Data: CharacterPreview) -> (),
	UpdateCharactersData: (self: Component) -> (),
	UpdateSkinsData: (self: Component, Data: CharacterPreview) -> (),

	ToggleInterface: (self: Component, Value: boolean) -> (),
	ToggleTab: (self: Component, Tab: TabTypes) -> (),
	ToggleScreen: (self: Component, Screen: TabTypes) -> (),
	ToggleOwnedVisibility: (self: Component) -> (),

	ShowCharacterPreview: (self: Component, Data: CharacterPreview) -> (),
	ShowItemPreview: (self: Component, Data: ItemPreview) -> (),
	ShowFacultiesPreview: (self: Component, FacultyName: string) -> (),

	AttemptPurchaseCharacter: (self: Component, Data: CharacterPreview) -> (),
	AttemptPurchaseSkin: (self: Component, Character: string, Skin: string) -> (),

	_Cleanup: (self: Component) -> (),
	_BindConnections: (self: Component) -> (),
	_BindTempConnections: (self: Component) -> (),
	_BindSetup: (self: Component) -> (),
	_Registery: (self: Component) -> (),
	
	_ConstructCharacters: (self: Component) -> (),
	_RegisterFaculties: (self: Component) -> (),
	_ConstructItems: (self: Component) -> (),

}

export type Fields = {
	
	EnabledJanitor: Janitor.Janitor,
	ShopJanitor: Janitor.Janitor,
	
	CharacterPreviewJanitor: Janitor.Janitor,
	FacultyPreviewJanitor: Janitor.Janitor,
	ItemPreviewJanitor: Janitor.Janitor,
	
	_CharacterChanged: Signal.Signal<string>,
	_SkinChanged: Signal.Signal<string, string>, -- Character \ skin
	CharactersDataChanged: Signal.Signal<>,

	ItemAmountChanged: Signal.Signal<string, number>, -- Item | Amount
	ItemPreviewChanged: Signal.Signal<string, boolean>, -- Item | IsRemoved
	ItemPurchaseChanged: Signal.Signal<string, boolean>, -- Item | Purchased
	PageChanged: Signal.Signal<string>,

	ShopEnabled: boolean,
	CurrentScreen: TabTypes,
	CurrentTab: TabTypes,
	LastTab: TabTypes,
	
	References: {
		
		Sidebar: Frame,
		Preview: Frame,
	},

	ShowOnlyOwned: boolean,

	PreviewItem: ItemPreview,
	PreviewSkin: SkinPreview,
	PreviewCharacter: CharacterPreview,
	PreviewFaculty: ModuleScript?,

	ItemsOwned: {string},

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ShopUI", Frame, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ShopUI", Frame, {}>

--// Variables

-- i think it like spaggetie code but no its to necesary
local CanPurchaseItem = true

local ShopEnterDebounce = false
local CanExitOnShop = false

local ItemPreviewPart = workspace.Lobby.Shop.ItemPreviewPart
local ShopCollision = workspace.Lobby.Shop.ShopCollider
local ShopActivePart = workspace.Lobby.Shop.ShopActivePart
local ShopPart = workspace.Lobby.Shop.ShopActivePart

local ShopUIFolder = ReplicatedStorage.Assets.UI.Shop
local RolesFolder = ReplicatedStorage.Shared.Data.Roles
local ShopMusic = MusicUtility.Music.Misc.Shop

local LocalPlayer = Players.LocalPlayer
local ShopUI = BaseComponent.CreateComponent("ShopUI", { isAbstract = false }, BaseUIComponent) :: Component
local Characters = {}

local Tabs = {
	Anomaly = {
		Icon = "rbxassetid://77659743414625", 
		Name = "Anomalies", 
		Type = "Anomaly", 
		Role = "Anomaly",
		Visible = false
	},

	Teacher = {
		Icon = "rbxassetid://77659743414625", 
		Name = "Teachers", 
		Type = "Teacher", 
		Role = "Teacher",
		Visible = true,
		Description = "The terrors of the night, Teachers offer discipline to students who fail miserably in survival. Each bring their own tools of torment to dismember, maim, and bludgeon the students in their own unique way. Work with two other teachers to properly educate your victims on how to endure the hunt"
	},

	Student = {
		Icon = "rbxassetid://72215827673764", 
		Name = "Students", 
		Type = "Student", 
		Role = "Student",
		Visible = true,
		Description = "Eternally stuck in a night of torment, Students are who you'll play as most of your time here. Each has their own unique passive that makes them stand out among the others. Pick and choose which student you wish to bring into the never ending hunt"
	},
	
	Faculty = {
		Icon = "rbxassetid://96658995447814",
		Name = "Faculties",
		Type = "Faculty",
		Role = nil,
		Visible = true,
		Description = "Faculties are different means in which a student can choose to survive. Each comes with its own active ability and a passive unique to them. Be it an offensive or defensive playstyle, there’s a faculty for each and every student to make use of"
	},
	
	Items = {
		Icon = "rbxassetid://139507704857901",
		Name = "Items",
		Type = "Items",
		Role = nil,
		Visible = true,
		Description = "Small trinkets to bring along with you when trying to fight off your tormentors. Some can be found in the map, some can only be bought here. You can only bring three with you, so use them wisely. Should you not be a student when purchasing an item, your purchase will be saved for next round instead"
	}
}

--// Constants

local MAX_ITEMS_SIZE = 3

local THROWABLE_NAMES = {
	"Book",
	"PaperAirplane",
	"TennisBall",
	"ViscousAcid"
}

local CONSUMABLE_NAMES = {
	"Apple",
	"Banana",
	"Soda",
	"Vitamins",
	"Orange"
}

local GENERAL_TAB_COLORS = {
	Anomaly = {
		--Glow = Color3.fromRGB(144, 11, 11),
		Background = Color3.fromRGB(97, 29, 13),
		Text = Color3.fromRGB(225, 83, 64)	
	},

	Teacher = {
		--Glow = Color3.fromRGB(177, 52, 52),
		Background = Color3.fromRGB(197, 64, 64),
		Text = Color3.fromRGB(255, 184, 149)
	},

	Student = {
		--Glow = Color3.fromRGB(62, 106, 116),
		Background = Color3.fromRGB(71, 111, 116),
		Text = Color3.fromRGB(221, 255, 249)
	},
	
	Items = {
		--Glow = Color3.fromRGB(62, 106, 116),
		Background = Color3.fromRGB(64, 84, 158),
		Text = Color3.fromRGB(215, 231, 241)
	},
	
	Faculty = {
		--Glow = Color3.fromRGB(100, 61, 116),
		Background = Color3.fromRGB(110, 75, 116),
		Text = Color3.fromRGB(245, 219, 255)
	},
}

local GENERAL_SKIN_STATUS_COLORS = {
	Purchase = {
		TextColor = Color3.fromRGB(103, 103, 115),
		BackgroundColor = Color3.fromRGB(91, 94, 103),
		IconTransparency = 0.75
	},

	Owned = {
		TextColor = Color3.fromRGB(157, 171, 181),
		BackgroundColor = Color3.fromRGB(138, 159, 179),
		IconTransparency = 0.12
	},

	Equipped = {
		TextColor = Color3.fromRGB(183, 197, 225),
		BackgroundColor = Color3.fromRGB(216, 218, 238),
		IconTransparency = 0
	}
}

local ITEM_COLOR_STATUS = {
	[0] = {
		TextColor = Color3.fromRGB(166, 178, 189),
		Background = Color3.fromRGB(60, 85, 152)
	},
	
	[1] = {
		TextColor = Color3.fromRGB(166, 178, 189),
		Background = Color3.fromRGB(60, 85, 152)
	},

	[2] = {
		TextColor = Color3.fromRGB(182, 163, 133),
		Background = Color3.fromRGB(249, 183, 91)
	},

	[3] = {
		TextColor = Color3.fromRGB(182, 80, 71),
		Background = Color3.fromRGB(238, 88, 58)
	},
}

local ITEM_STATUS_BUTTON_COLORS = {
	Add = {
		BackgroundEnabled = Color3.fromRGB(249, 249, 249),
		BackgroundDisabled = Color3.fromRGB(148, 152, 168)
	},
	
	Removed = {
		BackgroundEnabled = Color3.fromRGB(227, 119, 100),
		BackgroundDisabled = Color3.fromRGB(188, 143, 143)
	}
}

--// Methods

function ShopUI.UpdateCharacterPreview(self: Component, Data: CharacterPreview)
	
	local Preview = self.References.Preview
	local RegularView = Preview.RegularView
	local DescriptionView = Preview.DescriptionView
	
	local SkinData = self.PreviewSkin :: SkinPreview
	
	
	Data.IsOwned = ShopService:IsCharacterOwned(LocalPlayer, Data.Name)
	Data.IsEquipped = Data.IsOwned and ShopService:GetCurrentCharacter(LocalPlayer, Data.CharacterType) == Data.Name
	SkinData.IsOwned = ShopService:IsSkinOwned(LocalPlayer, Data.Name, SkinData.Name)
	SkinData.IsEquipped = SkinData.IsOwned and ShopService:GetCurrentSkin(LocalPlayer, Data.Name) == SkinData.Name
	
	-- Updating Visuals
	local ButtonText = Data.IsOwned and (Data.IsEquipped and "Equipped" or "Owned") or "Purchase"
	local CharacterPreview = self.References.Sidebar.Content:FindFirstChild(Data.CharacterType):FindFirstChild("Content"):FindFirstChild(Data.Name)

	--print(Data)

	--RegularView.ProcessButton.Text = ButtonText
	CharacterPreview.Status.Text = ButtonText
	print(ButtonText, CharacterPreview.Status.Text)
	RegularView.ProcessButton.BackgroundColor3 = Color3.fromRGB(226, 233, 249)
	RegularView.SubjectName.Text = Data.DisplayName
	RegularView.NameShade.ImageColor3 = GENERAL_TAB_COLORS[Data.CharacterType].Background	
	--RegularView.Thumbnail.Image = Data.Thumbnail ~= "" and Data.Thumbnail or Data.Icon

	print(SkinData)
	self:ShowSkinPreview(self.PreviewSkin)

	for SkinName, SkinData in Data.Skins do
		local SkinFrame = RegularView.Skins:FindFirstChild(SkinName)


		-- Update data
		SkinData.IsOwned = ShopService:IsSkinOwned(LocalPlayer, Data.Name, SkinName)
		SkinData.IsEquipped = SkinData.IsOwned and ShopService:GetCurrentSkin(LocalPlayer, Data.Name) == SkinName

		-- Updating visuals
		local IsSelected = SkinData.IsOwned and (SkinData.IsEquipped and 0.5 or 0.8) or 1
		SkinFrame.BackgroundTransparency = IsSelected
	end
end

function ShopUI.ShowFacultiesPreview(self: Component, Data: FacultyPreview)
	if self.PreviewFaculty == Data.Name then
		return
	end
	
	local StudentRoleModule = ReplicatedStorage.Shared.Data.Roles.Student
	
	local Preview = self.References.Preview
	local RegularView = Preview.RegularView
	local DescriptionView = Preview.DescriptionView
	local TextDescription = RegularView.TextDescription
	local MoreInfoButton = RegularView.MoreInfoButton
	
	local function AddTag(Context: string)
		local TagFrame = ShopUIFolder.PreviewTagText:Clone()
		TagFrame.BackgroundColor3 = GENERAL_TAB_COLORS.Faculty.Background
		TagFrame.Name = Context
		TagFrame.Text = Context:upper()
		TagFrame.Visible = true
		TagFrame.Parent = RegularView.Tags
	end
	
	local function CleanUpJanitors()
		self.ItemPreviewJanitor:Cleanup()
		self.CharacterPreviewJanitor:Cleanup()
		self.FacultyPreviewJanitor:Cleanup()
	end
	
	-- cleannning old data 
	for _, Tag in RegularView.Tags:GetChildren() do
		if not Tag:IsA("TextLabel") then
			continue
		end

		Tag:Destroy()
	end
	
	CleanUpJanitors()
	
	self.PreviewCharacter = nil
	self.PreviewItem = nil
	self.PreviewFaculty = Data
	
	Preview.Visible = true
	RegularView.Visible = true
	RegularView.RemoveButton.Visible = false
	TextDescription.Visible = true
	DescriptionView.Visible = false
	RegularView.Skins.Visible = false
	MoreInfoButton.Visible = true
	
	
	RegularView.Thumbnail.Image = Data.Icon
	TextDescription.Text = Data.Description
	RegularView.SubjectName.Text = Data.Name
	RegularView.ProcessButton.Text = "Owned" -- this its for now
	RegularView.ProcessButton.BackgroundColor3 = Color3.fromRGB(226, 233, 249)
	RegularView.NameShade.ImageColor3 = GENERAL_TAB_COLORS.Faculty.Background
	
	RegularView.SkinsLabel.Text = "DESCRIPTION"
	
	AddTag("Role")
	AddTag("Faculty")

	self:RenderDescriptionView()
	self:HandleMoreInfoFrame()
end

function ShopUI.RenderDescriptionView(self: Component)
	local Preview = self.References.Preview :: Frame
	local DescriptionView = Preview.DescriptionView
	
	for _, Passive in DescriptionView.PassivesContent:GetChildren() do
		if not Passive:IsA("Frame") then
			continue
		end

		Passive:Destroy()
	end
	
	local PassiveLayoutOrderCount = 0
	local DisplaySubject = self.PreviewCharacter or self.PreviewFaculty
	
	DescriptionView.SubjectName.Text = DisplaySubject.DisplayName
	DescriptionView.SubjectDescription.Text = DisplaySubject.Description
	
	if DisplaySubject and DisplaySubject.Passive then
		for PassiveName, PassiveData in DisplaySubject.Passive do
			PassiveLayoutOrderCount += 1			

			local PassiveFrame = ShopUIFolder.PassiveFrame:Clone()
			PassiveFrame.Name = PassiveName
			PassiveFrame.Parent = DescriptionView.PassivesContent

			PassiveFrame.PassiveName.Text = (PassiveData.DisplayType or PassiveData.Type or "Passive") .. ": ".. (PassiveData.DisplayName or "MISSING PASSIVE TITLE")
			PassiveFrame.Icon.Image = DisplaySubject.Icon
			PassiveFrame.LayoutOrder = PassiveData.LayoutOrder or PassiveLayoutOrderCount

			local Property = if DisplaySubject.Type == "Faculty" then require(RolesFolder.Student[DisplaySubject.Name]) else CharactersData[DisplaySubject.Name]
			local Role = if DisplaySubject.Type == "Faculty" then Property else require(RolesFolder[self.PreviewCharacter.CharacterType])
			local PassiveContext = PassiveData.Type == "Passive" and Property.PassivesData[PassiveName] or {}
			local ActiveContext = PassiveData.Type == "Active" and Property.SkillsData[PassiveName] or {}

			local Description = PassiveData.Type == "Active" and ActiveContext.Cooldown
				and `Cooldown: <font color="rgb(0,255,0)">{ActiveContext.Charge and "special" or (ActiveContext.Cooldown or 0).."s"}</font>` 
				or "" 

			local ContextTable = {
				Character = Property,
				Passive = PassiveContext,
				Role = Role,
				Active = ActiveContext,
			}

			for _, Properties in PassiveData.Description do
				local RenderingText = TemplateService:RenderText(Properties.Text, Properties.Properties, ContextTable)
				if Description ~= "" then
					Description = Description.."\n"..RenderingText
				else
					Description = RenderingText
				end
			end
			
			local AppropiateJanitor: Janitor.Janitor = DisplaySubject.Type == "Faculty" and self.FacultyPreviewJanitor or self.CharacterPreviewJanitor
			AppropiateJanitor:Add(RunService.RenderStepped:Connect(function(d)
				local ScreenSize = workspace.CurrentCamera.ViewportSize
				local FontSize = math.round(ScreenSize.Y / 1080 * 20)
				PassiveFrame.PassiveData.TextSize = FontSize

				local PassiveSize = TextService:GetTextSize(Description, FontSize, Enum.Font.Nunito, Vector2.new(PassiveFrame.AbsoluteSize.X * 0.925, 9999999))
				PassiveFrame.Size = UDim2.new(1, 0, 0, PassiveSize.Y + 52)
			end), nil, "FrameResizeThread"..PassiveLayoutOrderCount)
			PassiveFrame.PassiveData.Text = Description
		end
	end
end

function ShopUI.HandleMoreInfoFrame(self: Component)
	local Preview = self.References.Preview :: Frame
	local RegularView = Preview.RegularView
	local DescriptionView = Preview.DescriptionView
	local MoreInfoButton = RegularView.MoreInfoButton
	local PreviewSize = Preview.Size
	TweenUtility.ClearAllTweens(Preview)
	Preview.Size = UDim2.fromScale(0.25, 0.7)
	
	local IsFaculty = self.PreviewFaculty and true or false
	local AppropiatePreview = IsFaculty and "PreviewFaculty" or "PreviewCharacter"
	local AppropiateJanitor: Janitor.Janitor = IsFaculty and self.FacultyPreviewJanitor or self.CharacterPreviewJanitor
	
	
	AppropiateJanitor:Add(MoreInfoButton.MouseButton1Click:Connect(function()

		if not self[AppropiatePreview] then
			return
		end

		--size changing
		TweenUtility.ClearAllTweens(Preview)
		TweenUtility.PlayTween(Preview, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.4, PreviewSize.Y.Scale)
		})

		RegularView.Visible = false
		DescriptionView.Visible = true

	end))

	--disabling
	AppropiateJanitor:Add(DescriptionView.BackButton.MouseButton1Click:Connect(function()

		--restoring size
		TweenUtility.ClearAllTweens(Preview)
		TweenUtility.PlayTween(Preview, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.25, PreviewSize.Y.Scale)
		})

		RegularView.Visible = true
		DescriptionView.Visible = false

	end))
end

function ShopUI.ShowSkinPreview(self: Component, Skin: SkinPreview)		
	self.PreviewSkin = Skin
	
	local Preview = self.References.Preview :: Frame
	local RegularView = Preview.RegularView
	local ButtonText = Skin.IsOwned and (Skin.IsEquipped and "Equipped" or "Owned") or "Purchase"

	RegularView.SubjectName.Text = self.PreviewCharacter.DisplayName ..
		(self.PreviewSkin.DisplayName and self.PreviewSkin.DisplayName ~= "Default" and ` ({self.PreviewSkin.DisplayName})` or "")
	RegularView.Thumbnail.Image = (self.PreviewCharacter.Thumbnail ~= "" and self.PreviewCharacter.Thumbnail or self.PreviewCharacter.Icon)
	RegularView.ProcessButton.Text = ButtonText
end

function ShopUI.ShowCharacterPreview(self: Component, Data: CharacterPreview)
	
	if self.PreviewCharacter == Data then
		return
	end
	
	local Preview = self.References.Preview :: Frame
	local RegularView = Preview.RegularView
	local DescriptionView = Preview.DescriptionView
	local TextDescription = RegularView.TextDescription
	local MoreInfoButton = RegularView.MoreInfoButton
	local RemoveButton = RegularView.RemoveButton
	local PreviewSize = Preview.Size
	
	local function AddTag(Context: string)
		local TagFrame = ShopUIFolder.PreviewTagText:Clone()
		TagFrame.BackgroundColor3 = GENERAL_TAB_COLORS[Data.CharacterType].Background
		TagFrame.Name = Context
		TagFrame.Text = Context:upper()
		TagFrame.Visible = true
		TagFrame.Parent = RegularView.Tags
	end
	
	local function CleanUpJanitors()
		self.ItemPreviewJanitor:Cleanup()
		self.CharacterPreviewJanitor:Cleanup()
		self.FacultyPreviewJanitor:Cleanup()
	end
	
	-- Once Cleanning data
	for _, Tag in RegularView.Tags:GetChildren() do
		if not Tag:IsA("TextLabel") then
			continue
		end

		Tag:Destroy()
	end

	for _, Skin in RegularView.Skins:GetChildren() do
		if not Skin:IsA("CanvasGroup") then
			continue
		end
		
		Skin:Destroy()
	end
	
	-- Data
	CleanUpJanitors()

	self.PreviewCharacter = Data
	self.PreviewSkin = self.PreviewCharacter.Skins[ShopService:GetCurrentSkin(LocalPlayer, self.PreviewCharacter.Name) or "Default"]
	self.PreviewItem = nil
	self.PreviewFaculty = nil
	
	Preview.Visible = true
	RegularView.Visible = true
	RegularView.Skins.Visible = true
	DescriptionView.Visible = false
	TextDescription.Visible = false
	RemoveButton.Visible = false
	MoreInfoButton.Visible = true
	
	RegularView.SkinsLabel.Text = "AVAILABLE SKINS"
	
	AddTag("Character")
	AddTag(Data.CharacterType)
	
	-- Passives
	self:RenderDescriptionView()
	
	-- Skins
	local SkinLayoutCount = 0
	if self.PreviewCharacter.Skins then
		for SkinName, SkinData in self.PreviewCharacter.Skins do
			SkinLayoutCount += 1
			
			local SkinFrame = ShopUIFolder.CanvasSkin:Clone()
			SkinFrame.Name = SkinName
			SkinFrame.LayoutOrder = SkinLayoutCount
			SkinFrame.Visible = true
			SkinFrame.Parent = RegularView.Skins
			
			if SkinName == "Default" then
				SkinFrame.LayoutOrder = -1
			end

			local IsSelected = SkinData.IsEquipped and 0.6 or 1
			SkinFrame.BackgroundTransparency = IsSelected
			
			SkinFrame.SkinName.Text = SkinData.DisplayName
			SkinFrame.BackgroundImage.Image = SkinData.Thumbnail or ""
			SkinFrame.Cost.Text = SkinData.Cost
			
			self.CharacterPreviewJanitor:Add(SkinFrame.SelectionOverlay.MouseButton1Click:Connect(function()
				self:ShowSkinPreview(SkinData)
			end), nil, `Skin{Data.Name}${SkinName}PreviewConnection`)
		end
	end
	
	
	self:UpdateCharacterPreview(self.PreviewCharacter)
	
	-- Connectiong 
	self.CharacterPreviewJanitor:Add(RegularView.ProcessButton.MouseButton1Click:Connect(function()
		if not self.PreviewCharacter then
			return
		end
		
		if self.PreviewCharacter.CharacterType == "Teacher" then
			if ShopService:GetCurrentSkin(LocalPlayer, self.PreviewCharacter.Name) ~= self.PreviewSkin.Name then
				if self.PreviewSkin.IsOwned then
					ClientRemotes.ShopServiceChangeSelected.Fire({
						Character = self.PreviewCharacter.Name,
						Skin = self.PreviewSkin.Name
					})
				else
					self:AttemptPurchaseSkin(self.PreviewCharacter.Name, self.PreviewSkin.Name)
				end
			end

			return
		end

		self:AttemptPurchaseCharacter(self.PreviewCharacter)
		self:AttemptPurchaseSkin(self.PreviewCharacter.Name, self.PreviewSkin.Name)

	end))
	
	--
	-- MORE INFO content frame
	--
	
	--enabling
	self:HandleMoreInfoFrame()
	
	--other
	
	self.CharacterPreviewJanitor:Add(self.CharactersDataChanged:Connect(function()
		
		if not self.PreviewCharacter then
			return
		end
		
		self:UpdateCharacterPreview(self.PreviewCharacter)
	end))
end

function ShopUI.UpdateCharactersData(self: Component)
	local Sidebar = self.References.Sidebar
	--local CharactersContent = Sidebar.Content:FindFirstChild(self.CurrentScreen):FindFirstChild("Content")
	
	--for _, Character in CharactersContent do
	--	if not Character:IsA("CanvasGroup") then
	--		continue
	--	end
		
	--	local IsOwned = ShopService:IsCharacterOwned(LocalPlayer, Character.Name)
	--	local IsEquipped = IsOwned and ShopService:GetCurrentCharacter(LocalPlayer, ShopService:GetCharacterType(Character.Name)) == Character.Name
	--	local StatusText = IsOwned and (IsEquipped and "Equipped" or "Owned") or "Purchase"
		
	--	Character.Status.Text = StatusText
	--end
	
	for _, Screen in Sidebar.Content:GetChildren() do
		
		if not Screen:IsA("Frame") or Screen.Name == "Items" then
			continue
		end
		
		for _, Character in Screen.Content:GetChildren() do
			
			if not Character:IsA("CanvasGroup") then
				continue
			end
			
			local CharacterData = Characters[Character.Name]
			
			if not CharacterData then
				continue
			end
			
			-- update data
			CharacterData.IsOwned = ShopService:IsCharacterOwned(LocalPlayer, Character.Name)
			CharacterData.IsEquipped = CharacterData.IsOwned and ShopService:GetCurrentCharacter(LocalPlayer, CharacterData.CharacterType) == Character.Name
			
			-- update ui
			local StatusText = CharacterData.IsOwned
				and (CharacterData.IsEquipped and Screen.Name ~= "Faculties" and "Equipped" or "Owned")
				or `Purchase`
			
			print(StatusText)
			Character.Status.Text = StatusText
		end
	end	
end

function ShopUI.ShowItemPreview(self: Component, Data: ItemPreview)
	if self.PreviewItem == Data then
		return
	end
	
	local Preview = self.References.Preview
	local DescriptionView = Preview.DescriptionView
	local RegularView = Preview.RegularView
	local TextDescription = RegularView.TextDescription
	Preview.Size = UDim2.fromScale(0.25, 0.7)
	
	-- ohtere
	local function AddTag(Context: string)
		local TagFrame = ShopUIFolder.PreviewTagText:Clone()
		TagFrame.BackgroundColor3 = GENERAL_TAB_COLORS.Items.Background
		TagFrame.Name = Context
		TagFrame.Text = Context:upper()
		TagFrame.Visible = true
		TagFrame.Parent = RegularView.Tags
	end
	
	local function CleanUpJanitors()
		self.ItemPreviewJanitor:Cleanup()
		self.CharacterPreviewJanitor:Cleanup()
		self.FacultyPreviewJanitor:Cleanup()
	end
	
	-- game:Destroy()
	
	-- cleannning old data 
	for _, Tag in RegularView.Tags:GetChildren() do
		if not Tag:IsA("TextLabel") then
			continue
		end

		Tag:Destroy()
	end
	
	-- Updating
	CleanUpJanitors()
	
	self.PreviewItem = Data
	self.PreviewCharacter = nil
	self.PreviewFaculty = nil
	
	Preview.Visible = true
	RegularView.Visible = true
	RegularView.RemoveButton.Visible = true
	TextDescription.Visible = true
	DescriptionView.Visible = false
	RegularView.Skins.Visible = false
	
	RegularView.Thumbnail.Image = self.PreviewItem.Icon -- <-- its the kenny
	RegularView.SubjectName.Text = self.PreviewItem.DisplayName
	RegularView.NameShade.BackgroundColor3 = GENERAL_TAB_COLORS.Items.Background
	TextDescription.Text = self.PreviewItem.Description
	
	RegularView.ProcessButton.BackgroundColor3 = #TableKit.Values(self.ItemsOwned) < MAX_ITEMS_SIZE 
		and Color3.fromRGB(226, 233, 249)
		or Color3.fromRGB(127, 68, 68)
	
	-- events
	AddTag("Item")
	AddTag(Data.Type)
	
	-- whoops hardcoding moment :skull:
	RegularView.MoreInfoButton.Visible = false
	RegularView.ProcessButton.Text = "Purchase Item"
	RegularView.SkinsLabel.Text = "DESCRIPTION"

	self.ItemPreviewJanitor:Add(RegularView.ProcessButton.MouseButton1Click:Connect(function()
		local Size = #TableKit.Values(self.ItemsOwned)
		
		if Size < MAX_ITEMS_SIZE then
			self:AddItem(self.PreviewItem.Name)
		end
	end))
	
	self.ItemPreviewJanitor:Add(RegularView.RemoveButton.MouseButton1Click:Connect(function()
		local Size = #TableKit.Values(self.ItemsOwned)
		if Size == 0 then
			return
		end
		
		self:RemoveItem(self.PreviewItem.Name)
	end))
	
	local function UpdateLabel()
		if not self.PreviewItem then
			return
		end

		if #TableKit.Values(self.ItemsOwned) < MAX_ITEMS_SIZE then
			RegularView.ProcessButton.Text = "Purchase"
			TweenUtility.PlayTween(RegularView.ProcessButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(226, 233, 249)})
		else
			RegularView.ProcessButton.Text = "Max"
			TweenUtility.PlayTween(RegularView.ProcessButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(127, 68, 68)})
		end
	end
	
	self.ItemPreviewJanitor:Add(self.ItemAmountChanged:Connect(function(Item, Number)
		UpdateLabel()
	end))
	
	self:UpdateItemPreview()
	UpdateLabel()
end

function ShopUI.HidePreview(self: Component)
	local Preview = self.References.Preview
	Preview.Visible = false
end

function ShopUI.UpdateItemPreview(self: Component)
	
	local Sidebar = self.References.Sidebar
	local ItemsContent = Sidebar.Content:FindFirstChild("Items"):FindFirstChild("Content")
	local TweenTime = TweenInfo.new(0.12)
	
	local ItemsSize = #TableKit.Values(self.ItemsOwned)
	
	local ButtonPurchase = self.Instance.ItemPurchaseButton
	local Text = (not CanPurchaseItem and "Play a round as student before you purchase again") or 
		(ItemsSize > 0 and `Purchase: {ItemsSize}/{MAX_ITEMS_SIZE} Items` or "<b>Select Items</b> to purchase")

	local CalculateFinalCost = 0

	--updating data
	ButtonPurchase.ItemLabel.Text = Text
	TweenUtility.PlayTween(ButtonPurchase, TweenTime, {
		--BackgroundColor3 = ItemsSize <= 0 and Color3.fromRGB(99, 70, 70) or Color3.fromRGB(217, 199, 220),
		BackgroundTransparency = ( (ItemsSize == 0 or not CanPurchaseItem) and 1 or 0 )
	})

	TweenUtility.PlayTween(self.Instance.ItemPurchaseButton.ItemLabel, TweenTime, {
		TextColor3 = (ItemsSize == 0 or not CanPurchaseItem) and Color3.fromRGB(236, 235, 255) or Color3.fromRGB(19, 20, 0)
	})

	for _, Item in self.ItemsOwned do
		CalculateFinalCost = CalculateFinalCost + ItemsData[Item].Cost
	end

	ButtonPurchase.CostLabel.Text = "<b>Cost: </b>" .. tostring(CalculateFinalCost) .. " points"
	
	-- Only the Content
	for _, Item in  ItemsContent:GetChildren() do
		
		if not Item:IsA("CanvasGroup") then
			continue
		end
		
		local ItemData = ItemsData[Item.Name]
		local Status = Item.Status :: TextLabel
		local ItemColors = ITEM_COLOR_STATUS[ItemsSize]
		
		TweenUtility.PlayTween(Item.GlowImage, TweenTime, {ImageColor3 = ItemColors.Background})
		TweenUtility.PlayTween(Item.Cost.Icon, TweenTime, {ImageColor3 = ItemColors.TextColor})
		TweenUtility.PlayTween(Item.Cost, TweenTime, {TextColor3 = ItemColors.TextColor})
		TweenUtility.PlayTween(Item.Status, TweenTime, {TextColor3 = ItemColors.TextColor})
		TweenUtility.PlayTween(Item.DisplayName, TweenTime, {TextColor3 = ItemColors.TextColor})

		-- table.find won't work here
		local HasThisItem = false

		for _, Child in self.ItemsOwned do
			if Child == Item.Name then
				HasThisItem = true
				break
			end
		end

		Item.Status.Text = ItemsSize.."/"..MAX_ITEMS_SIZE
	end

	-- Only the preview
	
end

function ShopUI.ClearItems(self: Component)
	for Index = 1, MAX_ITEMS_SIZE do
		local Attachment = ItemPreviewPart:FindFirstChild(tostring(Index))
		local Item = Attachment:FindFirstChildWhichIsA("BasePart")
		if not Item then
			continue
		end
		Item:Destroy()
	end
	
	table.clear(self.ItemsOwned)
	self.ItemAmountChanged:Fire(nil, 0)
end

function ShopUI.AddItem(self: Component, Item: string)
	
	local Data = ItemsData[Item]
	--print(Data, Item)
	
	if not Data then
		return
	end
	
	if not CanPurchaseItem then
		return
	end

	-- floaitng animation and tweening only the Now and, whatthe?
	local Now = os.clock()
	local ItemsSize = #TableKit.Values(self.ItemsOwned) -- dont ask

	-- to be safe
	if ItemsSize >= 3 then
		return
	end

	--get if theres an attachment available
	local SelectedIndex

	for Index = 1, MAX_ITEMS_SIZE do
		
		local Attachment = ItemPreviewPart:FindFirstChild(tostring(Index))
		local Item = Attachment:FindFirstChildWhichIsA("BasePart")
		
		if not Item then
			
			SelectedIndex = Index
			
			break
		end
	end

	--print(SelectedIndex, self.ItemsOwned)

	if not SelectedIndex then
		return
	end

	-- Clonning instance
	local InstanceJanitor = self.Janitor:Add(Janitor.new(), "Destroy", "Item_"..SelectedIndex)
	local ModelAttachment = ItemPreviewPart:FindFirstChild(tostring(SelectedIndex)) :: Model
	local ItemInstance = Data.Instance:Clone() :: Tool
	local Handle = ItemInstance:FindFirstChildWhichIsA("BasePart")

	ItemInstance.Enabled = false

	local ProxPrompt: ProximityPrompt? = Handle:FindFirstChildWhichIsA("ProximityPrompt")
	
	if ProxPrompt then
		ProxPrompt:Destroy()
	end

	-- adding weld to the handler
	for _, Part in ItemInstance:GetDescendants() do
		if not Part:IsA("BasePart") 
			or Part == Handle then

			continue
		end

		local Weld = Instance.new("WeldConstraint")
		Weld.Parent = Handle
		Weld.Name = Part.Name
		Weld.Part0 = Handle
		Weld.Part1 = Part

		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.Parent = Handle
	end

	Handle.Anchored = true
	Handle.CanCollide = false
	Handle.CanQuery = true

	for _, Child: Instance in Handle:GetChildren() do
		if Child:IsA("BasePart") then
			Child.Anchored = true
		end
	end

	Handle.Parent = ModelAttachment
	Handle.Name = Item
	Handle:PivotTo(ModelAttachment.WorldPivot)
	ItemInstance:Destroy()
	InstanceJanitor:LinkToInstance(Handle, false)

	-- Animating 
	InstanceJanitor:Add(RunService.RenderStepped:Connect(function()
		
		if not MatchStateClient:IsIntermission() then
			return
		end

		local Time = os.clock() - Now
		Handle:PivotTo(
			ModelAttachment.WorldPivot * CFrame.new(0, math.sin(Time * 2) * 0.125, 0) 
				* CFrame.Angles(
					math.sin(Time * 1.5 + 0.134) * math.rad(6), 
					math.cos(Time * 1.3 + 0.412) * math.rad(8),
					math.sin(Time * 1.7 + 0.621) * math.rad(7)
				)
		)
	end))

	-- adding to the list
	self.ItemsOwned[SelectedIndex] = Item
	self.ItemAmountChanged:Fire(Item, ItemsSize+1)
end

function ShopUI.RemoveItem(self: Component, Item: string | number)
	if typeof(Item) == "string" then
		local Data = ItemsData[Item]
		if not Data then
			return
		end
	end
	
	if not CanPurchaseItem then
		return
	end

	local ItemsSize = #TableKit.Values(self.ItemsOwned) -- dont ask
	if ItemsSize <= 0 then
		return
	end

	local SelectedIndex

	if typeof(Item) == "string" then

		for Index = MAX_ITEMS_SIZE, 1, -1 do
			local Attachment = ItemPreviewPart:FindFirstChild(tostring(Index))
			local Handle = Attachment:FindFirstChild(Item)
			if Handle then
				SelectedIndex = Index
				break
			end
		end

		if not SelectedIndex then
			return
		end

	else

		SelectedIndex = Item

	end

	local Attachment = ItemPreviewPart:FindFirstChild(tostring(SelectedIndex)):GetChildren()[1]

	Attachment:Destroy()

	local Janitor = self.Janitor:Get("Item_"..SelectedIndex)
	if not Janitor then
		return
	end

	Janitor:Destroy()

	-- removing from the table list
	self.ItemsOwned[SelectedIndex] = nil
	self.ItemAmountChanged:Fire(Item, ItemsSize-1)
end

function ShopUI.AttemptPurchaseCharacter(self: Component, Data: CharacterPreview)
	if ShopService:IsCharacterOwned(LocalPlayer, Data.Name) then 
		if ShopService:GetCurrentCharacter(LocalPlayer, Data.CharacterType) ~= Data.Name then
			ClientRemotes.ShopServiceChangeSelected.Fire({
				Character = Data.Name,
				Skin = "Default"
			})
		end
	else
		ClientRemotes.ShopServiceBuy.Fire({
			Type = "Character",
			Data = {
				Character = Data.Name,
				Skin = "",
				ItemName = "",
			}
		})
	end

end 

function ShopUI.AttemptPurchaseSkin(self: Component, Character: string, Skin: string)
	if ShopService:IsSkinOwned(LocalPlayer, Character, Skin) then
		if ShopService:GetCurrentSkin(LocalPlayer, Character) ~= Skin then
			ClientRemotes.ShopServiceChangeSelected.Fire({
				Character = Character,
				Skin = Skin
			})
		end
	else
		ClientRemotes.ShopServiceBuy.Fire({
			Type = "Skin",
			Data = {
				Character = Character,
				Skin = Skin,
				ItemName = "",
			}
		})
	end
end

function ShopUI.ToggleTab(self: Component, Tab: TabTypes)
	
	if self.CurrentTab == Tab then
		return
	end

	local TabColor = GENERAL_TAB_COLORS[Tab]

	self.LastTab = self.CurrentTab
	self.CurrentTab = Tab

	-- Applying Tab Propts
	local CurrentRoleContent = Tab .. "Content"
	local CurrentTab = self.References.Sidebar.Sections[Tab]

	self:ToggleScreen(self.CurrentTab)
	self.PageChanged:Fire(Tab)
	--CurrentTabSection.Visible = true

	-- Animating His CurrentTab button :D
	TweenUtility.PlayTween(CurrentTab, TweenInfo.new(0.189), {
		BackgroundColor3 = TabColor.Background,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1.2, 0.04),
		TextColor3 = TabColor.Text
	})

	TweenUtility.PlayTween(CurrentTab.Icon, TweenInfo.new(0.189), {
		Size = UDim2.fromScale(1.3, 1.3),
		ImageTransparency = 0
	})
	
	if self.LastTab and self.LastTab ~= "" then
		local LastTab = self.References.Sidebar.Sections[self.LastTab]
		
		-- Animation for LastTab
		TweenUtility.PlayTween(LastTab, TweenInfo.new(0.189), {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.8,
			Size = UDim2.fromScale(1.0, 0.04),
			TextColor3 = Color3.new(1, 1, 1)
		})

		TweenUtility.PlayTween(LastTab.Icon, TweenInfo.new(0.189), {
			Size = UDim2.fromScale(1, 1),
			ImageTransparency = 0.6
		})
	end
end

function ShopUI.ToggleScreen(self: Component, Screen: TabTypes)
	
	if self.CurrentScreen == Screen then
		print("[ShopUI]: Same screen selected")
		return
	end
	
	local Sidebar = self.References.Sidebar
	local ScreenFrame = Sidebar.Content:FindFirstChild(Screen)
	
	ScreenFrame.Visible = true
	self.CurrentScreen = Screen
	
	if self.LastTab then
		local LastScreen = Sidebar.Content:FindFirstChild(self.LastTab)
		LastScreen.Visible = false
	end

	print("[ShopUI]: Switching to ".. self.CurrentScreen)
end

function ShopUI.ToggleInterface(self: Component, Value: boolean)
	
	if self.ShopEnabled == Value then
		return
	end

	self.ShopEnabled = Value
	self:SetEnabled(self.ShopEnabled)

	if self.ShopEnabled then

		self.Janitor:Remove("ExitShopThread")

		CameraController:SetActiveCamera("ShopAttached")

		TweenUtility.PlayTween(ShopCollision.Lighting.PointLight, TweenInfo.new(1), {
			Color = Color3.fromRGB(150, 125, 175),
			Brightness = 8.48,
			Range = 35
		})

		ShopMusic:ChangeVolume(1, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), "Set")
		ShopMusic:ChangePlayback(1, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), "Set")

		self:_BindTempConnections()
		self:HidePreview()

	else
		
		CameraController:SetActiveCamera("FreeAttached")

		TweenUtility.PlayTween(ShopCollision.Lighting.PointLight, TweenInfo.new(1), {
			Color = Color3.fromRGB(12, 68, 76),
			Brightness = 5.58,
			Range = 15
		})

		ShopMusic:ChangeVolume(0, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), "Set")
		ShopMusic:ChangePlayback(0, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), "Set")

		self.PreviewCharacter = nil
		self.PreviewItem = nil
		self.PreviewFaculty = nil
		
		self.EnabledJanitor:Cleanup()
	end
end

function ShopUI._Registery(self: Component)
	
	local TabIndex = 1
	
	for TabName, TabData in Tabs do
		
		if not TabData.Visible then
			continue
		end

		-- initialize SectionButton
		local TabButton = ShopUIFolder.SectionButton:Clone()
		TabButton.Name = TabName
		TabButton.Visible = true
		TabButton.Parent = self.References.Sidebar.Sections

		TabIndex += 1
		TabButton.LayoutOrder = TabIndex

		TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BackgroundTransparency = 0.8
		TabButton.Size = UDim2.fromScale(1.0, 0.04)
		TabButton.Text = TabData.Name:upper()
		TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)

		TabButton.Icon.Image = TabData.Icon
		TabButton.Icon.ImageTransparency = 0.6
		TabButton.Icon.Size = UDim2.fromScale(1, 1)
		
		TabButton:AddTag("UIButton")

		-- initialize SectionContent
		local SectionContent = ShopUIFolder.ContentSidebar:Clone()
		SectionContent.Name = TabName
		SectionContent.Visible = false
		SectionContent.Parent = self.References.Sidebar.Content

		SectionContent.Title.Text = TabData.Name
		SectionContent.Description.Text = TabData.Description or "SectionContent doesnt have description data, btw selkie when Tabs Description?"
		SectionContent.Title.Icon.Image = TabData.Icon
		
		-- adding events
		self.Janitor:Add(TabButton.MouseButton1Click:Connect(function()
			self:ToggleTab(TabName)
		end))
	end

	self:_RegisterFaculties()
	self:_ConstructCharacters()
	self:_ConstructItems()
end

function ShopUI._Cleanup(self: Component)
	-- removing Sidebar
	local Sidebar = self.References.Sidebar
	
	for _, Section in Sidebar.Sections:GetChildren() do
		if not Section:IsA("TextButton") then
			continue
		end
		
		Section:Destroy()
	end
	
	for _, Content in Sidebar.Content:GetChildren() do
		if not Content:IsA("Frame") then
			continue
		end
		Content:Destroy()
	end
	
	-- removing Preview
	local Preview = self.References.Preview
	for _, Tag in Preview.RegularView.Tags:GetChildren() do
		if not Tag:IsA("TextLabel") then
			continue
		end

		Tag:Destroy()
	end

	for _, Skin in Preview.RegularView.Skins:GetChildren() do
		if not Skin:IsA("CanvasGroup") then
			continue
		end

		Skin:Destroy()
	end
	
	for _, Passive in Preview.DescriptionView.PassivesContent:GetChildren() do
		if not Passive:IsA("Frame") then
			continue
		end

		Passive:Destroy()
	end
	
	-- Cleaned :fire:
	print("[ShopUI]: Store Content Cache Cleaned.")
end

function ShopUI._BindSetup(self: Component)
	
	self.Instance.Visible = false
	self.References.Preview.Visible = false

	-- Binding Functions
	self:_Registery()

	-- Setup Music and Lighting
	ShopMusic:PlayQuiet()
	ShopMusic:ChangePlayback(0, nil, "Set")
	
	--moving interface to 3D space
	
	local PlayerGui = LocalPlayer.PlayerGui
	local Interactive = workspace
		:WaitForChild("Shop")
		:WaitForChild("Interactive")
	
	--local LeftInterface = Interactive
	--	:FindFirstChild("LeftScreen").Interface :: SurfaceGui
	
	--local RightInterface = Interactive
	--	:FindFirstChild("RightScreen").Interface :: SurfaceGui
	
	--self.Instance.Preview.Parent = LeftInterface
	--self.Instance.Sidebar.Parent = RightInterface
	
	----display part linking
	--LeftInterface.Adornee = LeftInterface.Parent
	--RightInterface.Adornee = RightInterface.Parent
	
	----parenting interfaces to player's gui to allow interactions
	--LeftInterface.Parent = PlayerGui
	--RightInterface.Parent = PlayerGui
	
	-- Calling Functions
	self:ToggleScreen("Items")
	self:ToggleTab("Items")
end

function ShopUI._BindConnections(self: Component)
	
	-- This its for get his characters :skull:
	local function BindCharacterSelector(Type: string)
		self.Janitor:Add(ClientProducer.Root:subscribe(Selectors.SelectCharacter(LocalPlayer.Name, Type), function(Character)
			self.CharactersDataChanged:Fire()
		end))
	end
	
	-- we need to loop through the characters
	for CharacterName, CharacterData in CharactersData do
		self.Janitor:Add(ClientProducer.Root:subscribe(Selectors.SelectSkin(LocalPlayer.Name, CharacterName), function(Skin)
			self.CharactersDataChanged:Fire()
		end))
	end

	self.Janitor:Add(ClientProducer.Root:subscribe(Selectors.SelectStats(LocalPlayer.Name), function(data)
		self.Instance.Points.Text = data.Points
	end))
	
	self.Janitor:Add(self.PageChanged:Connect(function(Page)
		self.Instance.ItemPurchaseButton.Visible = (Page == "Items") -- looks weird but it works :skull:✨✨✨✨✨✨✨✨✨✨
		
	end))
	
	self.Janitor:Add(ClientProducer.Root:subscribe(Selectors.SelectOwnedCharacters(LocalPlayer.Name), function()
		self.CharactersDataChanged:Fire()
	end))

	-- this can be connected just once - put it under regular janitor
	self.Janitor:Add(MatchStateClient.PlayerSpawned:Connect(function(Player)
		
		if Player ~= LocalPlayer then
			return
		end

		if not MatchStateClient:IsRound() then
			
			CanExitOnShop = false
			
			return
		end

		
	end), nil, "SpawnControlThread")
	
	self.Janitor:Add(ClientRemotes.ShopItemPayoutComplete.SetCallback(function(data)
		print('got data from server', data)
		CanPurchaseItem = true
		self:ClearItems()
		self:UpdateItemPreview()
		
		TweenUtility.PlayTween(self.Instance.ItemPurchaseButton.CostLabel, TweenInfo.new(1), {
			TextTransparency = 0
		}, nil, 0.3)
		TweenUtility.PlayTween(self.Instance.ItemPurchaseButton.ItemLabel, TweenInfo.new(1), {
			TextTransparency = 0
		}, nil, 0.3)
	end), nil, "PayoutControlThread")

	self.Janitor:Add(RolesManager.PlayerRoleChanged:Connect(function(Player)
		if Player ~= LocalPlayer then
			return
		end

		self:ToggleInterface(false)
		CanExitOnShop = false
	end))
	
	self.Janitor:Add(MatchStateClient.PreparingChanged:Connect(function()
		
		self:ToggleInterface(false)
		CanExitOnShop = false

		Utility.ApplyParams(ShopCollision.Lighting.PointLight, {
			Color = Color3.fromRGB(12, 68, 76),
			Brightness = 5.58,
			Range = 15
		})

	end))

	self.Janitor:Add(ShopActivePart.Touched:Connect(function(HRP)
		--print('touched black')
		local Player = Players:GetPlayerFromCharacter(HRP.Parent)
		if Player ~= LocalPlayer then
			return
		end

		if not RolesManager:IsPlayerSpectator(Player) then
			return
		end
		
		if CanExitOnShop  then
			return
		end
		
		self.Janitor:AddPromise(Promise.delay(0.25):andThen(function()
			self:ToggleInterface(true)
			CanExitOnShop = true
		end))
	end))

	self.Janitor:Add(ShopPart.TouchEnded:Connect(function(HRP)
		
		--print('ended touch with white')
		local Player = Players:GetPlayerFromCharacter(HRP.Parent)
		
		if Player ~= LocalPlayer then
			return
		end

		for _, Part: BasePart in ShopActivePart:GetTouchingParts() do
			
			if Part.Name ~= "HumanoidRootPart" then
				continue
			end
			
			local Model = Part:FindFirstAncestorWhichIsA("Model")
			
			if not Model then
				continue
			end
			
			local Player = Players:GetPlayerFromCharacter(Model)
			
			if Player and Player == LocalPlayer then
				return
			end
		end

		if not RolesManager:IsPlayerSpectator(Player) then
			return
		end
		
		if not CanExitOnShop then
			return
		end
		
		CanExitOnShop = false
	end))

	self.Janitor:Add(self.Instance.ReturnButton.MouseButton1Click:Connect(function()
		self:ToggleInterface(false)
	end))

	self.Janitor:Add(self.Instance.ItemPurchaseButton.MouseButton1Click:Connect(function()
		if not CanPurchaseItem then
			return
		end


		local Size = #TableKit.Values(self.ItemsOwned)
		if Size <= 0  then
			return
		end

		local CalculateFinalCost = 0

		for _, Item in self.ItemsOwned do
			CalculateFinalCost = CalculateFinalCost + ItemsData[Item].Cost
		end

		local Points = ClientProducer.Root:getState(Selectors.SelectStats(LocalPlayer.Name)).Points

		if CalculateFinalCost > Points then
			-- you cant afford the items
			SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.ui_click_wrong)

			self.Instance.ItemPurchaseButton.CostLabel.Text = "Not enough points!"
			self.Instance.ItemsSection.ItemPurchaseButton.Size = UDim2.fromScale(0.8, 0.05)
			TweenUtility.PlayTween(self.Instance.ItemPurchaseButton, TweenInfo.new(1), {
				Size = UDim2.fromScale(0.8, 0.035)
			})
			
			self.Janitor:Add(task.delay(1, function()
				self:UpdateItemPreview()
			end), nil, "DelayedUpdateThread")

			return
		end

		for _, Item in self.ItemsOwned do
			ClientRemotes.ShopServiceBuy.Fire({
				Type = "Item",
				Data = {
					Character = "",
					Skin = "",
					ItemName = Item,
				}
			})
		end

		CanPurchaseItem = false
		TweenUtility.PlayTween(self.Instance.ItemPurchaseButton, TweenInfo.new(1), {
			BackgroundTransparency = 1
		}, nil, 0.3)
		TweenUtility.PlayTween(self.Instance.ItemPurchaseButton.CostLabel, TweenInfo.new(1), {
			TextTransparency = 1
		}, nil, 0.3)
		TweenUtility.PlayTween(self.Instance.ItemPurchaseButton.ItemLabel, TweenInfo.new(1), {
			TextTransparency = 0
		}, nil, 0.3)
		self.Instance.ItemPurchaseButton.ItemLabel.TextColor3 = Color3.fromRGB(236, 235, 255)
		
		self.Instance.ItemPurchaseButton.ItemLabel.Text = "Play a round as student before you purchase again"
		
		--self:ClearItems()

		SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Achievement)
	end))

	-- Connections about the characterchanged lol
	--BindCharacterSelector("Anomaly")
	BindCharacterSelector("Student")
end

-- connections that disappear when you go out and reappear when you come back
function ShopUI._BindTempConnections(self: Component)
	
	self.CharacterPreviewJanitor = self.EnabledJanitor:Add(Janitor.new(), nil, "CharacterPreview")
	self.ItemPreviewJanitor = self.EnabledJanitor:Add(Janitor.new(), nil, "ItemPreview")
	self.FacultyPreviewJanitor = self.EnabledJanitor:Add(Janitor.new(), nil, "FacultyPreview")
	
	local Mouse = LocalPlayer:GetMouse()
	Mouse.TargetFilter = workspace.Characters -- ignoring the players :3
	--local LastSelected = nil
	local CurrentSelected = nil

	local SelectionItemHighlight = self.EnabledJanitor:Add(Instance.new("Highlight"), nil, "SelectionItemHighlight")
	SelectionItemHighlight.Name = "SelectionItemHighlight"
	SelectionItemHighlight.Enabled = false
	SelectionItemHighlight.FillTransparency = 0.65
	SelectionItemHighlight.FillColor = Color3.fromRGB(255, 255, 255)
	SelectionItemHighlight.Parent = ItemPreviewPart

	self.EnabledJanitor:Add(Mouse.Move:Connect(function()

		if not SelectionItemHighlight or  
			not SelectionItemHighlight:IsA("Highlight") then
			return
		end

		if not Mouse.Target:IsDescendantOf(ItemPreviewPart) then
			SelectionItemHighlight.Enabled = false
			CurrentSelected = nil
			return
		end

		if not Mouse.Target or not Mouse.Target.Parent:IsA("Model") or not tonumber(Mouse.Target.Parent.Name) then
			SelectionItemHighlight.Enabled = false
			return
		end

		if CurrentSelected == Mouse.Target.Parent then
			return
		end

		SelectionItemHighlight.Enabled = true
		SelectionItemHighlight.Adornee = Mouse.Target.Parent

		if MatchStateClient:IsRound() then
			SelectionItemHighlight.Enabled = false
			return
		end

		CurrentSelected = Mouse.Target.Parent
		return
	end))

	self.EnabledJanitor:Add(Mouse.Button1Up:Connect(function()
		--print(CurrentSelected, CurrentSelected and CurrentSelected.Parent, CurrentSelected and CurrentSelected:IsA("Model"))

		if not CurrentSelected then
			return
		end

		if not CurrentSelected or not CurrentSelected:IsA("Model") then
			return
		end
		
		if not CanPurchaseItem then
			return
		end

		self:RemoveItem(tonumber(CurrentSelected.Name))

		return
	end))
end

function ShopUI._ConstructCharacters(self: Component)
	
	for CharacterName, CharacterData in CharactersData do
		
		-- constructing data
		local Skins = {}
		
		if CharacterData.Skins then
			
			for SkinName, SkinData in CharacterData.Skins do
				
				if not SkinData.IsForSale then
					continue
				end

				local IsOwned = ShopService:IsSkinOwned(LocalPlayer, CharacterName, SkinName)
				local IsEquipped = IsOwned and ShopService:GetCurrentSkin(LocalPlayer, CharacterName) == SkinName
				
				local Data = {
					Name = SkinName,
					DisplayName = SkinData.Name,
					Icon = SkinData.Icon,
					Cost = SkinData.Cost,

					IsOwned = IsOwned,
					IsEquipped = IsEquipped,
				}
				
				Skins[SkinName] = Data

			end
		end
		
		
		local CharacterType = ShopService:GetCharacterType(CharacterName)
		local IsOwnedPromise = ShopService:IsCharacterOwned(LocalPlayer, CharacterName, true)
		local IsEquippedPromise = ShopService:GetCurrentCharacter(LocalPlayer, CharacterType, true)
		local CharacterPromises = { IsOwnedPromise, IsEquippedPromise }
		
		Promise.allSettled(CharacterPromises):andThen(function(Arguments)
			
			local IsOwned = ShopService:IsCharacterOwned(LocalPlayer, CharacterName)
			local IsEquipped = IsOwned and ShopService:GetCurrentCharacter(LocalPlayer, CharacterType) == CharacterName
			local CharacterStatus = IsOwned and (IsEquipped and CharacterType ~= "Faculty" and "Equipped" or "Owned") or "Purchase"
			
			
			---
			--- FUCKING PLACE WHERE WE NEED MANUALLY INSERT NEW DATA FIELDS IN CHARACTER SECTION / Kannon
			---
			
			-- man if we delete this, the half of the game will broke ._.
			
			
			local Data = {
				
				Name = CharacterName,
				DisplayName = CharacterData.CharacterDisplayName or CharacterName,
				Description = CharacterData.Description,
				Icon = CharacterData.Icon,
				Thumbnail = CharacterData.Thumbnail,
				Cost = CharacterData.Cost or 0,
				CharacterType = CharacterType,

				Skins = Skins,
				Passive = CharactersPassive[CharacterName] or {},

				IsOwned = IsOwned,
				IsEquipped = IsOwned and IsEquipped
				
			} :: CharacterPreview
			
			local CharacterFrame = ShopUIFolder.CanvasSquareItem:Clone()
			CharacterFrame.Name = CharacterName
			CharacterFrame.Parent = self.References.Sidebar.Content:FindFirstChild(CharacterType).Content
			
			CharacterFrame.Icon.Image = Data.Icon
			CharacterFrame.DisplayName.Text = Data.DisplayName
			CharacterFrame.Cost.Text = Data.Cost
			CharacterFrame.GlowImage.ImageColor3 = GENERAL_TAB_COLORS[CharacterType].Background
			CharacterFrame.Status.Text = CharacterStatus
			
			self.Janitor:Add(CharacterFrame.SelectionOverlay.MouseButton1Click:Connect(function()
				self:ShowCharacterPreview(Data)
			end))
			
			self.Janitor:Add(CharacterFrame.MouseEnter:Connect(function()
				TweenUtility.PlayTween(CharacterFrame.DisplayName, TweenInfo.new(0.1), {BackgroundTransparency = 0.5, TextTransparency = 0})
			end))

			self.Janitor:Add(CharacterFrame.MouseLeave:Connect(function()
				TweenUtility.PlayTween(CharacterFrame.DisplayName, TweenInfo.new(0.1), {BackgroundTransparency = 1, TextTransparency = 1})
			end))
			
			Characters[Data.Name] = Data
		end)
	end
	
	self.Janitor:Add(self.CharactersDataChanged:Connect(function()
		self:UpdateCharactersData()
	end))
end

function ShopUI._ConstructItems(self: Component)
	
	local ItemJanitor = self.Janitor:Add(Janitor.new())
	local Items = {}

	for ItemName, ItemData in ItemsData do
		
		if not ItemData.CanOnShop then
			continue
		end

		-- Construct Visuals
		local ItemFrame = ShopUIFolder.CanvasSquareItem:Clone()
		ItemFrame.Name = ItemName
		ItemFrame.Parent = self.References.Sidebar.Content:FindFirstChild("Items").Content

		ItemFrame.DisplayName.Text = ItemData.Name
		ItemFrame.Icon.Image = ItemData.Icon
		ItemFrame.Cost.Text = ItemData.Cost
		ItemFrame.GlowImage.ImageColor3 = Color3.fromRGB(60, 85, 152)
		ItemFrame.Status.TextColor3 = Color3.fromRGB(204, 229, 234)
		ItemFrame.Status.BackgroundTransparency = 1
		ItemFrame.Status.Text = "0/3"
		ItemFrame.Status.Visible = true
		
		local Characteristics = {}

		-- Saving ItemPreviewData
		local Data: ItemPreview = {
			Name = ItemName,
			DisplayName = ItemData.Name,
			Description = ItemData.Description,
			Type = ItemData.Type,
			Cost = ItemData.Cost,
			Icon = ItemData.Icon,

			Characteristics = Characteristics
		}
		
		ItemJanitor:LinkToInstance(ItemFrame, true)
		ItemJanitor:Add(ItemFrame.SelectionOverlay.MouseButton1Click:Connect(function()
			self:ShowItemPreview(Data)
		end))
		
		self.Janitor:Add(ItemFrame.MouseEnter:Connect(function()
			TweenUtility.PlayTween(ItemFrame.DisplayName, TweenInfo.new(0.1), {BackgroundTransparency = 0.5, TextTransparency = 0})
		end))

		self.Janitor:Add(ItemFrame.MouseLeave:Connect(function()
			TweenUtility.PlayTween(ItemFrame.DisplayName, TweenInfo.new(0.1), {BackgroundTransparency = 1, TextTransparency = 1})
		end))

		Items[ItemName] = Data
	end
	
	ItemJanitor:Add(self.ItemAmountChanged:Connect(function()
		self:UpdateItemPreview()
	end))
end

function ShopUI._RegisterFaculties(self: Component)
	
	local StudentRoleModule = ReplicatedStorage.Shared.Data.Roles.Student
	
	for _, FacultyModule: ModuleScript in StudentRoleModule:GetChildren() do
		
		if not FacultyModule:IsA("ModuleScript") then
			continue
		end
		
		local FacultyRawData = require(FacultyModule)
		local FacultyFrame = ShopUIFolder.CanvasSquareItem:Clone()
		local FacultyName = FacultyRawData.MovesetName
		local FacultyData = {

			Name = FacultyName,
			DisplayName = FacultyRawData.DisplayName or FacultyName,
			Description = FacultyRawData.Description,
			Icon = FacultyRawData.Icon,
			Thumbnail = FacultyRawData.Thumbnail,
			Cost = FacultyRawData.Cost or 0,
			Type = "Faculty",

			Passive = CharactersPassive[FacultyName] or {},

			IsOwned = true, -- we doesnt ahve an selector for this :skull: for now..

		} :: FacultyPreview
		
		FacultyFrame.Name = FacultyModule.Name
		FacultyFrame.Status.Visible = true
		FacultyFrame.Cost.Visible = false
		FacultyFrame.Parent = self.References.Sidebar.Content:FindFirstChild("Faculty").Content
		
		FacultyFrame.Status.Text = "Owned" -- we doesnt ahve an selector for this :skull: for now..
		FacultyFrame.Icon.Image = FacultyData.Icon
		FacultyFrame.DisplayName.Text = FacultyData.DisplayName
		FacultyFrame.GlowImage.ImageColor3 = GENERAL_TAB_COLORS.Faculty.Background
		
		self.Janitor:Add(FacultyFrame.SelectionOverlay.MouseButton1Click:Connect(function()
			self:ShowFacultiesPreview(FacultyData)
		end))
		
		self.Janitor:Add(FacultyFrame.MouseEnter:Connect(function()
			TweenUtility.PlayTween(FacultyFrame.DisplayName, TweenInfo.new(0.1), {BackgroundTransparency = 0.5, TextTransparency = 0})
		end))
		
		self.Janitor:Add(FacultyFrame.MouseLeave:Connect(function()
			TweenUtility.PlayTween(FacultyFrame.DisplayName, TweenInfo.new(0.1), {BackgroundTransparency = 1, TextTransparency = 1})
		end))
	end
end

function ShopUI.OnConstruct(self: Component)
	
	BaseUIComponent.OnConstruct(self)
	
	-- do you *really* need other janitors? think twice
	self.EnabledJanitor = self.Janitor:Add(Janitor.new())
	self.CharacterPreviewJanitor = self.EnabledJanitor:Add(Janitor.new(), nil, "CharacterPreview")
	self.ItemPreviewJanitor = self.EnabledJanitor:Add(Janitor.new(), nil, "ItemPreview")
	self.FacultyPreviewJanitor = self.EnabledJanitor:Add(Janitor.new(), nil, "FacultyPreview")

	self.CharactersData = TableKit.DeepCopy(CharactersData)

	self.ItemAmountChanged = Signal.new()
	self.ItemPreviewChanged = Signal.new()
	self.ItemPurchaseChanged = Signal.new()

	self.CharactersDataChanged = Signal.new()
	self.PageChanged = Signal.new()

	self.ShopEnabled = false
	self.CurrentScreen = nil
	self.CurrentTab = nil
	self.LastTab = nil

	self.PreviewItem = nil
	self.PreviewSkin = nil
	self.PreviewCharacter = nil
	self.PreviewFaculty = nil

	self.ItemsOwned = {}
	
	self.References = {
		Sidebar = self.Instance:FindFirstChild("Sidebar"),
		Preview = self.Instance:FindFirstChild("Preview"),
	}
	
	self:_Cleanup()
	self:_BindSetup()
end

function ShopUI.OnConstructClient(self: Component)
	
	BaseUIComponent.OnConstructClient(self)
	
	self:SetEnabled(false)
	
	-- fixed broken Kannon code -Provitia
	local function PromiseToBindEvents()
		
		return Promise.new(function(resolve)
			
			local Connection
			local Role = RolesManager:GetPlayerRoleString(LocalPlayer) 

			-- oh wow we already loaded
			if Role then
				resolve()
				return
			end

			Connection = RolesManager.PlayerRoleChanged:Connect(function(Player)
				
				-- not us, dont care
				if Player ~= LocalPlayer then
					return
				end

				-- getting our role
				Role = RolesManager:GetPlayerRoleString(LocalPlayer) 


				--if Role == nil we havent loaded yet :shrug: (changing to nil is theoretically impossible but who knows what'll be in the future)
				if not Role then
					return
				end

				-- resolving the promise and removing connection to avoid ~~paper cut~~, errr, i mean memory leaks
				Connection:Disconnect()
				return resolve()
			end)
		end)  ---AAFAEGVFTSERFUYHBRGUIRGYBBIGYASERBGHIAERGB game:Destroy()
	end

	PromiseToBindEvents():andThen(function()
		
		local PlayerStats = ClientProducer.Root:getState(Selectors.SelectStats(LocalPlayer.Name))
		self.Instance.Points.Text = PlayerStats and PlayerStats.Points or 0
		
		print(PlayerStats, PlayerStats.Points)
		
		self:_BindConnections() 
	end)
end

--// Returner

return ShopUI