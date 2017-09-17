function toggleOn(keys)
	local ability = keys.ability
	local caster = keys.caster
	caster.toggleused = true
	GameRules:SetTimeOfDay(0)
	
end

function toggleOff(keys)
	local ability = keys.ability
	local caster = keys.caster
	caster.toggleused = true
	GameRules:SetTimeOfDay(0.5)
end