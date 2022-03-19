-- Copyright (C) 2022 Liam Powell
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
