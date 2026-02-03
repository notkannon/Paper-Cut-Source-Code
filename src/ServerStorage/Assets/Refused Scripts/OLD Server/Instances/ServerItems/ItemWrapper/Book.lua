local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local ItemWrapper = require(script.Parent)

-- Book constructor initial
local Book = setmetatable({}, ItemWrapper)
Book.enum = Enums.ItemTypeEnum.Book
Book.__index = Book

-- constructor
function Book.new()
	local tool = game.ReplicatedStorage.Assets.Items.Book:Clone()
	local self = setmetatable(ItemWrapper.new( tool ), Book)
	
	self:Init()
	return self
end

-- initial book method
-- ItemWrapper:Init() --> Book:Init() (it doesnt override .super :init)
function Book:Init()
	self.Equipped:Connect(function()
		print('Book just equipped!')
	end)
end


function Book:OnItemInited()
	print('Book has inited')
end


function Book:OnClientMessage(sender: Player, ...)
	print('Book message just received!', ...)
	self:SendClientMessage('FOCK U')
end

return Book