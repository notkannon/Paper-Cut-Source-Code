--//Services

local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local EnumsUtility = require(ReplicatedStorage.Shared.Utility.EnumUtility)

--// Returner

return table.freeze({
	
	RoundState = EnumsUtility.NewEnum(
		"NotStarted",
		"InProgress",
		"Finished"
	) :: {
		NotStarted: number,
		InProgress: number,
		Finished: number,
	},
	
	FaceExpression = EnumsUtility.NewEnum(
		"Blink",
		"Default",
		"InTerror",
		"InChase",
		"OnDamage",
		"OnInjuredDamage",
		"Injured",
		"Finisher",
		"Died",
		"InjuredBlink"
	) :: {
		Blink: number,
		Default: number,
		InTerror: number,
		InChase: number,
		OnDamage: number,
		OnInjuredDamage: number,
		Injured: number,
		Finisher: number,
		Died: number,
		InjuredBlink: number
	},
	
	InputType = EnumsUtility.NewManualEnum({
		Keyboard = 0,
		Sensor = 1,
		Gamepad = 2,
		VR = 3,
	}) :: {
		VR: number,
		Sensor: number,
		Gamepad: number,
		Keyboard: number,
	},
	
	--NumbersCodes Enums
	NumberCodes = EnumsUtility.NewManualEnum({
		Zero = 0,
		One = 1,
		Two = 2,
		Three = 3,
		Four = 4,
		Five = 5,
		Six = 6,
		Seven = 7,
		Eight = 8,
		Nine = 9
	}),
	
	--tool id's
	ItemIdsEnum = EnumsUtility.NewManualEnum({
		
		Oreo = 0,
		Apple = 1,
		Banana = 2,
		Orange = 16, -- 😊😛😛😛😛😛😛
		IceCream = 3,
		Soda = 4,
		
		ThrowableBook = 5,
		ThrowablePencil = 6,
		ThrowablePaperLump = 7,
		ThrowablePaperAirplane = 8,
		ThrowableTennisBall = 17,
		
		Flashlight = 9,
		Antiseptic = 10,
		FireExtinguisher = 11,
		Vitamins = 12,
		Gum = 13,
		Gun = 14,
		ViscousAcid = 15,
		
	}) :: {
		
		Soda: number,
		Oreo: number,
		Apple: number,
		Orange: number,
		Banana: number,
		IceCream: number, 
		
		ThrowableBook: number,
		ThrowablePencil: number,
		ThrowablePaperLump: number,
		ThrowablePaperAirplane: number,
		Flashlight: number,
		Antiseptic: number,
		FireExtinguisher: number, -- ate that
		Vitamins: number,
		Gum: number,
		Gun: number,
		ViscousAcid: number,
	},
	
	--any player actions
	PlayerActionsEnum = EnumsUtility.NewEnum(
		"Jump",
		"Crouch",
		"Sprint",
		"Dash",
		"Stealth",

		-- Взаимодействие с миром
		"OpenDoor",
		"CloseDoor",
		"LockDoor",
		"UnlockDoor",          -- Например, открыть замок с ключом или кодом
		"DamageDoor",
		
		"PickupItem",
		"DropItem",
		"UseItem",
		
		"Vault", -- поднятие/закрытие и перепрыгивание в окна
		"Ability",
		

		-- Командная работа и помощь
		"RevivePlayer",         -- Поднял тиммейта
		"HealOther",            -- Полечил другого игрока
		
		-- Атака и убийства
		"Attack",
		"Damage",
		"SpecialAttack",
		"HitPlayer",            -- Успешно попал по игроку
		"KillPlayer",           -- Добил игрока до смерти
		"AssistKill",           -- Помог в убийстве (например, дал дамаг до решающего удара)

		-- События смерти
		"Died",                   -- Сам умер
		"KilledByPlayer",        -- Убит конкретным игроком (можно доп-аргументом передать кто)
		"KilledByWorld",         -- Умер от окружения (ловушка, таймер и т.п.)

		-- Цели/объективы
		"ActivateObjective",     -- Активировал цель (например, включил предохранитель)
		"CompleteObjective",     -- Полностью завершил цель (например, починил все генераторы)
		"FailObjective",         -- Завалил цель (не успел или сломал)

		-- Стелс и укрытия
		"HideInLocker",          -- Спрятался в шкафчике
		"LeaveLocker",           -- Вышел из шкафчика
		
		"EscapedChase",

		-- Взаимодействие с игроками (геймплейно)
		"RescuePlayer",          -- Спас из состояния опасности (например, снял с крюка)

		-- Специфические экшены под режим
		"TriggerTrap",           -- Наступил в ловушку
		"PlaceTrap",              -- Поставил ловушку
		"BreakTrap",              -- Сломал ловушку

		-- Выживание
		"HealSelf",               -- Полечил сам себя

		-- Победные условия
		"Survived",                 -- Сбежал с карты
		"EliminateAllStudents",  -- Для маньяка: убил всех
		"SurviveTillEnd",          -- Для выживших: выжил до конца
		
		-- match results
		"NoneSurvived",
		"OneSurvived",
		"ManySurvived",
		
		-- LMS
		"SurviveTillLMS",
		"EliminateTillLMS"
	) :: {
		Jump: number,
		Crouch: number,
		Sprint: number,
		OpenDoor: number,
		CloseDoor: number,
		LockDoor: number,
		DamageDoor: number,
		UnlockDoor: number,
		PickupItem: number,
		DropItem: number,
		UseItem: number,
		RevivePlayer: number,
		HealOther: number,
		Attack: number,
		HitPlayer: number,
		KillPlayer: number,
		AssistKill: number,
		Died: number,
		KilledByPlayer: number,
		KilledByWorld: number,
		ActivateObjective: number,
		CompleteObjective: number,
		FailObjective: number,
		HideInLocker: number,
		LeaveLocker: number,
		PeekCorner: number,
		RescuePlayer: number,
		TriggerTrap: number,
		PlaceTrap: number,
		BreakTrap: number,
		HealSelf: number,
		Survived: number,
		EliminateAllStudents: number,
		SurviveTillEnd: number,
		Ability: number,
		EscapedChase: number
	},
	
	--CameraModes Enum
	CameraModeEnum = EnumsUtility.NewEnum(
		"CharacterBinded",
		"MenuBinded",
		"ShopBinded",
		"Headlocked",
		"ResultBinded"
	),
})