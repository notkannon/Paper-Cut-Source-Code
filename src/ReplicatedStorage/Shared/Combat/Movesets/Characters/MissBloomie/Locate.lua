--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Utility = require(ReplicatedStorage.Shared.Utility)
local BaseSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseSkill)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

--//Variables

local Player = Players.LocalPlayer
local Spheres = {} :: { Sphere? }
local SkillSFX = SoundUtility.Sounds.Players.Skills.Locate
local SkillAssets = ReplicatedStorage.Assets.Skills.Locate

local Locate = WCS.RegisterSkill("Locate", BaseSkill)

--//Types

type Sphere = {
	Instance: BasePart,
	DetectedCharacters: { Model? },
	--CharacterProjections: { [PlayerTypes.Character]: Model? },
}

type Skill = BaseSkill.BaseSkill

--//Functions

--local function CreateCharacterProjection(sphere: Sphere, character: PlayerTypes.Character)
--	local Projection = {}
	
--	local Model = Instance.new("Model")
--	Model.Parent = workspace.Temp
	
--	for _, Basepart in ipairs(character:GetChildren()) do
--		if not Basepart:IsA("BasePart") or Basepart.Name == "HumanoidRootPart" then
--			continue
--		end
--	end
--end

--local function UpdateCharacterPeojection(sphere: Sphere, character: PlayerTypes.Character)
	
--end

--//Methods

function Locate._UpdateSphere(self: Skill, sphere: Sphere)
	sphere.Instance.Size += Vector3.one * 2.8

	local Radius = sphere.Instance.Size.Magnitude / 2

	if Radius > 700 then
		table.remove(Spheres,
			table.find(Spheres, sphere)
		)

		sphere.Instance:Destroy()

		table.clear(sphere.DetectedCharacters)
		table.clear(sphere)

		return
	end
	
	--self._InternalRoleStringPasser.On(function(Character, RoleString)
		
	--end)


	for _, Character: PlayerTypes.Character? in ipairs(workspace.Characters:GetChildren()) do
	
		--self._InternalRoleStringInquirer.Fire(Character)
		
		if table.find(sphere.DetectedCharacters, Character)
			--or RoleString == "Teacher"
			or Character == Player.Character
			or not Character:FindFirstChildWhichIsA("Humanoid")
			or not Character:FindFirstChild("HumanoidRootPart") then

			continue
		end

		local Distance = (sphere.Instance.Position - Character.HumanoidRootPart.Position).Magnitude

		if Radius < Distance then
			continue
		end

		table.insert(sphere.DetectedCharacters, Character)

		local Highlight = HighlightPlayerEffect.locally(Character, {

			mode = "Overlay",
			color = Color3.new(1, 1, 1),
			fadeOutTime = 2,
			transparency = 0.5,
			respectTargetTransparency = true,

		})

		--destroying highlight on skill remove
		self.GenericJanitor:Add(function()
			local s, m = pcall(Highlight.Destroy, Highlight)
			if not s then warn(m) end
		end)
	end
end

function Locate._CreateShockwaveSphere(self: Skill)
	local Data = {} :: Sphere
	local Sphere = SkillAssets.Sphere:Clone()
	
	Sphere.Size = Vector3.zero
	Sphere.Parent = workspace.Temp
	Sphere.Anchored = true
	Sphere.Position = workspace.CurrentCamera.CFrame.Position
	Sphere.Transparency = 0.95
	
	TweenUtility.PlayTween(Sphere, TweenInfo.new(3), {Transparency = 1})
	
	table.insert(Spheres, Data)
	
	Data.Instance = Sphere
	Data.DetectedCharacters = {}
	
	SoundUtility.CreateTemporarySound(SkillSFX.Locate)
end

function Locate.OnStartClient(self: Skill)
	self.GenericJanitor:Add(RunService.RenderStepped:Connect(function()
		if #Spheres == 0 then
			self.GenericJanitor:Remove("LocateUpdater")
			
			return
		end
		
		for _, Sphere in ipairs(Spheres) do
			self:_UpdateSphere(Sphere)
		end
		
	end), nil, "LocateUpdater")
	
	local Iteration = 0
	
	task.spawn(function()
		while Iteration < 3 do
			self:_CreateShockwaveSphere()

			task.wait(1.6)
			Iteration += 1
		end
	end)
end

function Locate.OnStartServer(self: Skill)
	self:ApplyCooldown(self.FromRoleData.Cooldown)
	
	--self.GenericJanitor:Add(self._InternalRoleStringInquirer.On(function(char)
	--	local comp = ComponentsUtility.GetPlayerComponentFromCharacter(char)
	--	if comp then
	--		self._InternalRoleStringPasser.Fire(char, comp:GetRoleString())
	--	end
	--end))
end

function Locate.OnConstruct(self: Skill)
	BaseSkill.OnConstruct(self)
	
	--self._InternalRoleStringInquirer = self:CreateEvent("RoleStringInquirer", "Reliable", function(...) return true end)
	--self._InternalRoleStringPasser = self:CreateEvent("RoleStringPasser", "Reliable", function(...) return true end)
end

--//Returner

return Locate