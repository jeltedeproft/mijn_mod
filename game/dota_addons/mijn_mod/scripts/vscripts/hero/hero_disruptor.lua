function Glimpse_projectile( keys )
    local caster = keys.caster
    local ability = keys.ability
    local ability_level = ability:GetLevel() - 1
    local target = keys.target

    local currTime = GameRules:GetGameTime()

    local backtracktime = ability:GetLevelSpecialValueFor("backtrack_time", ability_level)
    local particle = keys.particle_glimpse
    local target_pos = target:GetAbsOrigin()
    local past_position = target.positions[math.floor(currTime-backtracktime)]

    local distance = (target_pos - past_position):Length2D()
    local direction = (target_pos - past_position):Normalized()
    local projectilespeed = distance / backtracktime

	-- Create the particle
	local fxIndex = ParticleManager:CreateParticle( particle, PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl(fxIndex, 0, target_pos)
	ParticleManager:SetParticleControl(fxIndex, 1, target_pos)
	ParticleManager:SetParticleControl(fxIndex, 2, Vector(8,0,0))
	ParticleManager:SetParticleControl(fxIndex, 3, target_pos)
	ParticleManager:SetParticleControl(fxIndex, 4, past_position)
	ParticleManager:SetParticleControl(fxIndex, 5, past_position)
end

function Glimpse( keys )
	local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local currTime = GameRules:GetGameTime()
    local ability_level = ability:GetLevel() - 1
    local backtracktime = ability:GetLevelSpecialValueFor("backtrack_time", ability_level)

    if not target.positions or not target.positions[math.floor(currTime-4-backtracktime)] then 
    	return 
    end

    FindClearSpaceForUnit(target, target.positions[math.floor(currTime-4-backtracktime)], true)
end



function KineticField( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local kinetic_field_center = keys.target_points[1]
	local modifier_enemy = keys.modifier_enemy
	local scepter = HasScepter(caster)

    -- Parameters
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local radius_ring_2 = (2 * ability:GetLevelSpecialValueFor("radius", ability_level))
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local formation_time = ability:GetLevelSpecialValueFor("formation_time", ability_level)
	local field_duration_elapsed = 0

	local dummy = CreateUnitByName("npc_dummy_unit_", kinetic_field_center, false, caster, caster, caster:GetTeamNumber())

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_kf_formation.vpcf", MAX_PATTACH_TYPES, dummy)
    ParticleManager:SetParticleControl(particle, 0, dummy:GetAbsOrigin()) --location
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,radius,1)) --ring/weird
    ParticleManager:SetParticleControl(particle, 2, Vector(duration,duration,0)) --duration

    local particle_2 = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_kf_formation.vpcf", MAX_PATTACH_TYPES, dummy)
    ParticleManager:SetParticleControl(particle_2, 0, dummy:GetAbsOrigin()) --location
    ParticleManager:SetParticleControl(particle_2, 1, Vector(radius_ring_2,radius_ring_2,1)) --ring/weird
    ParticleManager:SetParticleControl(particle_2, 2, Vector(duration,duration,0)) --duration

	-- Continuously check if enemies are at the boundary
	Timers:CreateTimer(1, function()

		-- Every enemy at the boundary of kinetic field gets frozen
		local all_enemies = FindUnitsInRadius(caster:GetTeamNumber(), kinetic_field_center, nil,25000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		for _,enemy in pairs(all_enemies) do
			if ((enemy:GetAbsOrigin() - kinetic_field_center ):Length2D() < (radius + 10)
			    	and (enemy:GetAbsOrigin() - kinetic_field_center ):Length2D() > (radius - 10))
				or ((enemy:GetAbsOrigin() - kinetic_field_center ):Length2D() < (radius_ring_2 + 10)
					and  (enemy:GetAbsOrigin() - kinetic_field_center ):Length2D() > (radius_ring_2 - 10)) then				
			   ability:ApplyDataDrivenModifier(caster,enemy,modifier_enemy, {})
			end
		end

		-- Check if the field has ended
		field_duration_elapsed = field_duration_elapsed + 0.05

		if field_duration_elapsed < duration then
			return 0.05
		else
	        -- Remove modifier from marked enemies
			for _,enemy in pairs(all_enemies) do
				enemy:RemoveModifierByName(modifier_enemy)
			end

			--remove particle effects
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:DestroyParticle(particle_2, false)
		end
	end)
end

function StaticStorm( keys )

	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local caster_pos = caster:GetAbsOrigin()
	local static_storm_center = keys.target_points[1]
	local modifier_enemy = keys.modifier_enemy
	local scepter = HasScepter(caster)

    -- Parameters
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local pulses = ability:GetLevelSpecialValueFor("pulses", ability_level)
	local damage_max = ability:GetLevelSpecialValueFor("damage_max", ability_level)
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local duration_scepter = ability:GetLevelSpecialValueFor("duration_scepter", ability_level)
	local pulses_scepter = ability:GetLevelSpecialValueFor("pulses_scepter", ability_level)
	local field_duration_elapsed = 0
	

	local dummy = CreateUnitByName("npc_dummy_unit_", static_storm_center, false, caster, caster, caster:GetTeamNumber())

	if caster:HasScepter() then
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", MAX_PATTACH_TYPES, dummy)
    	ParticleManager:SetParticleControl(particle, 0, dummy:GetAbsOrigin()) --location
    	ParticleManager:SetParticleControl(particle, 1, Vector(radius,radius,radius)) --ring/weird
    	ParticleManager:SetParticleControl(particle, 2, Vector(duration_scepter,duration_scepter,0)) --duration
    else
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", MAX_PATTACH_TYPES, dummy)
    	ParticleManager:SetParticleControl(particle, 0, dummy:GetAbsOrigin()) --location
    	ParticleManager:SetParticleControl(particle, 1, Vector(radius,radius,radius)) --ring/weird
    	ParticleManager:SetParticleControl(particle, 2, Vector(duration,duration,0)) --duration
    end

	-- Continuously apply modifier to enemies inside static storm
	Timers:CreateTimer(0, function()

		-- Mark the enemies inside the field 
		local marked_enemies = FindUnitsInRadius(caster:GetTeamNumber(), static_storm_center, nil,radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _,enemy in pairs(marked_enemies) do
			ability:ApplyDataDrivenModifier(caster, enemy, modifier_enemy, {})
		end

		-- If an enemy previously marked is outside the field, remove the modifier
		local all_enemies = FindUnitsInRadius(caster:GetTeamNumber(), static_storm_center, nil, 25000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(all_enemies) do
			if enemy:HasModifier(modifier_enemy) and ( enemy:GetAbsOrigin() - static_storm_center ):Length2D() > radius then
				enemy:RemoveModifierByName(modifier_enemy)
			end
		end

		local damage_per_tick = damage_max * 0.01
		local scepter_damage_per_tick =  (damage_max * 0.02)

		if caster:HasScepter() then
			for _,enemy in pairs(marked_enemies) do
				local damage = scepter_damage_per_tick
				ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
			end
    	else
    		for _,enemy in pairs(marked_enemies) do
				local damage = damage_per_tick
				ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
			end
   		end

		field_duration_elapsed = field_duration_elapsed + 0.05

		-- Check if the duration has ended
		if field_duration_elapsed < duration then
			return 0.05
		else	
			-- Remove modifier from marked enemies
			for _,enemy in pairs(marked_enemies) do
				enemy:RemoveModifierByName(modifier_enemy)
			end
		end
	end)
end

function Thunderbolt( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local target = keys.target
	local modifier_enemy = keys.modifier_enemy

    -- Parameters
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local pulses = ability:GetLevelSpecialValueFor("pulses", ability_level)
	local damage_max = ability:GetLevelSpecialValueFor("damage_max", ability_level)
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local duration_scepter = ability:GetLevelSpecialValueFor("duration_scepter", ability_level)
	local pulses_scepter = ability:GetLevelSpecialValueFor("pulses_scepter", ability_level)
	local field_duration_elapsed = 0
	
	
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
    ParticleManager:SetParticleControl(particle, 0, dummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, dummy:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 2, dummy:GetAbsOrigin())
end