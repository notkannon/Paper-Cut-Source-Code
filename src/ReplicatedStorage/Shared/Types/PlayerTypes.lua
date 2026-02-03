--//Types

export type IHumanoid = Humanoid & {
	Animator: Animator,
	HumanoidDescription: HumanoidDescription,
	Status: Status,
}

export type Head = Part & {
	HatAttachment: Attachment,
	FaceFrontAttachment: Attachment,
	HairAttachment: Attachment,
	face: Decal,
	Mesh: SpecialMesh,
	FaceCenterAttachment: Attachment,
}

export type HumanoidRootPart = Part & {
	Climbing: Sound,
	Died: Sound,
	FreeFalling: Sound,
	GettingUp: Sound,
	Jumping: Sound,
	Landing: Sound,
	Running: Sound,
	Splash: Sound,
	Swimming: Sound,
	RootJoint: Motor6D,
	RootAttachment: Attachment,
}

export type Torso = Part & {
	RightCollarAttachment: Attachment,
	WaistCenterAttachment: Attachment,
	BodyBackAttachment: Attachment,
	Neck: Motor6D,
	LeftCollarAttachment: Attachment,
	["Left Hip"]: Motor6D,
	["Right Hip"]: Motor6D,
	["Left Shoulder"]: Motor6D,
	["Right Shoulder"]: Motor6D,
	BodyFrontAttachment: Attachment,
	WaistBackAttachment: Attachment,
	WaistFrontAttachment: Attachment,
	NeckAttachment: Attachment,
}

export type CharacterChildren = {
	["Body Colors"]: BodyColors,
	Humanoid: IHumanoid,
	Head: Head,
	HumanoidRootPart: HumanoidRootPart,
	Torso: Torso,
	["Left Arm"]: Part & {
		LeftGripAttachment: Attachment,
		LeftShoulderAttachment: Attachment,
	},
	["Left Leg"]: Part & {
		LeftFootAttachment: Attachment,
	},
	["Right Arm"]: Part & {
		RightShoulderAttachment: Attachment,
		RightGripAttachment: Attachment,
	},
	["Right Leg"]: Part & {
		RightFootAttachment: Attachment,
	},
}

export type Character = Model & Instance & CharacterChildren

--//Returner

return nil
