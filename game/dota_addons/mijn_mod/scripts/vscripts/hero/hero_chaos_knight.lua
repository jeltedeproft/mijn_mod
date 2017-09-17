function ChaosBolt( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local stun_min = ability:GetLevelSpecialValueFor("stun_min", ability_level)
	local stun_max = ability:GetLevelSpecialValueFor("stun_max", ability_level) 
	local damage_min = ability:GetLevelSpecialValueFor("damage_min", ability_level) 
	local damage_max = ability:GetLevelSpecialValueFor("damage_max", ability_level)
	local chaos_bolt_particle = keys.chaos_bolt_particle

	local casterOrigin = caster:GetAbsOrigin()
	local casterAngles = caster:GetAngles()

	local player = caster:GetPlayerID()
	local unit_name = caster:GetUnitName()
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability_level )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "outgoing_damage", ability_level )
	local incomingDamage = ability:GetLevelSpecialValueFor( "incoming_damage", ability_level )
	local extra_illusion_chance = ability:GetLevelSpecialValueFor("extra_phantasm_chance_pct_tooltip", ability_level)
	local extra_illusion_sound = keys.sound

	-- Calculate the stun and damage values
	local random = RandomFloat(0, 1)
	local stun = stun_min + (stun_max - stun_min) * random
	local damage = damage_min + (damage_max - damage_min) * (1 - random)

	-- Calculate the number of digits needed for the particle
	local stun_digits = string.len(tostring(math.floor(stun))) + 1
	local damage_digits = string.len(tostring(math.floor(damage))) + 1

	-- Create the stun and damage particle for the spell
	local particle = ParticleManager:CreateParticle(chaos_bolt_particle, PATTACH_OVERHEAD_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, target_location) 

	-- Damage particle
	ParticleManager:SetParticleControl(particle, 1, Vector(9,damage,4)) -- prefix symbol, number, postfix symbol
	ParticleManager:SetParticleControl(particle, 2, Vector(2,damage_digits,0)) -- duration, digits, 0

	-- Stun particle
	ParticleManager:SetParticleControl(particle, 3, Vector(8,stun,0)) -- prefix symbol, number, postfix symbol
	ParticleManager:SetParticleControl(particle, 4, Vector(2,stun_digits,0)) -- duration, digits, 0
	ParticleManager:ReleaseParticleIndex(particle)

	-- Apply the stun duration
	target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun})

	-- Initialize the damage table and deal the damage
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.ability = ability
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.damage = damage

	ApplyDamage(damage_table)

	if (random >= 0.5) then
		-- Initialize the illusion table to keep track of the units created by the spell
		if not caster.chaos_bolt_illusion then
			caster.chaos_bolt_illusion = {}
		end

		-- Start a clean illusion table
		caster.chaos_bolt_illusion = {}

		-- Since its an extra illusion then create it at a random point
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
		EmitSoundOn(extra_illusion_sound, caster)

		-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
		table.insert(caster.chaos_bolt_illusion, illusion)

		print(illusion)
	end

end

function Phantasm( keys )
	local caster = keys.caster
	local player = caster:GetPlayerID()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local unit_name = caster:GetUnitName()
	local images_count = ability:GetLevelSpecialValueFor( "images_count", ability_level )
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability_level )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "outgoing_damage", ability_level )
	local incomingDamage = ability:GetLevelSpecialValueFor( "incoming_damage", ability_level )
	local extra_illusion_chance = ability:GetLevelSpecialValueFor("extra_phantasm_chance_pct_tooltip", ability_level)
	local extra_illusion_sound = keys.sound

	local chance = RandomInt(1, 100)
	local casterOrigin = caster:GetAbsOrigin()
	local casterAngles = caster:GetAngles()

	-- Stop any actions of the caster otherwise its obvious which unit is real
	caster:Stop()

	-- Initialize the illusion table to keep track of the units created by the spell
	if not caster.phantasm_illusions then
		caster.phantasm_illusions = {}
	end

	-- Kill the old images
	for k,v in pairs(caster.phantasm_illusions) do
		if v and IsValidEntity(v) then 
			v:ForceKill(false)
		end
	end

	-- Start a clean illusion table
	caster.phantasm_illusions = {}

	-- Setup a table of potential spawn positions
	local vRandomSpawnPos = {
		Vector( 72, 0, 0 ),		-- North
		Vector( 0, 72, 0 ),		-- East
		Vector( -72, 0, 0 ),	-- South
		Vector( 0, -72, 0 ),	-- West
		Vector( 72, 72, 0 ),	-- north east
		Vector( -72, -72, 0 ),	-- south West
	}

	for i=#vRandomSpawnPos, 2, -1 do	-- Simply shuffle them
		local j = RandomInt( 1, i )
		vRandomSpawnPos[i], vRandomSpawnPos[j] = vRandomSpawnPos[j], vRandomSpawnPos[i]
	end

	-- Insert the center position and make sure that at least one of the units will be spawned on there.
	table.insert( vRandomSpawnPos, RandomInt( 1, images_count+1 ), Vector( 0, 0, 0 ) )

	-- At first, move the main hero to one of the random spawn positions.
	FindClearSpaceForUnit( caster, casterOrigin + table.remove( vRandomSpawnPos, 1 ), true )

	-- Spawn illusions
	for i=1, images_count do

		local origin = casterOrigin + table.remove( vRandomSpawnPos, 1 )

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

		-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
		table.insert(caster.phantasm_illusions, illusion)
	end

	-- Check is we got lucky with the chance and create an extra illusion if we did
	if chance <= extra_illusion_chance then
		-- Since its an extra illsuion then create it at a random point
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
		EmitSoundOn(extra_illusion_sound, caster)

		-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
		table.insert(caster.phantasm_illusions, illusion)
	end
end

--[[Creates vision around the caster while shuffling the illusions]]
function PhantasmVision( keys )
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local vision_radius = ability:GetLevelSpecialValueFor("vision_radius", ability_level) 
	local vision_duration = ability:GetLevelSpecialValueFor("invuln_duration", ability_level)

	ability:CreateVisibilityNode(caster_location, vision_radius, vision_duration)
end

function RealityRiftPosition( keys )
	local caster = keys.caster
	local target = keys.target
	local caster_location = caster:GetAbsOrigin() 
	local target_location = target:GetAbsOrigin() 
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local min_range = ability:GetLevelSpecialValueFor("min_range", ability_level) 
	local max_range = ability:GetLevelSpecialValueFor("max_range", ability_level)
	local reality_rift_particle = keys.reality_rift_particle

	-- Position calculation
	local distance = (target_location - caster_location):Length2D() 
	local direction = (target_location - caster_location):Normalized()
	local target_point = RandomFloat(min_range, max_range) * distance
	local target_point_vector = caster_location + direction * target_point

	-- Particle
	local particle = ParticleManager:CreateParticle(reality_rift_particle, PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_location, true)
	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
	ParticleManager:SetParticleControl(particle, 2, target_point_vector)
	ParticleManager:SetParticleControlOrientation(particle, 2, direction, Vector(0,1,0), Vector(1,0,0))
	ParticleManager:ReleaseParticleIndex(particle) 

	-- Save the location
	ability.reality_rift_location = target_point_vector
	ability.reality_rift_direction = direction
end

--[[Author: Pizzalol
	Date: 09.04.2015.
	Relocates the target, caster and any illusions under the casters control]]
function RealityRift( keys )
	local caster = keys.caster
	local target = keys.target
	local caster_location = caster:GetAbsOrigin()
	local player = caster:GetPlayerOwnerID()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local bonus_duration = ability:GetLevelSpecialValueFor("bonus_duration", ability_level) 
	local illusion_search_radius = ability:GetLevelSpecialValueFor("illusion_search_radius", ability_level) 
	local bonus_modifier = keys.bonus_modifier

	-- Ability variables
	local casterAngles = caster:GetAngles()
	local player = caster:GetPlayerID()
	local unit_name = caster:GetUnitName()
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability_level )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "outgoing_damage", ability_level )
	local incomingDamage = ability:GetLevelSpecialValueFor( "incoming_damage", ability_level )
	local extra_illusion_chance = ability:GetLevelSpecialValueFor("extra_phantasm_chance_pct_tooltip", ability_level)
	local extra_illusion_sound = keys.sound
	
	-- Set the positions to be one on each side of the rift
	target:SetAbsOrigin(ability.reality_rift_location - ability.reality_rift_direction * 25)
	caster:SetAbsOrigin(ability.reality_rift_location + ability.reality_rift_direction * 25)

	-- Set the targets to face eachother
	target:SetForwardVector(ability.reality_rift_direction)
	caster:Stop() 
	caster:SetForwardVector(ability.reality_rift_direction * -1)

	-- Add the phased modifier to prevent getting stuck
	target:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03})
	caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03})

	-- Execute the attack order for the caster
	local order =
	{
		UnitIndex = caster:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = target:entindex(),
		Queue = true
	}

	ExecuteOrderFromTable(order)

	-- Find the caster illusions if they exist
	local target_teams = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local target_types = DOTA_UNIT_TARGET_HERO
	local target_flags = DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED

	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster_location, nil, illusion_search_radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)

	for _,unit in ipairs(units) do
		if unit:IsIllusion() and unit:GetPlayerOwnerID() == player then
			-- Do the same thing that we did for the caster
			-- Relocate and set the illusion to face the target
			unit:SetAbsOrigin(ability.reality_rift_location + ability.reality_rift_direction * 25) 
			unit:Stop() 
			unit:SetForwardVector(ability.reality_rift_direction * -1)

			-- Add the phased and reality rift modifiers
			unit:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03})
			ability:ApplyDataDrivenModifier(caster, unit, bonus_modifier, {duration = bonus_duration})

			-- Execute the attack order
			local order =
			{
				UnitIndex = unit:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = target:entindex(),
				Queue = true
			}

			ExecuteOrderFromTable(order)
		end
	end

	local random = RandomFloat(0, 1)

	if (random >= 0.5) then
		-- Initialize the illusion table to keep track of the units created by the spell
		if not caster.chaos_bolt_illusion then
			caster.chaos_bolt_illusion = {}
		end

		-- Start a clean illusion table
		caster.chaos_bolt_illusion = {}

		-- Since its an extra illusion then create it at a random point
		local origin = caster_location + RandomVector(100)

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
		EmitSoundOn(extra_illusion_sound, caster)

		-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
		table.insert(caster.chaos_bolt_illusion, illusion)

		print(illusion)
	end
end

function Spawnillusion( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local casterOrigin = caster:GetAbsOrigin()
	local casterAngles = caster:GetAngles()

	local player = caster:GetPlayerID()
	local unit_name = caster:GetUnitName()
	local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability_level )
	local outgoingDamage = ability:GetLevelSpecialValueFor( "outgoing_damage", ability_level )
	local incomingDamage = ability:GetLevelSpecialValueFor( "incoming_damage", ability_level )
	local extra_illusion_chance = ability:GetLevelSpecialValueFor("extra_phantasm_chance_pct_tooltip", ability_level)
	local extra_illusion_sound = keys.sound


	-- Initialize the illusion table to keep track of the units created by the spell
	if not caster.chaos_bolt_illusion then
		caster.chaos_bolt_illusion = {}
	end

	-- Start a clean illusion table
	caster.chaos_bolt_illusion = {}

	-- Since its an extra illusion then create it at a random point
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
	EmitSoundOn(extra_illusion_sound, caster)

	-- Add the illusion created to a table within the caster handle, to remove the illusions on the next cast if necessary
	table.insert(caster.chaos_bolt_illusion, illusion)
end