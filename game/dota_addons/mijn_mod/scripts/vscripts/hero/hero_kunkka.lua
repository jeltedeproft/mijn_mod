
function ghostship_mark_allies( caster, ability, target )
	local allHeroes = HeroList:GetAllHeroes()
	local delay = ability:GetLevelSpecialValueFor( "tooltip_delay", ability:GetLevel() - 1 )
	local particleName = "particles/units/heroes/hero_kunkka/kunkka_ghostship_marker.vpcf"
	
	for k, v in pairs( allHeroes ) do
		if v:GetPlayerID() and v:GetTeam() == caster:GetTeam() then
			local fxIndex = ParticleManager:CreateParticleForPlayer( particleName, PATTACH_ABSORIGIN, v, PlayerResource:GetPlayer( v:GetPlayerID() ) )
			ParticleManager:SetParticleControl( fxIndex, 0, target )
			
			EmitSoundOnClient( "Ability.pre.Torrent", PlayerResource:GetPlayer( v:GetPlayerID() ) )
			
			-- Destroy particle after delay
			Timers:CreateTimer( delay, function()
					ParticleManager:DestroyParticle( fxIndex, false )
					return nil
				end
			)
		end
	end
end


function ghostship_start_traverse( keys )
	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local casterPoint = caster:GetAbsOrigin()
	local targetPoint = keys.target_points[1]
	local spawnDistance = ability:GetLevelSpecialValueFor("ghostship_distance", ability:GetLevel() - 1)
	local projectileSpeed = ability:GetLevelSpecialValueFor("ghostship_speed", ability:GetLevel() - 1 )

	local radius = ability:GetLevelSpecialValueFor("ghostship_width", ability:GetLevel() - 1 )
	local stunDelay = ability:GetLevelSpecialValueFor("tooltip_delay", ability:GetLevel() - 1 )
	
	local stunDuration = ability:GetLevelSpecialValueFor("stun_duration", ability:GetLevel() - 1 )
	local damage = ability:GetAbilityDamage()
	local damageType = ability:GetAbilityDamageType()
	local targetBuffTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local targetImpactTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local targetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL
	local targetFlag = DOTA_UNIT_TARGET_FLAG_NONE
	
	-- Get necessary vectors
	local forwardVec = targetPoint - casterPoint
		forwardVec = forwardVec:Normalized()
	local backwardVec = casterPoint - targetPoint
		backwardVec = backwardVec:Normalized()
	local spawnPoint = casterPoint + ( spawnDistance * backwardVec )
	local impactPoint = casterPoint + ( spawnDistance * forwardVec )
	local velocityVec = Vector( forwardVec.x, forwardVec.y, 0 )

	-- Show visual effect
	ghostship_mark_allies( caster, ability, impactPoint )
	
	-- Spawn projectiles
	local projectileTable = {
		Ability = ability,
		EffectName = "particles/units/heroes/hero_kunkka/kunkka_ghost_ship.vpcf",
		vSpawnOrigin = spawnPoint,
		fDistance = spawnDistance * 2,
		fStartRadius = radius,
		fEndRadius = radius,
		fExpireTime = GameRules:GetGameTime() + 5,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		bProvidesVision = false,
		iUnitTargetTeam = targetBuffTeam,
		iUnitTargetType = targetType,
		vVelocity = velocityVec * projectileSpeed
	}
	ProjectileManager:CreateLinearProjectile( projectileTable )
	
	-- Create timer for crashing
	Timers:CreateTimer( stunDelay, function()
			local units = FindUnitsInRadius(
				caster:GetTeamNumber(), impactPoint, caster, radius, targetImpactTeam,
				targetType, targetFlag, FIND_ANY_ORDER, false
			)
			
			-- Fire sound event
			local dummy = CreateUnitByName( "npc_dummy_unit", impactPoint, false, caster, caster, caster:GetTeamNumber() )
			StartSoundEvent( "Ability.Ghostship.crash", dummy )
			dummy:ForceKill( true )
			
			-- Stun and damage enemies
			for k, v in pairs( units ) do
				if not v:IsMagicImmune() then
					local damageTable = {
						victim = v,
						attacker = caster,
						damage = damage,
						damage_type = damageType
					}
					ApplyDamage( damageTable )
				end
				
				v:AddNewModifier( caster, nil, "modifier_stunned", { duration = stunDuration } )
			end
			
			return nil	-- Delete timer
		end
	)
end


function ghostship_register_damage( keys )
	local target = keys.unit
	local damageTaken = keys.DamageTaken
	if not target.ghostship_damage then
		target.ghostship_damage = 0
	end
	
	target.ghostship_damage = target.ghostship_damage + damageTaken
end


function ghostship_spread_damage( keys )
	-- Init in case never take any damage
	if not keys.target.ghostship_damage then
		keys.target.ghostship_damage = 0
	end

	-- Variables
	local target = keys.target
	local ability = keys.ability
	local damageDuration = ability:GetLevelSpecialValueFor( "damage_duration", ability:GetLevel() - 1 )
	local damageInterval = ability:GetLevelSpecialValueFor( "damage_interval", ability:GetLevel() - 1 )
	local damageCurrentTime = 0.0
	local damagePerInterval = target.ghostship_damage * ( damageInterval / damageDuration )
	local minimumHealth = 1

	-- Overtime debuff
	Timers:CreateTimer( damageInterval, function()
			-- HP Removal
			local targetHealth = target:GetHealth()
			if targetHealth - damagePerInterval <= minimumHealth then
				target:SetHealth( minimumHealth )
			else
				target:SetHealth( targetHealth - damagePerInterval )
			end
			
			-- Update timer
			damageCurrentTime = damageCurrentTime + damageInterval
			
			-- Check closing condition
			if damageCurrentTime >= damageDuration then
				return nil
			else
				return damageInterval
			end
		end
	)
end


function tidebringer_set_cooldown( keys )
	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local cooldown = ability:GetCooldown( ability:GetLevel() )
	local modifierName = "modifier_tidebringer_splash_datadriven"
	
	-- Remove cooldown
	caster:RemoveModifierByName( modifierName )
	ability:StartCooldown( cooldown )
	Timers:CreateTimer( cooldown, function()
			ability:ApplyDataDrivenModifier( caster, caster, modifierName, {} )
			return nil
		end
	)
end


function torrent_bubble_allies( keys )
	local caster = keys.caster
	
	local allHeroes = HeroList:GetAllHeroes()
	local delay = keys.ability:GetLevelSpecialValueFor( "delay", keys.ability:GetLevel() - 1 )
	local particleName = "particles/units/heroes/hero_kunkka/kunkka_spell_torrent_bubbles.vpcf"
	local target = keys.target_points[1]
	
	for k, v in pairs( allHeroes ) do
		if v:GetPlayerID() and v:GetTeam() == caster:GetTeam() then
			local fxIndex = ParticleManager:CreateParticleForPlayer( particleName, PATTACH_ABSORIGIN, v, PlayerResource:GetPlayer( v:GetPlayerID() ) )
			ParticleManager:SetParticleControl( fxIndex, 0, target )
			
			EmitSoundOnClient( "Ability.pre.Torrent", PlayerResource:GetPlayer( v:GetPlayerID() ) )
			
			-- Destroy particle after delay
			Timers:CreateTimer( delay, function()
					ParticleManager:DestroyParticle( fxIndex, false )
					return nil
				end
			)
		end
	end
end


function torrent_emit_sound( keys )
	local dummy = CreateUnitByName( "npc_dummy_unit", keys.target_points[1], false, keys.caster, keys.caster, keys.caster:GetTeamNumber() )
	EmitSoundOn( "Ability.Torrent", dummy )
	dummy:ForceKill( true )
end


function torrent_post_vision( keys )
	local ability = keys.ability
	local target = keys.target_points[1]
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "vision_duration", ability:GetLevel() - 1 )
	
	ability:CreateVisibilityNode( target, radius, duration )
end



function x_marks_the_spot_init( keys )
  -- Variables
	local caster = keys.caster
	local target = keys.target
	local targetLoc = keys.target:GetAbsOrigin()
	local x_marks_return_name = "imba_kunkka_return"
	
	-- Set variables
	caster.x_marks_target = target
	caster.x_marks_origin = targetLoc
	
	-- Swap ability
	caster:SwapAbilities( keys.ability:GetAbilityName(), x_marks_return_name, false, true )
end

function x_marks_the_spot_transfer_init( keys )
  -- Variables
	local caster = keys.caster
	local target = keys.target
	local targetLoc = keys.target:GetAbsOrigin()
	
	-- Set variables
	caster.x_marks_target = target
	caster.x_marks_origin = targetLoc
end


function x_marks_the_spot_force_return( keys )
	local caster = keys.caster
	local modifierName = "modifier_x_marks_the_spot_debuff_datadriven"
	caster.x_marks_target:RemoveModifierByName( modifierName )
end


function x_marks_the_spot_return( keys )
  -- Variables
	local caster = keys.caster
	local x_marks = "imba_kunkka_x_marks_the_spot"
	local x_marks_return = "imba_kunkka_return"
	local modifierName = "modifier_x_marks_the_spot_debuff_datadriven"
	
	-- Check if there is target unit
	if caster.x_marks_target ~= nil and caster.x_marks_origin ~= nil then
		FindClearSpaceForUnit( caster.x_marks_target, caster.x_marks_origin, true )
		caster.x_marks_target = nil
		caster.x_marks_origin = nil
	end
	
	-- Swap ability
	caster:SwapAbilities( x_marks, x_marks_return, true, false )
	x_marks_start_cooldown( keys )
end

function x_marks_the_spot_transfer_return( keys )
  -- Variables
	local caster = keys.caster
	local modifierName = "modifier_x_marks_the_spot_transfered_datadriven"
	
	-- Check if there is target unit
	if caster.x_marks_target ~= nil and caster.x_marks_origin ~= nil then
		FindClearSpaceForUnit( caster.x_marks_target, caster.x_marks_origin, true )
		caster.x_marks_target = nil
		caster.x_marks_origin = nil
	end

	x_marks_start_cooldown( keys )
end

function transfer_x( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local Duration = keys.duration
	local modifierName = "modifier_x_marks_the_spot_transfered_datadriven"
	local target_pos = target:GetAbsOrigin()
	local time_past = 0

	local x_duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )

	Timers:CreateTimer(function()
		time_past = time_past + 1
    	local_enemies = FindUnitsInRadius(caster:GetTeamNumber(), target_pos, nil, 300, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)

    	for _,unit in pairs(local_enemies) do
    		if unit ~= target and unit:HasModifier("modifier_x_marks_the_spot_transfered_datadriven") == false then
				ability:ApplyDataDrivenModifier(target, unit, modifierName, {duration = Duration})
			end
		end

		if time_past <= x_duration then	
    		return 1.0
    	end
    end
    )
end


function x_marks_start_cooldown( keys )
  -- Name of both abilities
	local x_marks = "imba_kunkka_x_marks_the_spot"
	local x_marks_return = "imba_kunkka_return"

  -- Loop to reset cooldown
	for i = 0, keys.caster:GetAbilityCount() - 1 do
		local currentAbility = keys.caster:GetAbilityByIndex( i )
		if currentAbility ~= nil and ( currentAbility:GetAbilityName() == x_marks or currentAbility:GetAbilityName() == x_marks_return ) then
			currentAbility:EndCooldown()
			currentAbility:StartCooldown( currentAbility:GetCooldown( currentAbility:GetLevel() - 1 ) )
		end
	end
end


function LevelUpReturn( keys )
	local caster = keys.caster		
	local ability_name = keys.ability_name
	local ability_handle = caster:FindAbilityByName(ability_name)	

	-- Upgrades Return to level 1 if it hasn't already
	ability_handle:SetLevel(1)
end


