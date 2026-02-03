return [[
type HitboxType = enum { Box, Sphere }
type ChangeMethod = enum { Set, Multiply, Increment }
type ShopBuyType = enum { Item, Character, Skin }

event Loaded = {
    from: Client,
    type: Reliable,
    call: SingleAsync,
    data: unknown
}

event LoadedConfirmed = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: unknown
}

event Start = {
    from: Client,
    type: Reliable,
    call: SingleAsync
}

event Dispatch = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        name: string,
        arguments: unknown[]
    }[]
}

event RebuildRoleConfigClient = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		player: Instance.Player,
		params: struct {
			Role: string,
			Skin: string?,
			Character: string?,
		}
	},
}

event SetRagdoll = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        toggle: boolean,
        model: Instance?,
    }
}

event ApplyImpulse = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        part: Instance,
        impulse: Vector3,
        isAngular: boolean?
    }
}

event ChangeStamina = {
	from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        method: ChangeMethod,
        value: f64,
    }
}

event ReliableComponentNetworkClient = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: unknown,
}

event UnreliableComponentNetworkClient = {
    from: Server,
    type: Unreliable,
    call: ManyAsync,
   data: unknown,
}



event ReliableComponentNetworkServer = {
    from: Client,
    type: Reliable,
    call: ManyAsync,
    data: unknown,
}

event UnreliableComponentNetworkServer = {
    from: Client,
    type: Unreliable,
    call: ManyAsync,
    data: unknown,
}

event ComponentReplicatorClient = {
	from: Server,
    type: Reliable,
    call: SingleAsync,
    data: unknown,
}

event PlayerActionApplied = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: string
}

event DespawnRequest = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: unknown
}

event SpawnRequest = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: unknown
}

event RequestPlayersInHitbox = {
	from: Server,
    type: Reliable,
    call: SingleAsync,
    data: struct {
    	Type: HitboxType,
    	Size: unknown,
    	Offset: Vector3,
    }
}

event RespondPlayersInHitbox = {
	from: Client,
    type: Reliable,
    call: ManyAsync,
    data: Instance (Player)?[]
}



event CharacterSyncFromClient = {
	from: Client,
    type: Unreliable,
    call: SingleAsync,
   	data: struct {
		part: Instance (Part),
		cframe: CFrame,
	},
}

event CharacterSyncFromServer = {
	from: Server,
    type: Unreliable,
    call: SingleAsync,
   	data: struct {
		player: Instance.Player,
		part: Instance (Part),
		cframe: CFrame,
	},
}



event InventoryComponentDropItemServer = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: Instance (Tool),
}

event OnServerInventoryToggle = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: boolean,
}

event ReplicateItemServer = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		instance: Instance (Tool),
		destroyed: boolean,
		constructor: string,
	},
}

event HideoutLeavePrompt = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: unknown
}

event ThrowablesServiceCreate = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		instance: Instance (Tool),
		userData: struct {
			Origin: Vector3,
			Strength: f64,
			Direction: Vector3,
			Performer: Instance (Player)?,
		}
	}
}

event DamageTaken = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
    	player: Instance (Player),
        damager: Instance (Player)?,
        origin: Vector3?,
        damage: i8,
        source: string?
    },
}

event PlayerDied = {
	from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        player: Instance (Player),
        killers: Instance (Player)[]?,
    }
}

event PointsAwarded = {
	from: Server,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        amount: u32,
        actionId: u32?,
        message: string?,
    }
}

event MatchServiceStartLMS = {
	from: Server,
    type: Reliable,
    call: ManyAsync,
    data: unknown
}

event MatchServiceSetMap = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: string
}


event MatchServiceSetMatchState = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        name: string,
        ended: boolean,
        duration: u32,
    }
}

event MatchServiceCountdownChanged = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
        value: u32,
        reason: string?
    },
}

event MatchServiceSetPreparing = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    data: boolean,
}

event ObjectivesChanged = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		amount: u32,
		solvedAmount: u32,
	}
}

event ClientSettingSaveRequest = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: map {
		[string] : unknown
	}
}




event ClientChaseStateChanged = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: boolean,
}

event ClientTRStateChanged = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: u8,
}

event ClientLookVectorChanged = {
	from: Client,
	type: Unreliable,
	call: SingleAsync,
	data: Vector3
}

event ServerLookVectorReplicated = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		player: Instance (Player),
		lookDirection: Vector3,
		componentName: string,
	}
}

event ClientFallStarted = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: f64
}

event ClientLanded = {
	from: Client,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		StarterHeight: f64,
		EndHeight: f64,
	}
}

event ShopServiceBuy = {
    from: Client,
    type: Reliable,
    call: ManyAsync,
    data: struct {
        Type: ShopBuyType,
        Data: struct {
            Character: string,
            Skin: string,
            ItemName: string,
        },
    }
}

event ShopServiceBuyConfirm = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
     data: struct {
        Type: ShopBuyType,
        Data: struct {
            Character: string,
            Skin: string,
            ItemName: string,
            Amount: u8
        },
    }
}

event ShopItemPayoutComplete = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        Items: string[]
    }
}

event ShopServiceChangeSelected = {
    from: Client,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        Character: string,
        Skin: string,
    }
}

event RoundStatsComponentReplicator = {
    from: Server,
    type: Reliable,
    call: ManyAsync,
    data: map { [Instance (Player) ]: unknown }
}

]]
--[[

event ComponentReplicatorClient = {
	from: Server,
    type: Reliable,
    call: SingleAsync,
    data: struct {
        name: string,
        instance: Instance,
        destroyed: boolean,
        constructorArgs: unknown,
    }
}

]]