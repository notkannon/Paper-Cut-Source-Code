local Spring = {}

-- Более мягкие параметры по умолчанию для viewmodel sway
function Spring.create(mass, force, damping, speed)
	local self = {
		Target = Vector3.new(),
		Position = Vector3.new(),
		Velocity = Vector3.new(),

		Mass = mass or 1.5,      -- Меньшая масса для более быстрого отклика
		Force = force or 10,     -- Меньшая сила для плавности
		Damping = damping or 2,  -- Оптимальное демпфирование
		Speed = speed or 5,      -- Скорость реакции

		_timeAccumulator = 0
	}

	function self:shove(force)
		-- Защита от NaN/Infinity
		local x = (force.X == force.X and math.abs(force.X) ~= math.huge) and force.X or 0
		local y = (force.Y == force.Y and math.abs(force.Y) ~= math.huge) and force.Y or 0
		local z = (force.Z == force.Z and math.abs(force.Z) ~= math.huge) and force.Z or 0

		self.Velocity = self.Velocity + Vector3.new(x, y, z)
	end

	function self:update(dt)
		-- Адаптивный шаг времени (framerate-independent)
		local scaledDt = math.min(dt * self.Speed, 1/10) -- Ограничиваем максимальный шаг

		-- Упрощённый расчёт без итераций
		local displacement = self.Target - self.Position
		local springForce = displacement * self.Force
		local dampingForce = -self.Velocity * self.Damping
		local acceleration = (springForce + dampingForce) / self.Mass

		self.Velocity = self.Velocity + acceleration * scaledDt
		self.Position = self.Position + self.Velocity * scaledDt

		-- Небольшое дополнительное сглаживание
		if displacement.Magnitude < 0.01 and self.Velocity.Magnitude < 0.01 then
			self.Position = self.Target
			self.Velocity = Vector3.new()
		end

		return self.Position
	end

	return self
end

return Spring