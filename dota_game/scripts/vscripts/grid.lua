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

function SAD:GridXYToGridID(X, Y)
	return bit.lshift(X + 128, 8) + Y + 128
end

function SAD:GridIDToGridXY(GridID)
	return bit.rshift(GridID, 8) - 128, bit.band(GridID, 0xFF) - 128
end

function SAD:GridIDToNeighbours(GridID)
	return {
		GridID - 1,
		GridID + 1,
		GridID - bit.lshift(1, 8),
		GridID + bit.lshift(1, 8),
		GridID + bit.lshift(1, 8) + 1,
		GridID - bit.lshift(1, 8) - 1,
	}
end

function SAD:GridIDDistance(GridIDA, GridIDB)
	local XA, YA = SAD:GridIDToGridXY(GridIDA)
	local XB, YB = SAD:GridIDToGridXY(GridIDB)
	local ZA = YA - XA
	local ZB = YB - XB
	-- Credit to https://www.redblobgames.com/grids/hexagons/#distances
	return (math.abs(XA - XB) + math.abs(XA + ZA - XB - ZB) + math.abs(ZA - ZB)) / 2
end

function SAD:GridIDToMapOrigin(GridID)
	local GridX, GridY = SAD.GridIDToGridXY(nil, GridID)
	local MapX = self.GridMapXBegin + self.GridMapXSpacing * GridX - self.GridMapXSpacing * GridY / 2
	local MapY = self.GridMapYBegin + self.GridMapYSpacing * GridY
	return Vector(MapX, MapY, SAD.GridMapZBegin)
end

function SAD:IsMapXYInGridIDRadius(X, Y, GridID, Radius)
	local Origin = self:GridIDToMapOrigin(GridID)
	local GridX = Origin.x
	local GridY = Origin.y
	X = X - GridX
	Y = Y - GridY
	return math.sqrt(X * X + Y * Y) <= Radius
end


function SAD:MapXYToGridID(X, Y)
	X = X - self.GridMapXBegin
	Y = Y - self.GridMapYBegin
	X = X / self.GridMapXSpacing
	Y = Y / self.GridMapYSpacing
	X = X + Y * math.sin(math.rad(30)) -- TODO: Why does this have to be a +, shouldn't it be a -? Why is math hard? Have I done something dumb?
	XGrid = math.floor(X + 0.5)
	YGrid = math.floor(Y + 0.5)
	X = X - XGrid
	Y = Y - YGrid
	-- Credit to https://observablehq.com/@jrus/hexround
	if math.abs(X) >= math.abs(Y) then
		return self:GridXYToGridID(XGrid + math.floor(X - 0.5 * Y + 0.5), YGrid)
	else
		return self:GridXYToGridID(XGrid, YGrid + math.floor(Y - 0.5 * X + 0.5))
	end
	return self:GridXYToGridID(XGrid, YGrid)
end

-- In future we can stick this in PrivateGameState if we want to support more grids.
function SAD:InitGrid()
	self.Grid = {}
	for _, Data in pairs(self.DefaultGrid) do
		local Model
		local Colour
		local Origin = self:GridIDToMapOrigin(Data.ID)
		if Data.IsFriendly then
			Model = self.GridFrieldlyTileModel
			Colour = self.GridFriendlyColour
		else
			Model = self.GridEnemyTileModel
			Colour = self.GridEnemyColour
		end
		self.Grid[Data.ID] = {}
		self.Grid[Data.ID].Occupier = nil
		self.Grid[Data.ID].NextOccupier = nil
		self.Grid[Data.ID].IsFriendly = Data.IsFriendly
		self.Grid[Data.ID].PropEntity = SpawnEntityFromTableSynchronous(
			"prop_dynamic",
			{
				model = Model,
				rendercolor = Colour,
				scales = self.GridTileScales,
				origin = tostring(Origin.x) .. " " .. tostring(Origin.y) .. " " .. tostring(Origin.z),
				angles = self.GridTileAngles,
				solid = "0",
				disableshadows = "1",
			}
		)
	end
	-- For testing that we haven't messed up map to grid mapping:
	-- local Neighbours = self:GridIDToNeighbours(self:GridXYToGridID(0, 0))
	-- local X = -1000
	-- while X < 1000 do
	-- 	local Y = -1000
	-- 	while Y < 1000 do
	-- 		if Neighbours[self:MapXYToGridID(X, Y)] then
	-- 			DebugDrawSphere(Vector(X, Y, 128), Vector(0, 255, 0), 1, 8, false, 100)
	-- 		else
	-- 			DebugDrawSphere(Vector(X, Y, 128), Vector(255, 0, 0), 1, 8, false, 100)
	-- 		end
	-- 		Y = Y + 25
	-- 	end
	-- 	X = X + 25
	-- end
	-- DebugDrawSphere(self:GridIDToMapOrigin(self:GridXYToGridID(-1, -1)), Vector(0, 0, 255), 1, 20, false, 100)
	-- DebugDrawSphere(self:GridIDToMapOrigin(self:GridXYToGridID(3, 3)), Vector(255, 0, 255), 1, 20, false, 100)
end

function SAD:ResetGridData()
	for GridID, Tile in pairs(self.Grid) do
		self.Grid[GridID].Occupier = nil
		self.Grid[GridID].NextOccupier = nil
	end
end

function SAD:ReflectGridID(GridID)
	local X, Y = self:GridIDToGridXY(GridID)
	local X = 9 - X
	local Y = 6 - Y
	return self:GridXYToGridID(X, Y)
end

SAD.GridMapXSpacing = 230
SAD.GridMapYSpacing = SAD.GridMapXSpacing * math.sin(math.rad(60))
SAD.GridMapZBegin = 130
SAD.GridMapXBegin = -3 * SAD.GridMapXSpacing
SAD.GridMapYBegin = -3 * SAD.GridMapYSpacing
SAD.GridTileScales = "3.5 3.5 1"
SAD.GridTileAngles = "0 90 0"
SAD.GridFrieldlyTileModel = "models/props/sad_hex.vmdl"
-- SAD.GridEnemyTileModel = "models/props/sad_hex_enemy.vmdl"
SAD.GridEnemyTileModel = "models/props/sad_hex.vmdl"
SAD.GridFriendlyColour = "0 150 200 255"
SAD.GridEnemyColour = "200 0 0 255"


-- Note that while we don't use negative coordinates here they are fully supported.
SAD.DefaultGrid = {
	{ID = SAD.GridXYToGridID(nil,  0,  0), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  1,  0), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  2,  0), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  3,  0), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  4,  0), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  5,  0), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  6,  0), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  0,  1), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  1,  1), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  2,  1), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  3,  1), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  4,  1), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  5,  1), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  6,  1), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  7,  1), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  0,  2), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  1,  2), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  2,  2), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  3,  2), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  4,  2), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  5,  2), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  6,  2), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  7,  2), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  8,  2), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  0,  3), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  1,  3), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  2,  3), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  3,  3), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  4,  3), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  5,  3), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  6,  3), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  7,  3), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  8,  3), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  9,  3), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  1,  4), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  2,  4), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  3,  4), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  4,  4), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  5,  4), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  6,  4), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  7,  4), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  8,  4), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  9,  4), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  2,  5), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  3,  5), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  4,  5), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  5,  5), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  6,  5), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  7,  5), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  8,  5), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  9,  5), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  3,  6), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  4,  6), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  5,  6), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  6,  6), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  7,  6), IsFriendly =  true},
	{ID = SAD.GridXYToGridID(nil,  8,  6), IsFriendly = false},
	{ID = SAD.GridXYToGridID(nil,  9,  6), IsFriendly = false},
}
