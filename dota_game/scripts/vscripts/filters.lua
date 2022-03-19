function SAD:SetupFilters()
	local CastOrders = {
		[DOTA_UNIT_ORDER_CAST_TARGET] = true,
		[DOTA_UNIT_ORDER_CAST_NO_TARGET] = true
	}

	local GME = GameRules:GetGameModeEntity()
	GME:SetExecuteOrderFilter(
		function(self, Event)
			if Event.issuer_player_id_const ~= self.PlayerID then
				return true
			elseif self.GameStateNettable.IsBattleRunning then
				return false
			elseif Event.order_type == DOTA_UNIT_ORDER_SELL_ITEM then
				local Ability = EntIndexToHScript(Event.entindex_ability)
				if Ability and Ability:GetName() ~= "item_sad_slot_filler" then
					self:GameStateNettableSetAndPush({Gold = self.GameStateNettable.Gold + 1})
					return true
				else
					return false
				end
			elseif Event.order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
				-- TODO: Allow swapping of units.
				Event.queue = 0
				local GridID = self:MapXYToGridID(Event.position_x, Event.position_y)
				local Unit = EntIndexToHScript(Event.units["0"])
				if Unit:GetName() == "npc_dota_hero_wisp" then
					return false
				end
				if self.Grid[GridID] then
					if self.Grid[GridID].Occupier or not self.Grid[GridID].IsFriendly then
						return false
					end
					if Unit.GridID then
						self.Grid[Unit.GridID].Occupier = nil
					else
						self:GameStateNettableSetAndPush({UnitsInArena = self.GameStateNettable.UnitsInArena + 1})
					end
					self.Grid[GridID].Occupier = Unit
					Unit.GridID = GridID
					Event.units = {["0"] = Event.units["0"]}
					Event.position_x = self:GridIDToMapOrigin(GridID).x
					Event.position_y = self:GridIDToMapOrigin(GridID).y
				elseif Unit.GridID then
					self.Grid[Unit.GridID].Occupier = nil
					Unit.GridID = nil
					self:GameStateNettableSetAndPush({UnitsInArena = self.GameStateNettable.UnitsInArena - 1})
				end
				return true
			elseif Event.order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
				-- TODO: Allow swapping of units.
				return false
			elseif CastOrders[Event.order_type] then
				local Ability = EntIndexToHScript(Event.entindex_ability)
				if Ability and (Ability:GetName() == "sad_sell" or Ability:GetName() == "sad_combine") then
					return true
				else
					return false
				end
			elseif Event.order_type == DOTA_UNIT_ORDER_DROP_ITEM then
				local Item = EntIndexToHScript(Event.entindex_ability)
				local Dropper = EntIndexToHScript(Event.units["0"])
				if Item and Dropper then
					CreateItemOnPositionSync(Vector(Event.position_x, Event.position_y, Event.position_z), CreateItem(Item:GetName(), nil, nil))
					Dropper:RemoveItem(Item)
				end
				return false
			elseif Event.order_type == DOTA_UNIT_ORDER_PICKUP_ITEM then
				local Container = EntIndexToHScript(Event.entindex_target)
				if Container then
					for _, EntIndex in pairs(Event.units) do
						local PlayerUnit = EntIndexToHScript(EntIndex)
						if PlayerUnit and PlayerUnit:HasAnyAvailableInventorySpace() and PlayerUnit:GetName() ~= "npc_dota_hero_wisp" then
							PlayerUnit:AddItem(CreateItem(Container:GetContainedItem():GetName(), nil, nil))
							Container:Destroy()
							break
						end
					end
				end
				return false
			elseif Event.order_type == DOTA_UNIT_ORDER_GIVE_ITEM then
				local Item = EntIndexToHScript(Event.entindex_ability)
				local Target = EntIndexToHScript(Event.entindex_target)
				local Dropper = EntIndexToHScript(Event.units["0"])
				if Item and Target and Dropper and Target:HasAnyAvailableInventorySpace() and Target:GetName() ~= "npc_dota_hero_wisp" then
					Target:AddItem(CreateItem(Item:GetName(), nil, nil))
					Dropper:RemoveItem(Item)
				end
				return false
			else
				return false
			end
		end,
		self)

	GME:SetModifyExperienceFilter(
		function(self, Event)
			return false
		end,
		self)

	GME:SetDamageFilter(
		function(self, Event)
			local Target = EntIndexToHScript(Event.entindex_victim_const)
			local Attacker = EntIndexToHScript(Event.entindex_attacker_const)
			if Target then
				Target:GiveMana(Event.damage / 3)
			end
			if Attacker then
				Attacker:GiveMana(Event.damage / 3)
			end
			return true
		end,
		self)

	GME:SetModifierGainedFilter(
		function(self, Event)
			if Event.name_const == "modifier_fountain_invulnerability" then
				return false
			else
				return true
			end
		end,
		self)
end
