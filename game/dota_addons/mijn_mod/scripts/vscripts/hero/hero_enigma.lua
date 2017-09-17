function FastDummy(target, team, duration, vision)
  duration = duration or 0
  vision = vision or  250
  local dummy = CreateUnitByName("npc_dummy_unit", target, false, nil, nil, team)
  if dummy ~= nil then
    dummy:SetAbsOrigin(target) -- CreateUnitByName uses only the x and y coordinates so we have to move it with SetAbsOrigin()
    dummy:SetDayTimeVisionRange(vision)
    dummy:SetNightTimeVisionRange(vision)
    dummy:AddNewModifier(dummy, nil, "modifier_phased", { duration = 9999})
    dummy:AddNewModifier(dummy, nil, "modifier_invulnerable", { duration = 9999})
    dummy:AddNewModifier(dummy, nil, "modifier_kill", {duration = duration })
    
  end
  return dummy
end

function extra_black_holes(event)
  local caster = event.caster
  local caster_pos = caster:GetAbsOrigin()
  local targetted_point = event.target_points[1]
  local ability = event.ability
  local ability_level = ability:GetLevel() - 1
  local duration = ability:GetLevelSpecialValueFor("chargetime", ability_level)

  local origin_b = RotatePosition(caster_pos, QAngle(0,80,0), targetted_point)
  local origin_c = RotatePosition(caster_pos, QAngle(0,-80,0), targetted_point)

  local dummy_unit_b = FastDummy(origin_b,caster:GetTeam(),duration,600)
  local dummy_unit_c = FastDummy(origin_c,caster:GetTeam(),duration,600)

  ability:ApplyDataDrivenThinker(caster, origin_b, "extra_black_hole", {})
  ability:ApplyDataDrivenThinker(caster, origin_c, "extra_black_hole", {}) 
end


function abyssal_vortex_aura(event)
  local caster = event.caster
  local target = event.target
  local target_pos = target:GetAbsOrigin()
  local radius = event.radius
  local pull_speed = event.pull_speed
  
  local damage = event.damage or 150
  local dtype = DAMAGE_TYPE_MAGICAL
  local flags = nil
  if caster:HasScepter() then dtype = DAMAGE_TYPE_PURE flags = DOTA_DAMAGE_FLAG_BYPASSES_MAGIC_IMMUNITY end
  
  local enemy_found = FindUnitsInRadius( caster:GetTeamNumber(),
                              target:GetCenter(),
                              nil,
                                radius,
                                DOTA_UNIT_TARGET_TEAM_ENEMY,
                                DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_CREEP,
                                DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                FIND_CLOSEST,
                                false)
  if not caster:HasScepter() then -- Ignore magic immune units if we don't have Aghanim's Scepter
    for k,v in pairs(enemy_found) do
     if v:IsMagicImmune() then table.remove(enemy_found,k) end
    end
  end
  for k,v in pairs(enemy_found) do
    local direction = (target_pos - v:GetAbsOrigin()):Normalized()
    local distance = 1-((target_pos - v:GetAbsOrigin()):Length2D()/radius)
    local truedistance = distance
    local mindistance = 0.3
    local maxdistance = 0.4
    if distance < mindistance then distance = mindistance end
    if distance > maxdistance then distance = maxdistance end
    if truedistance < 0.98 then
      Physics:Unit(v)
      v:SetPhysicsFriction(0.1)
      v:PreventDI(false)
      
      v:SetPhysicsVelocity(direction * pull_speed * 1.25 * (distance))
    end
    local damage_table = {
      victim = v,
      attacker = caster,
      damage = damage*0.06*truedistance,
      damage_type = dtype,
      damage_flags = flags,
      ability = event.ability
      } 
      ApplyDamage(damage_table)
  end                              
end

function abyssal_vortex_aura_extra(event)
  local caster = event.caster
  local target = event.target
  local target_pos = target:GetAbsOrigin()
  local radius = event.radius
  local pull_speed = event.pull_speed
  
  local damage = event.damage or 150
  local dtype = DAMAGE_TYPE_PHYSICAL
  local flags = nil
  if caster:HasScepter() then dtype = DAMAGE_TYPE_PURE flags = DOTA_DAMAGE_FLAG_BYPASSES_MAGIC_IMMUNITY end
  
  local enemy_found = FindUnitsInRadius( caster:GetTeamNumber(),
                              target:GetCenter(),
                              nil,
                                radius,
                                DOTA_UNIT_TARGET_TEAM_ENEMY,
                                DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_CREEP,
                                DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                FIND_CLOSEST,
                                false)
  if not caster:HasScepter() then -- Ignore magic immune units if we don't have Aghanim's Scepter
    for k,v in pairs(enemy_found) do
     if v:IsMagicImmune() then table.remove(enemy_found,k) end
    end
  end
  for k,v in pairs(enemy_found) do
    local direction = (target_pos - v:GetAbsOrigin()):Normalized()
    local distance = 1-((target_pos - v:GetAbsOrigin()):Length2D()/radius)
    local truedistance = distance
    local mindistance = 0.3
    local maxdistance = 0.4
    if distance < mindistance then distance = mindistance end
    if distance > maxdistance then distance = maxdistance end
    if truedistance < 0.98 then
      Physics:Unit(v)
      v:SetPhysicsFriction(0.1)
      v:PreventDI(false)
      
      v:SetPhysicsVelocity(direction * pull_speed * 1.25 * (distance))
    end
    local damage_table = {
      victim = v,
      attacker = caster,
      damage = damage*0.06*truedistance,
      damage_type = dtype,
      damage_flags = flags,
      ability = event.ability
      } 
      ApplyDamage(damage_table)
  end                              
end


function abyssal_vortex_begin_sound(event)
  local caster = event.caster
  local d = FastDummy(caster:GetAbsOrigin(), caster:GetTeam(), 5, 600)
  caster.dsnd = d
  d:EmitSound("Hero_Enigma.Black_Hole")
end

function abyssal_vortex_stop_sound(event)
  local caster = event.caster
  if caster.dsnd then
    caster.dsnd:StopSound("Hero_Enigma.Black_Hole")
    caster.dsnd:EmitSound("Hero_Enigma.Black_Hole.Stop")
  end
end

function malefice( keys )
  local caster = keys.caster
  local ability = keys.ability
  local ability_level = ability:GetLevel() - 1
  local target = keys.target

  local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
  local tick_rate = ability:GetLevelSpecialValueFor("tick_rate", ability_level)
  local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
  local damage = ability:GetLevelSpecialValueFor("damage", ability_level)

  target:EmitSound("Hero_Enigma.Malefice")

  local time_elapsed = 0
  local time_elapsed_internal = 0

  Timers:CreateTimer(function()
    if time_elapsed < (duration + 1) then

      ability:ApplyDataDrivenModifier(caster, target, "modifier_malefice_stun", {})
      target:EmitSound("Hero_Enigma.MaleficeTick")

      Timers:CreateTimer(function()

        print(time_elapsed)
        print(time_elapsed_internal)

        if time_elapsed_internal < 2 then
          time_elapsed_internal = time_elapsed_internal + 1
          return 1.0
        else
          ability:ApplyDataDrivenModifier(caster, target, "modifier_malefice_stun", {})
          target:EmitSound("Hero_Enigma.MaleficeTick")
          time_elapsed_internal = 0
        end       
      end)
      time_elapsed = time_elapsed + 2
      return 1.0
    end
  end)
end

function Midnight_Pulse( keys )
  local caster = keys.caster
  local ability = keys.ability
  local ability_level = ability:GetLevel() - 1
  local targetted_point = keys.target_points[1]

  local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
  local damage_percent = ability:GetLevelSpecialValueFor("damage_percent", ability_level)
  local duration = ability:GetLevelSpecialValueFor("duration", ability_level)

  local current_duration = 0

  local dummy_unit = FastDummy(targetted_point,caster:GetTeam(),duration,600)

  --create particles
  MidnightPulseFx = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_midnight_pulse.vpcf", PATTACH_CUSTOMORIGIN, dummy_unit)
  ParticleManager:SetParticleControl(MidnightPulseFx, 0, targetted_point)
  ParticleManager:SetParticleControl(MidnightPulseFx, 1, Vector(radius, 0, 0))

  local enemies_in_range = FindUnitsInRadius(caster:GetTeamNumber(),targetted_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
  local friends_in_range = FindUnitsInRadius(caster:GetTeamNumber(),targetted_point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

  Timers:CreateTimer(function()
    if current_duration < duration then

      local enemies_in_range = FindUnitsInRadius(caster:GetTeamNumber(),targetted_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
      local friends_in_range = FindUnitsInRadius(caster:GetTeamNumber(),targetted_point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

      for _,enemy in pairs(enemies_in_range) do
        local damage_table = {
          victim = enemy,
          attacker = caster,
          damage = damage_percent,
          damage_type = DAMAGE_TYPE_MAGICAL,
          damage_flags = nil,
          ability = ability
          } 
        ApplyDamage(damage_table)
      end

      for _,friend in pairs(friends_in_range) do
        ability:ApplyDataDrivenModifier(caster, friend, "modifier_midnight_pulse_invis",{})
      end

      current_duration = current_duration + 1

      return 1.0

    else

      dummy_unit:RemoveSelf()
      ParticleManager:DestroyParticle(MidnightPulseFx, false)
      for _,friend in pairs(friends_in_range) do
        friend:RemoveModifierByName("modifier_midnight_pulse_invis")
      end
    end
  end)
end




