--[[
	Author: kritth
	Date: 1.1.2015.
	Check number of units every interval
	Note: Might be possible to do entirely in datadriven, however, I seem to crash everytime I tried
	to do so, insteads, I just use simple script
]]
function marksmanship_detection( keys )
	local caster = keys.caster
	local ability = keys.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ( ability:GetLevel() - 1 ) )
	local modifierName = "modifier_marksmanship_effect_datadriven"
	
	-- Count units in radius
	local units = FindUnitsInRadius( caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
	local count = 0
	for k, v in pairs( units ) do
		count = count + 1
	end
	
	-- Apply and destroy
	if count == 0 and not caster:HasModifier( modifierName ) then
		ability:ApplyDataDrivenModifier( caster, caster, modifierName, {} )
	elseif count ~= 0 and caster:HasModifier( modifierName ) then
		caster:RemoveModifierByName( modifierName )
	end
end


--[[
	Author: kritth, Pizzalol
	Date: 27.09.2015.
	Calculates the bonus damage based on casters agility and then applies a stack modifier to grant the damage
]]
function trueshot_initialize( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local trueshot_modifier = keys.trueshot_modifier
	local trueshot_damage_modifier = keys.trueshot_damage_modifier

	-- Check if its a valid target
	if target and IsValidEntity(target) and target:HasModifier(trueshot_modifier) then
		local agility = caster:GetAgility()
		local percent = ability:GetLevelSpecialValueFor("trueshot_ranged_damage", ability_level) 
		local trueshot_damage = math.floor(agility * percent / 100)

		-- If it doesnt have the stack modifier then apply it
		if not target:FindModifierByName(trueshot_damage_modifier) then
			ability:ApplyDataDrivenModifier(caster, target, trueshot_damage_modifier, {})
		end
		
		-- Set the damage to the calculated damage
		target:SetModifierStackCount(trueshot_damage_modifier, caster, trueshot_damage)
	end
end


--[[
	CHANGELIST:
	09.01.2015 - Change the file into .lua extension
]]

--[[
	Author: kritth
	Date: 09.01.2015
	Knockback enemies in the line accordingly to the distance
]]
function modifier_wave_of_silence_knockback( keys )
	local vCaster = keys.caster:GetAbsOrigin()
	local vTarget = keys.target:GetAbsOrigin()
	local len = ( vTarget - vCaster ):Length2D()
	len = keys.distance - keys.distance * ( len / keys.range )
	local knockbackModifierTable =
	{
		should_stun = 0,
		knockback_duration = keys.duration,
		duration = keys.duration,
		knockback_distance = len,
		knockback_height = 0,
		center_x = keys.caster:GetAbsOrigin().x,
		center_y = keys.caster:GetAbsOrigin().y,
		center_z = keys.caster:GetAbsOrigin().z
	}
	keys.target:AddNewModifier( keys.caster, nil, "modifier_knockback", knockbackModifierTable )
end
