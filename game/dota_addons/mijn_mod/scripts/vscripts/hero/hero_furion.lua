function furion_sprout( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target_points[1]
	local target_unit = keys.target

	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local vision_range = ability:GetLevelSpecialValueFor("vision_range", ability_level)
	local radius_a = ability:GetLevelSpecialValueFor("radius_a", ability_level)
	local radius_b = ability:GetLevelSpecialValueFor("radius_B", ability_level)
	local radius_c = ability:GetLevelSpecialValueFor("radius_C", ability_level)

	if target_unit == nil or ( target ~= nil and ( not target_unit:TriggerSpellAbsorb( keys ) ) ) then
		local vTargetPosition = nil
		if target_unit ~= nil then 
			vTargetPosition = target_unit:GetOrigin()
		else
			vTargetPosition = target
		end

		local r = radius_a 
		local c = math.sqrt( 2 ) * 0.5 * r 
		local x_offset = { -r, -c, 0.0, c, r, c, 0.0, -c }
		local y_offset = { 0.0, c, r, c, 0.0, -c, -r, -c }

		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_sprout.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl( nFXIndex, 0, vTargetPosition )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 0.0, r, 0.0 ) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

		for i = 1,8 do
			CreateTempTree( vTargetPosition + Vector( x_offset[i], y_offset[i], 0.0 ), duration )
		end

		for i = 1,8 do
			ResolveNPCPositions( vTargetPosition + Vector( x_offset[i], y_offset[i], 0.0 ), 64.0 ) --Tree Radius
		end

		AddFOWViewer( caster:GetTeamNumber(), vTargetPosition, vision_range, duration, false )
		EmitSoundOnLocationWithCaster( vTargetPosition, "Hero_Furion.Sprout", caster )

		local r_2 = radius_b
		local c_2 = math.sqrt( 2 ) * 0.5 * r_2
		local d =  0.927 * r_2
		local e = 0.375 * r_2
		local x_offset_2 = { -r_2,-d, -c_2,-e, 0.0, e, c, d , r_2, d , c_2, e , 0.0, -e , -c_2, -d }
		local y_offset_2 = { 0.0,e , c_2, d , r_2, d , c_2, e , 0.0, -e , -c_2, -d , -r_2, -d, -c_2, -e }

		print(r_2)
		print(c_2)
		print("nu volgt 1 - 16")

		for i = 1,16 do
			CreateTempTree( vTargetPosition + Vector( x_offset_2[i], y_offset_2[i], 0.0 ), duration )
			print(x_offset_2[i])
			print(y_offset_2[i])
		end

		for i = 1,16 do
			ResolveNPCPositions( vTargetPosition + Vector( x_offset_2[i], y_offset_2[i], 0.0 ), 64.0 ) --Tree Radius
		end

		local r_3 = radius_c
		local c_3 = math.sqrt( 2 ) * 0.5 * r_3 
		local f = 0.191 * r_3
		local g = 0.982 * r_3
		local h = 0.574 * r_3
		local j = 0.819 * r_3
		local x_offset_3 = { -r_3,-g,-d,-j, -c_3,-h,-e,-f, 0.0,f, e,h, c,j, d ,g, r_3,g, d ,j, c_3,h, e ,f, 0.0,-f, -e ,-h, -c_3,-j, -d,-g }
		local y_offset_3 = { 0.0,f,e ,h, c_3,j, d ,g, r_3,g, d ,j, c_3,h, e ,f, 0.0,-f, -e ,-h, -c_3,-j, -d ,-g, -r_3,-g, -d,-j, -c_3,-h, -e,-f }

		print(r_3)
		print(c_3)
		print("nu volgt 1 - 32")

		for i = 1,32 do
			CreateTempTree( vTargetPosition + Vector( x_offset_3[i], y_offset_3[i], 0.0 ), duration )
			print(x_offset_3[i])
			print(y_offset_3[i])
		end

		for i = 1,32 do
			ResolveNPCPositions( vTargetPosition + Vector( x_offset_3[i], y_offset_3[i], 0.0 ), 64.0 ) --Tree Radius
		end
	end
end

function CheckTrees( keys )
	if keys.ability:GetSpecialValueFor("check_trees_precast") == 1 then
		local caster = keys.caster
		local pID = caster:GetPlayerID()
		local ability = keys.ability
		local point = keys.target_points[1]
		local area_of_effect = ability:GetLevelSpecialValueFor( "area_of_effect", ability:GetLevel() - 1 )

		if GridNav:IsNearbyTree( point, area_of_effect, true ) then
			--print(ability,"Trees found")
		else
			caster:Interrupt()
			FireGamekeys( 'custom_error_show', { player_ID = pID, _error = "Must target a tree." } )
		end
	end
end

--[[
	Author: Noya
	Date: 25.01.2015.
	Latches the tree_cut keys to spawn treants up to the amount of trees destroyed, limited by the ability rank.
]]
function ForceOfNature( keys )
	local caster = keys.caster
	local pID = keys.caster:GetPlayerID()
	local ability = keys.ability
	local point = keys.target_points[1]
	local area_of_effect = ability:GetLevelSpecialValueFor( "area_of_effect", ability:GetLevel() - 1 )
	local max_treants = ability:GetLevelSpecialValueFor( "max_treants", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local unit_name = keys.UnitName

	local trees = GridNav:GetAllTreesAroundPoint( point, area_of_effect, true )
	local nTreeCount = #trees

	-- Reinitialize the trees cut count
	ability.trees_cut = 0
	print(ability.listenerRunning)

	-- Check if listener is already running
	if not ability.listenerRunning then
		ability.listenerRunning = true
		ListenToGameEvent("tree_cut", 
			function( keys )
				ability.trees_cut = ability.trees_cut + 1
				print(ability,"One tree cut")	
			end, 
		nil	)
	end

	-- Play the particle
	local particleName = "particles/units/heroes/hero_furion/furion_force_of_nature_cast.vpcf"
	local particle1 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle1, 0, point )
	ParticleManager:SetParticleControl( particle1, 1, point )
	ParticleManager:SetParticleControl( particle1, 2, Vector(area_of_effect,0,0) )

	-- Create the units on the next frame
	Timers:CreateTimer(0.03,
		function() 
			print(ability.trees_cut)
			local treants_spawned = max_treants
			if nTreeCount < max_treants then
				treants_spawned = nTreeCount
			end

			-- Spawn as many treants as possible
			for i=1,treants_spawned do
				local treant = CreateUnitByName(unit_name, point, true, caster, caster, caster:GetTeamNumber())
				treant:SetControllableByPlayer(pID, true)
				treant:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
				FindClearSpaceForUnit(treant, point, true)
			end
		end
	)
end

function Teleport( keys )
	local caster = keys.caster
	local point = keys.target_points[1]
	
    FindClearSpaceForUnit(caster, point, true)
    caster:Stop() 
    EndTeleport(keys)   
end

function CreateTeleportParticles( keys )
	local caster = keys.caster
	local point = keys.target_points[1]
	local particleName = "particles/units/heroes/hero_furion/furion_teleport_end.vpcf"
	caster.teleportParticle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(caster.teleportParticle, 1, point)	
end

function EndTeleport( keys )
	local caster = keys.caster
	local ability = keys.ability
	local casterOrigin = caster:GetAbsOrigin()
	local player = caster:GetPlayerID()
	local unit_name = caster:GetUnitName()
	local casterAngles = caster:GetAngles()
	local duration = 10
	local outgoingDamage = 40
	local incomingDamage = 100
	ParticleManager:DestroyParticle(caster.teleportParticle, false)
	caster:StopSound("Hero_Furion.Teleport_Grow")
end

function createillusion( keys )
	local caster = keys.caster
	local ability = keys.ability
	local casterOrigin = caster:GetAbsOrigin()
	local player = caster:GetPlayerID()
	local unit_name = caster:GetUnitName()
	local casterAngles = caster:GetAngles()
	local duration = 10
	local outgoingDamage = 40
	local incomingDamage = 100
	local origin = casterOrigin + RandomVector(100)

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
	illusion:SetPlayerID(caster:GetPlayerID())
	illusion:SetControllableByPlayer(player, true)

	illusion:SetAngles( casterAngles.x, casterAngles.y, casterAngles.z )
		
	-- Level Up the unit to the casters level
	local casterLevel = caster:GetLevel()
	for i=1,casterLevel-1 do
		illusion:HeroLevelUp(false)
	end

	-- Set the skill points to 0 and learn the skills of the caster
	illusion:SetAbilityPoints(0)
	for abilitySlot=0,15 do
		local ability = caster:GetAbilityByIndex(abilitySlot)
		if ability ~= nil then 
			local abilityLevel = ability:GetLevel()
			local abilityName = ability:GetAbilityName()
			local illusionAbility = illusion:FindAbilityByName(abilityName)
			illusionAbility:SetLevel(abilityLevel)
		end
	end

	-- Recreate the items of the caster
	for itemSlot=0,5 do
		local item = caster:GetItemInSlot(itemSlot)
		if item ~= nil then
			local itemName = item:GetName()
			local newItem = CreateItem(itemName, illusion, illusion)
			illusion:AddItem(newItem)
		end
	end

	-- Set the unit as an illusion
	-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
	illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
		
	-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
	illusion:MakeIllusion()
	-- Set the illusion hp to be the same as the caster
	illusion:SetHealth(caster:GetHealth())
end


function WrathOfNature( keys )
	local DEBUG = true
	local caster = keys.caster -- the hero
	local target = keys.target_points[1]
	local target_unit = keys.target
	local ability = keys.ability
	local abilityTargetType = ability:GetAbilityTargetType()
	local abilityDamageType = ability:GetAbilityDamageType()

	local max_targets = ability:GetLevelSpecialValueFor("max_targets", ability:GetLevel()-1)
	local damage = ability:GetLevelSpecialValueFor("damage", ability:GetLevel()-1)
	local damage_percent_add = ability:GetSpecialValueFor("damage_percent_add") * 0.01
	local jump_delay = ability:GetSpecialValueFor("jump_delay")
	local particleName = "particles/units/heroes/hero_furion/furion_wrath_of_nature.vpcf"
	-- Control points
	-- CP0 Origin
	-- CP1 Jump1
	-- CP2 Origin2
	-- CP3 Jump2
	-- CP4 Hit


	-- Get the first target
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target, nil, 25000, DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

	if not enemies then
		print("No enemies on the map")
		return
	end

	-- Filter for visible enemies (necessary? desirable?)
	local visible_enemies = {}
	for _,enemy in pairs(enemies) do
		if enemy:CanEntityBeSeenByMyTeam(caster) == true then
			table.insert(visible_enemies, enemy)
		end
	end

	-- Main target first. 
	-- Deal damage and play particle
	local target_number = 1
	local main_target = visible_enemies[target_number]
	local damage_table = {}
	damage_table.victim = main_target
	damage_table.attacker = caster					
	damage_table.damage_type = abilityDamageType
	damage_table.damage = damage

	ApplyDamage(damage_table)
	local targets_hit = 1

	-- Keep track of the previous target to set the particle origin on next jump
	local previous_target = main_target

	-- Do bounces from the main target to closest targets
	Timers:CreateTimer(DoUniqueString("WrathOfNature"), {
		callback = function()
	
			-- Increment target iterator
			target_number = target_number + 1

			-- Jump to this target if its possible
			local next_target = visible_enemies[target_number]
			if next_target and IsValidEntity(next_target) and next_target:CanEntityBeSeenByMyTeam(caster) then

				-- Valid target chosen
				targets_hit = targets_hit + 1

				-- Deal increased damaged
				damage_table.damage = damage_table.damage + (damage * damage_percent_add)
				damage_table.victim = next_target
				ApplyDamage(damage_table)
				if DEBUG then print("Wrath hit Number "..targets_hit..": "..damage_table.victim:GetUnitName().." for "..damage_table.damage) end

				-- Particle and sound
				local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(particle, 0, previous_target, PATTACH_POINT_FOLLOW, "attach_hitloc", previous_target:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 1, next_target, PATTACH_POINT_FOLLOW, "attach_hitloc", next_target:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 2, next_target, PATTACH_POINT_FOLLOW, "attach_hitloc", next_target:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 3, next_target, PATTACH_POINT_FOLLOW, "attach_hitloc", next_target:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 4, next_target, PATTACH_POINT_FOLLOW, "attach_hitloc", next_target:GetAbsOrigin(), true)

				if next_target:IsRealHero() then
					next_target:EmitSound("Hero_Furion.WrathOfNature_Damage")
				else
					next_target:EmitSound("Hero_Furion.WrathOfNature_Damage.Creep")
				end

				-- Fire the timer again if there are jumps left
				if targets_hit < max_targets then
					-- Update the previous target for the next jump
					previous_target = next_target

					return jump_delay
				end
			else
				-- The target is invalid (was killed while the ability was bouncing)
				-- Fire the timer again if there are jumps left, ignoring this bounce
				if targets_hit < max_targets then
					return jump_delay
				else
					if DEBUG then print("Wrath of Nature ends after "..targets_hit.." hits") end
					return
				end
			end
		end
	})
end