--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseVault = require(ReplicatedStorage.Shared.Components.Abstract.BaseVault)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

--//Variables

local LocalPlayer = Players.LocalPlayer
local WindowVault = BaseComponent.CreateComponent("WindowVault", {
	
	tag = "WindowVault",
	isAbstract = false,
	
	defaults = {
		OpenHoldDuration = 5,
		CloseHoldDuration = 2.3,
	},
	
}, BaseVault) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseVault.MyImpl)),

	OnConstruct: (self: Component, options: BaseVault.SharedComponentConstructOptions?) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}

export type Fields = {

	Attributes: {
		OpenHoldDuration: number,
		CloseHoldDuration: number,
	},

} & BaseVault.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "WindowVault", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "WindowVault", Instance, any...>

--//Methods

function WindowVault.SetEnabled(self: Component, value: boolean)
	BaseVault.SetEnabled(self, value)
	
	--Students can open the window, killers - close
	self.Interaction.Instance.HoldDuration = value
		and self.Attributes.CloseHoldDuration
		or self.Attributes.OpenHoldDuration
	
	self.Interaction.Instance.ActionText = value and "Close" or "Open"
	
	if RunService:IsServer() then
		
		SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Instances.Vaults.Window:FindFirstChild(value and "Open" or "Close")
		).Parent = self.Instance.Root
		
		self.Interaction:SetTeamAccessibility("Killer", not value)
		self.Interaction:SetTeamAccessibility("Student", value)
	end
end

--function WindowVault.OnConstruct(self: Component)
--	BaseVault.OnConstruct(self)
--end

--function WindowVault.OnConstructServer(self: Component)
--	BaseVault.OnConstructServer(self)
	
--end

function WindowVault.OnConstructClient(self: Component)
	
	local Root = self.Instance.Root
	local StartCF = Root.Opened.WorldCFrame
	local EndCF = Root.Closed.WorldCFrame
	local Slider = self.Instance.Slider

	-- Функция воспроизведения анимации
	local function PlayAnimation(isOpening)
		
		self.Janitor:RemoveList(
			"OpenAnimation",
			"CloseAnimation",
			"CloseAnimationThread"
		)
		
		local tweenInfo = TweenInfo.new(
			0.5,
			Enum.EasingStyle[isOpening and "Cubic" or "Quad"],
			Enum.EasingDirection[isOpening and "Out" or "In"]
		)

		local startCF = isOpening and EndCF or StartCF
		local endCF = isOpening and StartCF or EndCF

		return TweenUtility.TweenStep(tweenInfo, function(alpha)
			Slider:PivotTo(CFrame.new(startCF:Lerp(endCF, alpha).Position) * StartCF.Rotation)
		end)
	end

	-- Обработчик изменения состояния
	local function HandleStateChange(attribute, value)
		
		if attribute ~= "Enabled" then
			return
		end

		if value then
			-- Немедленно воспроизводим анимацию открытия
			self.Janitor:Add(PlayAnimation(true), nil, "OpenAnimation")
		else
			-- Запускаем отложенную анимацию закрытия
			self.Janitor:Add(
				task.delay(0.3, function()
				self.Janitor:Add(PlayAnimation(false), nil, "CloseAnimation")
			end, nil, "CloseAnimationThread")
			)
		end
	end

	-- Инициализация начального состояния
	HandleStateChange("Enabled", self.Attributes.Enabled)

	-- Подписываемся на изменения атрибута
	self.Janitor:Add(self.Attributes.AttributeChanged:Connect(HandleStateChange))
end

--//Returner

return WindowVault