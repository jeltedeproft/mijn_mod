function Fissure( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local particle_fissure = keys.particle_fissure
	local sound_fissure = keys.sound_fissure
	local target = keys.target_points[1]
	local point = target

	-- Parameters
	local fissure_range    = ability:GetLevelSpecialValueFor("fissure_range", ability_level)
	local fissure_duration = ability:GetLevelSpecialValueFor("fissure_duration", ability_level)
	local fissure_radius   = ability:GetLevelSpecialValueFor("fissure_radius", ability_level)
	local stun_duration    = ability:GetLevelSpecialValueFor("stun_duration", ability_level)


	local initial_pos = caster:GetAbsOrigin()
	local vector_forward = (point - initial_pos)
	vector_forward = vector_forward:Normalized()
	local point = initial_pos + vector_forward * fissure_range

	-- Play sound
	caster:EmitSound(sound_fissure)

	--launch particles
	local nFXIndex = ParticleManager:CreateParticle( particle_fissure, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex, 0, (initial_pos + vector_forward * 100) )
	ParticleManager:SetParticleControl( nFXIndex, 1, point)
	ParticleManager:SetParticleControl( nFXIndex, 2, Vector( fissure_duration, 0, 0 ) )

	local nFXIndex2 = ParticleManager:CreateParticle( particle_fissure, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex2, 0, RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward * 100)) )
	ParticleManager:SetParticleControl( nFXIndex2, 1, RotatePosition(initial_pos, QAngle(0, 60, 0), point) )
	ParticleManager:SetParticleControl( nFXIndex2, 2, Vector( fissure_duration, 0, 0 ) )

	local nFXIndex3 = ParticleManager:CreateParticle( particle_fissure, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex3, 0, RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward * 100)) )
	ParticleManager:SetParticleControl( nFXIndex3, 1, RotatePosition(initial_pos, QAngle(0, -60, 0), point) )
	ParticleManager:SetParticleControl( nFXIndex3, 2, Vector( fissure_duration, 0, 0 ) )

	local nFXIndex4 = ParticleManager:CreateParticle( particle_fissure, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex4, 0, RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward * 100)) )
	ParticleManager:SetParticleControl( nFXIndex4, 1, RotatePosition(initial_pos, QAngle(0, 120, 0), point) )
	ParticleManager:SetParticleControl( nFXIndex4, 2, Vector( fissure_duration, 0, 0 ) )

	local nFXIndex5 = ParticleManager:CreateParticle( particle_fissure, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex5, 0, RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward * 100)) )
	ParticleManager:SetParticleControl( nFXIndex5, 1, RotatePosition(initial_pos, QAngle(0, -120, 0), point) )
	ParticleManager:SetParticleControl( nFXIndex5, 2, Vector( fissure_duration, 0, 0 ) )

	local nFXIndex6 = ParticleManager:CreateParticle( particle_fissure, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex6, 0, RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward * 100)) )
	ParticleManager:SetParticleControl( nFXIndex6, 1, RotatePosition(initial_pos, QAngle(0, 180, 0), point) )
	ParticleManager:SetParticleControl( nFXIndex6, 2, Vector( fissure_duration, 0, 0 ) )

	--after particles are launched, we still need to aply the stun, therefor i need to create 6 dummy projectiles, so i can use onprojectilehitunit

	local fissure_projectile1 = {
		Ability				= ability,
		EffectName			= particle_fissure,
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= fissure_range,
		fStartRadius		= fissure_radius - 50,
		fEndRadius			= fissure_radius - 50,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
	--	iUnitTargetFlags	= ,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
	 	fExpireTime			= fissure_duration,
		bDeleteOnHit		= true,
		vVelocity			= point,
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	ProjectileManager:CreateLinearProjectile(fissure_projectile1)

		local fissure_projectile2 = {
		Ability				= ability,
		EffectName			= particle_fissure,
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= fissure_range,
		fStartRadius		= fissure_radius - 50,
		fEndRadius			= fissure_radius - 50,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
	--	iUnitTargetFlags	= ,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
	 	fExpireTime			= fissure_duration,
		bDeleteOnHit		= true,
		vVelocity			= RotatePosition(initial_pos, QAngle(0, 60, 0), point),
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	ProjectileManager:CreateLinearProjectile(fissure_projectile2)

		local fissure_projectile3 = {
		Ability				= ability,
		EffectName			= particle_fissure,
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= fissure_range,
		fStartRadius		= fissure_radius - 50,
		fEndRadius			= fissure_radius - 50,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
	--	iUnitTargetFlags	= ,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
	 	fExpireTime			= fissure_duration,
		bDeleteOnHit		= true,
		vVelocity			= RotatePosition(initial_pos, QAngle(0, -60, 0), point),
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	ProjectileManager:CreateLinearProjectile(fissure_projectile3)

		local fissure_projectile4 = {
		Ability				= ability,
		EffectName			= particle_fissure,
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= fissure_range,
		fStartRadius		= fissure_radius - 50,
		fEndRadius			= fissure_radius - 50,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
	--	iUnitTargetFlags	= ,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
	 	fExpireTime			= fissure_duration,
		bDeleteOnHit		= true,
		vVelocity			= RotatePosition(initial_pos, QAngle(0, 120, 0), point),
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	ProjectileManager:CreateLinearProjectile(fissure_projectile4)

		local fissure_projectile5 = {
		Ability				= ability,
		EffectName			= particle_fissure,
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= fissure_range,
		fStartRadius		= fissure_radius - 50,
		fEndRadius			= fissure_radius - 50,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
	--	iUnitTargetFlags	= ,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
	 	fExpireTime			= fissure_duration,
		bDeleteOnHit		= true,
		vVelocity			= RotatePosition(initial_pos, QAngle(0, -120, 0), point),
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	ProjectileManager:CreateLinearProjectile(fissure_projectile5)

		local fissure_projectile6 = {
		Ability				= ability,
		EffectName			= particle_fissure,
		vSpawnOrigin		= caster:GetAbsOrigin(),
		fDistance			= fissure_range,
		fStartRadius		= fissure_radius - 50,
		fEndRadius			= fissure_radius - 50,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
	--	iUnitTargetFlags	= ,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
	 	fExpireTime			= fissure_duration,
		bDeleteOnHit		= true,
		vVelocity			= RotatePosition(initial_pos, QAngle(0, 180, 0), point),
		bProvidesVision		= false,
	--	iVisionRadius		= ,
	--	iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	ProjectileManager:CreateLinearProjectile(fissure_projectile6)


	-- Now to make sure that people cannot walk over the fissure i need to create a line of dummy units for every fissure

	--parameters for creating dummys
	local number_of_dummys_line = fissure_range / fissure_radius

	--line of dummys for fissure 1
	local dummy_forward_1 = CreateUnitByName("npc_dummy_unit_", (initial_pos + vector_forward * (fissure_radius)), false, nul, nul, caster:GetTeam())
	local dummy_forward_2 = CreateUnitByName("npc_dummy_unit_", (initial_pos + vector_forward * (2 * fissure_radius )), false, nul, nul, caster:GetTeam())
	local dummy_forward_3 = CreateUnitByName("npc_dummy_unit_", (initial_pos + vector_forward * (3 * fissure_radius )), false, nul, nul, caster:GetTeam())
	local dummy_forward_4 = CreateUnitByName("npc_dummy_unit_", (initial_pos + vector_forward * (4 * fissure_radius )), false, nul, nul, caster:GetTeam())
	local dummy_forward_5 = CreateUnitByName("npc_dummy_unit_", (initial_pos + vector_forward * (5 * fissure_radius )), false, nul, nul, caster:GetTeam())
	local dummy_forward_6 = CreateUnitByName("npc_dummy_unit_", (initial_pos + vector_forward * (6 * fissure_radius )), false, nul, nul, caster:GetTeam())

	dummy_forward_1:SetHullRadius(150)
	dummy_forward_2:SetHullRadius(150)
	dummy_forward_3:SetHullRadius(150)
	dummy_forward_4:SetHullRadius(150)
	dummy_forward_5:SetHullRadius(150)
	dummy_forward_6:SetHullRadius(150)

	dummy_forward_1:SetAbsOrigin((initial_pos + vector_forward * (fissure_radius)))
	dummy_forward_2:SetAbsOrigin((initial_pos + vector_forward * (2 * fissure_radius )))
	dummy_forward_3:SetAbsOrigin((initial_pos + vector_forward * (3 * fissure_radius )))
	dummy_forward_4:SetAbsOrigin((initial_pos + vector_forward * (4 * fissure_radius )))
	dummy_forward_5:SetAbsOrigin((initial_pos + vector_forward * (5 * fissure_radius )))
	dummy_forward_6:SetAbsOrigin((initial_pos + vector_forward * (6 * fissure_radius )))
	

	--line of dummys for fissure 2
	local dummy_60degrees_plus_1 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward * (fissure_radius))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_plus_2 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (fissure_radius * 2))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_plus_3 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_plus_4 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_plus_5 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_plus_6 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))), false, nul, nul, caster:GetTeam())


	dummy_60degrees_plus_1:SetHullRadius(150)
	dummy_60degrees_plus_2:SetHullRadius(150)
	dummy_60degrees_plus_3:SetHullRadius(150)
	dummy_60degrees_plus_4:SetHullRadius(150)
	dummy_60degrees_plus_5:SetHullRadius(150)
	dummy_60degrees_plus_6:SetHullRadius(150)

	dummy_60degrees_plus_1:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward * (fissure_radius))))
	dummy_60degrees_plus_2:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (fissure_radius * 2))))
	dummy_60degrees_plus_3:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))))
	dummy_60degrees_plus_4:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))))
	dummy_60degrees_plus_5:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))))
	dummy_60degrees_plus_6:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 60, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))))

		--line of dummys for fissure 3
	local dummy_60degrees_minus_1 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward * (fissure_radius))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_minus_2 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward * (fissure_radius * 2))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_minus_3 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_minus_4 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_minus_5 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_60degrees_minus_6 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))), false, nul, nul, caster:GetTeam())


	dummy_60degrees_minus_1:SetHullRadius(150)
	dummy_60degrees_minus_2:SetHullRadius(150)
	dummy_60degrees_minus_3:SetHullRadius(150)
	dummy_60degrees_minus_4:SetHullRadius(150)
	dummy_60degrees_minus_5:SetHullRadius(150)
	dummy_60degrees_minus_6:SetHullRadius(150)

	dummy_60degrees_minus_1:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward * (fissure_radius))))
	dummy_60degrees_minus_2:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward * (fissure_radius * 2))))
	dummy_60degrees_minus_3:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))))
	dummy_60degrees_minus_4:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))))
	dummy_60degrees_minus_5:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))))
	dummy_60degrees_minus_6:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -60, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))))



		--line of dummys for fissure 4
	local dummy_120degrees_plus_1 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward * (fissure_radius))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_plus_2 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward * (fissure_radius * 2))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_plus_3 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_plus_4 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_plus_5 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_plus_6 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))), false, nul, nul, caster:GetTeam())



	dummy_120degrees_plus_1:SetHullRadius(150)
	dummy_120degrees_plus_2:SetHullRadius(150)
	dummy_120degrees_plus_3:SetHullRadius(150)
	dummy_120degrees_plus_4:SetHullRadius(150)
	dummy_120degrees_plus_5:SetHullRadius(150)
	dummy_120degrees_plus_6:SetHullRadius(150)

	dummy_120degrees_plus_1:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward * (fissure_radius))))
	dummy_120degrees_plus_2:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward * (fissure_radius * 2))))
	dummy_120degrees_plus_3:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))))
	dummy_120degrees_plus_4:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))))
	dummy_120degrees_plus_5:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))))
	dummy_120degrees_plus_6:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 120, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))))



		--line of dummys for fissure 5
	local dummy_120degrees_minus_1 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward * (fissure_radius))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_minus_2 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward * (fissure_radius * 2))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_minus_3 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_minus_4 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_minus_5 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_120degrees_minus_6 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))), false, nul, nul, caster:GetTeam())



	dummy_120degrees_minus_1:SetHullRadius(150)
	dummy_120degrees_minus_2:SetHullRadius(150)
	dummy_120degrees_minus_3:SetHullRadius(150)
	dummy_120degrees_minus_4:SetHullRadius(150)
	dummy_120degrees_minus_5:SetHullRadius(150)
	dummy_120degrees_minus_6:SetHullRadius(150)

	dummy_120degrees_minus_1:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward * (fissure_radius))))
	dummy_120degrees_minus_2:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward * (fissure_radius * 2))))
	dummy_120degrees_minus_3:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))))
	dummy_120degrees_minus_4:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))))
	dummy_120degrees_minus_5:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))))
	dummy_120degrees_minus_6:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, -120, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))))



		--line of dummys for fissure 6
	local dummy_180degrees_plus_1 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward * (fissure_radius))), false, nul, nul, caster:GetTeam())
	local dummy_180degrees_plus_2 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward * (fissure_radius * 2))), false, nul, nul, caster:GetTeam())
	local dummy_180degrees_plus_3 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_180degrees_plus_4 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_180degrees_plus_5 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))), false, nul, nul, caster:GetTeam())
	local dummy_180degrees_plus_6 = CreateUnitByName("npc_dummy_unit_", RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))), false, nul, nul, caster:GetTeam())


	dummy_180degrees_plus_1:SetHullRadius(150)
	dummy_180degrees_plus_2:SetHullRadius(150)
	dummy_180degrees_plus_3:SetHullRadius(150)
	dummy_180degrees_plus_4:SetHullRadius(150)
	dummy_180degrees_plus_5:SetHullRadius(150)
	dummy_180degrees_plus_6:SetHullRadius(150)

	dummy_180degrees_plus_1:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward * (fissure_radius))))
	dummy_180degrees_plus_2:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward * (fissure_radius * 2))))
	dummy_180degrees_plus_3:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (3 * fissure_radius ))))
	dummy_180degrees_plus_4:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (4 * fissure_radius ))))
	dummy_180degrees_plus_5:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (5 * fissure_radius ))))
	dummy_180degrees_plus_6:SetAbsOrigin(RotatePosition(initial_pos, QAngle(0, 180, 0), (initial_pos + vector_forward *  (6 * fissure_radius ))))


	-- now we need to make sure that everybody hit by the fissure will get a good position again outside of fissure
	local units = FindUnitsInRadius(caster:GetTeamNumber(), initial_pos, nil, fissure_range, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)	
	
	for _,unit in pairs(units) do
		if unit:HasMovementCapability() then
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		end
	end

	--last thing, we count till fissure time is over and then remove all dummys
  Timers:CreateTimer(fissure_duration, function()
            dummy_forward_1:RemoveSelf()
			dummy_forward_2:RemoveSelf()
			dummy_forward_3:RemoveSelf()
			dummy_forward_4:RemoveSelf()
			dummy_forward_5:RemoveSelf()
			dummy_forward_6:RemoveSelf()

			dummy_60degrees_plus_1:RemoveSelf()
			dummy_60degrees_plus_2:RemoveSelf()
			dummy_60degrees_plus_3:RemoveSelf()
			dummy_60degrees_plus_4:RemoveSelf()
			dummy_60degrees_plus_5:RemoveSelf()
			dummy_60degrees_plus_6:RemoveSelf()

			dummy_60degrees_minus_1:RemoveSelf()
			dummy_60degrees_minus_2:RemoveSelf()
			dummy_60degrees_minus_3:RemoveSelf()
			dummy_60degrees_minus_4:RemoveSelf()
			dummy_60degrees_minus_5:RemoveSelf()
			dummy_60degrees_minus_6:RemoveSelf()


			dummy_120degrees_plus_1:RemoveSelf()
			dummy_120degrees_plus_2:RemoveSelf()
			dummy_120degrees_plus_3:RemoveSelf()
			dummy_120degrees_plus_4:RemoveSelf()
			dummy_120degrees_plus_5:RemoveSelf()
			dummy_120degrees_plus_6:RemoveSelf()

			dummy_120degrees_minus_1:RemoveSelf()
			dummy_120degrees_minus_2:RemoveSelf()
			dummy_120degrees_minus_3:RemoveSelf()
			dummy_120degrees_minus_4:RemoveSelf()
			dummy_120degrees_minus_5:RemoveSelf()
			dummy_120degrees_minus_6:RemoveSelf()

			dummy_180degrees_plus_1:RemoveSelf()
			dummy_180degrees_plus_2:RemoveSelf()
			dummy_180degrees_plus_3:RemoveSelf()
			dummy_180degrees_plus_4:RemoveSelf()
			dummy_180degrees_plus_5:RemoveSelf()
			dummy_180degrees_plus_6:RemoveSelf()
    end
  )

end

function Enchant_Totem( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local particle_buff = keys.particle_buff
	local particle_hero_effect = keys.particle_hero_effect
	local particle_enchant_totem = keys.particle_enchant_totem

	--animation parameters
	local sAttachLock = "attach_attack1"
	local initial_pos = caster:GetAbsOrigin()
	
	--create particle
	nFXIndex = ParticleManager:CreateParticle( particle_buff, PATTACH_ABSORIGIN_FOLLOW, caster )

	ParticleManager:SetParticleControlEnt(nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, sAttachLock, initial_pos, true );

	nFXIndex2 = ParticleManager:CreateParticle( particle_hero_effect, PATTACH_ABSORIGIN_FOLLOW, caster )

	ParticleManager:SetParticleControlEnt(nFXIndex2, 0, caster, PATTACH_POINT_FOLLOW, sAttachLock, initial_pos, true );

	nFXIndex3 = ParticleManager:CreateParticle( particle_enchant_totem, PATTACH_ABSORIGIN_FOLLOW, caster )

	ParticleManager:SetParticleControlEnt(nFXIndex3, 0, caster, PATTACH_POINT_FOLLOW, sAttachLock, initial_pos, true );
end

function Aftershock( keys )
	local caster = keys.caster
	local target = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local cast_ability = keys.event_ability
	local aftershock_particle = keys.aftershock_particle
	local aftershock_sound = keys.aftershock_sound

	-- Parameters
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)

    if cast_ability and cast_ability:GetManaCost( cast_ability:GetLevel() - 1 ) > 0 and cast_ability:GetCooldown( cast_ability:GetLevel() - 1 ) > 1.01  then

	      local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)	
	      print(enemies)

	      local after_shock_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_loadout.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	      ParticleManager:SetParticleControl(after_shock_particle, 1, caster:GetAbsOrigin())

	      ability:ApplyDataDrivenModifier(caster, caster, "modifier_shock_particle", {})

	      for _,enemy in pairs(enemies) do		
		  enemy:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
		  ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = damage, damage_type = ability:GetAbilityDamageType()})
	      
	      end      
	 end
end

function earthshaker_echo_slam( keys )
	local caster = keys.caster
	local target = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local particle_echo = keys.particle_echo
    local particle_echo_start = keys.particle_echo_start        
    local sound_big = keys.sound_big
    local sound_echo = keys.sound_echo                  
    local sound_small = keys.sound_small

    local position = caster:GetAbsOrigin()

	local iAoE = ability:GetSpecialValueFor( "echo_slam_damage_range" )
	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( nFXIndex, 0, position )
	local enemies = FindUnitsInRadius( caster:GetTeamNumber(), position, caster, iAoE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )		
	if #enemies > 0 then
	EmitSoundOnLocationWithCaster( position, sound_big, caster )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 2*#enemies, 1, 1 ) )
		for _,hTarget in pairs(enemies) do
			if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) then
				
				local damage = {
					victim = hTarget,
					attacker = caster,
					damage = ability:GetAbilityDamage(),
					damage_type = ability:GetAbilityDamageType(),
					ability = ability
				}
				ApplyDamage(damage)
				if hTarget ~= caster then
					ability:ApplyDataDrivenModifier(caster, hTarget, "modifier_echo_slam_echo", {})
				end
			end
		end
	else
		EmitSoundOnLocationWithCaster( position, sound_small , caster )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 1, 1, 1 ) )
	end
	ParticleManager:ReleaseParticleIndex( nFXIndex )	
end

function earthshaker_echo_slam_Echoes( keys )
	local ability = keys.ability
	local hCaster = keys.caster
	local hTarget = keys.target
	local teamnumber = hCaster:GetTeamNumber()
	local position = hTarget:GetAbsOrigin()
	local iAoE = ability:GetSpecialValueFor( "echo_slam_echo_range" )
	local info = 
	{
		Source = hTarget,
		Ability = ability,	
		EffectName = "particles/units/heroes/hero_earthshaker/earthshaker_echoslam.vpcf",
		iMoveSpeed = iAoE,
		vSourceLoc= position,
		bDrawsOnMinimap = false, 
		bDodgeable = true,
		bIsAttack = false, 
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = nil,
		bProvidesVision = false,
		iVisionRadius = 0,
		iVisionTeamNumber = hCaster:GetTeamNumber()
	}
	
	local enemies = FindUnitsInRadius( teamnumber, position, hTarget, iAoE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
	if #enemies > 0 then
		for _,hEcho in pairs(enemies) do
			if hEcho ~= nil and ( not hEcho:IsMagicImmune() ) and ( not hEcho:IsInvulnerable() ) and hEcho ~= hTarget then
				print(1)
				info.Target = hEcho
				projectile = ProjectileManager:CreateTrackingProjectile(info)
				if hTarget:IsHero() and hCaster:HasScepter() then
					projectile = ProjectileManager:CreateTrackingProjectile(info)
				end
			end
		end
	end
end

function earthshaker_echo_slam_lua( keys )
	local ability = keys.ability
	local hTarget = keys.target 
	local caster = keys.caster
	local iDamage = ability:GetSpecialValueFor( "echo_slam_echo_damage" )
	local damage = {
		victim = hTarget,
		attacker = caster,
		damage = iDamage,
		damage_type = ability:GetAbilityDamageType(),
		ability = ability
	}
	ApplyDamage( damage )
	return true
end  
