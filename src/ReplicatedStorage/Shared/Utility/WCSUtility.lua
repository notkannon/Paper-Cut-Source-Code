--[[
	Allows scripts to get certain WCS data
--]]

--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

--//Types

type GlobalCooldownOptions = {
	Mode: "Include" | "Exclude"?,
	SkillNames: { string }?,
	EndActiveSkills: boolean?,
	OverrideCooldowned: boolean?,
}

--//Functions

local function PromiseCharacterAdded(character: PlayerTypes.Character): Promise.TypedPromise<WCS.Character>
	local Character = WCS.Character.GetCharacterFromInstance(character)

	if Character then
		return Promise.resolve(Character)
	end
	
	return Promise.fromEvent(WCS.Character.CharacterCreated :: any, function(addedCharacter: WCS.Character)
		return (addedCharacter.Instance :: any) == character
	end)
end

local function ApplyGlobalCooldown(character: WCS.Character, duration: number, options: GlobalCooldownOptions?)
	assert(RunService:IsServer())
	assert(duration >= 0, "Duration cannot be negative")
	
	local Skills = character:GetSkills()
	
	for _, Skill in ipairs(Skills) do
		if options.SkillNames then
			local Indexed = table.find(options.SkillNames, Skill:GetName())
			
			if (Indexed and options.Mode == "Exclude")
				or (not Indexed and options.Mode == "Include") then
				
				continue
			end
		end
		
		if Skill:GetState().IsActive and options.EndActiveSkills then
			Skill:End()
		end
		
		if Skill:GetState().Debounce then
			local CooldownLeft = 0
			local DebounceEndTimestamp = Skill:GetDebounceEndTimestamp()
			
			if DebounceEndTimestamp then
				CooldownLeft = DebounceEndTimestamp - workspace:GetServerTimeNow()
			end
			
			if options and options.OverrideCooldowned then
				Skill:CancelCooldown()
				Skill:ApplyCooldown(duration)
				
			elseif CooldownLeft < duration then
				local GoalDuration = math.clamp(CooldownLeft + duration, 0, duration)
				Skill:CancelCooldown()
				Skill:ApplyCooldown(GoalDuration)
			end
		else
			Skill:ApplyCooldown(duration)
		end
	end
end

local function GetAllActiveStatusEffectsFromString(character: WCS.Character, statusEffectName: string): { WCS.StatusEffect }
	local ActiveStatusEffects = {}

	for _, Status in ipairs(character:GetAllActiveStatusEffects()) do
		if statusEffectName == tostring(getmetatable(Status)) then
			table.insert(ActiveStatusEffects, Status)
		end
	end

	return ActiveStatusEffects
end

local function GetAllStatusEffectsFromString(character: WCS.Character, statusEffectName: string): { WCS.StatusEffect }
	local AllStatusEffects = {}

	for _, Status in ipairs(character:GetAllStatusEffects()) do
		if statusEffectName == tostring(getmetatable(Status)) then
			table.insert(AllStatusEffects, Status)
		end
	end

	return AllStatusEffects
end

local function GetAllStatusEffectsWithTags(character: WCS.Character, statusEffectName: string, tags: {string}, match: boolean?) : {WCS.StatusEffect}
	
	local AllStatusEffects = {}

	for _, Status in ipairs(character:GetAllActiveStatusEffects()) do
		
		if statusEffectName == Status.Name and Status.Options and Status.Options.Tag then
			
			local Found = false
			
			for _, tag in ipairs(tags) do
				
				if match and Status.Options.Tag:match(tag) then
					
					Found = true
					
					break
					
				elseif not match and Status.Options.Tag == tag then
					Found = true
					
					break
				end
				
			end
			
			if Found then
				table.insert(AllStatusEffects, Status)
			end
		end
	end

	return AllStatusEffects
end

local function HasStatusEffectsWithTags(character: WCS.Character, statusEffectName: string, tags: {string}, match: boolean?) : boolean
	return #GetAllStatusEffectsWithTags(character, statusEffectName, tags, match) > 0
end

local function HasSkillsWithName(character: WCS.Character, skillNames: { string }): boolean
	for _, SkillName in ipairs(skillNames) do
		local Skill = character:GetSkillFromString(SkillName)

		if not Skill then
			continue
		end

		return true
	end

	return false
end

local function HasSkills(character: WCS.Character, skillImpls: { any }): boolean
	local SkillNames = {}

	for _, SkillImpl in ipairs(skillImpls) do
		table.insert(SkillNames, tostring(SkillImpl))
	end

	return HasSkillsWithName(character, SkillNames)
end

local function HasActiveSkillsWithName(character: WCS.Character, skillNames: { string }): boolean
	for _, SkillName in ipairs(skillNames) do
		local Skill = character:GetSkillFromString(SkillName)

		if not Skill or not Skill:GetState().IsActive then
			continue
		end

		return true
	end

	return false
end

local function HasActiveSkills(character: WCS.Character, skillImpls: { any }): boolean
	local SkillNames = {}

	for _, SkillImpl in ipairs(skillImpls) do
		table.insert(SkillNames, tostring(SkillImpl))
	end

	return HasActiveSkillsWithName(character, SkillNames)
end

local function HasSkillsOtherThan(character: WCS.Character, skillImpls: { any }): boolean
	for _, Skill in ipairs(character:GetSkills()) do
		if not table.find(skillImpls, getmetatable(Skill)) then
			return true
		end
	end

	return false
end

-- returns true if character has other skills than provided skill names list
local function HasSkillsWithNameOtherThan(character: WCS.Character, skillNames: { string }): boolean
	for _, Skill in ipairs(character:GetSkills()) do
		if not table.find(skillNames, Skill:GetName()) then
			return true
		end
	end

	return false
end

local function HasActiveSkillsOtherThan(character: WCS.Character, skillImpls: { any }): boolean
	for _, Skill in ipairs(character:GetAllActiveSkills()) do
		if not table.find(skillImpls, getmetatable(Skill)) then
			return true
		end
	end

	return false
end

local function HasActiveSkillsWithNameOtherThan(character: WCS.Character, skillNames: { string }): boolean
	for _, Skill in ipairs(character:GetAllActiveSkills()) do
		if not table.find(skillNames, Skill:GetName()) then
			return true
		end
	end

	return false
end

-- returns true if one of provided character status effect is active
local function HasActiveStatusEffectsWithNames(character: WCS.Character, statusEffectNames: { string }): boolean
	local ActiveStatuses = character:GetAllActiveStatusEffects()
	
	for _, Status: WCS.StatusEffect in ipairs(ActiveStatuses) do
		if table.find(statusEffectNames, Status.Name) then
			return true
		end
	end
end

-- ends all active status effects of given type for provided character
local function EndAllStatusEffectsOfType(character: WCS.Character, statusEfect: WCS.StatusEffect): nil
	for _, Status: WCS.StatusEffect in ipairs(character:GetAllStatusEffectsOfType(statusEfect)) do
		Status:End()
	end
end

-- ends all active status effects with given names for provided character
local function EndAllActiveSkillsWithNames(character: WCS.Character, skillNames: { string }): nil
	for _, Skill: WCS.Skill in ipairs(character:GetAllActiveSkills()) do
		if table.find(skillNames, Skill:GetName()) then
			Skill:End()
		end
	end
end

local function RemoveStatusEffectsWithNames(
	character: WCS.Character,
	statusNames: { string },
	method: "End" | "Destroy", 
	state: "Active" | "Inactive" | "All"
)
	local Statuses = character:GetAllStatusEffects()
	
	state = state or "All"
	
	for _, Status in ipairs(Statuses) do
		
		--finding in table
		if not table.find(statusNames, Status.Name) then
			continue
		end
		
		--removal
		if state == "All"
			or (state == "Active" and Status:GetState().IsActive)
			or (state == "Inactive" and not Status:GetState().IsActive) then
			
			--removing status with provided method (default - :Destroy())
			Status[ method or "Destroy" ](Status)
		end
	end
end

local function GetAllStatusEffectsInstanceOf(character: WCS.Character, class: WCS.StatusEffectImpl, activeOnly: boolean?): {WCS.StatusEffect}
	local List = {}
	local Statuses = character:GetAllStatusEffects()
	
	for _, Status in ipairs(Statuses) do
		if not Classes.InstanceOf(Status, class) then
			continue
		end
		
		if activeOnly and not Status:GetState().IsActive then
			continue
		end
		
		table.insert(List, Status)
	end
	
	return List
end

--local function GetStatusByTag(character: WCS.Character, tag: string, statusNames: { string }?)
--	local Statuses = character:GetAllStatusEffects()

--	for _, Status: WCS.StatusEffect in ipairs(Statuses) do
--		if statusNames and not table.find(statusNames, Status) then
--			continue
--		end
		
--		if Status.Tag ~= nil and Status.Tag == tag then
--			return Status
--		end
--	end
--end

--local function HasActiveStatusesWithTags(character: WCS.Character, tags: { string })
--	for _, Tag in ipairs(tags) do
--		if GetStatusByTag(character, Tag) then
--			return true
--		end
--	end
	
--	return false
--end

--//Returner

return {
	PromiseCharacterAdded = PromiseCharacterAdded,
	ApplyGlobalCooldown = ApplyGlobalCooldown,
	
	GetAllActiveStatusEffectsFromString = GetAllActiveStatusEffectsFromString,
	GetAllStatusEffectsFromString = GetAllStatusEffectsFromString,
	GetAllStatusEffectsWithTags = GetAllStatusEffectsWithTags,
	
	EndAllStatusEffectsOfType = EndAllStatusEffectsOfType,
	EndAllActiveSkillsWithNames = EndAllActiveSkillsWithNames,
	RemoveStatusEffectsWithNames = RemoveStatusEffectsWithNames,
	
	HasSkills = HasSkills,
	HasSkillsWithName = HasSkillsWithName,
	HasActiveSkills = HasActiveSkills,
	HasActiveSkillsWithName = HasActiveSkillsWithName,
	HasSkillsOtherThan = HasSkillsOtherThan,
	HasActiveSkillsOtherThan = HasActiveSkillsOtherThan,
	HasSkillsWithNameOtherThan = HasSkillsWithNameOtherThan,
	HasActiveSkillsWithNameOtherThan = HasActiveSkillsWithNameOtherThan,
	HasStatusEffectsWithTags = HasStatusEffectsWithTags,
	
	GetAllStatusEffectsInstanceOf = GetAllStatusEffectsInstanceOf,
	HasActiveStatusEffectsWithNames = HasActiveStatusEffectsWithNames,
}