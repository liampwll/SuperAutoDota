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

function SAD:SetStandardRequestParameters(Request)
	Request:SetHTTPRequestAbsoluteTimeoutMS(self.ServerTimeout)
	Request:SetHTTPRequestHeaderValue("SAD-Round", tostring(self.GameStateNettable.Round or 0))
	Request:SetHTTPRequestHeaderValue("SAD-SteamID", tostring(self.PlayerSteamID))
	Request:SetHTTPRequestHeaderValue("SAD-MatchID", tostring(self.PrivateGameState.MatchID or 0))
	Request:SetHTTPRequestHeaderValue("SAD-Authorization", tostring(self.ServerKey))
end

function SAD:GetEnemyForRound(Callback)
	if self.GameStateNettable.OfflineMode then
		self:GetEnemyForRoundOffline(Callback)
	else
		self:WebGetEnemyForRound(Callback)
	end
end

function SAD:WebGetEnemyForRound(Callback)
	local Request = CreateHTTPRequest("GET", self.ServerBaseUrl.."/EnemyForRound")
	self:SetStandardRequestParameters(Request)
	Request:Send(
		function(Response)
			if Response.StatusCode ~= 200 then
				self:GameStateNettableSetAndPush({OfflineMode = true})
				self:GetEnemyForRoundOffline(Callback)
			else
				Callback(self:Deserialize(Response.Body))
			end
	end)
end

function SAD:WebPostEnemyForRoundAndOutcome()
	if self.GameStateNettable.OfflineMode then
		return
	end

	local Request = CreateHTTPRequest("POST", self.ServerBaseUrl.."/EnemyForRound")
	self:SetStandardRequestParameters(Request)
	Request:SetHTTPRequestHeaderValue("SAD-LastRoundWon", tostring(self.GameStateNettable.LastRoundWon))
	local PlayerTeamInArena = {}
	for ID, Data in pairs(self.PrivateGameState.PlayerTeam) do
		if Data.GridID then
			PlayerTeamInArena[ID] = {
				Name = Data.Name,
				GridID = self:ReflectGridID(Data.GridID),
				Item = Data.Item,
				Tier = Data.Tier,
				Stars = Data.Stars
			}
		end
	end
	Request:SetHTTPRequestRawPostBody("text/plain", self:Serialize({ID = self.PlayerSteamID, Team = PlayerTeamInArena}))
	Request:Send(
		function(_)
			-- We don't really care if this post fails.
	end)
end

function SAD:WebPostGameOver()
	if self.GameStateNettable.OfflineMode then
		return
	end

	local Request = CreateHTTPRequest("POST", self.ServerBaseUrl.."/GameOver")
	self:SetStandardRequestParameters(Request)
	Request:SetHTTPRequestRawPostBody("text/plain", "")
	Request:Send(
		function(Response)
			if Response.StatusCode ~= 200 then
				self:GameStateNettableSetAndPush({OfflineMode = true})
			end
	end)
end

function SAD:WebPostNewGame(Callback)
	if self.GameStateNettable.OfflineMode then
		Callback(nil)
		return
	end

	local Request = CreateHTTPRequest("POST", self.ServerBaseUrl.."/NewGame")
	self:SetStandardRequestParameters(Request)
	Request:SetHTTPRequestRawPostBody("text/plain", "")
	Request:Send(
		function(Response)
			if Response.StatusCode ~= 200 then
				self:GameStateNettableSetAndPush({OfflineMode = true})
				Callback(nil)
			else
				Callback(Response.Body)
			end
	end)
end


function SAD:WebPostResumeData()
	if self.GameStateNettable.OfflineMode then
		return
	end

	local Request = CreateHTTPRequest("POST", self.ServerBaseUrl.."/ResumeData")
	self:SetStandardRequestParameters(Request)
	Request:SetHTTPRequestRawPostBody("text/plain", self:Serialize(self.PrivateGameState.ResumeData))
	Request:Send(
		function(Response)
			if Response.StatusCode ~= 200 then
				self:GameStateNettableSetAndPush({OfflineMode = true})
			end
	end)
end

function SAD:WebGetResumeData(Callback)
	if self.GameStateNettable.OfflineMode then
		Callback()
		return
	end

	local Request = CreateHTTPRequest("GET", self.ServerBaseUrl.."/ResumeData")
	self:SetStandardRequestParameters(Request)
	Request:Send(
		function(Response)
			if Response.StatusCode == 404 then
				-- Do nothing.
			elseif Response.StatusCode == 200 then
				local ResumeData = self:Deserialize(Response.Body)
				if ResumeData then
					self.PrivateGameState.ResumeData = ResumeData
					self:GameStateNettableSetAndPush({ResumeAvailable = true})
				end
			else
				self:GameStateNettableSetAndPush({OfflineMode = true})
			end
			Callback()
	end)
end
