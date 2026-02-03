--//Services

local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)

--//Variables

local ItemInstances = ReplicatedStorage.Assets.Items

--//Types

export type ItemCharacteristic = {
	Positive: {
		[string]: string
	},

	Negative: {
		[string]: string
	}
}

export type Items = {
	Cost: number,
	Name: string,
	Icon: string,
	Type: string,
	Constructor: string,
	Description: string,
	Characteristic: ItemCharacteristic,
	CanOnShop: boolean,
	Guides: {
		{ Text: string, ContextBind: string } | string
	},
	
	ItemId: any?,
	Instance: Instance,
}

--//Returner

return table.freeze({
	
	Apple = {
		Cost = 35,
		Name = "Apple",
		Icon = "rbxassetid://109367483520534",
		Type = "Consumable",
		Constructor = "AppleItem",
		Description = "A medium-sized fruit allowing you to recover a little when eaten",
		CanOnShop = true,
		Guides = {
			{Text = "%s to use", ContextBind = "UseItem"},
		},
		Characteristic = {
			Positive = {
				Health = "Heals +7 HP on use"
			},
		},
		
		ItemId = Enums.ItemIdsEnum.Apple,
		Instance = ItemInstances:FindFirstChild("Apple")
	},
	
	Orange = {
		Cost = 300, -- New Orange Price
		Name = "Orangish 🍊",
		Icon = "rbxassetid://131380112883344",
		Type = "Consumable",
		Constructor = "OrangeItem",
		Description = `Yeah thats good of cost <br/>Okay dont kill me orangish :c`,
		CanOnShop = false,
		Guides = {
			{Text = "%s to touch", ContextBind = "UseItem"},
		},
		Characteristic = {
			Positive = {
				Speed = "+150% Of Running Speed"
			},
			Negative = {
				Health = "-60% Of Health"
			}
		},

		ItemId = Enums.ItemIdsEnum.Orange,
		Instance = ItemInstances:FindFirstChild("Orange")
	},
	
	Banana = {
		Cost = 65,
		Name = "Banana",
		Icon = "rbxassetid://87585873768811",
		Type = "Consumable",
		Constructor = "BananaItem",
		Description = "A more nutritional fruit, healing more on consumption",
		CanOnShop = true,
		Guides = {
			{Text = "%s to use", ContextBind = "UseItem"}
		},
		Characteristic = {
			Positive = {
				Health = "Heals +13 HP on use"
			},
		},

		ItemId = Enums.ItemIdsEnum.Banana,
		Instance = ItemInstances:FindFirstChild("Banana")
	},
	
	ThrowableBook = {
		Cost = 100,
		Name = "Book",
		Icon = "rbxassetid://96658995447814",
		Type = "Throwable",
		Constructor = "ThrowableBookItem",
		Description = "Throw books at teachers to stun them!",
		CanOnShop = true,
		Guides = {
			{Text = "%s to aim", ContextBind = "Aim"},
			{Text = "%s to throw", ContextBind = "UseItem"}
		},
		Characteristic = {
			Positive = {
				Hit = "Stuns teachers for 3 Seconds on hit",
			},

			Negative = {

			}
		},

		ItemId = Enums.ItemIdsEnum.ThrowableBook,
		Instance = ItemInstances:FindFirstChild("Book")
	},
	
	ThrowablePaperAirplane = {
		Cost = 110,
		Name = "Paper Airplane",
		Icon = "rbxassetid://139507704857901",
		Type = "Throwable",
		Constructor = "ThrowablePaperAirplaneItem",
		Description = "Throw paper airplanes at teachers to stun them! The extra floatiness may assist in making shots from afar",
		CanOnShop = true,
		Guides = {
			{Text = "%s to aim", ContextBind = "Aim"},
			{Text = "%s to throw", ContextBind = "UseItem"}
		},
		Characteristic = {
			Positive = {
				Hit = "Stuns teachers for 3 Seconds on hit",
				Floaty = "Less affected by gravity, therefore could be thrown further"
			},

			Negative = {
				
			}
		},

		ItemId = Enums.ItemIdsEnum.ThrowablePaperAirplane,
		Instance = ItemInstances:FindFirstChild("PaperAirplane")
	},
	
	ThrowableTennisBall = {
		Cost = 100,
		Name = "Tennis Ball",
		Icon = "rbxassetid://139507704857901",
		Type = "Throwable",
		Constructor = "ThrowableTennisBallItem",
		Description = "Very bouncy - Can stun multiple targets!",
		CanOnShop = false,
		Guides = {
			{Text = "%s to aim", ContextBind = "Aim"},
			{Text = "%s to throw", ContextBind = "UseItem"}
		},

		ItemId = Enums.ItemIdsEnum.ThrowableTennisBall,
		Instance = ItemInstances:FindFirstChild("TennisBall")
	},

	
	ViscousAcid = {
		Cost = 150,
		Name = "Viscous Acid",
		Icon = "rbxassetid://116607737703355",
		Type = "Throwable",
		Constructor = "ViscousAcidItem",
		Description = "A special throwable flask. On top of stunning teachers on hit, it also creates an acid puddle in the area, in which you are slowed and cannot sprint",
		CanOnShop = true,
		Guides = {
			{Text = "%s to aim", ContextBind = "Aim"},
			{Text = "%s to throw", ContextBind = "UseItem"}
		},
		Characteristic = {
			Positive = {
				Hit = "Stuns teachers for 3 seconds on hit",
				SlowingPuddle = "Creates a puddle for 15 seconds in the landing area",
				NoSprint = "Players in the puddle are unable to sprint and get slowed"
			},

			Negative = {
				NoSprint = "Students also cannot sprint and get slowed down in the puddle"
			}
		},

		ItemId = Enums.ItemIdsEnum.ViscousAcid,
		Instance = ItemInstances:FindFirstChild("ViscousAcid")
	},
	
	--Gun = {
	--	Cost = 100,
	--	Name = "Gun!",
	--	Icon = "rbxassetid://15286668292",
	--	Type = "Usable",
	--	Constructor = "GunItem",
	--	Description = "yes",
	--	CanOnShop = false,
	--	Guides = {
	--		{Text = "%s to shoot", ContextBind = "UseItem"}
	--	},

	--	ItemId = Enums.ItemIdsEnum.Gun,
	--	Instance = ItemInstances:FindFirstChild("Gun")
	--},
	
	--Antiseptic = {
	--	Cost = 100,
	--	Name = "Antiseptic",
	--	Icon = "rbxassetid://15288869014",
	--	Constructor = "AntisepticItem",
	--	Description = "",

	--	Guides = {
	--		"LMB to heal",
	--	},

	--	ItemId = Enums.ItemIdsEnum.Antiseptic,
	--	Instance = ItemInstances:FindFirstChild("Antiseptic")
	--},
	
	Gum = {
		Cost = 150,
		Name = "Gum",
		Icon = "rbxassetid://117468403179655",
		Type = "Usable",
		Constructor = "GumItem",
		Description = "Interact with doors with gum in hand to jam the door! Jammed doors cannot be opened normally, and have to be broken by teachers",
		CanOnShop = true,
		Guides = {
			{Text = "%s to use", ContextBind = "UseItem"}
		},
		Characteristic = {
			Positive = {
				Slowdown = "Breaking the jammed doors slows teachers for 4 seconds",
				StaminaBlock = "During the slowdown, teachers cannot recover stamina"
			},

			Negative = {
				OneShot = "Jammed doors always permanently break after 1 hit" -- done
			}
		},

		ItemId = Enums.ItemIdsEnum.Gum,
		Instance = ItemInstances:FindFirstChild("Gum")
	},
	
	Vitamins = {
		Cost = 100,
		Name = "Vitamins",
		Icon = "rbxassetid://86773665760824",
		Constructor = "VitaminsItem",
		Type = "Consumable",
		Description = "",
		CanOnShop = false,
		Guides = {
			{Text = "%s to heal", ContextBind = "UseItem"}
		},

		ItemId = Enums.ItemIdsEnum.Vitamins,
		Instance = ItemInstances:FindFirstChild("Vitamins")
	},
	
	Soda = {
		Cost = 200,
		Name = "Soda",
		Icon = "rbxassetid://101121602055938",
		Constructor = "SodaItem",
		Type = "Consumable",
		Description = "Initially slows you to drink, then recovers stamina and provides a speed boost",
		CanOnShop = true,
		Guides = {
			{Text = "%s to drink", ContextBind = "UseItem"}
		},

		ItemId = Enums.ItemIdsEnum.Soda,
		Instance = ItemInstances:FindFirstChild("Soda")
	},
	
	--FireExtinguisher = {
	--	Cost = 100,
	--	Name = "Fire extinguisher",
	--	Icon = "rbxassetid://89227063659044",
	--	Constructor = "FireExtinguisherItem",
	--	Description = "",

	--	Guides = {
	--		"LMB to activate",
	--	},

	--	ItemId = Enums.ItemIdsEnum.FireExtinguisher,
	--	Instance = ItemInstances:FindFirstChild("Fire Extinguisher")
	--},
	
	Flashlight = {
		Cost = 20,
		Name = "Flashlight",
		Icon = "rbxassetid://122765324703425",
		Type = "Usable",
		Constructor = "FlashlightItem",
		Description = "Helps you see better in the dark and signal to teammates. Slowly depletes charge when turned on",
		CanOnShop = true,
		Guides = {
			{Text = "%s to toggle", ContextBind = "UseItem"}
		},

		ItemId = Enums.ItemIdsEnum.Flashlight,
		Instance = ItemInstances:FindFirstChild("Flashlight")
	}
})

