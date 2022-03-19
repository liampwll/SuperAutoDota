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

sad_sell = class({})

function sad_sell:OnSpellStart()
	local SAD = GameRules.SAD
	SAD:RemovePlayerHeroByID(self:GetCaster().ID)
	SAD:GameStateNettableSetAndPush({Gold = SAD.GameStateNettable.Gold + 1})
end
