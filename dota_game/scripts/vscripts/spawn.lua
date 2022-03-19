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

function SAD:SpawnPlayerTeam()
	for ID, Data in pairs(self.PrivateGameState.PlayerTeam) do
		self:SpawnHero(DOTA_TEAM_GOODGUYS, ID, Data)
	end
end

function SAD:SpawnEnemyTeam()
	for ID, Data in pairs(self.PrivateGameState.EnemyTeam) do
		self:SpawnHero(DOTA_TEAM_BADGUYS, ID, Data)
	end
end

function SAD:SpawnPlayerGroundItems(Items)
	for ID, Data in pairs(Items) do
		CreateItemOnPositionSync(Vector(Data.X, Data.Y, Data.Z), CreateItem(Data.Name, nil, nil))
	end
end

function SAD:SpawnItem(Name)
	-- TODO: Find free space for item.
	CreateItemOnPositionSync(Vector(RandomInt(-400, 400), 950, 0), CreateItem(Name, nil, nil))
end

function SAD:SpawnHero(Team, ID, Data)
	local Owner
	local Position
	if Team == DOTA_TEAM_GOODGUYS then
		Owner = self.Player
		Position = Vector(Data.X, Data.Y, Data.Z)
	else
		Owner = nil
		Position = self:GridIDToMapOrigin(Data.GridID)
	end
	-- Using CreateUnitByNameAsync will ocasionally cause a crash when hosting on Valve servers when creating heroes.
	local Unit = CreateUnitByName(Data.Name, Position, true, Owner, Owner, Team)
	local Origin = Unit:GetAbsOrigin()
	Unit:SetAcquisitionRange(10000)
	if Team == DOTA_TEAM_GOODGUYS then
		Unit:FaceTowards(Vector(3000, 0, 128))
	else
		Unit:FaceTowards(Vector(-3000, 0, 128))
	end
	Unit.ID = ID
	Unit.GridID = Data.GridID
	if Data.GridID then
		self.Grid[Data.GridID].Occupier = Unit
	end
	for I = 0, 8 do
		Unit:AddItemByName("item_sad_slot_filler")
	end
	Unit:RemoveItem(Unit:GetItemInSlot(0))
	if Data.Item then
		Unit:AddItemByName(Data.Item)
	end
	if Team == DOTA_TEAM_GOODGUYS then
		self.PrivateGameState.PlayerTeamUnits[ID] = Unit
		Unit:SetControllableByPlayer(self.PlayerID, true)
	else
		self.PrivateGameState.EnemyTeamUnits[ID] = Unit
	end
	Unit.OldAttackCapability = Unit:GetAttackCapability()
	Unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
	for I = 2, Data.Stars do
		for J = 1, self.LevelsPerStar do
			Unit:HeroLevelUp(false)
		end
	end
	for I = 2, Data.Tier do
		for J = 1, self.LevelsPerTier do
			Unit:HeroLevelUp(false)
		end
	end
	Unit:SetAbilityPoints(0)
	Unit:GetAbilityByIndex(0):SetLevel(Data.Stars)
	Unit:GetAbilityByIndex(1):SetLevel(1)
	Unit:GetAbilityByIndex(2):SetLevel(1)
	if bit.band(Unit:GetAbilityByIndex(0):GetBehavior(), DOTA_ABILITY_BEHAVIOR_AUTOCAST) ~= 0 then
		Unit:CastAbilityToggle(Unit:GetAbilityByIndex(0), -1)
	end
	Unit:SetMaxMana(Unit:GetAbilityByIndex(0):GetManaCost(-1) * 1.1)
	Unit:SetMana(0)
	Unit:AddNewModifier(nil, nil, "sad_big_range", {})
	if Unit.OldAttackCapability == DOTA_UNIT_CAP_RANGED_ATTACK then
		Unit.TileAttackRange = 2
	else
		Unit.TileAttackRange = 1
	end
	-- if Team == DOTA_TEAM_GOODGUYS and self.PrivateGameState.PlayerUnitsSpawned < 10 then
	-- 	self.PrivateGameState.PlayerUnitsSpawned = self.PrivateGameState.PlayerUnitsSpawned + 1
	-- 	GameRules:SendCustomMessage("SAD_spawn_tip_" .. tostring(self.PrivateGameState.PlayerUnitsSpawned), 0, 0)
	-- end
end
