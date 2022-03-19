function SAD:BootstrapRandomTeam()
	self:GetEnemyForRoundOffline(function (Enemy)
			print("INSERT INTO rounds (match_id, round_num, team_data, enemy_match_id, won) VALUES (1, " .. tostring(self.GameStateNettable.Round) .. ", '" .. self:Serialize(Enemy) .. "', 1, false);")
	end)
end
