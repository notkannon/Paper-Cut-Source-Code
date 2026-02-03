--//Types

export type Hitbox = {
	Size: Vector3 | number,
	Offset: Vector3,
}

export type ItemData = {
	Cost: number,
	Name: string,
	Icon: string,
	Guide: string,
	Constructor: string,
	Description: string,
	ItemId: number,
	Instance: Tool,
}

--//Returner

return nil