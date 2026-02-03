--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local BindImagesID = {} :: { [string]: string }
local Binds = ReplicatedStorage.Assets.UI.Binds

--//Functions

local function GetAllImagesID(): { [string]: string}
	return table.clone(BindImagesID)
end

local function GetInputNameToImage(Input: string | Enum.KeyCode | Enum.UserInputState)
	if typeof(Input) == "EnumItem" then
		Input = Input.Name
	end
	
	local Name = BindImagesID[Input] or nil
	if Name then
		return Name
	end
end

--//Main

for _, v in Binds:GetDescendants() do
	if not v:IsA("ImageLabel") then
		continue
	end
	
	BindImagesID[v.Name] = v.Image
end

--//Returner

return {
	GetAllImagesID = GetAllImagesID,
	GetInputNameToImage = GetInputNameToImage,
}