sad_big_range = class({})

function sad_big_range:IsPermanent()
	return true
end

function sad_big_range:RemoveOnDeath()
	return true
end

function sad_big_range:IsPurgable()
	return false
end

function sad_big_range:IsHidden()
	return true
end

function sad_big_range:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function sad_big_range:DeclareFunctions()
	return {MODIFIER_PROPERTY_CAST_RANGE_BONUS, MODIFIER_PROPERTY_ATTACK_RANGE_BASE_OVERRIDE, MODIFIER_PROPERTY_DISABLE_AUTOATTACK}
end

function sad_big_range:GetModifierAttackRangeOverride()
	return 10000
end

function sad_big_range:GetModifierCastRangeBonus()
	return 10000
end

function sad_big_range:GetDisableAutoAttack()
	return 1
end
