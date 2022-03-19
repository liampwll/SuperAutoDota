function SAD:GetEnemyForRoundOffline(Callback)
	local Enemy = {ID = "76561198053315971", Team = {}}
	local GoldLeft = self.GameStateNettable.Round * self.GoldPerRound
	local PossibleTiles = {}
	for GridID, Data in pairs(self.Grid) do
		if not Data.IsFriendly then
			table.insert(PossibleTiles, GridID)
		end
	end
	for I = 1, #PossibleTiles - 1 do
		local J = RandomInt(I, #PossibleTiles)
		PossibleTiles[I], PossibleTiles[J] = PossibleTiles[J], PossibleTiles[I]
	end
	for I = 1, self.GameStateNettable.MaxUnitsInArena do
		local Tier = self:RandomTier()
		if Tier > GoldLeft then
			Tier = GoldLeft
		end
		GoldLeft = GoldLeft - Tier
		local Hero = self.HeroesByCost[Tier][RandomInt(1, #self.HeroesByCost[Tier])]
		Enemy.Team[I] = {Name = Hero.Key, Item = nil, Stars = 1, Tier = Hero.Value.SADCost, GridID = PossibleTiles[I]}
		if GoldLeft == 0 then
			break
		end
	end

	while GoldLeft > 0 do
		local NoUpgradePossible = true
		for ID, Data in pairs(Enemy.Team) do
			if (Data.Tier * Data.Stars) <= GoldLeft and Data.Stars < 3 then
				Data.Stars = Data.Stars + 1
				GoldLeft = GoldLeft - (Data.Tier * Data.Stars)
				NoUpgradePossible = false
				break
			end
		end
		if NoUpgradePossible then
			break
		end
	end

	while GoldLeft > 0 do
		local NoItemPossible = true
		for ID, Data in pairs(Enemy.Team) do
			if Data.Item == nil then
				local Tier = self:RandomTier()
				if Tier > GoldLeft then
					Tier = GoldLeft
				end
				GoldLeft = GoldLeft - Tier
				Data.Item = self.ItemsByCost[Tier][RandomInt(1, #self.ItemsByCost[Tier])]
				NoItemPossible = false
				break
			end
		end
		if NoItemPossible then
			break
		end
	end

	Callback(Enemy)
end
