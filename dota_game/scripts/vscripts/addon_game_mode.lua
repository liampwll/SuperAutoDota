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

if SAD == nil then
	SAD = class({})
	_G.SAD = SAD
end

require("grid")
require("battle_runner")
require("gui_listeners")
require("shops")
require("web_api")
require("filters")
require("offline_teams")
require("resume")
require("spawn")
require("utility")
require("serialize_id_lookups")
require("bootstrap_random_teams")
require("item_prices")

function Precache(Context)
	PrecacheResource("model", "models/props/sad_hex.vmdl", Context)
	PrecacheResource("model", "models/props/sad_hex_enemy.vmdl", Context)
	local Heroes = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	for Name, _ in pairs(Heroes) do
		PrecacheUnitByNameSync(Name, Context)
	end
end

-- Create the game mode when we activate
function Activate()
	GameRules.SAD = SAD()
	GameRules.SAD:InitGameMode()
end

function SAD:InitGameMode()
	local GME = GameRules:GetGameModeEntity()
	GME:SetFogOfWarDisabled(true)
	GME:SetDeathOverlayDisabled(true)
	GME:SetSendToStashEnabled(false)
	GME:SetCustomGameForceHero("npc_dota_hero_wisp")
	GME:SetFixedRespawnTime(99999)
	GME:SetKillingSpreeAnnouncerDisabled(true)
	GME:SetAnnouncerDisabled(true)
	GME:SetBuybackEnabled(false)
	GME:SetCanSellAnywhere(true)
	GME:SetCustomHeroMaxLevel(3)
	GME:SetGiveFreeTPOnDeath(false)
	GME:SetGoldSoundDisabled(true)
	GME:SetHudCombatEventsDisabled(true)
	GME:SetInnateMeleeDamageBlockAmount(0)
	GME:SetInnateMeleeDamageBlockPerLevelAmount(0)
	GME:SetInnateMeleeDamageBlockPercent(0)
	GME:SetNeutralStashEnabled(false)
	GME:SetRemoveIllusionsOnDeath(true)
	GME:SetStashPurchasingDisabled(false)
	GameRules:SetHideKillMessageHeaders(true)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 1)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
	GameRules:SetPreGameTime(0)
	GameRules:SetStrategyTime(0)
	GME:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_MANA_REGEN, 0)
	LinkLuaModifier("sad_big_range", "modifiers/sad_big_range.lua", LUA_MODIFIER_MOTION_NONE)
	GME:SetThink("InitialSetup", self, "InitialSetup", 1)
end

function SAD:InitialSetup()
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return 1
	end

	self:InitGrid()

	self.ServerKey = GetDedicatedServerKeyV2("1")
	self.ServerBaseUrl = "http://45.32.77.112:7001"
	self.ServerTimeout = 10000
	self.GameStateNettable = {}
	local GameStateNettableInitial = {
		IsLoaded = false,
		ResumeAvailable = false,
		IsInMatch = false,
		OfflineMode = false,
		IsBattleRunning = true,
		LastRoundWon = false,
		EnemyID = "",
		Gold = 0,
		Life = 0,
		Round = 0,
		UnitsInArena = 0,
		MaxUnitsInArena = 0,
		HeroShop = {},
		ItemShop = {}
	}
	self.ShopOdds = {
		-- Use 9.0 for max level to prevent silly mistakes with addition.
		-- Last value is also all shops after that level.
		{0.8, 9.0, 0.0, 0.0, 0.0},
		{0.7, 9.0, 0.0, 0.0, 0.0},
		{0.6, 0.3, 9.0, 0.0, 0.0},
		{0.5, 0.4, 9.0, 0.0, 0.0},
		{0.4, 0.4, 0.1, 9.0, 0.0},
		{0.3, 0.5, 0.2, 9.0, 0.0},
		{0.3, 0.4, 0.3, 9.0, 0.0},
		{0.2, 0.2, 0.3, 0.2, 9.0},
		{0.2, 0.2, 0.2, 0.2, 9.0},
		{0.1, 0.2, 0.2, 0.3, 9.0},
		{0.1, 0.2, 0.2, 0.3, 9.0},
		{0.1, 0.1, 0.2, 0.3, 9.0}
	}
	self.Heroes = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	self.HeroesByCost = {
		self:FilterByCost(self.Heroes, 1),
		self:FilterByCost(self.Heroes, 2),
		self:FilterByCost(self.Heroes, 3),
		self:FilterByCost(self.Heroes, 4),
		self:FilterByCost(self.Heroes, 5)
	}
	self.GoldPerRound = 4
	self.MaxHeroCost = 5
	self.MaxItemCost = 5
	self.MaxEverUnits = 10
	self.PlayerID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_GOODGUYS, 1)
	self.PlayerSteamID = tostring(PlayerResource:GetSteamID(self.PlayerID))
	self.Player = PlayerResource:GetPlayer(self.PlayerID)
	self.PrivateGameState = {}
	self.LevelsPerStar = 4
	self.LevelsPerTier = 3
	self:GameStateNettableSetAndPush(GameStateNettableInitial)
	self:SetupFilters()

	-- For generating an initial database of matches.
	-- for I = 1, 2000 do
	-- 	self.GameStateNettable.Round = I
	-- 	self.GameStateNettable.MaxUnitsInArena = math.min(self.GameStateNettable.MaxUnitsInArena + 1, self.MaxEverUnits)
	-- 	self:BootstrapRandomTeam()
	-- end

	GameRules:GetGameModeEntity():SetThink("FaceInArena", self, "FaceInArena", 0.2)

	self:Connect()
	return nil
end

function SAD:FaceInArena()
	if self.PrivateGameState.PlayerTeamUnits and not self.GameStateNettable.IsBattleRunning then
		for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
			if Unit.GridID and not Unit:IsMoving() then
				Unit:FaceTowards(Vector(3000, 0, 128))
			end
		end
	end
	return 0.2
end

function SAD:Connect()
	self:WebGetResumeData(
		function()
			-- These listeners stay permanently running and check the game state when called.
			self:SetupGUIListeners()
			self:GameStateNettableSetAndPush({IsLoaded = true})
	end)
end

function SAD:StartNewGame()
	self:ResetGridData()
	self:GameStateNettableSetAndPush(
		{
			Round = 0,
			Gold = 0,
			Life = 20,
			UnitsInArena = 0,
			MaxUnitsInArena = 1,
	})
	self.PrivateGameState.PlayerTeam = {}
	self.PrivateGameState.PlayerTeamUnits = {}
	self.PrivateGameState.EnemyTeamUnits = {}
	self.PrivateGameState.PlayerUnitsSpawned = 0
	self:WebPostNewGame(function (MatchID)
			self.PrivateGameState.MatchID = MatchID
			self:GameStateNettableSetAndPush({IsInMatch = true})
			self:StartNextRound()
	end)
end

function SAD:StartNextRound()
	self:GameStateNettableSetAndPush({Round = self.GameStateNettable.Round + 1})
	self:GameStateNettableSetAndPush({MaxUnitsInArena = math.min(self.GameStateNettable.MaxUnitsInArena + 1, self.MaxEverUnits)})
	self:GetEnemyForRound(
		function(Enemy)
			self.PrivateGameState.EnemyTeam = Enemy.Team
			self:RandomHeroShop()
			self:RandomItemShop()
			self:GameStateNettableSetAndPush(
				{
					Gold = self.GameStateNettable.Gold + self.GoldPerRound,
					EnemyID = Enemy.ID
			})
			self:GameStateNettableSetAndPush({IsBattleRunning = false})
			self:MakeResumeData()
			self:WebPostResumeData()
			self:SpawnEnemyTeam()
	end)
end

function SAD:GameOver()
	self:MessageToPlayer("Game over.")
	self:GameStateNettableSetAndPush({IsInMatch = false, ResumeData = nil, ResumeAvailable = false})
	self:WebPostGameOver()
	for ID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		Unit:SetUnitCanRespawn(false)
		Unit:ForceKill(false)
	end
	self.PrivateGameState.PlayerTeam = {}
	self.PrivateGameState.PlayerTeamUnits = {}
	local Items = Entities:FindAllByClassname("dota_item_drop")
	for K, V in pairs(Items) do
		V:Destroy()
	end

end

function SAD:MessageToPlayer(Message)
	FireGameEvent("dota_hud_error_message", {reason = 80, message = Message})
end
