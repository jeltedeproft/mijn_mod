--[[ 	Authors: Pizzalol and D2imba
		Date: 10.07.2015				]]

function HookCast( keys )
	local caster = keys.caster
	local target = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_cast_check = keys.modifier_cast_check

	-- Parameters
	local base_range = ability:GetLevelSpecialValueFor("base_range", ability_level)
	local cast_distance = ( target - caster:GetAbsOrigin() ):Length2D()
	caster.stop_hook_cast = nil

	-- Calculate actual cast range
	local hook_range = base_range

	-- Check if the target point is inside range, if not, stop casting and move closer
	if cast_distance > hook_range then

		-- Start moving
		caster:MoveToPosition(target)
		Timers:CreateTimer(0.1, function()

			-- Update distance and range
			cast_distance = ( target - caster:GetAbsOrigin() ):Length2D()
			hook_range = base_range

			-- If it's not a legal cast situation and no other order was given, keep moving
			if cast_distance > hook_range and not caster.stop_hook_cast then
				return 0.1
			-- If another order was given, stop tracking the cast distance
			elseif caster.stop_hook_cast then
				caster:RemoveModifierByName(modifier_cast_check)
				caster.stop_hook_cast = nil

			-- If all conditions are met, cast Hook again
			else
				caster:CastAbilityOnPosition(target, ability, caster:GetPlayerID())
			end
		end)
		
		return nil		
	end
end

function HookCastCheck( keys )
	
	local caster = keys.caster
	caster.stop_hook_cast = true
	
end

function MeatHook( keys )
	
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local caster_pos = caster:GetAbsOrigin()

	-- If another hook is already out, refund mana cost and do nothing
	if caster.hook_launched then
		caster:GiveMana(ability:GetManaCost(ability_level))
		ability:EndCooldown()
		
		return nil
	end

	-- Set the global hook_launched variable
	caster.hook_launched = true

	-- Sound, particle and modifier keys
	local sound_extend = keys.sound_extend
	local sound_hit = keys.sound_hit
	local sound_scepter_hit = keys.sound_scepter_hit
	local sound_retract = keys.sound_retract
	local sound_retract_stop = keys.sound_retract_stop
	local particle_hook = keys.particle_hook
	local particle_hit = keys.particle_hit
	local particle_hit_scepter = keys.particle_hit_scepter
	local modifier_caster = keys.modifier_caster
	local modifier_target_enemy = keys.modifier_target_enemy
	local modifier_target_ally = keys.modifier_target_ally
	local modifier_dummy = keys.modifier_dummy

	
	-- Parameters
	local scepter = HasScepter(caster)
	local base_speed = ability:GetLevelSpecialValueFor("base_speed", ability_level)
	local hook_width = ability:GetLevelSpecialValueFor("hook_width", ability_level)
	local base_range = ability:GetLevelSpecialValueFor("base_range", ability_level)
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local vision_radius = ability:GetLevelSpecialValueFor("vision_radius", ability_level)
	local vision_duration = ability:GetLevelSpecialValueFor("vision_duration", ability_level)
	local damage_scepter = ability:GetLevelSpecialValueFor("damage_scepter", ability_level)
	local caster_loc = caster:GetAbsOrigin()
	local start_loc = caster_loc + caster:GetForwardVector() * hook_width

	local hook_direction2 = (RotatePosition(caster_pos, QAngle(0, 45, 0), caster_pos + caster:GetForwardVector()) - caster_pos):Normalized()
	local hook_direction3 = (RotatePosition(caster_pos, QAngle(0, -45, 0), caster_pos + caster:GetForwardVector()) - caster_pos):Normalized()
	local hook_direction4 = (RotatePosition(caster_pos, QAngle(0, 90, 0), caster_pos + caster:GetForwardVector()) - caster_pos):Normalized()
	local hook_direction5 = (RotatePosition(caster_pos, QAngle(0, -90, 0), caster_pos + caster:GetForwardVector()) - caster_pos):Normalized()
	local hook_direction6 = (RotatePosition(caster_pos, QAngle(0,135, 0), caster_pos + caster:GetForwardVector()) - caster_pos):Normalized()

	-- Calculate range, speed, and damage

	local hook_speed = base_speed
	local hook_speed2 = base_speed
	local hook_speed3 = base_speed
	local hook_speed4 = base_speed
	local hook_speed5 = base_speed
	local hook_speed6 = base_speed
	local hook_range = base_range
	local hook_damage = base_damage

	-- Stun the caster for the hook duration
	ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})

	-- Play Hook launch sound
	caster:EmitSound(sound_extend)

	-- Create and set up the Hook dummy unit
	local hook_dummy = CreateUnitByName("npc_dummy_blank", start_loc, false, caster, caster, caster:GetTeam())
	hook_dummy:AddNewModifier(caster, nil, "modifier_phased", {})
	ability:ApplyDataDrivenModifier(caster, hook_dummy, modifier_dummy, {})
	hook_dummy:SetForwardVector(caster:GetForwardVector())

	-- Make the hook always visible to both teams
	caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, hook_range / hook_speed)
	caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, hook_range / hook_speed)
	
	-- Attach the Hook particle
	local hook_pfx = ParticleManager:CreateParticle(particle_hook, PATTACH_RENDERORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleAlwaysSimulate(hook_pfx)
	ParticleManager:SetParticleControlEnt(hook_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", caster_loc, true)
	ParticleManager:SetParticleControl(hook_pfx, 1, start_loc)
	ParticleManager:SetParticleControl(hook_pfx, 2, Vector(hook_speed, hook_range, hook_width) )
	ParticleManager:SetParticleControlEnt(hook_pfx, 6, hook_dummy, 5, "attach_hitloc", start_loc, false)
	ParticleManager:SetParticleControlEnt(hook_pfx, 7, caster, PATTACH_CUSTOMORIGIN, nil, caster_loc, true)

	-- Remove the caster's hook
	local weapon_hook = caster:GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
	if weapon_hook ~= nil then
		weapon_hook:AddEffects( EF_NODRAW )
	end

	-- Initialize Hook variables
	local hook_loc = start_loc
	local tick_rate = 0.03
	hook_speed = hook_speed * tick_rate

	local travel_distance = (hook_loc - caster_loc):Length2D()
	local hook_step = caster:GetForwardVector() * hook_speed

	local target_hit = false
	local target

	-- Main Hook loop
	Timers:CreateTimer(tick_rate, function()

		-- Check for valid units in the area
		local units = FindUnitsInRadius(caster:GetTeamNumber(), hook_loc, nil, hook_width, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
		for _,unit in pairs(units) do
			if unit ~= caster and unit ~= hook_dummy and not unit:IsAncient() then
				target_hit = true
				target = unit
				break
			end
		end

		-- If a valid target was hit, start dragging them
		if target_hit then

			-- Apply stun/root modifier, and damage if the target is an enemy
			if caster:GetTeam() == target:GetTeam() then
				ability:ApplyDataDrivenModifier(caster, target, modifier_target_ally, {})
			else
				ability:ApplyDataDrivenModifier(caster, target, modifier_target_enemy, {})
				ApplyDamage({attacker = caster, victim = target, ability = ability, damage = hook_damage, damage_type = DAMAGE_TYPE_PURE})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, hook_damage, nil)
			end

			-- Play the hit sound and particle
			target:EmitSound(sound_hit)
			local hook_pfx = ParticleManager:CreateParticle(particle_hit, PATTACH_ABSORIGIN_FOLLOW, target)

			-- If Pudge has scepter, play the Rupture sound effect
			if scepter and target:GetTeam() ~= caster:GetTeam() then
				target:EmitSound(sound_scepter_hit)
			end

			-- Grant vision on the hook hit area
			ability:CreateVisibilityNode(hook_loc, vision_radius, vision_duration)
		end

		-- If no target was hit and the maximum range is not reached, move the hook and keep going
		if not target_hit and travel_distance < hook_range then

			-- Move the hook
			hook_dummy:SetAbsOrigin(hook_loc + hook_step)

			-- Recalculate position and distance
			hook_loc = hook_dummy:GetAbsOrigin()
			travel_distance = (hook_loc - caster_loc):Length2D()
			return tick_rate
		end

		-- If we are here, this means the hook has to start reeling back; prepare return variables
		local direction = ( caster_loc - hook_loc )

		-- Stop the extending sound and start playing the return sound
		caster:StopSound(sound_extend)
		caster:EmitSound(sound_retract)

		-- Remove the caster's self-stun
		caster:RemoveModifierByName(modifier_caster)

		-- Play sound reaction according to which target was hit
		if target_hit and target:IsRealHero() and target:GetTeam() ~= caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_0"..RandomInt(1,9))
		elseif target_hit and target:IsRealHero() and target:GetTeam() == caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_miss_01")
		elseif target_hit then
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(2,6))
		else
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(8,9))
		end

		-- Hook reeling loop
		Timers:CreateTimer(tick_rate, function()

			-- Recalculate position variables
			caster_loc = caster:GetAbsOrigin()
			hook_loc = hook_dummy:GetAbsOrigin()
			direction = ( caster_loc - hook_loc )
			hook_step = direction:Normalized() * hook_speed
			
			-- If the target is close enough, finalize the hook return
			if direction:Length2D() < hook_speed then

				-- Stop moving the target
				if target_hit then
					local final_loc = caster_loc + caster:GetForwardVector() * 100
					FindClearSpaceForUnit(target, final_loc, false)

					-- Remove the target's modifiers
					target:RemoveModifierByName(modifier_target_ally)
					target:RemoveModifierByName(modifier_target_enemy)
				end

				-- Destroy the hook dummy and particles
				hook_dummy:Destroy()
				ParticleManager:DestroyParticle(hook_pfx, false)

				-- Stop playing the reeling sound
				caster:StopSound(sound_retract)
				caster:EmitSound(sound_retract_stop)

				-- Give back the caster's hook
				if weapon_hook ~= nil then
					weapon_hook:RemoveEffects( EF_NODRAW )
				end

				-- Clear global variables
				caster.hook_launched = nil

			-- If this is not the final step, keep reeling the hook in
			else

				-- Move the hook and an eventual target
				hook_dummy:SetAbsOrigin(hook_loc + hook_step)

				if target_hit then
					target:SetAbsOrigin(hook_loc + hook_step)
					target:SetForwardVector(direction:Normalized())
					ability:CreateVisibilityNode(hook_loc, vision_radius, 0.5)

					-- If Pudge has scepter, deal damage on every step
					if scepter and target:GetTeam() ~= caster:GetTeam() then
						local step_damage = damage_scepter * hook_speed / 1000
						ApplyDamage({attacker = caster, victim = target, ability = ability, damage = step_damage, damage_type = DAMAGE_TYPE_PURE})
						local rupture_pfx = ParticleManager:CreateParticle(particle_hit_scepter, PATTACH_ABSORIGIN, target)
					end
				end
				
				return tick_rate
			end
		end)
	end)

	--HOOK NUMBER 2!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	-- Create and set up the Hook dummy unit
	local hook_dummy2 = CreateUnitByName("npc_dummy_blank", caster_pos + hook_direction2, false, caster, caster, caster:GetTeam())
	hook_dummy2:AddNewModifier(caster, nil, "modifier_phased", {})
	ability:ApplyDataDrivenModifier(caster, hook_dummy2, modifier_dummy, {})
	hook_dummy2:SetForwardVector(hook_direction2)

	-- Make the hook always visible to both teams
	caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, hook_range / hook_speed)
	caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, hook_range / hook_speed)
	
	-- Attach the Hook particle
	local hook_pfx2 = ParticleManager:CreateParticle(particle_hook, PATTACH_RENDERORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleAlwaysSimulate(hook_pfx2)
	ParticleManager:SetParticleControlEnt(hook_pfx2, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", caster_loc + hook_direction2, true)
	ParticleManager:SetParticleControl(hook_pfx2, 1, caster_pos + hook_direction2)
	ParticleManager:SetParticleControl(hook_pfx2, 2, Vector(hook_speed2, hook_range, hook_width) )
	ParticleManager:SetParticleControlEnt(hook_pfx2, 6, hook_dummy2, 5, "attach_hitloc", caster_pos + hook_direction2, false)
	ParticleManager:SetParticleControlEnt(hook_pfx2, 7, caster, PATTACH_CUSTOMORIGIN, nil, caster_loc + hook_direction2, true)

	-- Initialize Hook variables
	local hook_loc2 = caster_pos + hook_direction2
	local tick_rate2 = 0.03
	local hook_speed2 = hook_speed2 * tick_rate2

	local travel_distance2 = (hook_loc2 - caster_loc):Length2D()
	local hook_step2 = hook_direction2 * hook_speed2

	local target_hit2 = false
	local target2

	-- Main Hook loop
	Timers:CreateTimer(tick_rate2, function()

		-- Check for valid units in the area
		local units2 = FindUnitsInRadius(caster:GetTeamNumber(), hook_loc2, nil, hook_width, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
		for _,unit in pairs(units2) do
			if unit ~= caster and unit ~= hook_dummy2 and not unit:IsAncient() then
				target_hit2 = true
				target2 = unit
				break
			end
		end

		-- If a valid target was hit, start dragging them
		if target_hit2 then

			-- Apply stun/root modifier, and damage if the target is an enemy
			if caster:GetTeam() == target2:GetTeam() then
				ability:ApplyDataDrivenModifier(caster, target2, modifier_target_ally, {})
			else
				ability:ApplyDataDrivenModifier(caster, target2, modifier_target_enemy, {})
				ApplyDamage({attacker = caster, victim = target2, ability = ability, damage = hook_damage, damage_type = DAMAGE_TYPE_PURE})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target2, hook_damage, nil)
			end

			-- Play the hit sound and particle
			target2:EmitSound(sound_hit)
			local hook_pfx2 = ParticleManager:CreateParticle(particle_hit, PATTACH_ABSORIGIN_FOLLOW, target2)

			-- If Pudge has scepter, play the Rupture sound effect
			if scepter and target2:GetTeam() ~= caster:GetTeam() then
				target2:EmitSound(sound_scepter_hit)
			end

			-- Grant vision on the hook hit area
			ability:CreateVisibilityNode(hook_loc2, vision_radius, vision_duration)
		end

		-- If no target was hit and the maximum range is not reached, move the hook and keep going
		if not target_hit2 and travel_distance2 < hook_range then
			-- Move the hook
			hook_dummy2:SetAbsOrigin(hook_loc2 + hook_step2)

			-- Recalculate position and distance
			hook_loc2 = hook_dummy2:GetAbsOrigin()
			travel_distance2 = (hook_loc2 - caster_loc):Length2D()
			return tick_rate2
		end

		-- If we are here, this means the hook has to start reeling back; prepare return variables
		local direction2 = ( caster_loc - hook_loc2 )

		-- Stop the extending sound and start playing the return sound
		caster:StopSound(sound_extend)
		caster:EmitSound(sound_retract)

		-- Remove the caster's self-stun
		caster:RemoveModifierByName(modifier_caster)

		-- Play sound reaction according to which target was hit
		if target_hit2 and target2:IsRealHero() and target2:GetTeam() ~= caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_0"..RandomInt(1,9))
		elseif target_hit2 and target2:IsRealHero() and target2:GetTeam() == caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_miss_01")
		elseif target_hit2 then
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(2,6))
		else
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(8,9))
		end

		-- Hook reeling loop
		Timers:CreateTimer(tick_rate2, function()

			-- Recalculate position variables
			caster_loc = caster:GetAbsOrigin()
			hook_loc2 = hook_dummy2:GetAbsOrigin()
			direction2 = ( caster_loc - hook_loc2 )
			hook_step2 = direction2:Normalized() * hook_speed2
			
			-- If the target is close enough, finalize the hook return
			if direction2:Length2D() < hook_speed2 then

				-- Stop moving the target
				if target_hit2 then
					local final_loc2 = caster_loc + hook_direction2 * 100
					FindClearSpaceForUnit(target2, final_loc2, false)

					-- Remove the target's modifiers
					target2:RemoveModifierByName(modifier_target_ally)
					target2:RemoveModifierByName(modifier_target_enemy)
				end

				-- Destroy the hook dummy and particles
				hook_dummy2:Destroy()
				ParticleManager:DestroyParticle(hook_pfx2, false)

				-- Stop playing the reeling sound
				caster:StopSound(sound_retract)
				caster:EmitSound(sound_retract_stop)

				-- Give back the caster's hook
				if weapon_hook2 ~= nil then
					weapon_hook2:RemoveEffects( EF_NODRAW )
				end

				-- Clear global variables
				caster.hook_launched = nil

			-- If this is not the final step, keep reeling the hook in
			else

				-- Move the hook and an eventual target
				hook_dummy2:SetAbsOrigin(hook_loc2 + hook_step2)

				if target_hit2 then
					target2:SetAbsOrigin(hook_loc2 + hook_step2)
					target2:SetForwardVector(direction2:Normalized())
					ability:CreateVisibilityNode(hook_loc2, vision_radius, 0.5)

					-- If Pudge has scepter, deal damage on every step
					if scepter and target2:GetTeam() ~= caster:GetTeam() then
						local step_damage2 = damage_scepter * hook_speed2 / 1000
						ApplyDamage({attacker = caster, victim = target2, ability = ability, damage = step_damage2, damage_type = DAMAGE_TYPE_PURE})
						local rupture_pfx2 = ParticleManager:CreateParticle(particle_hit_scepter, PATTACH_ABSORIGIN, target)
					end
				end
				
				return tick_rate2
			end
		end)
	end)

--HOOK NUMBER 3!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	-- Create and set up the Hook dummy unit
	local hook_dummy3 = CreateUnitByName("npc_dummy_blank", caster_pos + hook_direction3, false, caster, caster, caster:GetTeam())
	hook_dummy3:AddNewModifier(caster, nil, "modifier_phased", {})
	ability:ApplyDataDrivenModifier(caster, hook_dummy3, modifier_dummy, {})
	hook_dummy3:SetForwardVector(hook_direction3)

	-- Make the hook always visible to both teams
	caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, hook_range / hook_speed)
	caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, hook_range / hook_speed)
	
	-- Attach the Hook particle
	local hook_pfx3 = ParticleManager:CreateParticle(particle_hook, PATTACH_RENDERORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleAlwaysSimulate(hook_pfx3)
	ParticleManager:SetParticleControlEnt(hook_pfx3, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", caster_loc + hook_direction3, true)
	ParticleManager:SetParticleControl(hook_pfx3, 1, caster_pos + hook_direction3)
	ParticleManager:SetParticleControl(hook_pfx3, 2, Vector(hook_speed3, hook_range, hook_width) )
	ParticleManager:SetParticleControlEnt(hook_pfx3, 6, hook_dummy3, 5, "attach_hitloc", caster_pos + hook_direction3, false)
	ParticleManager:SetParticleControlEnt(hook_pfx3, 7, caster, PATTACH_CUSTOMORIGIN, nil, caster_loc + hook_direction3, true)

	-- Initialize Hook variables
	local hook_loc3 = caster_pos + hook_direction3
	local tick_rate3 = 0.03
	local hook_speed3 = hook_speed3 * tick_rate3

	local travel_distance3 = (hook_loc3 - caster_loc):Length2D()
	local hook_step3 = hook_direction3 * hook_speed3

	local target_hit3 = false
	local target3

	-- Main Hook loop
	Timers:CreateTimer(tick_rate3, function()

		-- Check for valid units in the area
		local units3 = FindUnitsInRadius(caster:GetTeamNumber(), hook_loc3, nil, hook_width, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
		for _,unit in pairs(units3) do
			if unit ~= caster and unit ~= hook_dummy3 and not unit:IsAncient() then
				target_hit3 = true
				target3 = unit
				break
			end
		end

		-- If a valid target was hit, start dragging them
		if target_hit3 then

			-- Apply stun/root modifier, and damage if the target is an enemy
			if caster:GetTeam() == target3:GetTeam() then
				ability:ApplyDataDrivenModifier(caster, target3, modifier_target_ally, {})
			else
				ability:ApplyDataDrivenModifier(caster, target3, modifier_target_enemy, {})
				ApplyDamage({attacker = caster, victim = target3, ability = ability, damage = hook_damage, damage_type = DAMAGE_TYPE_PURE})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target3, hook_damage, nil)
			end

			-- Play the hit sound and particle
			target3:EmitSound(sound_hit)
			local hook_pfx3 = ParticleManager:CreateParticle(particle_hit, PATTACH_ABSORIGIN_FOLLOW, target3)

			-- If Pudge has scepter, play the Rupture sound effect
			if scepter and target3:GetTeam() ~= caster:GetTeam() then
				target3:EmitSound(sound_scepter_hit)
			end

			-- Grant vision on the hook hit area
			ability:CreateVisibilityNode(hook_loc3, vision_radius, vision_duration)
		end

		-- If no target was hit and the maximum range is not reached, move the hook and keep going
		if not target_hit3 and travel_distance3 < hook_range then
			-- Move the hook
			hook_dummy3:SetAbsOrigin(hook_loc3 + hook_step3)

			-- Recalculate position and distance
			hook_loc3 = hook_dummy3:GetAbsOrigin()
			travel_distance3 = (hook_loc3 - caster_loc):Length2D()
			return tick_rate3
		end

		-- If we are here, this means the hook has to start reeling back; prepare return variables
		local direction3 = ( caster_loc - hook_loc3 )

		-- Stop the extending sound and start playing the return sound
		caster:StopSound(sound_extend)
		caster:EmitSound(sound_retract)

		-- Remove the caster's self-stun
		caster:RemoveModifierByName(modifier_caster)

		-- Play sound reaction according to which target was hit
		if target_hit3 and target3:IsRealHero() and target3:GetTeam() ~= caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_0"..RandomInt(1,9))
		elseif target_hit3 and target3:IsRealHero() and target3:GetTeam() == caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_miss_01")
		elseif target_hit3 then
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(2,6))
		else
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(8,9))
		end

		-- Hook reeling loop
		Timers:CreateTimer(tick_rate3, function()

			-- Recalculate position variables
			caster_loc = caster:GetAbsOrigin()
			hook_loc3 = hook_dummy3:GetAbsOrigin()
			direction3 = ( caster_loc - hook_loc3 )
			hook_step3 = direction3:Normalized() * hook_speed3
			
			-- If the target is close enough, finalize the hook return
			if direction3:Length2D() < hook_speed3 then

				-- Stop moving the target
				if target_hit3 then
					local final_loc3 = caster_loc + hook_direction3 * 100
					FindClearSpaceForUnit(target3, final_loc3, false)

					-- Remove the target's modifiers
					target3:RemoveModifierByName(modifier_target_ally)
					target3:RemoveModifierByName(modifier_target_enemy)
				end

				-- Destroy the hook dummy and particles
				hook_dummy3:Destroy()
				ParticleManager:DestroyParticle(hook_pfx3, false)

				-- Stop playing the reeling sound
				caster:StopSound(sound_retract)
				caster:EmitSound(sound_retract_stop)

				-- Give back the caster's hook
				if weapon_hook3 ~= nil then
					weapon_hook3:RemoveEffects( EF_NODRAW )
				end

				-- Clear global variables
				caster.hook_launched = nil

			-- If this is not the final step, keep reeling the hook in
			else

				-- Move the hook and an eventual target
				hook_dummy3:SetAbsOrigin(hook_loc3 + hook_step3)

				if target_hit3 then
					target3:SetAbsOrigin(hook_loc3 + hook_step3)
					target3:SetForwardVector(direction3:Normalized())
					ability:CreateVisibilityNode(hook_loc3, vision_radius, 0.5)

					-- If Pudge has scepter, deal damage on every step
					if scepter and target3:GetTeam() ~= caster:GetTeam() then
						local step_damage3 = damage_scepter * hook_speed3 / 1000
						ApplyDamage({attacker = caster, victim = target3, ability = ability, damage = step_damage3, damage_type = DAMAGE_TYPE_PURE})
						local rupture_pfx3 = ParticleManager:CreateParticle(particle_hit_scepter, PATTACH_ABSORIGIN, target)
					end
				end
				
				return tick_rate3
			end
		end)
	end)

--HOOK NUMBER 4!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	-- Create and set up the Hook dummy unit
	local hook_dummy4 = CreateUnitByName("npc_dummy_blank", caster_pos + hook_direction2, false, caster, caster, caster:GetTeam())
	hook_dummy4:AddNewModifier(caster, nil, "modifier_phased", {})
	ability:ApplyDataDrivenModifier(caster, hook_dummy4, modifier_dummy, {})
	hook_dummy4:SetForwardVector(hook_direction4)

	-- Make the hook always visible to both teams
	caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, hook_range / hook_speed)
	caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, hook_range / hook_speed)
	
	-- Attach the Hook particle
	local hook_pfx4 = ParticleManager:CreateParticle(particle_hook, PATTACH_RENDERORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleAlwaysSimulate(hook_pfx4)
	ParticleManager:SetParticleControlEnt(hook_pfx4, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", caster_loc + hook_direction4, true)
	ParticleManager:SetParticleControl(hook_pfx4, 1, caster_pos + hook_direction4)
	ParticleManager:SetParticleControl(hook_pfx4, 2, Vector(hook_speed4, hook_range, hook_width) )
	ParticleManager:SetParticleControlEnt(hook_pfx4, 6, hook_dummy4, 5, "attach_hitloc", caster_pos + hook_direction4, false)
	ParticleManager:SetParticleControlEnt(hook_pfx4, 7, caster, PATTACH_CUSTOMORIGIN, nil, caster_loc + hook_direction4, true)

	-- Initialize Hook variables
	local hook_loc4 = caster_pos + hook_direction4
	local tick_rate4 = 0.03
	local hook_speed4 = hook_speed4 * tick_rate4

	local travel_distance4 = (hook_loc4 - caster_loc):Length2D()
	local hook_step4 = hook_direction4 * hook_speed4

	local target_hit4 = false
	local target4

	-- Main Hook loop
	Timers:CreateTimer(tick_rate4, function()

		-- Check for valid units in the area
		local units4 = FindUnitsInRadius(caster:GetTeamNumber(), hook_loc4, nil, hook_width, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
		for _,unit in pairs(units4) do
			if unit ~= caster and unit ~= hook_dummy4 and not unit:IsAncient() then
				target_hit4 = true
				target4 = unit
				break
			end
		end

		-- If a valid target was hit, start dragging them
		if target_hit4 then

			-- Apply stun/root modifier, and damage if the target is an enemy
			if caster:GetTeam() == target4:GetTeam() then
				ability:ApplyDataDrivenModifier(caster, target4, modifier_target_ally, {})
			else
				ability:ApplyDataDrivenModifier(caster, target4, modifier_target_enemy, {})
				ApplyDamage({attacker = caster, victim = target4, ability = ability, damage = hook_damage, damage_type = DAMAGE_TYPE_PURE})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target4, hook_damage, nil)
			end

			-- Play the hit sound and particle
			target4:EmitSound(sound_hit)
			local hook_pfx4 = ParticleManager:CreateParticle(particle_hit, PATTACH_ABSORIGIN_FOLLOW, target4)

			-- If Pudge has scepter, play the Rupture sound effect
			if scepter and target4:GetTeam() ~= caster:GetTeam() then
				target4:EmitSound(sound_scepter_hit)
			end

			-- Grant vision on the hook hit area
			ability:CreateVisibilityNode(hook_loc4, vision_radius, vision_duration)
		end

		-- If no target was hit and the maximum range is not reached, move the hook and keep going
		if not target_hit4 and travel_distance4 < hook_range then
			-- Move the hook
			hook_dummy4:SetAbsOrigin(hook_loc4 + hook_step4)

			-- Recalculate position and distance
			hook_loc4 = hook_dummy4:GetAbsOrigin()
			travel_distance4 = (hook_loc4 - caster_loc):Length2D()
			return tick_rate4
		end

		-- If we are here, this means the hook has to start reeling back; prepare return variables
		local direction4 = ( caster_loc - hook_loc4 )

		-- Stop the extending sound and start playing the return sound
		caster:StopSound(sound_extend)
		caster:EmitSound(sound_retract)

		-- Remove the caster's self-stun
		caster:RemoveModifierByName(modifier_caster)

		-- Play sound reaction according to which target was hit
		if target_hit4 and target4:IsRealHero() and target4:GetTeam() ~= caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_0"..RandomInt(1,9))
		elseif target_hit4 and target4:IsRealHero() and target4:GetTeam() == caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_miss_01")
		elseif target_hit4 then
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(2,6))
		else
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(8,9))
		end

		-- Hook reeling loop
		Timers:CreateTimer(tick_rate4, function()

			-- Recalculate position variables
			caster_loc = caster:GetAbsOrigin()
			hook_loc4 = hook_dummy4:GetAbsOrigin()
			direction4 = ( caster_loc - hook_loc4 )
			hook_step4 = direction4:Normalized() * hook_speed4
			
			-- If the target is close enough, finalize the hook return
			if direction4:Length2D() < hook_speed4 then

				-- Stop moving the target
				if target_hit4 then
					local final_loc4 = caster_loc + hook_direction4 * 100
					FindClearSpaceForUnit(target4, final_loc4, false)

					-- Remove the target's modifiers
					target4:RemoveModifierByName(modifier_target_ally)
					target4:RemoveModifierByName(modifier_target_enemy)
				end

				-- Destroy the hook dummy and particles
				hook_dummy4:Destroy()
				ParticleManager:DestroyParticle(hook_pfx4, false)

				-- Stop playing the reeling sound
				caster:StopSound(sound_retract)
				caster:EmitSound(sound_retract_stop)

				-- Give back the caster's hook
				if weapon_hook4 ~= nil then
					weapon_hook4:RemoveEffects( EF_NODRAW )
				end

				-- Clear global variables
				caster.hook_launched = nil

			-- If this is not the final step, keep reeling the hook in
			else

				-- Move the hook and an eventual target
				hook_dummy4:SetAbsOrigin(hook_loc4 + hook_step4)

				if target_hit4 then
					target4:SetAbsOrigin(hook_loc4 + hook_step4)
					target4:SetForwardVector(direction4:Normalized())
					ability:CreateVisibilityNode(hook_loc4, vision_radius, 0.5)

					-- If Pudge has scepter, deal damage on every step
					if scepter and target4:GetTeam() ~= caster:GetTeam() then
						local step_damage4 = damage_scepter * hook_speed4 / 1000
						ApplyDamage({attacker = caster, victim = target4, ability = ability, damage = step_damage4, damage_type = DAMAGE_TYPE_PURE})
						local rupture_pfx4 = ParticleManager:CreateParticle(particle_hit_scepter, PATTACH_ABSORIGIN, target)
					end
				end
				
				return tick_rate4
			end
		end)
	end)

--HOOK NUMBER 5!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	-- Create and set up the Hook dummy unit
	local hook_dummy5 = CreateUnitByName("npc_dummy_blank", caster_pos + hook_direction5, false, caster, caster, caster:GetTeam())
	hook_dummy5:AddNewModifier(caster, nil, "modifier_phased", {})
	ability:ApplyDataDrivenModifier(caster, hook_dummy5, modifier_dummy, {})
	hook_dummy5:SetForwardVector(hook_direction5)

	-- Make the hook always visible to both teams
	caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, hook_range / hook_speed)
	caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, hook_range / hook_speed)
	
	-- Attach the Hook particle
	local hook_pfx5 = ParticleManager:CreateParticle(particle_hook, PATTACH_RENDERORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleAlwaysSimulate(hook_pfx5)
	ParticleManager:SetParticleControlEnt(hook_pfx5, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", caster_loc + hook_direction5, true)
	ParticleManager:SetParticleControl(hook_pfx5, 1, caster_pos + hook_direction5)
	ParticleManager:SetParticleControl(hook_pfx5, 2, Vector(hook_speed5, hook_range, hook_width) )
	ParticleManager:SetParticleControlEnt(hook_pfx5, 6, hook_dummy5, 5, "attach_hitloc", caster_pos + hook_direction5, false)
	ParticleManager:SetParticleControlEnt(hook_pfx5, 7, caster, PATTACH_CUSTOMORIGIN, nil, caster_loc + hook_direction5, true)

	-- Initialize Hook variables
	local hook_loc5 = caster_pos + hook_direction5
	local tick_rate5 = 0.03
	local hook_speed5 = hook_speed5 * tick_rate5

	local travel_distance5 = (hook_loc5 - caster_loc):Length2D()
	local hook_step5 = hook_direction5 * hook_speed5

	local target_hit5 = false
	local target5

	-- Main Hook loop
	Timers:CreateTimer(tick_rate5, function()

		-- Check for valid units in the area
		local units5 = FindUnitsInRadius(caster:GetTeamNumber(), hook_loc5, nil, hook_width, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
		for _,unit in pairs(units5) do
			if unit ~= caster and unit ~= hook_dummy5 and not unit:IsAncient() then
				target_hit5 = true
				target5 = unit
				break
			end
		end

		-- If a valid target was hit, start dragging them
		if target_hit5 then

			-- Apply stun/root modifier, and damage if the target is an enemy
			if caster:GetTeam() == target5:GetTeam() then
				ability:ApplyDataDrivenModifier(caster, target5, modifier_target_ally, {})
			else
				ability:ApplyDataDrivenModifier(caster, target5, modifier_target_enemy, {})
				ApplyDamage({attacker = caster, victim = target5, ability = ability, damage = hook_damage, damage_type = DAMAGE_TYPE_PURE})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target5, hook_damage, nil)
			end

			-- Play the hit sound and particle
			target5:EmitSound(sound_hit)
			local hook_pfx5 = ParticleManager:CreateParticle(particle_hit, PATTACH_ABSORIGIN_FOLLOW, target5)

			-- If Pudge has scepter, play the Rupture sound effect
			if scepter and target5:GetTeam() ~= caster:GetTeam() then
				target5:EmitSound(sound_scepter_hit)
			end

			-- Grant vision on the hook hit area
			ability:CreateVisibilityNode(hook_loc5, vision_radius, vision_duration)
		end

		-- If no target was hit and the maximum range is not reached, move the hook and keep going
		if not target_hit5 and travel_distance5 < hook_range then
			-- Move the hook
			hook_dummy5:SetAbsOrigin(hook_loc5 + hook_step5)

			-- Recalculate position and distance
			hook_loc5 = hook_dummy5:GetAbsOrigin()
			travel_distance5 = (hook_loc5 - caster_loc):Length2D()
			return tick_rate5
		end

		-- If we are here, this means the hook has to start reeling back; prepare return variables
		local direction5 = ( caster_loc - hook_loc5 )

		-- Stop the extending sound and start playing the return sound
		caster:StopSound(sound_extend)
		caster:EmitSound(sound_retract)

		-- Remove the caster's self-stun
		caster:RemoveModifierByName(modifier_caster)

		-- Play sound reaction according to which target was hit
		if target_hit5 and target5:IsRealHero() and target5:GetTeam() ~= caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_0"..RandomInt(1,9))
		elseif target_hit5 and target5:IsRealHero() and target5:GetTeam() == caster:GetTeam() then
			caster:EmitSound("pudge_pud_ability_hook_miss_01")
		elseif target_hit5 then
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(2,6))
		else
			caster:EmitSound("pudge_pud_ability_hook_miss_0"..RandomInt(8,9))
		end

		-- Hook reeling loop
		Timers:CreateTimer(tick_rate5, function()

			-- Recalculate position variables
			caster_loc = caster:GetAbsOrigin()
			hook_loc5 = hook_dummy5:GetAbsOrigin()
			direction5 = ( caster_loc - hook_loc5 )
			hook_step5 = direction5:Normalized() * hook_speed5
			
			-- If the target is close enough, finalize the hook return
			if direction5:Length2D() < hook_speed5 then

				-- Stop moving the target
				if target_hit5 then
					local final_loc5 = caster_loc + hook_direction5 * 100
					FindClearSpaceForUnit(target5, final_loc5, false)

					-- Remove the target's modifiers
					target5:RemoveModifierByName(modifier_target_ally)
					target5:RemoveModifierByName(modifier_target_enemy)
				end

				-- Destroy the hook dummy and particles
				hook_dummy5:Destroy()
				ParticleManager:DestroyParticle(hook_pfx5, false)

				-- Stop playing the reeling sound
				caster:StopSound(sound_retract)
				caster:EmitSound(sound_retract_stop)

				-- Give back the caster's hook
				if weapon_hook5 ~= nil then
					weapon_hook5:RemoveEffects( EF_NODRAW )
				end

				-- Clear global variables
				caster.hook_launched = nil

			-- If this is not the final step, keep reeling the hook in
			else

				-- Move the hook and an eventual target
				hook_dummy5:SetAbsOrigin(hook_loc5 + hook_step5)

				if target_hit5 then
					target5:SetAbsOrigin(hook_loc5 + hook_step5)
					target5:SetForwardVector(direction5:Normalized())
					ability:CreateVisibilityNode(hook_loc5, vision_radius, 0.5)

					-- If Pudge has scepter, deal damage on every step
					if scepter and target5:GetTeam() ~= caster:GetTeam() then
						local step_damage5 = damage_scepter * hook_speed5 / 1000
						ApplyDamage({attacker = caster, victim = target5, ability = ability, damage = step_damage5, damage_type = DAMAGE_TYPE_PURE})
						local rupture_pfx5 = ParticleManager:CreateParticle(particle_hit_scepter, PATTACH_ABSORIGIN, target)
					end
				end
				
				return tick_rate5
			end
		end)
	end)
end


function Rot( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_slow= keys.modifier_slow
	local modifier_heap = keys.modifier_heap

	-- Parameters
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local stack_damage = ability:GetLevelSpecialValueFor("stack_damage", ability_level)
	local base_radius = ability:GetLevelSpecialValueFor("base_radius", ability_level)
	local stack_radius = ability:GetLevelSpecialValueFor("stack_radius", ability_level)
	local max_stacks = ability:GetLevelSpecialValueFor("max_stacks", ability_level)
	local rot_tick = ability:GetLevelSpecialValueFor("rot_tick", ability_level)

	-- Retrieve flesh heap stacks
	local heap_stacks = 0
	if caster:HasModifier(modifier_heap) then
		heap_stacks = math.min(caster:GetModifierStackCount(modifier_heap, caster), max_stacks)
	end

	-- Calculate damage and radius
	local damage = base_damage * ( ( 100 + heap_stacks * stack_damage ) * rot_tick ) / 100
	local radius = base_radius + stack_radius * heap_stacks

	-- Damage the caster
	ApplyDamage({attacker = caster, victim = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})

	-- Deal damage and apply slow
	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,unit in pairs(units) do
		ApplyDamage({attacker = caster, victim = unit, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
		ability:ApplyDataDrivenModifier(caster, unit, modifier_slow, {})
	end
end

function RotParticle( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_heap = keys.modifier_heap
	local rot_particle= keys.rot_particle

	-- Parameters
	local base_radius = ability:GetLevelSpecialValueFor("base_radius", ability_level)
	local stack_radius = ability:GetLevelSpecialValueFor("stack_radius", ability_level)
	local max_stacks = ability:GetLevelSpecialValueFor("max_stacks", ability_level)

	-- Retrieve flesh heap stacks
	local heap_stacks = 0
	if caster:HasModifier(modifier_heap) then
		heap_stacks = math.min(caster:GetModifierStackCount(modifier_heap, caster), max_stacks)
	end

	-- Calculate radius
	local radius = base_radius + stack_radius * heap_stacks

	-- Draw the particle
	caster.rot_fx = ParticleManager:CreateParticle(rot_particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(caster.rot_fx, 0, caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl(caster.rot_fx, 1, Vector(radius,0,0) )
end

function RotResponse( keys )
	local caster = keys.caster

	-- Play pudge's voice reaction
	local random_int = RandomInt(7,13)
	if random_int < 10 then
		caster:EmitSound("pudge_pud_ability_rot_0"..random_int)
	else
		caster:EmitSound("pudge_pud_ability_rot_"..random_int)
	end
end

function RotEnd( keys )
	local caster = keys.caster
	local rot_sound = keys.rot_sound

	StopSoundEvent(rot_sound, caster)
	ParticleManager:DestroyParticle(caster.rot_fx, false)
end

function FleshHeapUpgrade( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_resist = keys.modifier_resist
	local modifier_stacks = keys.modifier_stacks

	-- Parameters
	local stack_scale_up = ability:GetLevelSpecialValueFor("stack_scale_up", ability_level)
	local max_stacks = ability:GetLevelSpecialValueFor("max_stacks", ability_level)
	local stack_amount
	local resist_amount

	-- If Heap is already learned, fetch the current amount of stacks
	if caster.heap_stacks then
		stack_amount = caster.heap_stacks
		resist_amount = caster.heap_resist_stacks

	-- Else, fetch kills/assists up to this point of the game (lazy way to make Heap retroactive)
	else
		local assists = caster:GetAssists()
		local kills = caster:GetKills()	
		stack_amount = kills + assists
		resist_amount = math.min(stack_amount, max_stacks)

		-- Define the global variables which keep track of heap stacks
		caster.heap_stacks = stack_amount
		caster.heap_resist_stacks = resist_amount
	end
	
	-- Remove both modifiers in order to update their bonuses
	caster:RemoveModifierByName(modifier_stacks)
	while caster:HasModifier(modifier_resist) do
		caster:RemoveModifierByName(modifier_resist)
	end

	-- Add stacks of the capped (magic resist) modifier
	for i = 1, resist_amount do
		ability:ApplyDataDrivenModifier(caster, caster, modifier_resist, {})
	end

	-- Add stacks of the uncapped modifier
	AddStacks(ability, caster, caster, modifier_stacks, stack_amount, true)

	-- Update stats
	caster:CalculateStatBonus()

	-- Make pudge GROW
	caster:SetModelScale( math.min( 1 + stack_scale_up * stack_amount / 100, 1.75) )
end

function FleshHeap( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Parameters
	local max_stacks = ability:GetLevelSpecialValueFor("max_stacks", ability_level)

	-- Prevent resist stacks from resetting if the skill is unlearned
	if ability_level == 0 then
		max_stacks = caster.heap_resist_stacks + 1
	end

	-- Update the global heap stacks variable
	caster.heap_stacks = caster.heap_stacks + 1
	caster.heap_resist_stacks = math.min(caster.heap_resist_stacks + 1, max_stacks)

	-- Play pudge's voice reaction
	caster:EmitSound("pudge_pud_ability_heap_0"..RandomInt(1,2))
end

function HeapUpdater( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_resist = keys.modifier_resist
	local modifier_stacks = keys.modifier_stacks

	-- Parameters
	local stack_scale_up = ability:GetLevelSpecialValueFor("stack_scale_up", ability_level)
	local stack_amount = caster:GetModifierStackCount(modifier_stacks, caster)
	local resist_amount = caster:FindAllModifiersByName(modifier_resist)

	-- If the amount of strength stacks has increased, update it
	if caster.heap_stacks > stack_amount and caster:IsAlive() then
		local stacks_missing = caster.heap_stacks - stack_amount

		-- Add the appropriate amount of strength stacks
		AddStacks(ability, caster, caster, modifier_stacks, stacks_missing, true)

		-- Update stats
		caster:CalculateStatBonus()

		-- Make pudge GROW
		caster:SetModelScale( math.min( 1 + stack_scale_up * stack_amount / 100, 1.75) )
	end

	-- If the amount of resist stacks has increased, update it
	if caster.heap_resist_stacks > #resist_amount and caster:IsAlive() then
		local stacks_missing = caster.heap_resist_stacks - #resist_amount

		-- Add the appropriate amount of resist stacks
		for i = 1, stacks_missing do
			ability:ApplyDataDrivenModifier(caster, caster, modifier_resist, {})
		end
	end
end

function Dismember( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local particle_target = keys.particle_target

	-- Parameters
	local dismember_damage = ability:GetLevelSpecialValueFor("dismember_damage", ability_level)
	local strength_damage = ability:GetLevelSpecialValueFor("strength_damage", ability_level)
	local caster_str = caster:GetStrength()

	-- Flag the target as such
	if not caster.dismember_target then
		caster.dismember_target = target
	end

	-- Calculate damage/heal
	local damage = dismember_damage + caster_str * strength_damage / 100

	-- Apply damage/heal
	caster:Heal(damage, caster)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, damage, nil)
	ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})

	-- Play the particle
	local blood_pfx = ParticleManager:CreateParticle(particle_target, PATTACH_ABSORIGIN, target)
end

function DismemberEnd( keys )
	local caster = keys.caster
	local modifier_dismember = keys.modifier_dismember

	-- Remove dismember modifier from the target
	if caster.dismember_target then
		caster.dismember_target:RemoveModifierByName(modifier_dismember)

		-- Reset dismember target
		caster.dismember_target = nil
	end
end