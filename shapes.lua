-- MiniBlocks — cut blocks into 21 mini-forms
-- Copyright (C) 2026 Vasyl Onufriichuk
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.

-- shapes.lua
-- Геометрія MiniBlocks:
--   * маска 0..255 → node_box (3D-форма блоку)
--   * маска 0..255 → патерн 3×3 (shaped-крафт)
--
-- Бітова маска описує 8 мінікубиків у сітці 2×2×2.
-- Індекс біта: id = x + 2*y + 4*z.

miniblocks = miniblocks or {}

local HALF = 0.5

-- ---------------------------------------------------------------------------
-- Конфігурація
-- ---------------------------------------------------------------------------

-- true  → об'єднувати суміжні кубики в прямокутники (менше швів)
-- false → кожен кубик окремою коробкою (для порівняння)
local MERGE_CUBES = true

-- ---------------------------------------------------------------------------
-- 3D-сітка 2×2×2
-- ---------------------------------------------------------------------------

local function mask_to_grid(mask)
	local grid = {}
	for x = 0, 1 do
		grid[x] = {}
		for y = 0, 1 do
			grid[x][y] = {}
			for z = 0, 1 do
				local idx = x + 2 * y + 4 * z
				grid[x][y][z] = (math.floor(mask / 2 ^ idx) % 2 == 1)
			end
		end
	end
	return grid
end

-- ---------------------------------------------------------------------------
-- Перетворення сітки в коробки
-- ---------------------------------------------------------------------------

-- Варіант A: кожен кубик окремо
local function grid_to_boxes_separate(grid)
	local boxes = {}
	for x = 0, 1 do
		for y = 0, 1 do
			for z = 0, 1 do
				if grid[x][y][z] then
					boxes[#boxes + 1] = {
						-HALF + x * HALF,
						-HALF + y * HALF,
						-HALF + z * HALF,
						-HALF + (x + 1) * HALF,
						-HALF + (y + 1) * HALF,
						-HALF + (z + 1) * HALF,
					}
				end
			end
		end
	end
	return boxes
end

-- Варіант B: greedy meshing (об'єднання суміжних кубиків)
local function grid_to_boxes_merged(grid)
	local used = {}
	local boxes = {}

	local function key(x, y, z)
		return x .. "," .. y .. "," .. z
	end

	for z = 0, 1 do
		for y = 0, 1 do
			for x = 0, 1 do

				if grid[x][y][z] and not used[key(x, y, z)] then

					local x2 = x
					while x2 + 1 <= 1
						and grid[x2 + 1][y][z]
						and not used[key(x2 + 1, y, z)] do
						x2 = x2 + 1
					end

					local y2 = y
					local can_y = true
					while can_y and y2 + 1 <= 1 do
						for xi = x, x2 do
							if not grid[xi][y2 + 1][z]
								or used[key(xi, y2 + 1, z)] then
								can_y = false
								break
							end
						end
						if can_y then y2 = y2 + 1 end
					end

					local z2 = z
					local can_z = true
					while can_z and z2 + 1 <= 1 do
						for xi = x, x2 do
							for yi = y, y2 do
								if not grid[xi][yi][z2 + 1]
									or used[key(xi, yi, z2 + 1)] then
									can_z = false
									break
								end
							end
							if not can_z then break end
						end
						if can_z then z2 = z2 + 1 end
					end

					for xi = x, x2 do
						for yi = y, y2 do
							for zi = z, z2 do
								used[key(xi, yi, zi)] = true
							end
						end
					end

					boxes[#boxes + 1] = {
						-HALF + x * HALF,
						-HALF + y * HALF,
						-HALF + z * HALF,
						-HALF + (x2 + 1) * HALF,
						-HALF + (y2 + 1) * HALF,
						-HALF + (z2 + 1) * HALF,
					}
				end
			end
		end
	end

	return boxes
end

-- ---------------------------------------------------------------------------
-- Публічні функції
-- ---------------------------------------------------------------------------

function miniblocks.mask_to_node_box(mask)
	if type(mask) ~= "number" then
		error("MiniBlocks: mask must be a number")
	end
	if mask < 0 or mask > 255 or mask % 1 ~= 0 then
		error("MiniBlocks: mask must be an integer from 0 to 255")
	end

	local grid = mask_to_grid(mask)
	local boxes

	if MERGE_CUBES then
		boxes = grid_to_boxes_merged(grid)
	else
		boxes = grid_to_boxes_separate(grid)
	end

	return {
		type = "fixed",
		fixed = boxes,
	}
end


function miniblocks.mask_count(mask)
	local count = 0
	for index = 0, 7 do
		if math.floor(mask / 2 ^ index) % 2 == 1 then
			count = count + 1
		end
	end
	return count
end

-- ---------------------------------------------------------------------------
-- Патерн 3×3 для shaped-крафту
-- ---------------------------------------------------------------------------

local PATTERN_POS = {
	[0] = {1, 1},
	[1] = {1, 3},
	[2] = {3, 1},
	[3] = {3, 3},
	[4] = {1, 2},
	[5] = {2, 1},
	[6] = {2, 3},
	[7] = {3, 2},
}


function miniblocks.mask_to_pattern(mask)
	local pattern = {
		{ "", "", "" },
		{ "", "", "" },
		{ "", "", "" },
	}

	for i = 0, 7 do
		if math.floor(mask / 2 ^ i) % 2 == 1 then
			local pos = PATTERN_POS[i]
			pattern[pos[1]][pos[2]] = "P"
		end
	end

	return pattern
end