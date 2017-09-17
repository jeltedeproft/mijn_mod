function TickDrain( event )
	local caster = event.caster
	local deltaDrainPct	= event.drain_interval * event.drain_pct

	ApplyDamage( {
		victim = caster,
		attacker = caster,
		damage = caster:GetHealth() * deltaDrainPct,
		damage_type = DAMAGE_TYPE_PURE,
	} )

	caster:SpendMana( caster:GetMana() * deltaDrainPct, event.ability )
end


function GrabTetherAbility( event )
	local caster = event.caster
	local tether = caster:FindAbilityByName( event.tether_ability_name )
	local overcharge = event.ability

	-- Store tether
	overcharge.overcharge_tether = tether

	-- Reset the overcharged ally
	overcharge.overcharge_ally = nil
end


function CheckTetheredAlly( event )

	local caster		= event.caster
	local overcharge	= event.ability
	local buffModifier	= event.buff_modifier

	-- If the caster has no TETHER ability, skip it.
	if not overcharge.overcharge_tether then
		return
	end

	local tetheredAlly		= overcharge.overcharge_tether[ event.tether_ally_property_name ]
	local overchargedAlly	= overcharge.overcharge_ally

	-- If the tethered ally has been changed
	if tetheredAlly ~= overchargedAlly then

		-- Remove the buff from the old overcharged ally
		if overchargedAlly then
			overchargedAlly:RemoveModifierByNameAndCaster( buffModifier, caster )
		end

		-- Attach the buff to the new tethered ally
		if tetheredAlly then
			overcharge:ApplyDataDrivenModifier( caster, tetheredAlly, buffModifier, {} )
		end

		-- Update overcharged ally
		overcharge.overcharge_ally = tetheredAlly
	end
end


function RemoveOverchargeFromAlly( event )
	
	local caster		= event.caster
	local overcharge	= event.ability
	local buffModifier	= event.buff_modifier

	local overchargedAlly	= overcharge.overcharge_ally

	if overchargedAlly then
		overchargedAlly:RemoveModifierByNameAndCaster( buffModifier, caster )
	end

	overcharge.overcharge_ally = nil
end


function StopSound( event )
	StopSoundEvent( event.sound_name, event.caster )
end

function CastRelocate( event )

	local caster	= event.caster
	local ability	= event.ability
	local point		= event.target_points[1]

	-- Store the target loc
	ability.relocate_targetPoint = point

	-- Reset states
	ability.relocate_isInterrupted = false

	-- Try to refresh the tether duration
	local tetherModifierName = event.tether_modifier

	if caster:HasModifier( tetherModifierName ) then
		local tetherAbility = caster:FindAbilityByName( event.tether_ability )
		local tetheredAlly = tetherAbility[event.tether_ally_property_name]

		if IsRelocatableUnit( tetheredAlly ) then
			tetherAbility:ApplyDataDrivenModifier( caster, caster, tetherModifierName, {} )
			tetherAbility:ApplyDataDrivenModifier( caster, tetheredAlly, event.tether_ally_modifier, {} )
		end
	end
end


function CreateMarkerEndpoint( event )
	
	local caster	= event.caster
	local ability	= event.ability

	local pfx = ParticleManager:CreateParticle( event.endpoint_particle, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( pfx, 0, ability.relocate_targetPoint )

	-- Store the particle ID
	ability.relocate_endpointPfx = pfx

	-- Create vision
	ability:CreateVisibilityNode( ability.relocate_targetPoint, event.vision_radius, event.vision_duration )

end


function CheckToInterrupt( event )
	local caster	= event.caster
	local ability	= event.ability

	if caster:IsStunned() or caster:IsHexed() or caster:IsNightmared() or caster:IsOutOfGame() then
		-- Interrupt the ability
		ability.relocate_isInterrupted = true
		caster:RemoveModifierByName( event.channel_modifier )
	end
end


function DestroyMarkerEndpoint( event )
	local ability	= event.ability

	local pfx = ability.relocate_endpointPfx
	ParticleManager:DestroyParticle( pfx, false )

	ability.relocate_endpointPfx = nil
end


function TryToTeleport( event )
	local caster	= event.caster
	local ability	= event.ability

	-- Interrupted by any disable?
	if ability.relocate_isInterrupted then
		ability.relocate_isInterrupted = nil
		return
	end

	-- Ensnared?
	if caster:IsRooted() then
		return
	end

	-- Now we teleport!
	ability:ApplyDataDrivenModifier( caster, caster, event.timer_modifier, {} )
end

--[[
	If the caster has tethered ally, refresh the tether duration.

	Store the original location and teleport the caster.
	Fire the teleport particle on the old location before the teleportation.

	After this function is called, trees around the caster will be destroyed.
]]
function Teleportation_PreDestroyTree( event )
	
	local caster	= event.caster
	local ability	= event.ability

	-- Try to refresh the tether duration
	local tetherModifierName = event.tether_modifier
	local tetherAbility = caster:FindAbilityByName( event.tether_ability )
	local tetheredAlly = nil

	if caster:HasModifier( tetherModifierName ) then
		tetheredAlly = tetherAbility[event.tether_ally_property_name]
		if IsRelocatableUnit( tetheredAlly ) then
			local tetherDuration = event.tether_duration

			tetherAbility:ApplyDataDrivenModifier( caster, caster, tetherModifierName, { duration = tetherDuration } )
			tetherAbility:ApplyDataDrivenModifier( caster, tetheredAlly, event.tether_ally_modifier, { duration = tetherDuration } )
		else
			tetheredAlly = nil
		end
	end
	ability.relocate_tetheredAlly = tetheredAlly

	-- Store the original loc
	ability.relocate_originalPoint = caster:GetAbsOrigin()

	-- Fire the teleport particle
	local pfx = ParticleManager:CreateParticle( event.teleport_particle, PATTACH_POINT, caster )
	ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT, "attach_hitloc", caster:GetAbsOrigin(), true )

	if tetheredAlly then
		pfx = ParticleManager:CreateParticle( event.teleport_particle, PATTACH_POINT, tetheredAlly )
		ParticleManager:SetParticleControlEnt( pfx, 0, tetheredAlly, PATTACH_POINT, "attach_hitloc", tetheredAlly:GetAbsOrigin(), true )
	end

	-- Move to the location
	caster:SetAbsOrigin( ability.relocate_targetPoint )
end

--[[

	Find clear space for the caster, then teleport the tethered ally to near the caster.
	Discard current orders of caster and the tethered ally.

	We need to create the timer particle from script in order to control the number showing.
	Even the original location marker is created in this function.
]]
function Teleportation_PostDestroyTree( event )
	
	local caster	= event.caster
	local ability	= event.ability

	-- Find clear space for the caster, and stop
	FindClearSpaceForUnit( caster, ability.relocate_targetPoint, false )
	caster:Stop()

	-- Find clear space for the tethered ally
	-- Ally's teleportation point is always NORTH EAST from the caster.
	local all_friends = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 25000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _,friend in pairs(all_friends) do
		FindClearSpaceForUnit( friend, ability.relocate_targetPoint + Vector( 16, 16, 0 ), false )
		friend:Stop()

		ability.relocate_tetheredAlly = nil
	end

	-- Initialize the timer
	ability.relocate_timer = event.return_time

	local pfx = ParticleManager:CreateParticle( event.timer_particle, PATTACH_OVERHEAD_FOLLOW, caster )

	local timerCP1_x = event.return_time >= 10 and 1 or 0
	local timerCP1_y = event.return_time % 10
	ParticleManager:SetParticleControl( pfx, 1, Vector( timerCP1_x, timerCP1_y, 0 ) )

	ability.relocate_timerPfx = pfx

	-- Create original location marker
	pfx = ParticleManager:CreateParticle( event.marker_particle, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( pfx, 0, ability.relocate_originalPoint )

	ability.relocate_markerPfx = pfx

end

--[[
	Update the timer particle.
]]
function UpdateTimer( event )

	local ability = event.ability
	ability.relocate_timer = ability.relocate_timer - 1

	local pfx = ability.relocate_timerPfx

	local timerCP1_x = ability.relocate_timer >= 10 and 1 or 0
	local timerCP1_y = ability.relocate_timer % 10
	ParticleManager:SetParticleControl( pfx, 1, Vector( timerCP1_x, timerCP1_y, 0 ) )

end

--[[

	Destroy the particle effects.
	Check to see if the caster is alive.
]]
function TryReturningTeleportation( event )

	local caster	= event.caster
	local ability	= event.ability

	-- Destroy particle FXs
	ParticleManager:DestroyParticle( ability.relocate_timerPfx, false )
	ParticleManager:DestroyParticle( ability.relocate_markerPfx, false )

	-- If caster is dead, skip the teleportation back
	if not caster:IsAlive() then
		return
	end

	-- Now we teleport to the original location!
	ability:ApplyDataDrivenModifier( caster, caster, event.returning_modifier, {} )

end

--[[
	If the caster is still alive, teleport back to the original location.
	Fire the teleport particle on the old location before the teleportation.

	After this function is called, trees around the caster will be destroyed.
]]
function ReturningTeleportation_PreDestroyTree( event )
	
	local caster	= event.caster
	local ability	= event.ability

	-- Grab the tethered ally
	local tetherAbility = caster:FindAbilityByName( event.tether_ability )
	local tetheredAlly = nil

	if caster:HasModifier( event.tether_modifier ) then
		tetheredAlly = tetherAbility[event.tether_ally_property_name]
		if not IsRelocatableUnit( tetheredAlly ) then
			tetheredAlly = nil
		end
	end
	ability.relocate_tetheredAlly = tetheredAlly

	-- Fire the teleport particle
	local pfx = ParticleManager:CreateParticle( event.teleport_particle, PATTACH_POINT, caster )
	ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT, "attach_hitloc", caster:GetAbsOrigin(), true )

	if tetheredAlly then
		pfx = ParticleManager:CreateParticle( event.teleport_particle, PATTACH_POINT, tetheredAlly )
		ParticleManager:SetParticleControlEnt( pfx, 0, tetheredAlly, PATTACH_POINT, "attach_hitloc", tetheredAlly:GetAbsOrigin(), true )
	end

	-- Move to the location
	caster:SetAbsOrigin( ability.relocate_originalPoint )

end

--[[

	Find clear space for the caster, then teleport back even the tethered ally.
	Discard current orders of caster and the tethered ally.
]]
function ReturningTeleportation_PostDestroyTree( event )
	
	local caster	= event.caster
	local ability	= event.ability

	-- Find clear space for the caster, and stop
	FindClearSpaceForUnit( caster, ability.relocate_originalPoint, false )
	caster:Stop()

	-- Find clear space for the tethered ally
	-- Ally's teleportation point is always NORTH EAST from the caster.
	local all_friends = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 25000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _,friend in pairs(all_friends) do
		FindClearSpaceForUnit( friend, ability.relocate_originalPoint + Vector( 16, 16, 0 ), false )
		friend:Stop()

		ability.relocate_tetheredAlly = nil
	end

end



--[[
	Heroes, Illusions, LD's spirit bear, Warlock's Golem, Storm and Fire spirits from Primal Split can be relocated.

	Spirit bear, Golem, Storm and Fire spirits all have this property:
		"ConsideredHero" "1"
	So we can use it in order to check to see if the unit is relocatable.
]]
function IsRelocatableUnit( unit )
	if unit:IsHero() then return true end
	return false
end

--[[
	Stop a sound on the target unit.
]]
function StopSound( event )
	StopSoundEvent( event.sound_name, event.target )
end

function CastSpirits( event )
	
	local caster	= event.caster
	local ability	= event.ability

	ability.spirits_startTime		= GameRules:GetGameTime()
	ability.spirits_numSpirits		= 0		-- Use this rather than "#spirits_spiritsSpawned"
	ability.spirits_spiritsSpawned	= {}
	caster.spirits_radius			= event.default_radius
	caster.spirits_movementFactor	= 0		-- Changed by the toggle abilities

	-- Enable the toggle abilities
	caster:SwapAbilities( event.empty1_ability, event.spirits_in_ability, false, true )
	caster:SwapAbilities( event.empty2_ability, event.spirits_out_ability, false, true )

end

--[[

	Update spirits.
]]
function ThinkSpirits( event )
	
	local caster	= event.caster
	local ability	= event.ability

	local numSpiritsMax	= event.num_spirits

	local casterOrigin	= caster:GetAbsOrigin()

	local elapsedTime	= GameRules:GetGameTime() - ability.spirits_startTime

	--------------------------------------------------------------------------------
	-- Validate the number of spirits summoned
	--
	local idealNumSpiritsSpawned = elapsedTime / event.spirit_summon_interval
	idealNumSpiritsSpawned = math.min( idealNumSpiritsSpawned, numSpiritsMax )

	if ability.spirits_numSpirits < idealNumSpiritsSpawned then

		-- Spawn a new spirit
		local newSpirit = CreateUnitByName( "npc_dota_wisp_spirit", casterOrigin, false, caster, caster, caster:GetTeam() )

		-- Create particle FX
		local pfx = ParticleManager:CreateParticle( event.spirit_particle_name, PATTACH_ABSORIGIN_FOLLOW, newSpirit )
		newSpirit.spirit_pfx = pfx

		-- Update the state
		local spiritIndex = ability.spirits_numSpirits + 1
		newSpirit.spirit_index = spiritIndex
		ability.spirits_numSpirits = spiritIndex
		ability.spirits_spiritsSpawned[spiritIndex] = newSpirit

		-- Apply the spirit modifier
		ability:ApplyDataDrivenModifier( caster, newSpirit, event.spirit_modifier, {} )

	end

	--------------------------------------------------------------------------------
	-- Update the radius
	--
	local currentRadius	= caster.spirits_radius
	local deltaRadius = caster.spirits_movementFactor * event.spirit_movement_rate * event.think_interval
	currentRadius = currentRadius + deltaRadius
	currentRadius = math.min( math.max( currentRadius, event.min_range ), event.max_range )

	caster.spirits_radius = currentRadius

	--------------------------------------------------------------------------------
	-- Update the spirits' positions
	--
	local currentRotationAngle	= elapsedTime * event.spirit_turn_rate
	local rotationAngleOffset	= 360 / event.num_spirits

	local numSpiritsAlive = 0

	for k,v in pairs( ability.spirits_spiritsSpawned ) do

		numSpiritsAlive = numSpiritsAlive + 1

		-- Rotate
		local rotationAngle = currentRotationAngle - rotationAngleOffset * ( k - 1 )
		local relPos = Vector( 0, currentRadius, 0 )
		relPos = RotatePosition( Vector(0,0,0), QAngle( 0, -rotationAngle, 0 ), relPos )

		local absPos = GetGroundPosition( relPos + casterOrigin, v )

		v:SetAbsOrigin( absPos )

		-- Update particle
		ParticleManager:SetParticleControl( v.spirit_pfx, 1, Vector( currentRadius, 0, 0 ) )

	end

	if ability.spirits_numSpirits == numSpiritsMax and numSpiritsAlive == 0 then
		-- All spirits have been exploded.
		caster:RemoveModifierByName( event.caster_modifier )
		return
	end

end

--[[
	Destroy all spirits and swap the abilities back to the original states.
]]
function EndSpirits( event )
	
	local caster	= event.caster
	local ability	= event.ability

	local spiritModifier	= event.spirit_modifier

	-- Destroy all spirits
	for k,v in pairs( ability.spirits_spiritsSpawned ) do
		v:RemoveModifierByName( spiritModifier )
	end

	-- Disable the toggle abilities
	caster:SwapAbilities( event.empty1_ability, event.spirits_in_ability, true, false )
	caster:SwapAbilities( event.empty2_ability, event.spirits_out_ability, true, false )

	-- Reset the toggle states.
	ResetToggleState( caster, event.spirits_in_ability )
	ResetToggleState( caster, event.spirits_out_ability )

end

--[[

	Change the movement factor.
]]
function ToggleOn( event )
	local caster	= event.caster

	-- Make sure that the opposite ability is toggled off.
	ResetToggleState( caster, event.opposite_ability )

	-- Change the movement factor
	caster.spirits_movementFactor = event.spirit_movement
end

--[[
	Reset the movement factor.
]]
function ToggleOff( event )
	event.caster.spirits_movementFactor = 0
end

--[[
	Reset the toggle state.
]]
function ResetToggleState( caster, abilityName )
	local ability = caster:FindAbilityByName( abilityName )
	if ability:GetToggleState() then
		ability:ToggleAbility()
	end
end

--[[
	Apply a modifier which detects collision with a hero.
]]
function OnCreatedSpirit( event )
	
	local spirit = event.target
	local ability = event.ability

	-- Set the spirit to caster
	ability:ApplyDataDrivenModifier( spirit, spirit, event.additionalModifier, {} )

end

--[[
	Destroy a spirit.
]]
function OnDestroySpirit( event )

	local spirit	= event.target
	local ability	= event.ability
	
	ParticleManager:DestroyParticle( spirit.spirit_pfx, false )

	-- Create vision
	ability:CreateVisibilityNode( spirit:GetAbsOrigin(), event.vision_radius, event.vision_duration )

	-- Kill
	spirit:ForceKill( true )

end

--[[
	Explode the spirit due to collision with an enemy hero.
]]
function ExplodeSpirit( event )
	
	local spirit	= event.caster		-- We have set the spirit to the caster
	local ability	= event.ability

	if not spirit.spirit_isExploded then

		spirit.spirit_isExploded = true

		-- Remove from the list of spirits
		ability.spirits_spiritsSpawned[spirit.spirit_index] = nil

		-- Remove the spirit modifier
		spirit:RemoveModifierByName( event.spirit_modifier )

		-- Fire the hit sound
		StartSoundEvent( event.explosion_sound, spirit )

	end

end



--[[
	Levels up the ability_name to the same level of the ability that runs this
]]
function LevelUpAbility( event )
	local caster = event.caster
	local this_ability = event.ability		
	local this_abilityName = this_ability:GetAbilityName()
	local this_abilityLevel = this_ability:GetLevel()

	-- The ability to level up
	local ability_name = event.ability_name
	local ability_handle = caster:FindAbilityByName(ability_name)	
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end
end

--[[
	Stop a sound.
]]
function StopSound( event )
	StopSoundEvent( event.sound_name, event.caster )
end

function CastTether( event )
	-- Variables
	local caster	= event.caster
	local target	= event.target
	local ability	= event.ability

	local casterOrigin	= caster:GetAbsOrigin()
	local targetOrigin	= target:GetAbsOrigin()

	-- Store current Health/Mana to detect gained value
	TrackCurrentHealth( event )
	TrackCurrentMana( event )

	-- Store the ally unit
	ability.tether_ally = target

	-- Clear the slowed units list
	ability.tether_slowedUnits = {}

	-- Start latching
	local distToAlly = (targetOrigin - casterOrigin):Length2D()
	if distToAlly >= event.latch_distance then
		ability:ApplyDataDrivenModifier( caster, caster, event.latch_modifier, {} )
	end

	-- Swap sub ability
	local mainAbilityName	= ability:GetAbilityName()
	local subAbilityName	= event.sub_ability_name
	caster:SwapAbilities( mainAbilityName, subAbilityName, false, true )
end

--[[
	Check for tether break distance.
]]
function CheckDistance( event )
	local caster = event.caster
	local ability = event.ability

	-- Now on latching, so we don't need to break tether.
	if caster:HasModifier( event.latch_modifier ) then
		return
	end

	local distance = ( ability.tether_ally:GetAbsOrigin() - caster:GetAbsOrigin() ):Length2D()
	if distance <= event.radius then
		return
	end

	-- Break tether
	caster:RemoveModifierByName( event.caster_modifier )
end

--[[
	Remove tether from the ally, then swap the abilities back to the original states.
]]
function EndTether( event )
	local caster = event.caster
	local ability = event.ability

	ability.tether_ally:RemoveModifierByName( event.ally_modifier )
	ability.tether_ally = nil

	caster:SwapAbilities( ability:GetAbilityName(), event.sub_ability_name, true, false )
end

--[[
	Store the current health.
]]
function TrackCurrentHealth( event )
	local caster = event.caster
	caster.tether_lastHealth = caster:GetHealth()
end


function TrackCurrentMana( event )
	local caster = event.caster
	caster.tether_lastMana = caster:GetMana()
end


function HealAlly( event )
	local caster	= event.caster
	local ability	= event.ability
	local target	= ability.tether_ally

	local healthGained = caster:GetHealth() - caster.tether_lastHealth
	if healthGained < 0 then
		return
	end

	-- Heal the tethered ally
	target:Heal( healthGained * event.tether_heal_amp, ability )
end


function GiveManaToAlly( event )
	local caster	= event.caster
	local ability	= event.ability
	local target	= ability.tether_ally

	local manaGained = caster:GetMana() - caster.tether_lastMana
	if manaGained < 0 then
		return
	end

	--print( caster.tether_lastMana )

	target:GiveMana( manaGained * event.tether_heal_amp )
end


function Latch( event )
	-- Variables
	local caster	= event.caster
	local ability	= event.ability
	local target 	= ability.tether_ally

	local tickInterval	= event.tick_interval
	local latchSpeed	= event.latch_speed
	local latchDistance	= event.latch_distance_to_target

	local casterOrigin	= caster:GetAbsOrigin()
	local targetOrigin	= target:GetAbsOrigin()

	-- Calculate the distance
	local casterDir = casterOrigin - targetOrigin
	local distToAlly = casterDir:Length2D()
	casterDir = casterDir:Normalized()

	if distToAlly > latchDistance then

		-- Leap to the target
		distToAlly = distToAlly - latchSpeed * tickInterval
		distToAlly = math.max( distToAlly, latchDistance )	-- Clamp this value

		local pos = targetOrigin + casterDir * distToAlly
		pos = GetGroundPosition( pos, caster )

		caster:SetAbsOrigin( pos )

	end

	if distToAlly <= latchDistance then
		-- We've reached, so finish latching
		caster:RemoveModifierByName( event.latch_modifier )
	end

end


function FireTetherProjectile( event )
	-- Variables
	local caster	= event.caster
	local target	= event.target
	local ability	= event.ability

	local lineRadius	= event.tether_line_radius
	local tickInterval	= event.tick_interval

	local casterOrigin	= caster:GetAbsOrigin()
	local targetOrigin	= target:GetAbsOrigin()

	local velocity = targetOrigin - casterOrigin

	-- Create a projectile
	ProjectileManager:CreateLinearProjectile( {
		Ability				= ability,
		vSpawnOrigin		= casterOrigin,
		fDistance			= velocity:Length2D(),
		fStartRadius		= lineRadius,
		fEndRadius			= lineRadius,
		Source				= caster,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime			= GameRules:GetGameTime() + tickInterval + 0.03,
		bDeleteOnHit		= false,
		vVelocity			= velocity / tickInterval,
	} )
end


function OnProjectileHit( event )
	-- Variables
	local caster	= event.caster
	local target	= event.target	-- An enemy unit
	local ability	= event.ability

	-- Already got slowed
	if ability.tether_slowedUnits[target] then
		return
	end

	-- Apply slow debuff
	ability:ApplyDataDrivenModifier( caster, target, event.slow_modifier, {} )

	-- An enemy unit may only be slowed once per cast.
	-- We store the enemy unit to the hashset, so we can check whether the unit has got debuff already later on.
	ability.tether_slowedUnits[target] = true
end



function LevelUpAbility( event )
	local caster = event.caster
	local this_ability = event.ability		
	local this_abilityName = this_ability:GetAbilityName()
	local this_abilityLevel = this_ability:GetLevel()

	-- The ability to level up
	local ability_name = event.ability_name
	print(ability_name)
	print(caster:FindAbilityByName(ability_name))
	local ability_handle = caster:FindAbilityByName(ability_name)	
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end
end


function StopSound( event )
	StopSoundEvent( event.sound_name, event.caster )
end
