--[[	Author: D2imba
		Date: 20.03.2015	]]

function HoofStomp( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifier_caster = keys.modifier_caster
	local modifier_enemies = keys.modifier_enemies
	local particle_pit = keys.particle_pit

	-- Parameters
	local pit_radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
	local pit_duration = ability:GetLevelSpecialValueFor("pit_duration", ability:GetLevel() - 1)
	local pit_center = caster:GetAbsOrigin()
	local pit_duration_elapsed = 0

	-- Fire the particle
	local pit_fx = ParticleManager:CreateParticle(particle_pit, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(pit_fx, 0, pit_center)

	-- Continuously prevent enemies inside the ring from leaving
	Timers:CreateTimer(0, function()

		-- Mark the enemies inside the pit to prevent them from leaving
		local marked_enemies = FindUnitsInRadius(caster:GetTeamNumber(), pit_center, nil, pit_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
		for _, enemy in pairs(marked_enemies) do
			ability:ApplyDataDrivenModifier(caster, enemy, modifier_enemies, {})
			enemy.hoof_pit_owner = caster
		end

		-- If an enemy previously marked is outside the ring, move it in
		local all_enemies = FindUnitsInRadius(caster:GetTeamNumber(), pit_center, nil, 25000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
		for _, enemy in pairs(all_enemies) do
			if enemy:HasModifier(modifier_enemies) and ( enemy:GetAbsOrigin() - pit_center ):Length2D() > pit_radius and enemy.hoof_pit_owner == caster then
				FindClearSpaceForUnit(enemy, pit_center + ( enemy:GetAbsOrigin() - pit_center ):Normalized() * pit_radius, true)
			end
		end

		-- If the caster is outside the pit, remove the damage reduction modifier
		if ( caster:GetAbsOrigin() - pit_center ):Length2D() > pit_radius then
			caster:RemoveModifierByName(modifier_caster)
		end

		-- Check if the pit has ended
		pit_duration_elapsed = pit_duration_elapsed + 0.05
		if pit_duration_elapsed < pit_duration then
			return 0.05
		else

			-- Destroy particle
			ParticleManager:DestroyParticle(pit_fx, false)

			-- Remove modifier from marked enemies
			all_enemies = FindUnitsInRadius(caster:GetTeamNumber(), pit_center, nil, 25000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
			for _, enemy in pairs(all_enemies) do
				enemy:RemoveModifierByName(modifier_enemies)
				enemy.hoof_pit_owner = nil
			end
		end
	end)
end

function DoubleEdge( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_caster = keys.modifier_caster

	-- Parameters
	local damage = ability:GetLevelSpecialValueFor("edge_damage", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local str_percentage = ability:GetLevelSpecialValueFor("str_percentage", ability_level)
	local target_pos = target:GetAbsOrigin()
	local caster_str = caster:GetStrength()

	-- Draw the particle
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_double_edge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 5, target:GetAbsOrigin())

	-- Calculate bonus damage
	damage = damage + caster_str * str_percentage / 100

	-- Find enemies to deal damage to
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	for _,enemy in pairs(enemies) do
		ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
	end

	-- Apply the deny prevention modifier before dealing self damage
	ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})

	-- Deal the self damage
	ApplyDamage({victim = caster, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})

	-- Remove the deny prevention modifier
	caster:RemoveModifierByName(modifier_caster)
end

function Return( keys )
	local caster = keys.caster
	local attacker = keys.attacker
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_prevent_return = keys.modifier_prevent_return

	-- Parameters
	local str_percentage = ability:GetLevelSpecialValueFor("strength_pct", ability_level)
	local duration = ability:GetLevelSpecialValueFor("cooldown", ability_level)

	-- Calculate return damage
	local damage = caster:GetStrength() * str_percentage / 100

	-- Damages attacker if it hasn't taken return damage in the last second
	if not attacker:HasModifier(modifier_prevent_return) then
		-- Applies "damaged by return" modifier to the attacker
		ability:ApplyDataDrivenModifier(caster, attacker, modifier_prevent_return, {duration = duration})

		-- Deals damage
		ApplyDamage({victim = attacker, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL })
	end
end

function ReturnUpdate( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_stacks = keys.modifier_stacks

	-- Parameters
	local max_block = ability:GetLevelSpecialValueFor("max_block", ability_level)
	local block_str_percentage = ability:GetLevelSpecialValueFor("block_str_percentage", ability_level)

	-- Calculate amount of stacks to give
	local total_block = math.min( caster:GetStrength() * block_str_percentage / 100 , max_block)

	-- Update amount of stacks
	caster:RemoveModifierByName(modifier_stacks)
	AddStacks(ability, caster, caster, modifier_stacks, total_block, true)
end

-- Emits the global sound and initializes a table to keep track of the units hit
function StampedeStart( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_stampede = keys.modifier_stampede
	local modifier_scepter = keys.modifier_scepter
	local scepter = HasScepter(caster)

	-- Parameters
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	if scepter then
		duration = ability:GetLevelSpecialValueFor("duration_scepter", ability_level)
	end

	-- Apply the modifier to all allied units
	local allies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 25000, DOTA_UNIT_TARGET_TEAM_FRIENDLY , DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	for _, ally in pairs(allies) do
		ability:ApplyDataDrivenModifier(caster, ally, modifier_stampede, {duration = duration})
		if scepter then
			ability:ApplyDataDrivenModifier(caster, ally, modifier_scepter, {duration = duration})
		end
	end
	
	-- Plays the global sound
	EmitGlobalSound("Hero_Centaur.Stampede.Cast")

	-- Initialize the hit table
	if caster.stampede_targets_hit then
		caster.stampede_targets_hit = nil
	end

	caster.stampede_targets_hit = {}
end

function Stampede( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local sound_impact = keys.sound_impact

	-- Parameters
	local duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
	local str_percentage = ability:GetLevelSpecialValueFor("strength_damage", ability_level)

	-- Damage calculation
	local damage = caster:GetStrength() * str_percentage / 100
	
	-- Check if the target was already hit by this cast of Stampede
	local hit = false
	for _, unit in pairs(caster.stampede_targets_hit) do
		if unit == target then
			hit = true
		end
	end

	-- If not, hit the target with Stampede
	if not hit then

		-- Damage
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})

		-- Stun
		target:AddNewModifier(caster, ability, "modifier_stunned", {duration = duration})

		-- Play sound
		target:EmitSound(sound_impact)

		-- Add to hit table
		table.insert(caster.stampede_targets_hit, target)
	end
end