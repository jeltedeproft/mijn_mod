LinkLuaModifier( "modifier_super_speed_lua", "libraries/modifiers/modifier_super_speed.lua", LUA_MODIFIER_MOTION_NONE )

--[[Author: Pizzalol
	Date: 02.04.2015.
	Deals damage around the holder of the ion shell modifier]]
function IonShell( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level) 
	local think_interval = ability:GetLevelSpecialValueFor("think_interval", ability_level) 
	local damage = ability:GetLevelSpecialValueFor("damage_per_second", ability_level) * think_interval
	local ion_particle = keys.ion_particle

	-- Targeting variables
	local target_teams = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_types = ability:GetAbilityTargetType() 
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

	-- Initialize the damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage = damage
	damage_table.damage_type = ability:GetAbilityDamageType() 
	damage_table.ability = ability

	-- Find all the valid units in radius
	local units = FindUnitsInRadius(caster:GetTeamNumber(), target_location, nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)

	for _,unit in ipairs(units) do
		-- Damage the unit as long as the found unit is not the holder of the modifier
		if unit ~= target then
			-- Play the damage particle
			local particle = ParticleManager:CreateParticle(ion_particle, PATTACH_POINT_FOLLOW, unit) 
			ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true) 
			ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(particle)

			damage_table.victim = unit
			ApplyDamage(damage_table)
		end
	end
end

--[[Author: Pizzalol
	Date: 03.04.2015.
	Pulls the targets to the center]]
function Vacuum( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local vacuum_modifier = keys.vacuum_modifier
	local remaining_duration = duration - (GameRules:GetGameTime() - target.vacuum_start_time)

	-- Targeting variables
	local target_teams = ability:GetAbilityTargetTeam() 
	local target_types = ability:GetAbilityTargetType() 
	local target_flags = ability:GetAbilityTargetFlags() 

	local units = FindUnitsInRadius(caster:GetTeamNumber(), target_location, nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)

	-- Calculate the position of each found unit
	for _,unit in ipairs(units) do
		local unit_location = unit:GetAbsOrigin()
		local vector_distance = target_location - unit_location
		local distance = (vector_distance):Length2D()
		local direction = (vector_distance):Normalized()

		-- Check if its a new vacuum cast
		-- Set the new pull speed if it is
		if unit.vacuum_caster ~= target then
			unit.vacuum_caster = target
			-- The standard speed value is for 1 second durations so we have to calculate the difference
			-- with 1/duration
			unit.vacuum_caster.pull_speed = distance * 1/duration * 1/30
		end

		-- Apply the stun and no collision modifier then set the new location
		ability:ApplyDataDrivenModifier(caster, unit, vacuum_modifier, {duration = remaining_duration})
		unit:SetAbsOrigin(unit_location + direction * unit.vacuum_caster.pull_speed)
	end

	target_location = target_location + Vector(000,200,0)

	Timers:CreateTimer({
    	endTime = 0.4, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
    	callback = function()
     		local units2 = FindUnitsInRadius(caster:GetTeamNumber(), target_location, nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)

			-- Calculate the position of each found unit
			for _,unit in ipairs(units2) do
				local unit_location = unit:GetAbsOrigin()
				local vector_distance = target_location - unit_location
				local distance = (vector_distance):Length2D()
				local direction = (vector_distance):Normalized()

				-- Check if its a new vacuum cast
				-- Set the new pull speed if it is
				if unit.vacuum_caster ~= target then
					unit.vacuum_caster = target
					-- The standard speed value is for 1 second durations so we have to calculate the difference
					-- with 1/duration
					unit.vacuum_caster.pull_speed = distance * 1/duration * 1/30
				end

				-- Apply the stun and no collision modifier then set the new location
				ability:ApplyDataDrivenModifier(caster, unit, vacuum_modifier, {duration = remaining_duration})
				unit:SetAbsOrigin(unit_location + direction * unit.vacuum_caster.pull_speed)
			end
		end
  	})
	

	target_location = target_location + Vector(200,0,0)

	Timers:CreateTimer({
    	endTime = 0.9, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
    	callback = function()
     		local units3 = FindUnitsInRadius(caster:GetTeamNumber(), target_location, nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)

			-- Calculate the position of each found unit
			for _,unit in ipairs(units3) do
				local unit_location = unit:GetAbsOrigin()
				local vector_distance = target_location - unit_location
				local distance = (vector_distance):Length2D()
				local direction = (vector_distance):Normalized()

				-- Check if its a new vacuum cast
				-- Set the new pull speed if it is
				if unit.vacuum_caster ~= target then
					unit.vacuum_caster = target
					-- The standard speed value is for 1 second durations so we have to calculate the difference
					-- with 1/duration
					unit.vacuum_caster.pull_speed = distance * 1/duration * 1/30
				end

				-- Apply the stun and no collision modifier then set the new location
				ability:ApplyDataDrivenModifier(caster, unit, vacuum_modifier, {duration = remaining_duration})
				unit:SetAbsOrigin(unit_location + direction * unit.vacuum_caster.pull_speed)
			end
		end
  	})	
end

--[[Author: Pizzalol
	Date: 03.04.2015.
	Track the starting vacuum time]]
function VacuumStart( keys )
	local target = keys.target

	target.vacuum_start_time = GameRules:GetGameTime()
end

--[[Author: Pizzalol, kritth
	Date: 05.04.2015.
	Create the wall dummies at along the wall]]
function WallOfReplica( keys )
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local caster_team = caster:GetTeamNumber()
	local target_point = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Cosmetic variables
	local dummy_modifier = keys.dummy_modifier
	local wall_particle = keys.wall_particle
	local dummy_sound = keys.dummy_sound

	-- Ability variables
	local length = ability:GetLevelSpecialValueFor("length", ability_level) 
	local width = ability:GetLevelSpecialValueFor("width", ability_level)
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)

	-- Targeting variables
	local direction = (target_point - caster_location):Normalized()
	local rotation_point = target_point + direction * length/2
	local end_point_left = RotatePosition(target_point, QAngle(0,90,0), rotation_point)
	local end_point_right = RotatePosition(target_point, QAngle(0,-90,0), rotation_point)

	local direction_left = (end_point_left - target_point):Normalized() 
	local direction_right = (end_point_right - target_point):Normalized()

	-- Calculate the number of secondary dummies that we need to create
	local num_of_dummies = (((length/2) - width) / (width*2))
	if num_of_dummies%2 ~= 0 then
		-- If its an uneven number then make the number even
		num_of_dummies = num_of_dummies + 1
	end
	num_of_dummies = num_of_dummies / 2

	-- Create the main wall dummy
	local dummy = CreateUnitByName("npc_dummy_unit", target_point, false, caster, caster, caster_team)
	ability:ApplyDataDrivenModifier(dummy, dummy, dummy_modifier, {})
	EmitSoundOn(dummy_sound, dummy)	

	-- Create the secondary dummies for the left half of the wall
	for i=1,num_of_dummies + 2 do
		-- Create a dummy on every interval point to fill the whole wall
		local temporary_point = target_point + (width * 2 * i + (width - width/10)) * direction_left

		-- Create the secondary dummy and apply the dummy aura to it, make sure the caster of the aura is the main dummmy
		-- otherwise you wont be able to save illusion targets
		local dummy_secondary = CreateUnitByName("npc_dummy_unit", temporary_point, false, caster, caster, caster_team)
		ability:ApplyDataDrivenModifier(dummy, dummy_secondary, dummy_modifier, {})

		Timers:CreateTimer(duration, function()
			dummy_secondary:RemoveSelf()
		end)
	end

	-- Create the secondary dummies for the right half of the wall
	for i=1,num_of_dummies + 2 do
		-- Create a dummy on every interval point to fill the whole wall
		local temporary_point = target_point + (width * 2 * i + (width - width/10)) * direction_right
		
		-- Create the secondary dummy and apply the dummy aura to it, make sure the caster of the aura is the main dummmy
		-- otherwise you wont be able to save illusion targets
		local dummy_secondary = CreateUnitByName("npc_dummy_unit", temporary_point, false, caster, caster, caster_team)
		ability:ApplyDataDrivenModifier(dummy, dummy_secondary, dummy_modifier, {})

		Timers:CreateTimer(duration, function()
			dummy_secondary:RemoveSelf()
		end)
	end

	-- Save the relevant data
	dummy.wall_start_time = dummy.wall_start_time or GameRules:GetGameTime()
	dummy.wall_duration = dummy_wall_duration or duration
	dummy.wall_level = dummy.wall_level or ability_level
	dummy.wall_table = dummy.wall_table or {}

	-- Create the wall particle
	local particle = ParticleManager:CreateParticle(wall_particle, PATTACH_POINT_FOLLOW, dummy)
	ParticleManager:SetParticleControl(particle, 0, end_point_left) 
	ParticleManager:SetParticleControl(particle, 1, end_point_right)

	-- Set a timer to kill the sound and particle
	Timers:CreateTimer(duration,function()
		StopSoundOn(dummy_sound, dummy)
		dummy:RemoveSelf()
	end)
end

--[[Author: Pizzalol
	Date: 05.04.2015.
	Checks if there is an alive illusion of the target, if there is not then create an illusion]]
function WallOfReplicaIllusionCheck( keys )
	local caster = keys.caster -- This is the dummy in this case
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability

	-- Get the original hero
	local player = caster:GetPlayerOwnerID()
	local player_hero = PlayerResource:GetPlayer(player):GetAssignedHero()
	
	-- Initialize the tracking data variables in case there was a hero at the wall spawn point
	caster.wall_level = caster.wall_level or (ability:GetLevel() - 1)
	local ability_level = caster.wall_level
	caster.wall_start_time = caster.wall_start_time or GameRules:GetGameTime() 
	caster.wall_duration = caster.wall_duration or (ability:GetLevelSpecialValueFor("duration", ability_level))
	caster.wall_table = caster.wall_table or {}

	-- Ability variables	
	local unit_name = target:GetUnitName()
	local illusion_origin = target_location + RandomVector(100)
	local illusion_duration = caster.wall_duration - (GameRules:GetGameTime() - caster.wall_start_time)
	local illusion_outgoing_damage = ability:GetLevelSpecialValueFor("replica_damage_outgoing", ability_level)
	local illusion_incoming_damage = ability:GetLevelSpecialValueFor("replica_damage_incoming", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)

	-- Check if the hit hero is a real hero
	if target:IsRealHero() then
		-- Check if the illusion of the target is alive
		if not IsValidEntity(caster.wall_table[target]) or not caster.wall_table[target]:IsAlive() then
			-- Create an illusion if its not
			local illusion = CreateUnitByName(unit_name, illusion_origin, true, player_hero, nil, caster:GetTeamNumber())
			illusion:SetPlayerID(player)
			illusion:SetControllableByPlayer(player, true)

			local target_level = target:GetLevel()
			for i = 1, target_level - 1 do
				illusion:HeroLevelUp(false)
			end

			illusion:SetAbilityPoints(0) 
			for ability_slot = 0, 15 do
				local target_ability = target:GetAbilityByIndex(ability_slot) 
				if target_ability then
					local target_ability_level = target_ability:GetLevel() 
					local target_ability_name = target_ability:GetAbilityName() 
					local illusion_ability = illusion:FindAbilityByName(target_ability_name) 
					illusion_ability:SetLevel(target_ability_level) 
				end
			end

			for item_slot = 0, 5 do
				local item = target:GetItemInSlot(item_slot) 
				if item then
					local item_name = item:GetName() 
					local new_item = CreateItem(item_name, illusion, illusion) 
					illusion:AddItem(new_item) 
				end
			end

			illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = illusion_duration, outgoing_damage = illusion_outgoing_damage, incoming_damage = illusion_incoming_damage})

			illusion:MakeIllusion() 
			illusion:SetHealth(target:GetHealth()) -- Set the health of the illusion to be the same as the target HP
			caster.wall_table[target] = illusion -- Keep track of the illusion

			-- Deal damage for creating the illusion
			local damage_table = {}
			damage_table.attacker = player_hero
			damage_table.victim = target
			damage_table.ability = ability
			damage_table.damage_type = ability:GetAbilityDamageType() 
			damage_table.damage = damage

			ApplyDamage(damage_table)
		end
	end
end

--[[Author: Pizzalol
	Date: 05.04.2015.
	Acts as an aura which checks if any hero passed the wall]]
function WallOfReplicaAura( keys )
	local caster = keys.caster -- Main wall dummy
	local target = keys.target -- Secondary dummies
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local radius = ability:GetLevelSpecialValueFor("width", ability_level)
	local aura_modifier = keys.aura_modifier

	local target_teams = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_types = DOTA_UNIT_TARGET_HERO
	local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

	local units = FindUnitsInRadius(caster:GetTeamNumber(), target_location, nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)

	for _,unit in ipairs(units) do
		ability:ApplyDataDrivenModifier(caster, unit, aura_modifier, {Duration = 0.1})
	end
end

function Surge( keys )
	local caster = keys.caster -- Main wall dummy
	local target = keys.target -- Secondary dummies
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local move_speed = ability:GetLevelSpecialValueFor("move_speed", ability_level)
	
	target:AddNewModifier(caster, ability, "modifier_imba_speed_limit_break", {duration = duration})
end

