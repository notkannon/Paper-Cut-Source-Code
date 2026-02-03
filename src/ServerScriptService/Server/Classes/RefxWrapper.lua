--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)

--//Variables

local RefxWrapper: Impl = Classes.CreateClass("RefxWrapper", false) :: Impl

--//Types

export type Impl = {
	__index: Impl,
	
	new: (effectImpl: Refx.EffectImpl, ...unknown) -> Wrapper,
	
	Start: (self: Wrapper, players: { Player }, duration: number?) -> (),
	Destroy: (self: Wrapper) -> (),
	GetPlayers: (self: Wrapper) -> { Player },
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Effects: { Refx.Effect },
	EffectImpl: Refx.EffectImpl,
	ConstructorArgs: { unknown },
	CreatesForNewPlayers: boolean,
	
	_Active: boolean,
}

export type Wrapper = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function RefxWrapper.new(effectImpl: Refx.EffectImpl, ...)
	
	--if we want to use custom effect events but not override them
	local self = setmetatable({}, {
		__index = function(self: Wrapper, k)
			-- 1. Если метод есть в RefxWrapper — вернуть его
			local Result = RefxWrapper[k]
			if Result then return Result end

			-- 2. Проверяем, есть ли такой метод у хотя бы одного эффекта
			local firstEffect = self.Effects[1]
			if firstEffect and typeof(firstEffect[k]) == "function" then
				-- 3. Если метод найден, создаем функцию-прокси
				return function(_, ...) -- `_` вместо self, чтобы не передавать Wrapper
					for _, Effect in ipairs(self.Effects) do
						local Func = Effect[k]
						if typeof(Func) == "function" then
							Func(Effect, ...) -- Вызываем метод у каждого эффекта
						end
					end
				end
			end

			-- 4. Если это просто свойство (не функция), пробуем вернуть его из первого эффекта
			if firstEffect and firstEffect[k] ~= nil then
				return firstEffect[k]
			end
		end
	})
	
	return self:_Constructor(effectImpl, ...) or self
end

function RefxWrapper._Constructor(self: Wrapper, effectImpl: Refx.EffectImpl, ...)
	self.ConstructorArgs = { ... }
	self.EffectImpl = effectImpl
	self.Janitor = Janitor.new()
	self.Effects = {}
	self._Active = false
	self.CreatesForNewPlayers = false
end

function RefxWrapper.GetPlayers(self: Wrapper)
	return self.Effects[1]:GetPlayers()
end

function RefxWrapper.Start(self: Wrapper, players: { Player }, duration: number?)
	assert(not self._Active, "Effect already running")
	
	local function Create(...: Player)
		
		local Effect = self.EffectImpl.new(table.unpack(self.ConstructorArgs))
		Effect:Start({ ... })
		
		table.insert(self.Effects, Effect)
		
		self.Janitor:Add(function()
			if table.find(self.Effects, Effect) then
				table.remove(self.Effects, table.find(self.Effects, Effect))
			end
			
			Effect:Destroy()
		end)
	end
	
	if self.CreatesForNewPlayers then
		self.Janitor:Add(PlayerService.PlayerLoaded:Connect(Create))
	end
	
	if duration then
		self.Janitor:Add(
			task.delay(duration, self.Destroy, self)
		)
	end
	
	Create(table.unpack(players))
	
	self._Active = true
end

function RefxWrapper.Destroy(self: Wrapper)
	self.Janitor:Destroy()
	
	table.clear(self)
	setmetatable(self, nil)
end

--//Return

return {
	new = RefxWrapper.new,
}