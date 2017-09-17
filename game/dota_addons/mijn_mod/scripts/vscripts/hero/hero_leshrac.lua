function speed( keys)
	local target_point = keys.target_points[1]
    local caster = keys.caster
    local ability = keys.ability

    local movement_speed_bonus = ability:GetLevelSpecialValueFor("movement_speed_bonus", ability:GetLevel() - 1)
    local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

    local friends = FindUnitsInRadius(caster:GetTeamNumber(), target_point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _,unit in pairs(friends) do
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_speed_boost_allies", {duration = duration})		
	end
end

function slow( keys)
    local target_point = keys.target_points[1]
    local caster = keys.caster
    local ability = keys.ability

    local movement_speed_bonus = ability:GetLevelSpecialValueFor("movement_speed_bonus", ability:GetLevel() - 1)
    local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

    local enemys = FindUnitsInRadius(caster:GetTeamNumber(), target_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

    for _,unit in pairs(enemys) do
        ability:ApplyDataDrivenModifier(caster, unit, "modifier_slow_debuff_enemies", {duration = duration})     
    end
end

function flux_sphere( keys)
    local caster = keys.caster
    local chrono_center = keys.target_points[1]
    local ability = keys.ability
    local ability_level = ability:GetLevel() - 1
    local sound_cast = keys.sound_cast
    local particle_chrono = keys.particle_chrono
    local modifier_enemy = keys.modifier_enemy
    local modifier_ally = keys.modifier_ally
    
    -- Parameters
    local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
    local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
    local tick_interval = ability:GetLevelSpecialValueFor("tick_interval", ability_level)

    -- Play sound
    caster:EmitSound(sound_cast)

    -- Create flying vision node
    ability:CreateVisibilityNode(chrono_center, radius, duration)

    -- Create particle
    local chrono_pfx = ParticleManager:CreateParticle(particle_chrono, PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(chrono_pfx, 0, chrono_center)
    ParticleManager:SetParticleControl(chrono_pfx, 1, Vector(radius, radius, 0))

    -- Find all units 
    local friends = FindUnitsInRadius(caster:GetTeamNumber(), chrono_center, nil, 25000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(), chrono_center, nil, 25000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL , DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

    -- Effect loop
    local elapsed_duration = 0
    Timers:CreateTimer(0, function()
        
        -- Find units inside the Chrono's radius
        local units = FindUnitsInRadius(caster:GetTeamNumber(), chrono_center, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
        local units2 = FindUnitsInRadius(caster:GetTeamNumber(), chrono_center, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
        
        -- Apply appropriate modifiers
        for _,unit in pairs(units) do 
            ability:ApplyDataDrivenModifier(caster, unit, modifier_ally, {})
        end

        for _,unit in pairs(units2) do
            ability:ApplyDataDrivenModifier(caster, unit, modifier_enemy, {})
        end

        for _, friend in pairs(friends) do
            if friend:HasModifier(modifier_ally) and ( friend:GetAbsOrigin() - chrono_center ):Length2D() > radius then
                friend:RemoveModifierByName(modifier_ally)
            end
        end

        for _, enemy in pairs(enemies) do
            if enemy:HasModifier(modifier_enemy) and ( enemy:GetAbsOrigin() - chrono_center ):Length2D() > radius then
                enemy:RemoveModifierByName(modifier_enemy)
            end
        end

        -- Update duration and check end condition
        print( "elapsed duration is: " .. elapsed_duration )
        elapsed_duration = elapsed_duration + tick_interval
        if elapsed_duration < duration then
            return tick_interval
        else
            ParticleManager:DestroyParticle(chrono_pfx, false)

        for _, friend in pairs(friends) do
            friend:RemoveModifierByName(modifier_ally)
        end

        for _, enemy in pairs(enemies) do
            enemy:RemoveModifierByName(modifier_enemy)
        end

        end        
    end)
end


