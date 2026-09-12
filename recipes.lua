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

-- recipes.lua
-- Генерація крафтів для одного матеріалу.
--
-- Що реєструється:
--   * shaped 3×3   — N частинок → форма N
--   * shapeless    — форма N → N частинок
--   * 1 частинка ↔ форма 1
--   * 8 частинок → повний блок
--
-- Прямий крафт "блок → 8 частинок" вимкнено.
-- Частинки отримуються різанням блоків інструментами
-- (див. tool_cutter.lua).

-- Нормалізує патерн у підпис для виявлення конфліктів.
local function pattern_signature(pattern)
	local min_row, max_row = 4, 0
	local min_col, max_col = 4, 0

	for row = 1, 3 do
		for col = 1, 3 do
			if pattern[row][col] ~= "" then
				if row < min_row then min_row = row end
				if row > max_row then max_row = row end
				if col < min_col then min_col = col end
				if col > max_col then max_col = col end
			end
		end
	end

	local sig = ""
	for row = min_row, max_row do
		for col = min_col, max_col do
			sig = sig .. (pattern[row][col] ~= "" and "P" or ".")
		end
		sig = sig .. "/"
	end

	return sig
end


function miniblocks.register_recipes(node_name)
	local name = miniblocks.get_material_name(node_name)
	local particle = "miniblocks:" .. name .. "_particle"

	local seen_signatures = {}

	for _, shape in ipairs(miniblocks.shapes) do
		local count = miniblocks.mask_count(shape.mask)
		local item = "miniblocks:" .. name .. "_" .. shape.name

		-- Базова форма: 1 частинка ↔ 1 міні-блок
		if count == 1 then
			minetest.register_craft({
				type = "shapeless",
				output = item,
				recipe = { particle },
			})

			minetest.register_craft({
				type = "shapeless",
				output = particle,
				recipe = { item },
			})

		-- Решта форм: shaped + зворотний
		else
			local pattern = miniblocks.mask_to_pattern(shape.mask)

			for row = 1, 3 do
				for col = 1, 3 do
					if pattern[row][col] == "P" then
						pattern[row][col] = particle
					end
				end
			end

			-- Перевірка на конфлікт патернів
			local sig = pattern_signature(pattern)
			if seen_signatures[sig] then
				minetest.log("warning",
					"[miniblocks] pattern conflict: "
					.. name .. "_" .. shape.name
					.. " == " .. name .. "_" .. seen_signatures[sig]
					.. "  (" .. sig .. ")")
			else
				seen_signatures[sig] = shape.name
			end

			minetest.register_craft({
				type = "shaped",
				output = item,
				recipe = pattern,
			})

			minetest.register_craft({
				type = "shapeless",
				output = particle .. " " .. count,
				recipe = { item },
			})
		end
	end

	-- Зворотний крафт: 8 частинок → повний блок
	minetest.register_craft({
		type = "shapeless",
		output = node_name,
		recipe = {
			particle, particle, particle, particle,
			particle, particle, particle, particle,
		},
	})
end