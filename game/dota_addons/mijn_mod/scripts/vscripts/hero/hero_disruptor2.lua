function Glimpse( keys )

	local caster = keys.caster
	local attacker = keys.attacker
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local particle_glimpse = keys.particle_glimpse

	-- If the ability was unlearned, do nothing
	if not ability then
		return nil
	end

	-- Parameters
	local backtrack_time = ability:GetLevelSpecialValueFor("backtrack_time", ability_level)
	local cast_range = ability:GetLevelSpecialValueFor("cast_range", ability_level)
    local position_target = target:GetAbsOrigin()
    local position_caster = caster:GetAbsOrigin()
    local units = FindUnitsInRadius(caster:GetTeamNumber(), position_caster, nil, 25000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_FLAG_NONE,FIND_ANY_ORDER, false)

    -- Fire the particle
	local glimpse_fx = ParticleManager:CreateParticle(particle_glimpse, PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(glimpse_fx, 0, position_target)


    Timers:CreateTimer({
    endTime = backtrack_time,
    callback = function()
      for _,unit in pairs(units) do
			unit:SetAbsOrigin(position_target)
			end
		end
    })

        -- Destroy particle
    ParticleManager:DestroyParticle(glimpse_fx, false)
end



function KineticField( keys )

    Msg("ik begin met kinetic field")
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local kinetic_field_center = keys.target_points[1]
	local sound_cast = keys.sound_cast
	local particle_kineticfield = keys.particle_kineticfield
	local modifier_enemy = keys.modifier_enemy
	local scepter = HasScepter(caster)

    -- Parameters
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local formation_time = ability:GetLevelSpecialValueFor("formation_time", ability_level)
	local field_duration_elapsed = 0


    --create dummy
	local kinetic_field_dummy = CreateUnitByName("npc_dummy_unit", kinetic_field_center, false, nil, nil, caster:GetTeamNumber())

	-- Fire the particle
	local field_fx = ParticleManager:CreateParticle(particle_kineticfield, PATTACH_WORLDORIGIN, kinetic_field_dummy)
	ParticleManager:SetParticleControl(field_fx, 1, kinetic_field_center)

	-- Continuously check if enemies are at the boundary
	Timers:CreateTimer(0, function()

		-- Every enemy at the boundary of kinetic field gets frozen
		local marked_enemies = FindUnitsInRadius(caster:GetTeamNumber(), kinetic_field_center, nil,radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		for _, enemy in pairs(marked_enemies) do
			if (enemy:GetAbsOrigin() - kinetic_field_center ):Length2D() == radius then
			   ability:ApplyDataDrivenModifier(caster, enemy, modifier_enemy, {})
			end
		end

		-- Check if the field has ended
		field_duration_elapsed = field_duration_elapsed + 0.05

		if field_duration_elapsed < duration then
			return 0.05
		else

			-- Destroy particle
			ParticleManager:DestroyParticle(field_fx, false)

			--Destroy dummy
			kinetic_field_dummy:Destroy()

			-- Remove modifier from marked enemies
			for _, enemy in pairs(marked_enemies) do
				enemy:RemoveModifierByName(modifier_enemies)
			end
		end
	end)
 end

function StaticStorm( keys )

    Msg("ik begin met staticstorm")
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local static_storm_center = keys.target_points[1]
	local sound_cast = keys.sound_cast
	local particle_staticstorm = keys.particle_staticstorm
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
	local caster_pos = caster:GetAbsOrigin()

    -- dummy for applying sound and particles
	local static_storm_dummy = CreateUnitByName("npc_dummy_unit", static_storm_center, false, nil, nil, caster:GetTeamNumber())

	-- Play sounds
	static_storm_dummy:EmitSound(sound_cast)

	-- Fire the particle
	local field_fx = ParticleManager:CreateParticle(particle_staticstorm, PATTACH_WORLDORIGIN, static_storm_dummy)
	ParticleManager:SetParticleControl(field_pfx, 1, static_storm_center)

	-- Continuously apply modifier to enemies inside static storm
	Timers:CreateTimer(0, function()

		-- Mark the enemies inside the field 
		local marked_enemies = FindUnitsInRadius(caster:GetTeamNumber(), static_storm_center, nil,radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL,DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(marked_enemies) do
			ability:ApplyDataDrivenModifier(caster, enemy, modifier_enemy, {})
		end

		-- Check if the pit has ended
		field_duration_elapsed = field_duration_elapsed + 0.05
		if field_duration_elapsed < duration then
			return 0.05
		else

			-- Destroy particle
			ParticleManager:DestroyParticle(field_fx, false)

			--Destroy dummy
			static_storm_dummy:Destroy()

			-- Remove modifier from marked enemies
			for _, enemy in pairs(marked_enemies) do
				enemy:RemoveModifierByName(modifier_enemies)
			end
		end
	end)
end