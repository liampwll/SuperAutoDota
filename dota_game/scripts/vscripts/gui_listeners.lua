function SAD:SetupGUIListeners()
	CustomGameEventManager:RegisterListener(
		"SADTryBuyItem",
		function(UserID, Event)
			if (not self.GameStateNettable.IsInMatch) or self.GameStateNettable.IsBattleRunning then
				return
			elseif self.GameStateNettable.ItemShop[Event.Index].Cost > self.GameStateNettable.Gold then
				self:MessageToPlayer("Not enough gold.")
			else
				self:GameStateNettableSetAndPush({Gold = self.GameStateNettable.Gold - self.GameStateNettable.ItemShop[Event.Index].Cost})
				self.GameStateNettable.ItemShop[Event.Index].IsSold = true
				self:GameStateNettableSetAndPush({ItemShop = self.GameStateNettable.ItemShop})
				self:MessageToPlayer("Item dropped above arena.")
				self:SpawnItem(self.GameStateNettable.ItemShop[Event.Index].Name)
			end
	end)

	CustomGameEventManager:RegisterListener(
		"SADTryBuyHero",
		function(UserID, Event)
			if (not self.GameStateNettable.IsInMatch) or self.GameStateNettable.IsBattleRunning then
				return
			elseif self.GameStateNettable.HeroShop[Event.Index].Cost > self.GameStateNettable.Gold then
				self:MessageToPlayer("Not enough gold.")
			else
				self:GameStateNettableSetAndPush({Gold = self.GameStateNettable.Gold - self.GameStateNettable.HeroShop[Event.Index].Cost})
				self.GameStateNettable.HeroShop[Event.Index].IsSold = true
				self:GameStateNettableSetAndPush({HeroShop = self.GameStateNettable.HeroShop})
				local ID = 0
				while self.PrivateGameState.PlayerTeam[ID] do
					ID = ID + 1
				end
				local HeroName = self.GameStateNettable.HeroShop[Event.Index].Name
				self.PrivateGameState.PlayerTeam[ID] = {Name = HeroName, X = RandomInt(-400, 400), Y = 1300, Z = 0, Item = nil, Stars = 1, Tier = self.Heroes[HeroName].SADCost}
				self:SpawnHero(DOTA_TEAM_GOODGUYS, ID, self.PrivateGameState.PlayerTeam[ID])
				self:MessageToPlayer("Hero spawned above arena.")
			end
	end)

	CustomGameEventManager:RegisterListener(
		"SADTryBattle",
		function(UserID, Event)
			if (not self.GameStateNettable.IsInMatch) or self.GameStateNettable.IsBattleRunning then
				return
			end
			self:RecountUnits()
			if self.GameStateNettable.UnitsInArena > self.GameStateNettable.MaxUnitsInArena then
				self:MessageToPlayer("Too many units in arena, move some out of the arena.")
			else
				self:RunBattle()
			end
	end)

	CustomGameEventManager:RegisterListener(
		"SADTryStartGame",
		function(UserID, Event)
			if self.GameStateNettable.IsInMatch then
				return
			end

			if Event.Resume ~= 0 then
				if not self.PrivateGameState.ResumeData then
					self:MessageToPlayer("Resume data missing, start a new game.")
				else
					self:ResumeGame()
				end
			else
				self:StartNewGame()
			end
	end)

	CustomGameEventManager:RegisterListener(
		"SADRerollHero",
		function(UserID, Event)
			if (not self.GameStateNettable.IsInMatch) or self.GameStateNettable.IsBattleRunning then
				return
			end

			if self.GameStateNettable.Gold < 1 then
				self:MessageToPlayer("Need 1 gold to reroll.")
			else
				self:GameStateNettableSetAndPush({Gold = self.GameStateNettable.Gold - 1})
				self:RandomHeroShop()
			end
	end)

	CustomGameEventManager:RegisterListener(
		"SADRerollItem",
		function(UserID, Event)
			if (not self.GameStateNettable.IsInMatch) or self.GameStateNettable.IsBattleRunning then
				return
			end

			if self.GameStateNettable.Gold < 1 then
				self:MessageToPlayer("Need 1 gold to reroll.")
			else
				self:GameStateNettableSetAndPush({Gold = self.GameStateNettable.Gold - 1})
				self:RandomItemShop()
			end
	end)
end
