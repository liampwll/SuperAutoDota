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

function SAD:RandomTier()
	local Tier = 0
	local TierOdds = self.ShopOdds[self.GameStateNettable.Round] or self.ShopOdds[#self.ShopOdds]
	local Rand = RandomFloat(0.0, 1.0)
	while Rand >= 0.0 do
		Tier = Tier + 1
		Rand = Rand - TierOdds[Tier]
	end
	return Tier
end

function SAD:RandomHeroShop()
	local Shop = {}

	for I = 1, 5 do
		local Tier = self:RandomTier()
		local Hero = self.HeroesByCost[Tier][RandomInt(1, #self.HeroesByCost[Tier])]
		Shop[I] = {Name = Hero.Key, Ability = Hero.Value.Ability1, Cost = Tier, IsSold = false}
	end
	-- Shop[1] = {Name = "npc_dota_hero_clinkz", Ability = "aaa", Cost = 1, IsSold = false}

	self:GameStateNettableSetAndPush({HeroShop = Shop})
end

function SAD:RandomItemShop()
	local Shop = {}

	for I = 1, 3 do
		local Tier = self:RandomTier()
		local Item = self.ItemsByCost[Tier][RandomInt(1, #self.ItemsByCost[Tier])]
		Shop[I] = {Name = Item, Cost = Tier, IsSold = false}
	end

	self:GameStateNettableSetAndPush({ItemShop = Shop})
end
