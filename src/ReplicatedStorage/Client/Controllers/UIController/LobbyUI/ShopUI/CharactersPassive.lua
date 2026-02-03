--// Types


export type PassiveDescriptionType = {
	Text: string,
	Properties: {string}
}

export type DataType = {
	Icon: string?,
	Cooldown: number?,
	DisplayName: string,
	Type: "Active" | "Passive",
	DisplayType: string?,
	LayoutOrder: number?,
	Description: { PassiveDescriptionType },
}

--//Returner

return table.freeze({
	Ed = {
		Healing = { -- got an idea. use actual name for key, have display name in field
			Icon = nil,
			DisplayName = "Hearty Diet",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Ed's endless appetite leads him to eat more than others</grey>",
					Properties = {},
				},
				{
					Text = "Ed recovers <PERCENTAGE_DIFF_VERBOSE_COLOR> health from eating food items (like bananas and apples)", 
					Properties = {"Character.CharacterData.UniqueProperties.FoodHealingMultiplier"}
				} 
			}
		}
	},
	
	Engel = {
		GuardianAngel = {
			Icon = nil,
			DisplayName = "Guardian Angel",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Engel will throw himself in harm's way for his friends, even if it might kill him in the end</grey>",
					Properties = {},
				},
				{
					-- note order of execution - first custom specifiers trigger left-to-right, then normal ones left-to-right
					Text = "When within <cyan>%d studs</cyan> to another student, Engel receives <PERCENTAGE_DIFF_VERBOSE_COLOR_REVERSE> damage",
					Properties = {"Passive.DamageTakenMultiplier", "Passive.MaxProtectionDistance"}
				},
				{
					Text = "All students within those <cyan>%d studs</cyan> also get highlighted to him",
					Properties = {"Passive.MaxProtectionDistance"}
				},
				{
					Text = "<red>This passive ignores other Engels</red>",
					Properties = {}
				}
			}
		}
	},
	
	Claire = {
		PacedRunning = {
			Icon = nil,
			DisplayName = "Steady Stride",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Claire paces herself while she runs, letting her endure chases for longer</grey>",
					Properties = {}
				},
				{
					Text = "Claire's running speed is <red>reduced from %d to %d</red>. She spends <green>notably less</green> stamina running",
					Properties = {"Role.SkillsData.Sprint.WalkSpeed", "Character.SkillsData.Sprint.WalkSpeed"}
				}
			}
		}
	},
	
	Abbie = {
		FastRunning = {
			Icon = nil,
			DisplayName = "Panicked Pace",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Abbie breaks into a sprint at any sign of danger, meaning he’s quick but can’t sustain that speed for long</grey>",
					Properties = {}
				},
				{
					Text = "Abbie's running speed is <green>increased from %d to %d</green>. He spends <red>notably more</red> stamina running",
					Properties = {"Role.SkillsData.Sprint.WalkSpeed", "Character.SkillsData.Sprint.WalkSpeed"}
				}
			}
		}
	},
	
	Kenny = {
		ShyReticence = {
			Icon = nil,
			DisplayName = "Shy Reticence",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Kenny feels a sense of relief when wandering around minding her business</grey>",
					Properties = {}
				},
				{
					Text = "Panicked status effect lasts <PERCENTAGE_DIFF_VERBOSE_COLOR_REVERSE> time for Kenny",
					Properties = {"Character.CharacterData.UniqueProperties.PanickedDurationMultiplier"}
				},
				{
					Text = "In LMS, Panicked is not permanent, and only lasts <green><PERCENTAGE></green> of its duration",
					Properties = {"Character.CharacterData.UniqueProperties.LMSPanickedDurationMultiplier"}
				}
			}
		}
	},
	
	Lana = {
		HidingLong = {
			Icon = nil,
			DisplayName = "Crafted Comfort",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Lana finds comfort while sitting in lockers, able to focus on her puppets to calm herself</grey>",
					Properties = {}
				},
				{
					Text = "Lana gains Panicked slower, allowing her to stay in lockers for <PERCENTAGE_DIFF_COLOR> longer",
					Properties = {"Character.CharacterData.UniqueProperties.LockerTimeMultiplier"}
				}
			}
		}
	},
	
	Oliver = {
		EyeForTrouble = {
			Icon = nil,
			DisplayName = "Eye For Trouble",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Oliver's ceaseless mischief leads him to seek out trouble whenever he can</grey>",
					Properties = {}
				},
				{
					Text = "Every <cyan>%d</cyan> seconds, Oliver reveals himself to the teachers for <cyan>%d</cyan> seconds, but also reveals them to himself for <cyan>%d</cyan> seconds",
					Properties = {"Passive.CooldownTime", "Passive.SelfHighlightDuration", "Passive.TeacherHighlightDuration"}
				}
			}
		}
	},
	
	Ritvi = {
		EyeForTrouble = {
			Icon = nil,
			DisplayName = "Second Wind",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Despite showing little care, Ritvi doesn’t want to give up quite yet</grey>",
					Properties = {}
				},
				{
					Text = "Ritvi's on-hit speed boost lasts from <cyan>%d</cyan> to <cyan>%d</cyan> seconds longer, depending on the amount of health he has left",
					Properties = {"Character.PassivesData.MinOnHitDurationBoost", "Character.PassivesData.MaxOnHitDurationBoost"}
				}
			}
		}
	},
	
	Ruby = {
		ToughSkin = {
			Icon = nil,
			DisplayName = "Built Tough",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Ruby is a machine, making her naturally tougher than the others</grey>",
					Properties = {}
				},
				{
					Text = "Ruby receives <PERCENTAGE_DIFF_VERBOSE_COLOR_REVERSE> damage when being hit by teachers’ basic attacks or abilities",
					Properties = {"Character.CharacterData.UniqueProperties.DamageTakenMultiplier"}
				}
			}
		}
	},
	
	Yoshi = {
		RoomToBreathe = {
			Icon = nil,
			DisplayName = "Room To Breathe",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Yoshi’s worries are put at ease when no-one can bother her</grey>",
					Properties = {}
				},
				{
					Text = "When Last Man Standing triggers, receive healing up of <green>%d HP</green>",
					Properties = {"Passive.HealAmount"}
				}
			}
		}
	},
	
	Zip = {
		StrongerThrows = {
			Icon = nil,
			DisplayName = "Strong Armed",
			Type = "Passive",
			Description = {
				{
					Text = "<grey>Zip is part dragon, letting her pack a little more punch in what she does</grey>",
					Properties = {}
				},
				{
					Text = "Zip can throw items with <PERCENTAGE_DIFF_COLOR> extra force, making them fly further and straighter",
					Properties = {"Character.CharacterData.UniqueProperties.ThrowStrength"}
				}
			}
		}
	},
	
	MissCircle = {
		Attack = {
			Type = "Active",
			DisplayType = "Basic Attack",
			Icon = nil,
			DisplayName = "Swing",
			LayoutOrder = 0,
			Description = {
				{
					Text = "<grey>The usual way Miss Circle dishes out pain to the failures before her</grey>",
					Properties = {}
				},
				{
					Text = "Using her compass to hit the students, Miss Circle deals <cyan>%d</cyan> damage per swing",
					Properties = {"Active.Damage"}
				}
			}
		},
		
		FailureInstinctPassive = {
			Type = "Passive",
			Icon = nil,
			LayoutOrder = 1,
			DisplayName = "Failure Instinct",
			Description = {
				{
					Text = "<grey>Miss Circle's knowledge of hunting down failures far surpasses the others</grey>",
					Properties = {}
				},
				{
					Text = "If a student has not been chased for at least <cyan>%d</cyan> seconds, Miss Circle sees their location until they are found by her or her allies",
					Properties = {"Passive.OutOfChaseTime"}
				}
			}
		},
		
		Harpoon = {
			Type = "Active",
			DisplayType = "Active Ability",
			Icon = nil,
			DisplayName = "Harpoon",
			LayoutOrder = 2,
			Description = {
				{
					Text = "<grey>Even when students are far ahead, Miss Circle will always make them come to her one way or another</grey>",
					Properties = {}
				},
				{
					Text = "Pressing the aiming button will allow Miss Circle to aim her compass towards students",
					Properties = {}
				},
				{
					Text = "Letting go will set it back down",
					Properties = {}
				},
				{
					Text = "Pressing the basic attack button will launch the spike in her compass towards a student",
					Properties = {}
				},
				{
					Text = "Hitting them will stop their movement, drag them towards Miss Circle and deal <cyan>%d</cyan> damage",
					Properties = {"Active.Damage"}
				},
				{
					Text = "If the student is unable to be dragged to Miss Circle or breaks the harpoon line, they will take <cyan>%d</cyan> extra damage and Miss Circle will be able to move as normal",
					Properties = {"Active.SnapDamage"}
				},
				{
					Text = "<red>Students can move slightly while pierced by the harpoon, which gives them a chance of breaking the harpoon line</red>",
					Properties = {}
				},
			}
		},
		
		Shockwave = {
			Type = "Active",
			DisplayType = "Active Ability",
			Icon = nil,
			DisplayName = "Stomp",
			LayoutOrder = 3,
			Description = {
				{
					Text = "<grey>Using her larger stature, Miss Circle shakes the ground under her feet and disrupt others’ progress</grey>",
					Properties = {}
				},
				{
					Text = "Pressing the secondary active ability button, Miss Circle quickly winds up a stomp, sending a shockwave in <cyan>%d</cyan> studs radius",
					Properties = {"Active.Hitbox.Size"}
				},
				{
					Text = "Any student caught in the radius will be stopped for <cyan>%d</cyan> seconds and slowed for an extra <cyan>%d</cyan> seconds afterward",
					Properties = {"Active.SlownessDuration", "Active.SlownessFadeOutTime"}
				},
				{
					Text = "Miss Circle also gets a slight speed boost after performing this ability",
					Properties = {}
				}
			}
		},
	},
	
	MissBloomie = {
		BloomieAttack = {
			Type = "Active",
			DisplayType = "Basic Attack",
			Icon = nil,
			DisplayName = "Swipe",
			LayoutOrder = 0,
			Description = {
				{
					Text = "<grey>Miss Bloomie's blade cuts deep into the flesh of students</grey>",
					Properties = {}
				},
				{
					Text = "Miss Bloomie deals <cyan>%d</cyan> damage per hit with her exacto-knife",
					Properties = {"Active.Damage"}
				}
			}
		},
		
		Stealth = {
			Type = "Active",
			DisplayType = "Active Ability",
			Icon = nil,
			DisplayName = "Stealth",
			LayoutOrder = 1,
			Description = {
				{
					Text = "<grey>Miss Bloomie specialises in attacking students when they don’t see it coming</grey>",
					Properties = {}
				},
				{
					Text = "Pressing the active ability button, Miss Bloomie becomes near invisible and moves at <cyan>%d</cyan> studs per second.",
					Properties = {"Active.WalkSpeed"}
				},
				{
					Text = "When <cyan>%d</cyan> seconds have passed, any melee hit on a student will deal <red>double damage</red> to them",
					Properties = {"Active.SneakAttackDelay"}
				},
				{
					Text = "After <cyan>%d</cyan> seconds, she'll be automatically made visible again and gain a <PERCENTAGE_DIFF_COLOR> speed boost for <cyan>%.1f</cyan> seconds",
					Properties = {"Active.EndSpeedMultiplier", "Active.Duration", "Active.EndBoostDuration"}
				},
				{
					Text = "Attacking ends Stealth prematurely, still granting the speed boost",
					Properties = {}
				}
			}
		},
		
		Locate = {
			Type = "Active",
			DisplayType = "Active Ability",
			Icon = nil,
			DisplayName = "Radar",
			LayoutOrder = 2,
			Description = {
				{
					Text = "<grey>Miss Bloomie has a keen sense of hearing, listening out to see if anything suspicious is going on</grey>",
					Properties = {}
				},
				{
					Text = "Using the secondary ability button, students will briefly be revealed to Miss Bloomie for every pulse of the radar that is sent out",
					Properties = {}
				},
			}
		},

		SerratedBladePassive = {
			Type = "Passive",
			Icon = nil,
			DisplayName = "Serrated Blade",
			LayoutOrder = 3,
			Description = {
				{
					Text = "<grey>When hitting a student with her exacto-knife, Miss Bloomie cuts deep into them</grey>",
					Properties = {}
				},
				{
					Text = "Miss Bloomie's attacks inflict Bleeding, dealing <cyan>%d</cyan> points of damage every <cyan>%d</cyan> seconds over <cyan>%d</cyan> seconds",
					Properties = {"Passive.BleedDamage", "Passive.BleedInterval", "Passive.BleedDuration"}
				}
			}
		}
	},
	
	MissThavel = {
		ThavelAttack = {
			Type = "Active",
			DisplayType = "Basic Attack",
			Icon = nil,
			DisplayName = "Slash",
			LayoutOrder = 0,
			Description = {
				{
					Text = "<grey>Miss Thavel's hands are big and her claws are sharp, being able to tear someone apart</grey>",
					Properties = {}
				},
				{
					Text = "Swinging, Miss Thavel's arms deal <cyan>%d</cyan> damage when hitting a student",
					Properties = {"Active.Damage"}
				}
			}
		},

		Dash = {
			Type = "Active",
			DisplayType = "Active Ability",
			Icon = nil,
			DisplayName = "Dash",
			LayoutOrder = 1,
			Description = {
				{
					Text = "<grey>Seeing a student fills Miss Thavel with a feral desire to lunge at them at full speed</grey>",
					Properties = {}
				},
				{
					Text = "Pressing the active ability button will cause Miss Thavel to leap forward, using <cyan>%d</cyan> stamina and deal <cyan>%d</cyan> damage to anyone she hits",
					Properties = {"Active.StaminaLoss", "Active.Damage"}
				},
				{
					Text = "This will activate Progressive Punishment when landing it",
					Properties = {}
				}
			}
		},

		Flair = {
			Type = "Active",
			DisplayType = "Active Ability",
			Icon = nil,
			DisplayName = "Instincts",
			LayoutOrder = 3,
			Description = {
				{
					Text = "<grey>Using her heightened senses, Miss Thavel is able to track students from where they walked</grey>",
					Properties = {}
				},
				{
					Text = "Using the active ability button, she sees students' footprints for up to <cyan>%d</cyan> seconds",
					Properties = {"Active.Duration"}
				},
				{
					Text = "Miss Thavel is able to see footprints students already made upon activating this ability as well",
					Properties = {}
				}
			}
		},

		ProgressivePunishmentPassive = {
			Type = "Passive",
			Icon = nil,
			DisplayName = "Progressive Punishment",
			LayoutOrder = 2,
			Description = {
				{
					Text = "<grey>Tasting the blood of students sends Miss Thavel nuts, craving more of it until quenched of bloodlust</grey>",
					Properties = {}
				},
				{
					Text = "After landing a dash, Miss Thavel gains one stack of Progressive Punishment",
					Properties = {}
				},
				{
					Text = "Whenever Miss Thavel gets a stack of Progressive Punishment, she gains <cyan>%d</cyan> stamina",
					Properties = {"Passive.StaminaIncrement"}
				},
				{
					Text = "She can prolong Progressive Punishment by hitting a <b>different</b> student with her Dash ability or with a Basic Attack",
					Properties = {}
				},
				{
					Text = "This will give Miss Thavel another stack of Progressive Punishment up to five and restart the countdown",
					Properties = {}
				},
				{
					-- note last field is hardcoded. TODO: remove hardcode
					Text = "When at <cyan>%d</cyan> stacks of Progressive Punishment, the next student Miss Thavel hits will take <red>%d</red> damage. After that, Miss Thavel is slowed and her abilities go on cooldown for <cyan>3</cyan> seconds",
					Properties = {"Passive.Max", "Character.SkillsData.ThavelAttack.MaxDamage"}
				},
				{
					Text = "<red>Hitting the same student twice in a row doesn't advance Progressive Punishment, deals only minimal damage and slows Miss Thavel down for %.1f seconds</red>",
					Properties = {"Passive.TunnelingPunishmentDuration"}
				}
			}
		},
	},
	
	Medic = {
		EmpathicConnection = {
			Type = "Passive",
			Icon = nil,
			DisplayName = "Doctor's Hunch",
			LayoutOrder = 0,
			Description = {
				{
					Text = "<grey>You have an innate sense for knowing when to give medical care to someone who needs it</grey>",
					Properties = {}
				},
				{
					Text = "When another student is at <cyan>%d%% HP</cyan> or below, you will hear a sound cue and see their location until they are above <cyan>%d%% HP</cyan> again",
					Properties = {"Passive.MaxHealthDetect", "Passive.MaxHealthDetect"}
				}
			}
		},
		
		PatchUp = {
			Type = "Active",
			Icon = nil,
			DisplayType = "Active Ability",
			DisplayName = "Tender Care",
			LayoutOrder = 1,
			Description = {
				{
					Text = "<grey>Using your Biology and Health class knowledge to use, you aim to patch others up as best as you can</grey>",
					Properties = {}
				},
				{
					Text = "When pressing the active ability on a student at <cyan>%d%% HP</cyan> or below, you will begin a healing interaction that will give them <cyan>%d%% HP</cyan> per second for up to <cyan>%d%% HP</cyan>",
					Properties = {"Active.MinHealthRequired", "Active.HealPerSecond", "Active.MaxHeal"}
				},
				{
					Text = "You can also press the button while alone to heal yourself, but with <PERCENTAGE_DIFF_VERBOSE_COLOR> efficiency and <PERCENTAGE_DIFF_VERBOSE_COLOR> speed",
					Properties = {"Active.SelfHealEfficiency", "Active.SelfHealSpeed"}
				}, 
				{
					Text = "Both healee and healer can cancel the healing process at any time",
					Properties = {}
				}
			}
		}
	},
	
	Runner = {
		LightfootedPace = {
			Type = "Passive",
			Icon = nil,
			DisplayName = "Steady Breathing",
			LayoutOrder = 0,
			Description = {
				{
					Text = "<grey>You use your downtime to move quickly without rushing</grey>",
					Properties = {}
				},
				{
					Text = "While outside of a <red>Terror Radius</red> for <cyan>%d seconds</cyan>, you will use up to <PERCENTAGE_DIFF_VERBOSE_COLOR_REVERSE> stamina while running",
					Properties = {"Passive.StaminaLossMultiplier", "Passive.Delay"}
				},
				{
					Text = "This effect takes <cyan>%d more seconds</cyan> to fully fade in, but it instantly disappears inside a <red>Terror Radius</red>",
					Properties = {"Passive.FadeIn"}
				}
			}
		},
		
		Evade = {
			Type = "Active",
			Icon = nil,
			DisplayType = "Active Ability",
			DisplayName = "Dash",
			LayoutOrder = 1,
			Description = {
				{
					Text = "<grey>Being evasive is just as important as being fast</grey>",
					Properties = {}
				},
				{
					Text = "Dash progressively fills up over time. The normal charge rate is <cyan>%.1f%% per second</cyan>",
					Properties = {"Active.Charge.FillSources.Passive.Amount"}
				},
				{
					Text = "When entering a <red>Terror Radius</red>, the charge rate increases by <cyan>%.1f%% per second</cyan>",
					Properties = {"Active.Charge.FillSources.TerrorRadius.Amount"}
				},
				{
					Text = "This further increases by another <cyan>%.1f%% per second</cyan> when in a chase with a teacher",
					Properties = {"Active.Charge.FillSources.Chase.Amount"}
				}, 
				{
					Text = "When at <green>100% charge</green>, press the active ability to dash forward and be invulnerable during the dashes duration",
					Properties = {}
				},
				{
					Text = "Dashing into a window will cause you to vault it",
					Properties = {}
				},
				{
					Text = "After using the ability, dash will be set to <red>0% charge</red> again",
					Properties = {}
				},
			}
		}
	},
	
	Stealther = {
		HushedActions = {
			Type = "Passive",
			Icon = nil,
			DisplayName = "Keeping it Down",
			LayoutOrder = 0,
			Description = {
				{
					Text = "<grey>Avoiding loud noises ensures you’re not heard by the teachers as easily</grey>",
					Properties = {}
				},
				{
					Text = "Every action you make is <PERCENTAGE_DIFF_VERBOSE_COLOR_REVERSE> loud and can be heard from <PERCENTAGE_DIFF_VERBOSE_COLOR_REVERSE> distance",
					Properties = {"Passive.ActionVolumeScale", "Passive.ActionRollOffScale"}
				}, 
			}
		},

		ConcealedPresence = {
			Type = "Active",
			Icon = nil,
			DisplayType = "Active Ability",
			DisplayName = "Crouch",
			LayoutOrder = 1,
			Description = {
				{
					Text = "<grey>Keeping a low profile keeps you out of the gaze of your educator</grey>",
					Properties = {}
				},
				{
					Text = "Pressing the ability button will make you crouch down and become mostly invisible for <cyan>%d seconds</cyan>",
					Properties = {"Active.Duration"}
				},
				{
					Text = "You can cancel this state prematurely by pressing the ability button again",
					Properties = {}
				}
			}
		}
	},
	
	Troublemaker = {
		MischievousHeadstart = {
			Type = "Passive",
			Icon = nil,
			DisplayName = "Contraband",
			LayoutOrder = 0,
			Description = {
				{
					Text = "<grey>Bringing in banned items is a bad habit of yours</grey>",
					Properties = {}
				},
				{
					Text = "When starting a round, you will be given a book in your inventory",
					Properties = {}
				},
				{
					Text = "If any items from your item shop purchase don't fit in your inventory because of this, they get dropped on the floor instead",
					Properties = {}
				}
			}
		},

		Spray = {
			Type = "Active",
			Icon = nil,
			DisplayType = "Active Ability",
			DisplayName = "Fire Extinguisher Toss",
			LayoutOrder = 1,
			Description = {
				{
					Text = "<grey>Using your active ability button, you will toss the fire extinguisher across the floor</grey>",
					Properties = {}
				},
				{
					Text = "After <cyan>%.1f seconds</cyan>, it will detonate and blind anyone in its immediate radius for <cyan>%d seconds</cyan>",
					Properties = {"Active.DetonationDelay", "Active.DetonationBlindnessDuration"}
				},
				{
					Text = "It will then rotate on the spot, blinding anyone that is hit by the wave of foam, giving anyone gradual blindness the longer they are hit by the sweeping foam.",
					Properties = {}
				},
				{
					Text = "After <cyan>%d seconds</cyan>, the extinguisher will disappear and then go on cooldown",
					Properties = {"Active.Duration"}
				}
			}
		}
	}

}) :: { [string]: { [string]: DataType } }