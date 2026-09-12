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

-- colored_glass.lua
-- Кольорове скло MiniBlocks.
--
-- Для кожного кольору реєструється повноцінний матеріал:
--   * блок-джерело (miniblocks:glass_red)
--   * частинка
--   * 21 форма
--   * рецепти

local S = minetest.get_translator("miniblocks")

-- { технічна_назва, hex-колір, назва для перекладу }
miniblocks.glass_colors = {
	{ "red",     "#ff2020", "Red"     },
	{ "orange",  "#ff9020", "Orange"  },
	{ "yellow",  "#ffea20", "Yellow"  },
	{ "green",   "#20cc20", "Green"   },
	{ "cyan",    "#20cccc", "Cyan"    },
	{ "blue",    "#2050ff", "Blue"    },
	{ "violet",  "#9020ff", "Violet"  },
	{ "magenta", "#ff20cc", "Magenta" },
	{ "pink",    "#ff80b0", "Pink"    },
	{ "brown",   "#804020", "Brown"   },
	{ "black",   "#202020", "Black"   },
	{ "white",   "#f0f0f0", "White"   },
}


function miniblocks.register_colored_glass(color_name, color_hex, color_display)
	local node_name = "miniblocks:glass_" .. color_name

	-- Суцільний колір без текстури скла.
	local tex = "[fill:16x16:" .. color_hex .. "^[opacity:70"

	minetest.register_node(":" .. node_name, {
		description = S("Colored Glass (@1)", S(color_display)),
		drawtype = "allfaces_optional",
		tiles = { tex },
		use_texture_alpha = "blend",
		paramtype = "light",
		sunlight_propagates = true,
		groups = { cracky = 3, glass = 1, oddly_breakable_by_hand = 3 },
	})

	-- Рецепт: 8 скла + 1 барвник → 8 кольорових стекол
	if minetest.get_modpath("dye") then
		minetest.register_craft({
			type = "shapeless",
			output = node_name .. " 8",
			recipe = {
				"default:glass", "default:glass",
				"default:glass", "default:glass",
				"default:glass", "default:glass",
				"default:glass", "default:glass",
				"dye:" .. color_name,
			},
		})
	end

	miniblocks.register_material(node_name)
end


function miniblocks.register_all_colored_glass()
	for _, c in ipairs(miniblocks.glass_colors) do
		miniblocks.register_colored_glass(c[1], c[2], c[3])
	end
end