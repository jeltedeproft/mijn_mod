--[[Author: Pizzalol
	Date: 19.01.2015.
	Restores a set amount of mana to the target]]
function ChakraMagic( keys )
	local target = keys.target
	local ability = keys.ability
	local mana_restore = ability:GetLevelSpecialValueFor("mana_restore", (ability:GetLevel() - 1))

	target:GiveMana(mana_restore)
end


--[[Author: Pizzalol/Noya
	Date: 24.01.2015.
	Initializes the Illuminate and swaps the abilities]]
function IlluminateStart( keys )
	local caster = keys.caster
	local ability = keys.ability
	caster.illuminate_position = caster:GetAbsOrigin()
	caster.illuminate_vision_position = caster.illuminate_position
	caster.illuminate_direction = caster:GetForwardVector()
	caster.illuminate_start_time = GameRules:GetGameTime()

	-- Swap sub_ability
	local sub_ability_name = keys.sub_ability_name
	local main_ability_name = ability:GetAbilityName()

	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

--[[Author: Pizzalol
	Date: 24.01.2015.
	Creates vision fields every tick interval on the set positions]]
function IlluminateVisionFields( keys )
	local caster = keys.caster
	local ability = keys.ability

	-- Vision variables
	local channel_vision_radius = ability:GetLevelSpecialValueFor("channel_vision_radius", (ability:GetLevel() - 1))
	local channel_vision_duration = ability:GetLevelSpecialValueFor("channel_vision_duration", (ability:GetLevel() - 1))
	local channel_vision_step = ability:GetLevelSpecialValueFor("channel_vision_step", (ability:GetLevel() - 1))

	-- Calculating the position
	caster.illuminate_vision_position = caster.illuminate_vision_position + caster.illuminate_direction * channel_vision_step

	ability:CreateVisibilityNode(caster.illuminate_vision_position, channel_vision_radius, channel_vision_duration)
end

--[[Author: Pizzalol
	Date: 24.01.2015.
	Calculates the channel time according to the starting time and current time
	Calculates the damage according to the channel time
	Creates a projectile based on the casters starting channeling position]]
function IlluminateEnd( keys )
	local caster = keys.caster
	local ability = keys.ability

	-- Ability variables	
	caster.illuminate_damage = 0
	local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", (ability:GetLevel() - 1))

	-- Projectile variables
	local projectile_name = keys.projectile_name
	local projectile_speed = ability:GetLevelSpecialValueFor("speed", (ability:GetLevel() - 1))
	local projectile_distance = ability:GetLevelSpecialValueFor("range", (ability:GetLevel() - 1))
	local projectile_radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))


	-- Calculating the Illuminate channel time and damage
	caster.illuminate_channel_time = GameRules:GetGameTime() - caster.illuminate_start_time
	caster.illuminate_damage = caster.illuminate_channel_time * damage_per_second


	-- Create projectile
	local projectileTable =
	{
		EffectName = projectile_name,
		Ability = ability,
		vSpawnOrigin = caster.illuminate_position,
		vVelocity = caster.illuminate_direction * projectile_speed,
		fDistance = projectile_distance,
		fStartRadius = projectile_radius,
		fEndRadius = projectile_radius,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = true,
		iUnitTargetTeam = ability:GetAbilityTargetTeam(),
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = ability:GetAbilityTargetType()
	}
	caster.illuminate_projectileID = ProjectileManager:CreateLinearProjectile( projectileTable )
end

--[[Author: Pizzalol
	Date: 24.01.2015.
	Deals damage according to the channel time]]
function IlluminateProjectileHit( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage_table = {}

	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.ability = ability
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.damage = caster.illuminate_damage

	ApplyDamage(damage_table)
end

--[[Author: Noya
	Used by: Pizzalol
	Date: 24.01.2015.
	Swaps the abilities back]]
function IlluminateSwapEnd( keys )
	local caster = keys.caster
	local main_ability = keys.ability

	-- Swap the sub_ability back to normal
	local main_ability_name = main_ability:GetAbilityName()
	local sub_ability_name = keys.sub_ability_name

	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
end

--[[Author: Pizzalol
	Date: 24.01.2015.
	Stops the ability channel]]
function IlluminateStop( keys )
	local caster = keys.caster

	caster:Stop()
end

--[[
	Author: Noya
	Used by: Pizzalol
	Date: 24.01.2015.
	Levels up the ability_name to the same level of the ability that runs this
]]
function LevelUpAbility( event )
	local caster = event.caster
	local this_ability = event.ability		
	local this_abilityName = this_ability:GetAbilityName()
	local this_abilityLevel = this_ability:GetLevel()

	-- The ability to level up
	local ability_name = event.ability_name
	local ability_handle = caster:FindAbilityByName(ability_name)	
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end
end

--[[Author: Pizzalol
	Date: 20.01.2015.
	Initializes the starting position of the target and does the initial mana check]]
function ManaLeakInit( keys )
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local target_mana = target:GetMana()
	local ability = keys.ability

	print(target_mana)
	-- Extra variables
	local sound = keys.sound
	local modifier = keys.modifier
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", (ability:GetLevel() - 1))

	-- Initial mana check
	if target_mana <= 0 then
		target:RemoveModifierByName(modifier)
		target:AddNewModifier(caster, nil, "modifier_stunned", {duration = stun_duration})
		EmitSoundOn(sound, target)
	end

	-- Setting the starting position
	target.position = target_location
end

--[[Author: Pizzalol
	Date: 20.01.2015.
	Compares the new and previous position on each check
	Checks if the target moved more than the leash range, if it didnt then it drains mana
	and checks if the mana is empty, if true then it applies the stun]]
function ManaLeak( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	-- Variables
	local target_max_mana = target:GetMaxMana()
	local target_current_mana = target:GetMana()
	-- How much of the mana pool is reduced per 100 units
	local mana_pct_per_100 = ability:GetLevelSpecialValueFor("mana_leak_pct", (ability:GetLevel() - 1)) / 100
	-- How much of the mana pool is lost per 1 unit
	local mana_pct = mana_pct_per_100 / 100
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", (ability:GetLevel() - 1))
	-- The limit until which we consider draining mana, if the change is greater than this then dont do anything
	local leash_range_check = ability:GetLevelSpecialValueFor("leash_range_check", (ability:GetLevel() - 1))

	-- Extra variables
	local sound = keys.sound
	local modifier = keys.modifier

	-- Calculations
	local old_position = target.position
	local new_position = target:GetAbsOrigin()
	local distance = (new_position - old_position):Length2D()
	-- Calculating the mana loss
	local mana_reduction = target_max_mana * distance * mana_pct

	-- Checks if the distance is greater than the leash, if not then it reduces mana and
	-- checks if the target still has mana, if not then it stuns the target and plays the corresponding sound
	if distance < leash_range_check and distance ~= 0 then
		target:ReduceMana(mana_reduction)
		if target_current_mana <= mana_reduction then
			target:RemoveModifierByName(modifier)
			target:AddNewModifier(caster, nil, "modifier_stunned", {duration = stun_duration})
			EmitSoundOn(sound, target)
		end
	end

	local units = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _,unit in pairs(units) do
		unit:GiveMana(mana_reduction)
	end

	-- Saves the new position for the next check
	target.position = new_position
end

--[[Author: Pizzalol
	Date: 19.01.2015.
	Changed: 25.01.2015.
	Reason: Fixed error case
	Finds the closest unit to the selected point and then applies the Recall modifier]]
function Recall( keys )
	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local point = keys.target_points[1]

	-- Extra variables
	local sound_caster = keys.sound_caster
	local sound_target = keys.sound_target
	local modifier = keys.modifier
	local duration = ability:GetLevelSpecialValueFor("teleport_delay", (ability:GetLevel() - 1))

	-- Find the closest target
	local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, FIND_UNITS_EVERYWHERE, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_CLOSEST, false)
	
	-- In case the caster is the only one available then it stops the sound
	if #targets < 2 then
		Timers:CreateTimer(0.03, function()
			StopSoundOn(sound_caster, caster)
		end)
		return
	end

	-- Apply the modifier to the closest target
	for _,v in ipairs(targets) do
		if v ~= caster then
			print(v:GetName())
			ability:ApplyDataDrivenModifier(caster, v, modifier, {duration = duration})
			EmitSoundOn(sound_target, v)

			-- Stop the sound after the duration
			Timers:CreateTimer(duration, function()				
				StopSoundOn(sound_caster, caster)
				StopSoundOn(sound_target, v)
				-- Stop the active command of the target upon being teleported
				v:Stop()
			end)
			return
		end
	end
end

--[[Author: Pizzalol
	Date: 19.01.2015.
	Finds the closest unit to the selected point and then applies the Recall modifier]]
function RecallFail( keys )
	local caster = keys.caster
	local target = keys.unit

	local sound_caster = keys.sound_caster
	local sound_target = keys.sound_target

	StopSoundOn(sound_caster, caster)
	StopSoundOn(sound_target, target)
end

--[[Author: Noya
	Used by: Pizzalol
	Date: 25.01.2015.
	Swaps the abilities]]
function SwapAbilities( keys )
	local caster = keys.caster

	-- Swap sub_ability
	local sub_ability_name = keys.sub_ability_name
	local main_ability_name = keys.main_ability_name

	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

--[[
	Author: Noya,Pizzalol
	Date: 27.09.2015.
	Levels up the ability_name to the same level of the ability that runs this and only
	if the target has the specified modifier
]]
function LevelUpAbility( event )
	local caster = event.caster
	local modifier = event.modifier
	local this_ability = event.ability		
	local this_abilityName = this_ability:GetAbilityName()
	local this_abilityLevel = this_ability:GetLevel()

	-- The ability to level up
	local ability_name = event.ability_name
	local ability_handle = caster:FindAbilityByName(ability_name)	
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end

	-- Disable/Enable the ability depending if Spirit Form is active
	if caster:HasModifier(modifier) then
		ability_handle:SetActivated(true) 
	else
		ability_handle:SetActivated(false)
	end
end

--[[Enables the Spirit Form abilities]]
function SpiritFormStart( keys )
	local caster = keys.caster
	local spirit_form = keys.ability

	local illuminate = caster:FindAbilityByName(keys.illuminate)
	local spirit_form_illuminate = caster:FindAbilityByName(keys.spirit_form_illuminate)
	local recall = caster:FindAbilityByName(keys.recall)
	local blinding_light = caster:FindAbilityByName(keys.blinding_light)

	local illuminate_level = illuminate:GetLevel()

	spirit_form_illuminate:SetLevel(illuminate_level)
	recall:SetActivated(true)
	blinding_light:SetActivated(true)
end

--[[Disables the Spirit Form abilities]]
function SpiritFormEnd( keys )
	local caster = keys.caster

	local illuminate = caster:FindAbilityByName(keys.illuminate)
	local spirit_form_illuminate = caster:FindAbilityByName(keys.spirit_form_illuminate)
	local recall = caster:FindAbilityByName(keys.recall)
	local blinding_light = caster:FindAbilityByName(keys.blinding_light)

	local spirit_form_illuminate_level = spirit_form_illuminate:GetLevel()

	illuminate:SetLevel(spirit_form_illuminate_level)
	recall:SetActivated(false)
	blinding_light:SetActivated(false)

	if caster.spirit_form_illuminate_dummy and IsValidEntity(caster.spirit_form_illuminate_dummy) then
		caster.spirit_form_illuminate_dummy:RemoveModifierByName("modifier_spirit_form_illuminate_dummy_datadriven")
	end
end


--[[Author: Pizzalol
	Date: 25.01.2015.
	Initializes the dummy unit, channeling time and all the necessary positions and modifiers]]
function SpiritFormIlluminateInitialize( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel()
	local ability_name = ability:GetAbilityName()

	local caster_location = caster:GetAbsOrigin()
	local player = caster:GetPlayerID()
	local caster_direction = caster:GetForwardVector()

	local dummy_modifier = keys.dummy_modifier

	local max_channel_time = ability:GetLevelSpecialValueFor("max_channel_time", (ability:GetLevel() - 1)) + 0.03 -- Apply it for 1 frame longer than the duration

	caster.spirit_form_illuminate_dummy = CreateUnitByName("npc_dummy_unit", caster_location, false, caster, caster, caster:GetTeam())
	caster.spirit_form_illuminate_dummy:SetForwardVector(caster_direction)
	caster.spirit_form_illuminate_dummy.spirit_form_illuminate_vision_position = caster_location
	caster.spirit_form_illuminate_dummy.spirit_form_illuminate_position = caster_location
	caster.spirit_form_illuminate_dummy.spirit_form_illuminate_direction = caster_direction
	caster.spirit_form_illuminate_dummy.spirit_form_illuminate_start_time = GameRules:GetGameTime()
	ability:ApplyDataDrivenModifier(caster, caster.spirit_form_illuminate_dummy, dummy_modifier, {duration = max_channel_time})
end

--[[
	Author: Noya
	Used by: Pizzalol
	Date: 25.01.2015.
	Levels up the ability_name to the same level of the ability that runs this
]]
function LevelUpAbility( event )
	local caster = event.caster
	local this_ability = event.ability		
	local this_abilityName = this_ability:GetAbilityName()
	local this_abilityLevel = this_ability:GetLevel()

	-- The ability to level up
	local ability_name = event.ability_name
	local ability_handle = caster:FindAbilityByName(ability_name)	
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end
end

--[[Author: Pizzalol
	Date: 25.01.2015.
	Creates vision fields every tick interval on the set positions]]
function SpiritFormIlluminateVisionFields( keys )
	local target = keys.target
	local ability = keys.ability

	-- Vision variables
	local channel_vision_radius = ability:GetLevelSpecialValueFor("channel_vision_radius", (ability:GetLevel() - 1))
	local channel_vision_duration = ability:GetLevelSpecialValueFor("channel_vision_duration", (ability:GetLevel() - 1))
	local channel_vision_step = ability:GetLevelSpecialValueFor("channel_vision_step", (ability:GetLevel() - 1))

	-- Calculating the position
	target.spirit_form_illuminate_vision_position = target.spirit_form_illuminate_vision_position + target.spirit_form_illuminate_direction * channel_vision_step

	ability:CreateVisibilityNode(target.spirit_form_illuminate_vision_position, channel_vision_radius, channel_vision_duration)
end

--[[Author: Pizzalol
	Date: 25.01.2015.
	Calculates the channel time according to the modifiers on the dummy unit
	Calculates the damage according to the channel time
	Creates a projectile based on the casters starting channeling position]]
function SpiritFormIlluminateEnd( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	-- Ability variables
	caster.spirit_form_illuminate_damage = 0
	local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", (ability:GetLevel() - 1))

	-- Projectile variables
	local projectile_name = keys.projectile_name
	local projectile_speed = ability:GetLevelSpecialValueFor("speed", (ability:GetLevel() - 1))
	local projectile_distance = ability:GetLevelSpecialValueFor("range", (ability:GetLevel() - 1))
	local projectile_radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))

	-- Calculating the Illuminate channel time and damage
	caster.spirit_form_illuminate_channel_time = GameRules:GetGameTime() - caster.spirit_form_illuminate_dummy.spirit_form_illuminate_start_time
	caster.spirit_form_illuminate_damage = caster.spirit_form_illuminate_channel_time * damage_per_second

	-- Create projectile
	local projectileTable =
	{
		EffectName = projectile_name,
		Ability = ability,
		vSpawnOrigin = target.spirit_form_illuminate_position,
		vVelocity = target.spirit_form_illuminate_direction * projectile_speed,
		fDistance = projectile_distance,
		fStartRadius = projectile_radius,
		fEndRadius = projectile_radius,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = true,
		iUnitTargetTeam = ability:GetAbilityTargetTeam(),
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = ability:GetAbilityTargetType()
	}
	caster.spirit_form_illuminate_projectileID = ProjectileManager:CreateLinearProjectile( projectileTable )

	-- Kill the dummy
	Timers:CreateTimer(0.03, function()
		target:RemoveSelf()
	end)
end

--[[Author: Pizzalol
	Date: 25.01.2015.
	Deals damage according to the channel time]]
function SpiritFormIlluminateProjectileHit( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage_table = {}

	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.ability = ability
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.damage = caster.spirit_form_illuminate_damage

	ApplyDamage(damage_table)
end

--[[Author: Noya
	Used by: Pizzalol
	Date: 25.01.2015.
	Swaps the abilities]]
function SwapAbilities( keys )
	local caster = keys.caster

	-- Swap sub_ability
	local sub_ability_name = keys.sub_ability_name
	local main_ability_name = keys.main_ability_name

	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

--[[Author: Pizzalol
	Date: 25.01.2015.
	Stops the dummy channeling]]
function SpiritFormIlluminateStop( keys )
	local caster = keys.caster
	local ability = keys.ability

	local dummy_modifier = keys.dummy_modifier

	caster.spirit_form_illuminate_dummy:RemoveModifierByName(dummy_modifier)
end