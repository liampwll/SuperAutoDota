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

function SAD:ResumeGame()
	local ResumeData = self.PrivateGameState.ResumeData
	self.PrivateGameState.ResumeData = nil
	self:GameStateNettableSetAndPush(ResumeData.GameStateNettablePartial)
	self.PrivateGameState.EnemyTeam = ResumeData.EnemyTeam
	self.PrivateGameState.MatchID = ResumeData.MatchID
	self.PrivateGameState.PlayerTeam = ResumeData.PlayerTeam
	self.PrivateGameState.PlayerTeamUnits = {}
	self.PrivateGameState.EnemyTeamUnits = {}
	self.PrivateGameState.PlayerUnitsSpawned = 9999 -- TODO: Should we save this?
	self:SpawnEnemyTeam()
	self:SpawnPlayerTeam()
	self.PrivateGameState.PlayerUnitsSpawned = 0 -- TODO: Should we save this?
	self:SpawnPlayerGroundItems(ResumeData.PlayerGroundItems)
	self:GameStateNettableSetAndPush({IsInMatch = true, IsBattleRunning = false})
end

function SAD:MakeResumeData()
	local Data = {}

	for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		local Origin = Unit:GetAbsOrigin()
		self.PrivateGameState.PlayerTeam[ID].X = Origin.x
		self.PrivateGameState.PlayerTeam[ID].Y = Origin.y
		self.PrivateGameState.PlayerTeam[ID].Z = Origin.z
		if Unit:GetItemInSlot(0) then
			self.PrivateGameState.PlayerTeam[ID].Item = Unit:GetItemInSlot(0):GetName()
		end
		self.PrivateGameState.PlayerTeam[ID].GridID = Unit.GridID
	end

	Data.EnemyTeam = self.PrivateGameState.EnemyTeam
	Data.MatchID = self.PrivateGameState.MatchID
	Data.GameStateNettablePartial = {
		LastRoundWon = self.GameStateNettable.LastRoundWon,
		EnemyID = self.GameStateNettable.EnemyID,
		Gold = self.GameStateNettable.Gold,
		Life = self.GameStateNettable.Life,
		Round = self.GameStateNettable.Round,
		MaxUnitsInArena = self.GameStateNettable.MaxUnitsInArena,
		HeroShop = self.GameStateNettable.HeroShop,
		ItemShop = self.GameStateNettable.ItemShop
	}
	Data.PlayerTeam = self.PrivateGameState.PlayerTeam
	Data.PlayerGroundItems = self.GetPlayerGroundItems()
	self.PrivateGameState.ResumeData = Data
end

function SAD:GetPlayerGroundItems()
	local Items = Entities:FindAllByClassname("dota_item_drop")
	local RetVal = {}
	for K, V in pairs(Items) do
		local Origin = V:GetAbsOrigin()
		if V:GetContainedItem() then
			RetVal[K] = {Name = V:GetContainedItem():GetName(), X = Origin.x, Y = Origin.y, Z = Origin.z}
		end
	end
	return RetVal
end
