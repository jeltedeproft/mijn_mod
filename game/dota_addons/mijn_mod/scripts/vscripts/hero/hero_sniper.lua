--[[	Author: Firetoad
		Date: 09.07.2015	]]

function Headshot( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_normal_debuff = keys.modifier_normal_debuff

	-- Parameters
	local near_duration = ability:GetLevelSpecialValueFor("near_duration", ability_level)
	local normal_damage = ability:GetLevelSpecialValueFor("normal_damage", ability_level)
	local far_aoe = ability:GetLevelSpecialValueFor("far_aoe", ability_level)
	local far_shot_speed = ability:GetLevelSpecialValueFor("far_shot_speed", ability_level)


	-- apply modifier
	if not target:IsBuilding() then
			ApplyDamage({attacker = caster, victim = target, ability = ability, damage = normal_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
			ability:ApplyDataDrivenModifier(caster, target, modifier_normal_debuff, {})
		end
	
		
	
end


function AssassinateCast( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_shrapnel = keys.modifier_shrapnel
	local modifier_target = keys.modifier_target
	local modifier_caster = keys.modifier_caster
	local modifier_cast_check = keys.modifier_cast_check

	-- Parameters
	local regular_range = ability:GetLevelSpecialValueFor("regular_range", ability_level)
	local cast_distance = ( target:GetAbsOrigin() - caster:GetAbsOrigin() ):Length2D()

	-- Check if the target can be assassinated, if not, stop casting and move closer
	if cast_distance > regular_range and not target:HasModifier(modifier_shrapnel) then

		-- Start moving
		caster:MoveToPosition(target:GetAbsOrigin())
		Timers:CreateTimer(0.1, function()

			-- Update distance between caster and target
			cast_distance = ( target:GetAbsOrigin() - caster:GetAbsOrigin() ):Length2D()

			-- If it's not a legal cast situation and no other order was given, keep moving
			if cast_distance > regular_range and not target:HasModifier(modifier_shrapnel) and not caster.stop_assassinate_cast then
				return 0.1

			-- If another order was given, stop tracking the cast distance
			elseif caster.stop_assassinate_cast then
				caster:RemoveModifierByName(modifier_cast_check)
				caster.stop_assassinate_cast = nil

			-- If all conditions are met, cast Assassinate again
			else
				caster:CastAbilityOnTarget(target, ability, caster:GetPlayerID())
			end
		end)
		return nil
	end

	-- Play the pre-cast sound
	caster:EmitSound("Ability.AssassinateLoad")

	-- Mark the target with the crosshair
	ability:ApplyDataDrivenModifier(caster, target, modifier_target, {})

	-- Apply the caster modifiers
	ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})
	caster:RemoveModifierByName(modifier_cast_check)

	-- Memorize the target
	caster.assassinate_target = target

end

function AssassinateCastCheck( keys )
	local caster = keys.caster
	caster.stop_assassinate_cast = true
end

function AssassinateStop( keys )
	local caster = keys.caster
	local target_modifier = keys.target_modifier
	caster.assassinate_target:RemoveModifierByName(target_modifier)
	caster.assassinate_target = nil
end

function Assassinate( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Parameters
	local bullet_duration = ability:GetLevelSpecialValueFor("projectile_travel_time", ability_level)
	local spill_range = ability:GetLevelSpecialValueFor("spill_range", ability_level)
	local bullet_radius = ability:GetLevelSpecialValueFor("aoe_size", ability_level)
	local bullet_direction = ( target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized()
	bullet_direction = Vector(bullet_direction.x, bullet_direction.y, 0)
	local bullet_distance = ( target:GetAbsOrigin() - caster:GetAbsOrigin() ):Length2D() + spill_range
	local bullet_speed = bullet_distance / bullet_duration

	-- Create the real, invisible projectile
	local assassinate_projectile = {
		Ability				= ability,
		EffectName			= "",
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= bullet_distance,
		fStartRadius		= bullet_radius,
		fEndRadius			= bullet_radius,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_MECHANICAL,
	--	fExpireTime			= ,
		bDeleteOnHit		= false,
		vVelocity			= bullet_direction * bullet_speed,
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	ProjectileManager:CreateLinearProjectile(assassinate_projectile)

	-- Create the fake, visible projectile
	assassinate_projectile = {
		Target = target,
		Source = caster,
		Ability = nil,	
		EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,
		bDeleteOnHit = true,
		iMoveSpeed = bullet_speed,
		bProvidesVision = false,
		bDodgeable = true,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
	}

	ProjectileManager:CreateTrackingProjectile(assassinate_projectile)
end

function AssassinateHit( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local scepter = HasScepter(caster)
	local modifier_slow = keys.modifier_slow

	-- Parameters
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)

	-- Scepter damage and debuff
	if scepter then

		-- Scepter parameters
		damage = ability:GetLevelSpecialValueFor("damage_scepter", ability_level)
		local knockback_speed = ability:GetLevelSpecialValueFor("knockback_speed_scepter", ability_level)

		-- Knockback geometry calculations
		local caster_pos = caster:GetAbsOrigin()
		local caster_range = caster:GetAttackRange()
		local target_pos = target:GetAbsOrigin()
		local knockback_pos = caster_pos + ( target_pos - caster_pos ):Normalized() * caster_range
		local knockback_distance = ( knockback_pos - target_pos ):Length2D()
		if ( target_pos - caster_pos ):Length2D() > caster_range then
			knockback_distance = 50
		end
		
		local assassinate_knockback =	{
			should_stun = 1,
			knockback_duration = math.min( knockback_distance / knockback_speed, 0.6),
			duration = math.min( knockback_distance / knockback_speed, 0.6),
			knockback_distance = knockback_distance,
			knockback_height = knockback_distance * 0.3,
			center_x = caster_pos.x,
			center_y = caster_pos.y,
			center_z = caster_pos.z
		}

		-- Apply knockback and slow modifiers
		target:RemoveModifierByName("modifier_knockback")
		target:AddNewModifier(caster, ability, "modifier_knockback", assassinate_knockback )
		ability:ApplyDataDrivenModifier(caster, target, modifier_slow, {})
	end

	-- Apply damage
	ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})

	-- Grant short-lived vision
	ability:CreateVisibilityNode(target:GetAbsOrigin(), 500, 1.0)

	-- Ministun
	target:AddNewModifier(caster, ability, "modifier_stunned", {duration = 0.1})

	-- Fire particle
	local hit_fx = ParticleManager:CreateParticle("particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missile_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(hit_fx, 0, target:GetAbsOrigin() )
end

--[[
	CHANGELIST:
	09.01.2015 - Remove ReleaseParticleIndex( .. )
]]

--[[
	Author: kritth
	Date: 7.1.2015.
	Init: Create a timer to start charging charges
]]
function shrapnel_start_charge( keys )
	-- Only start charging at level 1
	if keys.ability:GetLevel() ~= 1 then return end

	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local modifierName = "modifier_shrapnel_stack_counter_datadriven"
	local maximum_charges = ability:GetLevelSpecialValueFor( "maximum_charges", ( ability:GetLevel() - 1 ) )
	local charge_replenish_time = ability:GetLevelSpecialValueFor( "charge_replenish_time", ( ability:GetLevel() - 1 ) )
	
	-- Initialize stack
	caster:SetModifierStackCount( modifierName, caster, 0 )
	caster.shrapnel_charges = maximum_charges
	caster.start_charge = false
	caster.shrapnel_cooldown = 0.0
	
	ability:ApplyDataDrivenModifier( caster, caster, modifierName, {} )
	caster:SetModifierStackCount( modifierName, caster, maximum_charges )
	
	-- create timer to restore stack
	Timers:CreateTimer( function()
			-- Restore charge
			if caster.start_charge and caster.shrapnel_charges < maximum_charges then
				-- Calculate stacks
				local next_charge = caster.shrapnel_charges + 1
				caster:RemoveModifierByName( modifierName )
				if next_charge ~= 3 then
					ability:ApplyDataDrivenModifier( caster, caster, modifierName, { Duration = charge_replenish_time } )
					shrapnel_start_cooldown( caster, charge_replenish_time )
				else
					ability:ApplyDataDrivenModifier( caster, caster, modifierName, {} )
					caster.start_charge = false
				end
				caster:SetModifierStackCount( modifierName, caster, next_charge )
				
				-- Update stack
				caster.shrapnel_charges = next_charge
			end
			
			-- Check if max is reached then check every 0.5 seconds if the charge is used
			if caster.shrapnel_charges ~= maximum_charges then
				caster.start_charge = true
				return charge_replenish_time
			else
				return 0.5
			end
		end
	)
end

--[[
	Author: kritth
	Date: 6.1.2015.
	Helper: Create timer to track cooldown
]]
function shrapnel_start_cooldown( caster, charge_replenish_time )
	caster.shrapnel_cooldown = charge_replenish_time
	Timers:CreateTimer( function()
			local current_cooldown = caster.shrapnel_cooldown - 0.1
			if current_cooldown > 0.1 then
				caster.shrapnel_cooldown = current_cooldown
				return 0.1
			else
				return nil
			end
		end
	)
end

--[[
	Author: kritth
	Date: 6.1.2015.
	Main: Check/Reduce charge, spawn dummy and cast the actual ability
]]
function shrapnel_fire( keys )
	-- Reduce stack if more than 0 else refund mana
	if keys.caster.shrapnel_charges > 0 then
		-- variables
		local caster = keys.caster
		local target = keys.target_points[1]
		local ability = keys.ability
		local casterLoc = caster:GetAbsOrigin()
		local modifierName = "modifier_shrapnel_stack_counter_datadriven"
		local dummyModifierName = "modifier_shrapnel_dummy_datadriven"
		local radius = ability:GetLevelSpecialValueFor( "radius", ( ability:GetLevel() - 1 ) )
		local maximum_charges = ability:GetLevelSpecialValueFor( "maximum_charges", ( ability:GetLevel() - 1 ) )
		local charge_replenish_time = ability:GetLevelSpecialValueFor( "charge_replenish_time", ( ability:GetLevel() - 1 ) )
		local dummy_duration = ability:GetLevelSpecialValueFor( "duration", ( ability:GetLevel() - 1 ) ) + 0.1
		local damage_delay = ability:GetLevelSpecialValueFor( "damage_delay", ( ability:GetLevel() - 1 ) ) + 0.1
		local launch_particle_name = "particles/units/heroes/hero_sniper/sniper_shrapnel_launch.vpcf"
		local launch_sound_name = "Hero_Sniper.ShrapnelShoot"
		
		-- Deplete charge
		local next_charge = caster.shrapnel_charges - 1
		if caster.shrapnel_charges == maximum_charges then
			caster:RemoveModifierByName( modifierName )
			ability:ApplyDataDrivenModifier( caster, caster, modifierName, { Duration = charge_replenish_time } )
			shrapnel_start_cooldown( caster, charge_replenish_time )
		end
		caster:SetModifierStackCount( modifierName, caster, next_charge )
		caster.shrapnel_charges = next_charge
		
		-- Check if stack is 0, display ability cooldown
		if caster.shrapnel_charges == 0 then
			-- Start Cooldown from caster.shrapnel_cooldown
			ability:StartCooldown( caster.shrapnel_cooldown )
		else
			ability:EndCooldown()
		end
		
		-- Create particle at caster
		local fxLaunchIndex = ParticleManager:CreateParticle( launch_particle_name, PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( fxLaunchIndex, 0, casterLoc )
		ParticleManager:SetParticleControl( fxLaunchIndex, 1, Vector( casterLoc.x, casterLoc.y, 800 ) )
		StartSoundEvent( launch_sound_name, caster )
		
		-- Deal damage
		shrapnel_damage( caster, ability, target, damage_delay, dummyModifierName, dummy_duration )
	else
		keys.ability:RefundManaCost()
	end
end

--[[
	Author: kritth
	Date: 6.1.2015.
	Main: Create dummy to apply damage
]]
function shrapnel_damage( caster, ability, target, damage_delay, dummyModifierName, dummy_duration )
	Timers:CreateTimer( damage_delay, function()
			-- create dummy to do damage and apply debuff modifier
			local dummy = CreateUnitByName( "npc_dummy_unit", target, false, caster, caster, caster:GetTeamNumber() )
			ability:ApplyDataDrivenModifier( caster, dummy, dummyModifierName, {} )
			Timers:CreateTimer( dummy_duration, function()
					dummy:ForceKill( true )
					return nil
				end
			)
			return nil
		end
	)
end
