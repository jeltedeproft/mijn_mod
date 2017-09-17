--[[
	Author: Noya
	Date: 9.1.2015.
	Absorbs damage up to the max absorb, substracting from the shield until removed.
]]
function AphoticShield( event )
	-- Variables
	local target = event.target
	local max_damage_absorb = event.ability:GetLevelSpecialValueFor("damage_absorb", event.ability:GetLevel() - 1 )
	local shield_size = target:GetModelRadius() * 0.7

	-- Strong Dispel
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = true
	local RemoveExceptions = false
	target:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

	-- Reset the shield
	target.AphoticShieldRemaining = max_damage_absorb

	-- Particle. Need to wait one frame for the older particle to be destroyed
	Timers:CreateTimer(0.01, function() 
		target.ShieldParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(target.ShieldParticle, 1, Vector(shield_size,0,shield_size))
		ParticleManager:SetParticleControl(target.ShieldParticle, 2, Vector(shield_size,0,shield_size))
		ParticleManager:SetParticleControl(target.ShieldParticle, 4, Vector(shield_size,0,shield_size))
		ParticleManager:SetParticleControl(target.ShieldParticle, 5, Vector(shield_size,0,0))

		-- Proper Particle attachment courtesy of BMD. Only PATTACH_POINT_FOLLOW will give the proper shield position
		ParticleManager:SetParticleControlEnt(target.ShieldParticle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	end)
end

function AphoticShieldAbsorb( event )
	-- Variables
	local damage = event.DamageTaken
	local unit = event.unit
	local ability = event.ability
	
	-- Track how much damage was already absorbed by the shield
	local shield_remaining = unit.AphoticShieldRemaining
	print("Shield Remaining: "..shield_remaining)
	print("Damage Taken pre Absorb: "..damage)

	-- Check if the unit has the borrowed time modifier
	if not unit:HasModifier("modifier_borrowed_time") then
		-- If the damage is bigger than what the shield can absorb, heal a portion
		if damage > shield_remaining then
			local newHealth = unit.OldHealth - damage + shield_remaining
			print("Old Health: "..unit.OldHealth.." - New Health: "..newHealth.." - Absorbed: "..shield_remaining)
			unit:SetHealth(newHealth)
		else
			local newHealth = unit.OldHealth			
			unit:SetHealth(newHealth)
			print("Old Health: "..unit.OldHealth.." - New Health: "..newHealth.." - Absorbed: "..damage)
		end

		-- Reduce the shield remaining and remove
		unit.AphoticShieldRemaining = unit.AphoticShieldRemaining-damage
		if unit.AphoticShieldRemaining <= 0 then
			unit.AphoticShieldRemaining = nil
			unit:RemoveModifierByName("modifier_aphotic_shield")
			print("--Shield removed--")
		end

		if unit.AphoticShieldRemaining then
			print("Shield Remaining after Absorb: "..unit.AphoticShieldRemaining)
			print("---------------")
		end
	end

end

-- Destroys the particle when the modifier is destroyed. Also plays the sound
function EndShieldParticle( event )
	local target = event.target
	target:EmitSound("Hero_Abaddon.AphoticShield.Destroy")
	ParticleManager:DestroyParticle(target.ShieldParticle,false)
end


-- Keeps track of the targets health
function AphoticShieldHealth( event )
	local target = event.target

	target.OldHealth = target:GetHealth()
end

function BorrowedTimeActivate( keys )

	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local threshold = ability:GetLevelSpecialValueFor( "hp_threshold" , ability:GetLevel() - 1  )
	local cooldown = ability:GetCooldown( ability:GetLevel() - 1 ) 
	local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1  )
	local duration_scepter = ability:GetLevelSpecialValueFor( "duration_scepter" , ability:GetLevel() - 1  )
	local scepter = HasScepter(caster)

	print("doing borrowed time")

	-- Apply the modifier
	if ability:GetCooldownTimeRemaining() == 0 then
		print("ability:GetCooldownTimeRemaining()")
		if caster:GetHealth() < 400 then
			print("caster:GetHealth() < 400")
			-- prevents illusions from gaining the borrowed time buff
			if not caster:IsIllusion() and caster:IsAlive() then
				print("BorrowedTimePurge")
				BorrowedTimePurge( keys )
				print("caster:EmitSoundHero_Abaddon.BorrowedTime")
				caster:EmitSound("Hero_Abaddon.BorrowedTime")
				print("ability:StartCooldown(cooldown)")
				ability:StartCooldown(cooldown)
				print("einde")
			end
		end
	end
end

function BorrowedTimeHeal( keys )

	-- Variables
	local damage = keys.DamageTaken
	local caster = keys.caster
	local ability = keys.ability
	local scepter = HasScepter(caster)
	local radius = keys.ability:GetLevelSpecialValueFor("redirect_range", ability:GetLevel() - 1 )

	local allies = FindUnitsInRadius(caster.GetTeam(caster), caster.GetAbsOrigin(caster), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	if scepter == true then
		caster:Heal(damage, caster)
		for _,unit in pairs(allies) do
			unit:Heal(damage / #allies, caster)
		end
	else
		caster:Heal(damage * 2, caster)
	end
end

function BorrowedTimePurge( keys )
	local caster = keys.caster
	local ability = keys.ability
	local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1  )
	local duration_scepter = ability:GetLevelSpecialValueFor( "duration_scepter" , ability:GetLevel() - 1  )
	local scepter = HasScepter(caster)

	-- Strong Dispel
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = true
	local RemoveExceptions = false
	caster:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
	if scepter == true then
		ability:ApplyDataDrivenModifier( caster, caster, "modifier_borrowed_time", { duration = duration_scepter })
	else
		ability:ApplyDataDrivenModifier( caster, caster, "modifier_borrowed_time", { duration = duration })
	end

	-- Toggle the ability off
	ability:ToggleAbility()
end

function BorrowedTimeAllies( keys )
	local caster = keys.caster
	local unit = keys.unit
	local ability = keys.ability
	local damage_taken = keys.DamageTaken
	local attacker = keys.attacker
	local redirect = ability:GetLevelSpecialValueFor("redirect", ability:GetLevel() - 1 )

	-- If this unit is an illusion or currently has Borrowed Time active, do nothing
	if unit:IsIllusion() or unit:HasModifier("modifier_borrowed_time") then
		return nil
	end

	local redirect_damage = damage_taken * ( redirect / ( 1 - redirect ) )
	
	ApplyDamage({ victim = caster, attacker = attacker, damage = redirect_damage, damage_type = DAMAGE_TYPE_PURE })
end

--[[
	Author: Noya
	Date: 14.1.2015.
	If cast on an ally it will heal, if cast on an enemy it will do damage
]]
function DeathCoil( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local damage = ability:GetLevelSpecialValueFor( "target_damage" , ability:GetLevel() - 1  )
	local self_damage = ability:GetLevelSpecialValueFor( "self_damage" , ability:GetLevel() - 1  )
	local heal = ability:GetLevelSpecialValueFor( "heal_amount" , ability:GetLevel() - 1 )
	local projectile_speed = ability:GetSpecialValueFor( "projectile_speed" )
	local particle_name = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf"

	-- Play the ability sound
	caster:EmitSound("Hero_Abaddon.DeathCoil.Cast")
	target:EmitSound("Hero_Abaddon.DeathCoil.Target")

	-- If the target and caster are on a different team, do Damage. Heal otherwise
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({ victim = target, attacker = caster, damage = damage,	damage_type = DAMAGE_TYPE_MAGICAL })
	else
		target:Heal( heal, caster)
	end

	-- Self Damage
	ApplyDamage({ victim = caster, attacker = caster, damage = self_damage,	damage_type = DAMAGE_TYPE_PURE })

	-- Create the projectile
	local info = {
		Target = target,
		Source = caster,
		Ability = ability,
		EffectName = particle_name,
		bDodgeable = false,
			bProvidesVision = true,
			iMoveSpeed = projectile_speed,
        iVisionRadius = 0,
        iVisionTeamNumber = caster:GetTeamNumber(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	}
	ProjectileManager:CreateTrackingProjectile( info )

end