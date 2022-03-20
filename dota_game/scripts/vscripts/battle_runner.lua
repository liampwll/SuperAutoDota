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

function SAD:RunBattle()
	local FirstRun = false
	if not self.GameStateNettable.IsBattleRunning then
		self:GameStateNettableSetAndPush({IsBattleRunning = true})
		FirstRun = true
	end

	for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		if Unit:IsMoving() then
			if FirstRun then
				self:MessageToPlayer("Waiting for units to stop moving.")
			end
			GameRules:GetGameModeEntity():SetThink("RunBattle", self, "RunBattle", 0.2)
			return 0.1
		end
	end

	for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		-- Prevent showing of death screen
		Unit:SetOwner(nil)
		Unit.RespawnPos = Unit:GetAbsOrigin()
		if not Unit.GridID then
			Unit:ForceKill(false)
			Unit.StartingGridID = nil
		else
			Unit:SetAttackCapability(Unit.OldAttackCapability)
			Unit:SetMaxMana(Unit:GetAbilityByIndex(0):GetManaCost(-1) * 1.1)
			Unit:SetMana(0)
			Unit:Stop()
			Unit:GetAbilityByIndex(0):EndCooldown()
			Unit.CurrentAction = nil
			Unit.StartingGridID = Unit.GridID
		end
	end

	for ID, Unit in pairs(self.PrivateGameState.EnemyTeamUnits) do
		if Unit:IsAlive() then
			Unit:SetAttackCapability(Unit.OldAttackCapability)
			Unit:SetMaxMana(Unit:GetAbilityByIndex(0):GetManaCost(-1) * 1.1)
			Unit:SetMana(0)
			Unit:Stop()
			Unit:GetAbilityByIndex(0):EndCooldown()
			Unit.CurrentAction = nil
		end
	end

	GameRules:GetGameModeEntity():SetThink("RunBattleLoop", self, "RunBattleLoop", 1/1000) -- 1/1000 Will limit itself to once per tick.
end

function SAD:RunBattleLoop()
	local PlanNextAction
	local MakeDistanceTable
	local ProcessUnitStep
	local FindTargetInAttackRange
	local DoAbilityCast
	local DistanceToEnemy
	local DistanceToFriendly

	function MakeDistanceTable(Team)
		local DistanceTable = {}
		local SeenTiles = {}
		local TeamUnits
		if Team == DOTA_TEAM_GOODGUYS then
			TeamUnits = self.PrivateGameState.PlayerTeamUnits
		else
			TeamUnits = self.PrivateGameState.EnemyTeamUnits
		end
		for GridID, _ in pairs(self.Grid) do
			DistanceTable[GridID] = nil
		end
		for UnitID, Unit in pairs(TeamUnits) do
			if Unit:IsAlive() then
				DistanceTable[Unit.GridID] = 0
			end
		end
		local KeepGoing = true
		local PreviousDistance = 0
		while KeepGoing do
			KeepGoing = false
			local TmpOldDistanceTable = {}
			for PreviousGridID, Distance in pairs(DistanceTable) do
				if Distance == PreviousDistance then
					for _, NeighbourGridID in pairs(self:GridIDToNeighbours(PreviousGridID)) do
						if SeenTiles[NeighbourGridID] then
							-- Do nothing
						elseif self.Grid[NeighbourGridID] and self.Grid[NeighbourGridID].Occupier and self.Grid[NeighbourGridID].Occupier.CurrentAction ~= "Moving" then
							SeenTiles[NeighbourGridID] = true
							KeepGoing = true
						elseif self.Grid[NeighbourGridID] and not DistanceTable[NeighbourGridID] then
							SeenTiles[NeighbourGridID] = true
							DistanceTable[NeighbourGridID] = PreviousDistance + 1
							KeepGoing = true
						end
					end
				end
			end
			PreviousDistance = PreviousDistance + 1
		end

		return DistanceTable
	end

	function ProcessUnitStep(Unit)
		if Unit:IsAlive() then
			if Unit.CurrentAction == nil then
				PlanNextAction(Unit)
			elseif Unit.CurrentAction == "Attacking" then
				if (not Unit.Target:IsAlive()) or self:GridIDDistance(Unit.GridID, Unit.Target.GridID) > Unit.TileAttackRange then
					Unit.Target = nil
					Unit.CurrentAction = nil
				elseif Unit:GetAbilityByIndex(0):IsFullyCastable() then
					DoAbilityCast(Unit)
				end
			elseif Unit.CurrentAction == "Moving" then
				local UnitPos = Unit:GetAbsOrigin()
				local CurrentGridID = self:MapXYToGridID(UnitPos.x, UnitPos.y)
				if Unit.GridID ~= Unit.TargetGridID and CurrentGridID == Unit.TargetGridID then
					self.Grid[Unit.GridID].Occupier = nil
					self.Grid[Unit.TargetGridID].Occupier = Unit
					self.Grid[Unit.TargetGridID].NextOccupier = nil
					Unit.GridID = Unit.TargetGridID
				elseif Unit:IsStunned() or Unit:IsRooted() or Unit:IsFrozen() then
					Unit:Stop()
					self.Grid[Unit.TargetGridID].NextOccupier = nil
					Unit.TargetGridID = nil
					Unit.CurrentAction = nil
				elseif not Unit:IsMoving() then
					-- Sometimes units just don't move and I have no idea why.
					Unit:MoveToPosition(self:GridIDToMapOrigin(Unit.TargetGridID))
				elseif self:IsMapXYInGridIDRadius(UnitPos.x, UnitPos.y, Unit.TargetGridID, 10) then -- This value is just used to tune how movement looks.
					Unit:Stop()
					Unit.TargetGridID = nil
					Unit.CurrentAction = nil
				end
			elseif Unit.CurrentAction == "Casting" then
				if Unit:GetCurrentActiveAbility() == nil then
					if Unit.CastingGraceCooldown ~= 0 then
						Unit.CastingGraceCooldown = Unit.CastingGraceCooldown - 1
					elseif (not Unit.Target:IsAlive()) or self:GridIDDistance(Unit.GridID, Unit.Target.GridID) > Unit.TileAttackRange then
						Unit:Stop()
						Unit.Target = nil
						Unit.CurrentAction = nil
					else
						Unit.CurrentAction = "Attacking"
						Unit:MoveToTargetToAttack(Unit.Target)
					end
				end
			end
		elseif Unit.GridID then
			self.Grid[Unit.GridID].Occupier = nil
			if Unit.TargetGridID then
				self.Grid[Unit.TargetGridID].NextOccupier = nil
			end
			Unit.TargetGridID = nil
			Unit.GridID = nil
		end
	end

	function PlanNextAction(Unit)
		-- print(Unit:GetName())
		Unit.Target = FindTargetInAttackRange(Unit)
		if Unit.Target then
			-- print("Attack")
			Unit.CurrentAction = "Attacking"
			Unit:MoveToTargetToAttack(Unit.Target)
		elseif not (Unit:IsStunned() or Unit:IsRooted() or Unit:IsFrozen()) then
			local DistanceTable
			if Unit:GetTeam() == DOTA_TEAM_GOODGUYS then
				DistanceTable = DistanceToEnemy
			else
				DistanceTable = DistanceToFriendly
			end
			local BestTile = nil
			local BestTileScore = DistanceTable[Unit.GridID] or 99999
			for _, NeighbourGridID in pairs(self:GridIDToNeighbours(Unit.GridID)) do
				if DistanceTable[NeighbourGridID] and (DistanceTable[NeighbourGridID] < BestTileScore) and NeighbourGridID ~= Unit.GridID then
					BestTile = NeighbourGridID
					BestTileScore = DistanceTable[NeighbourGridID]
				end
			end
			-- if BestTile then
			-- 	local A = "None"
			-- 	if self.Grid[BestTile].Occupier then
			-- 		A = self.Grid[BestTile].Occupier:GetName()
			-- 	end
			-- 	local B = "None"
			-- 	if self.Grid[BestTile].NextOccupier then
			-- 		B = self.Grid[BestTile].NextOccupier:GetName()
			-- 	end
			-- 	print("Moving, Occupier: "..A..", next: "..B)
			-- else
			-- 	print("No path")
			-- end
			if BestTile and (self.Grid[BestTile].Occupier == nil and self.Grid[BestTile].NextOccupier == nil) then
				Unit.TargetGridID = BestTile
				self.Grid[BestTile].NextOccupier = Unit
				Unit:MoveToPosition(self:GridIDToMapOrigin(BestTile))
				Unit.CurrentAction = "Moving"
			elseif Unit:IsAttacking() then
				Unit:Stop()
			end
		else
			-- print("Movement impaired")
		end
	end

	function FindTargetInAttackRange(Unit)
		local TargetUnits
		if Unit:GetTeam() == DOTA_TEAM_GOODGUYS then
			TargetUnits = self.PrivateGameState.EnemyTeamUnits
		else
			TargetUnits = self.PrivateGameState.PlayerTeamUnits
		end
		local BestEnemyUnit = nil
		local BestEnemyDistance = 99999
		for _, EnemyUnit in pairs(TargetUnits) do
			if EnemyUnit:IsAlive() then
				local Distance = self:GridIDDistance(Unit.GridID, EnemyUnit.GridID)
				if Distance <= math.min(Unit.TileAttackRange, BestEnemyDistance) then
					BestEnemyUnit = EnemyUnit
					BestEnemyDistance = Distance
				end
			end
		end
		return BestEnemyUnit
	end

	function DoAbilityCast(Unit)
		local Ability = Unit:GetAbilityByIndex(0)
		Ability:SetOverrideCastPoint(1/1000)
		local TargetType = Ability:GetAbilityTargetType()
		local TargetTeam = Ability:GetAbilityTargetTeam()
		if bit.band(Ability:GetBehavior(), DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_PASSIVE) ~= 0 then
			-- Do nothing
		elseif bit.band(TargetType, DOTA_UNIT_TARGET_HERO) ~= 0 and bit.band(TargetTeam, DOTA_UNIT_TARGET_TEAM_ENEMY) ~= 0 then
			-- print(Unit:GetName())
			-- print("Casting")
			Unit:CastAbilityOnTarget(Unit.Target, Ability, 0)
			Unit.CurrentAction = "Casting"
			Unit.CastingGraceCooldown = 15
		elseif bit.band(TargetType, DOTA_UNIT_TARGET_HERO) ~= 0 and bit.band(TargetTeam, DOTA_UNIT_TARGET_TEAM_FRIENDLY) ~= 0 then
			-- print(Unit:GetName())
			-- print("Casting")
			Unit:CastAbilityOnTarget(Unit, Ability, 0)
			Unit.CurrentAction = "Casting"
			Unit.CastingGraceCooldown = 15
		elseif bit.band(TargetType, DOTA_UNIT_TARGET_NONE) ~= 0 then
			-- print(Unit:GetName())
			-- print("Casting")
			Unit:CastAbilityNoTarget(Ability, 0)
			Unit.CurrentAction = "Casting"
			Unit.CastingGraceCooldown = 15
		else
			-- print(Unit:GetName())
			-- print("Casting")
			Unit:CastAbilityOnPosition(Unit.Target:GetAbsOrigin(), Ability, -1)
			Unit.CurrentAction = "Casting"
			Unit.CastingGraceCooldown = 15
		end
	end

	DistanceToEnemy = MakeDistanceTable(DOTA_TEAM_BADGUYS)
	DistanceToFriendly = MakeDistanceTable(DOTA_TEAM_GOODGUYS)

	local PlayerAlive = 0
	local EnemyAlive = 0

	for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		if Unit:IsAlive() then
			PlayerAlive = PlayerAlive + 1
		end
		ProcessUnitStep(Unit)
	end
	for ID, Unit in pairs(self.PrivateGameState.EnemyTeamUnits) do
		if Unit:IsAlive() then
			EnemyAlive = EnemyAlive + 1
		end
		ProcessUnitStep(Unit)
	end

	if PlayerAlive ~= 0 and EnemyAlive ~= 0 then
		return 1/1000
	end

	for ID, Unit in pairs(self.PrivateGameState.EnemyTeamUnits) do
		Unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
		Unit:Stop()
	end
	for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		Unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
		Unit:Stop()
	end
	-- Grace period
	GameRules:GetGameModeEntity():SetThink("EndBattle", self, "EndBattle", 2)
	return nil
end

function SAD:EndBattle()
	local EnemyAlive = 0
	for ID, Unit in pairs(self.PrivateGameState.EnemyTeamUnits) do
		if Unit:IsAlive() then
			EnemyAlive = EnemyAlive + 1
		end
	end

	if EnemyAlive ~= 0 then
		self:GameStateNettableSetAndPush({Life = self.GameStateNettable.Life - EnemyAlive, LastRoundWon = false})
		self:MessageToPlayer("Round lost.")
	else
		self:GameStateNettableSetAndPush({Life = self.GameStateNettable.Life - EnemyAlive, LastRoundWon = true})
		self:MessageToPlayer("Round won.")
	end

	for k, v in pairs(self.PrivateGameState.EnemyTeamUnits) do
		v:Destroy()
	end
	self.PrivateGameState.EnemyTeamUnits = {}

	self:ResetGridData()
	for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		Unit:Stop()
		Unit:ForceKill(false)
		Unit:RespawnHero(false, false)
		if Unit.StartingGridID then
			Unit.GridID = Unit.StartingGridID
			self.Grid[Unit.GridID].Occupier = Unit
			Unit.RespawnPos = self:GridIDToMapOrigin(Unit.GridID) -- Without this units can slowly slide off the grid
		end
		FindClearSpaceForUnit(Unit, Unit.RespawnPos, true)
		local Origin = Unit:GetAbsOrigin()
		Unit:FaceTowards(Vector(0, 10000, 0))
		Unit:SetOwner(self.Player)
		Unit:GetAbilityByIndex(0):EndCooldown()
		Unit.Target = nil
		Unit.TargetGridID = nil
		Unit:SetMaxMana(Unit:GetAbilityByIndex(0):GetManaCost(-1) * 1.1)
	end

	self:MakeResumeData()
	self:WebPostEnemyForRoundAndOutcome()

	if self.GameStateNettable.Life <= 0 then
		self:GameOver()
	else
		GameRules:GetGameModeEntity():SetThink("StartNextRound", self, "StartNextRound", 1)
	end

	return nil
end
