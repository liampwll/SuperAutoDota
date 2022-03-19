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

sad_combine = class({})

function sad_combine:OnSpellStart()
	local SAD = GameRules.SAD
	for I = 2, SAD.LevelsPerStar do
		self:GetCursorTarget():HeroLevelUp(false)
	end
	self:GetCursorTarget():HeroLevelUp(true)
	self:GetCursorTarget():SetAbilityPoints(0)
	self:GetCursorTarget():GetAbilityByIndex(0):SetLevel(self:GetCursorTarget():GetAbilityByIndex(0):GetLevel() + 1)
	SAD.PrivateGameState.PlayerTeam[self:GetCursorTarget().ID].Stars = SAD.PrivateGameState.PlayerTeam[self:GetCursorTarget().ID].Stars + 1
	self:GetCursorTarget():SetMaxMana(self:GetCursorTarget():GetAbilityByIndex(0):GetManaCost(-1) * 1.1)
	if SAD.PrivateGameState.PlayerTeam[self:GetCursorTarget().ID].Stars == 3 then
		self:GetCursorTarget():FindAbilityByName("sad_combine"):SetActivated(false)
	end
	SAD:RemovePlayerHeroByID(self:GetCaster().ID)
end

function sad_combine:CastFilterResultTarget(Target)
	if self:GetCaster() == Target or Target:GetName() ~= self:GetCaster():GetName() or self:GetCaster():GetLevel() ~= Target:GetLevel() then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end
