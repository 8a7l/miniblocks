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

-- init.lua
-- MiniBlocks: точка входу моду.
-- Порядок завантаження важливий:
--   shapes       → базові функції (без залежностей)
--   shapes_list  → список 21 форми
--   recipes      → реєстрація рецептів (викликається з materials)
--   materials    → реєстрація нод і рецептів для матеріалів
--   colored_glass → кольорове скло
--   tool_cutter  → різання блоків інструментами

miniblocks = {}

local modpath = minetest.get_modpath("miniblocks")

dofile(modpath .. "/shapes.lua")
dofile(modpath .. "/shapes_list.lua")
dofile(modpath .. "/recipes.lua")
dofile(modpath .. "/materials.lua")
dofile(modpath .. "/colored_glass.lua")
dofile(modpath .. "/tool_cutter.lua")


minetest.register_on_mods_loaded(function()
	-- Реєструємо всі стандартні матеріали
	miniblocks.register_all_materials()

	-- Реєструємо кольорове скло
	miniblocks.register_all_colored_glass()
end)

