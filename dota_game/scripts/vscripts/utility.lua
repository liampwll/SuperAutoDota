function SAD:GameStateNettableSetAndPush(Table)
	for K, V in pairs(Table) do
		self.GameStateNettable[K] = V
		CustomNetTables:SetTableValue("GameState", K, {value = V})
	end
end

function SAD:FilterByCost(Table, Cost)
	local Filtered = {}
	local I = 1
	for K, V in pairs(Table) do
		if V.SADCost == Cost then
			Filtered[I] = {Key = K, Value = V}
			I = I + 1
		end
	end
	return Filtered
end

function SAD:RemovePlayerHeroByID(IDToRemove)
	-- Replace the table here so we don't have to worry about nil anywhere else in the code.
	local NewPlayerTeam = {}
	local NewPlayerTeamUnits = {}
	for ID, Data in pairs(self.PrivateGameState.PlayerTeam) do
		if ID ~= IDToRemove then
			NewPlayerTeam[ID] = Data
			NewPlayerTeamUnits[ID] = self.PrivateGameState.PlayerTeamUnits[ID]
		end
	end
	local Item = self.PrivateGameState.PlayerTeamUnits[IDToRemove]:GetItemInSlot(0)
	if Item then
		self:GetCaster():DropItemAtPositionImmediate(Item, self:GetCaster():GetAbsOrigin())
	end
	if self.PrivateGameState.PlayerTeamUnits[IDToRemove].GridID then
		self.Grid[self.PrivateGameState.PlayerTeamUnits[IDToRemove].GridID].Occupier = nil
		self:GameStateNettableSetAndPush({UnitsInArena = self.GameStateNettable.UnitsInArena - 1})
	end
	self.PrivateGameState.PlayerTeamUnits[IDToRemove]:SetUnitCanRespawn(false)
	self.PrivateGameState.PlayerTeamUnits[IDToRemove]:ForceKill(false)
	self.PrivateGameState.PlayerTeam = NewPlayerTeam
	self.PrivateGameState.PlayerTeamUnits = NewPlayerTeamUnits
end

-- TODO: Work out where our unit count is getting messed up
function SAD:RecountUnits()
	local Count = 0
	for UnitID, Unit in pairs(self.PrivateGameState.PlayerTeamUnits) do
		if Unit.GridID then
			Count = Count + 1
		end
	end
	self:GameStateNettableSetAndPush({UnitsInArena = Count})
end

-- BEGIN CODE FROM LUME

SAD.SerializeMap = {
	[ "boolean"  ] = tostring,
	[ "nil"      ] = tostring,
	[ "string"   ] = function(v) return SAD.SerializeNameToIDLookups[v] or string.format("%q", v) end,
	[ "number"   ] = function(v)
		if      v ~=  v     then return  "0/0"      --  nan
		elseif  v ==  1 / 0 then return  "1/0"      --  inf
		elseif  v == -1 / 0 then return "-1/0"      -- -inf
		elseif  v % 1 == 0  then return string.format("%d", v) end
		return string.format("%.2f", v) -- We shouldn't ever need more than 2 decimal places.
	end,
	[ "table"   ] = function(t, stk)
		stk = stk or {}
		if stk[t] then error("circular reference") end
		local rtn = {}
		stk[t] = true
		for k, v in pairs(t) do
			rtn[#rtn + 1] = "[" .. SAD.SerializeInternal(k, stk) .. "]=" .. SAD.SerializeInternal(v, stk)
		end
		stk[t] = nil
		return "{" .. table.concat(rtn, ",") .. "}"
	end
}

setmetatable(SAD.SerializeMap, {__index = function(_, k) error("unsupported serialize type: " .. k) end})

function SAD.SerializeInternal(x, stk)
	return SAD.SerializeMap[type(x)](x, stk)
end

function SAD:Serialize(x)
	return SAD.SerializeInternal(x)
end


function SAD:Deserialize(str)
	return load("return" .. str, "=(load)", "bt", SAD.SerializeIDToNameLookups)()
end

-- END CODE FROM LUME
