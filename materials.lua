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

-- materials.lua
-- Реєстрація матеріалу:
--   * частинка-мініблок (окрема нода, що не ставиться)
--   * 21 форма-нода
--   * рецепти (через register_recipes)
--
-- Також автоматична реєстрація всіх підходящих нод
-- через register_all_materials().

miniblocks.materials = {}

local S = minetest.get_translator("miniblocks")

-- ---------------------------------------------------------------------------
-- Утиліти
-- ---------------------------------------------------------------------------

local function get_material_name(node_name)
	return node_name:gsub(":", "_")
end

miniblocks.get_material_name = get_material_name


local function copy_material_properties(def)
	local properties = {
		tiles             = def.tiles,
		sounds            = def.sounds,
		light_source      = def.light_source,
		use_texture_alpha = def.use_texture_alpha,
		paramtype         = "light",
	}

	-- Звичайне скло (default:glass, default:obsidian_glass):
	-- беремо чисту текстуру без рамки, розмножуємо на 6 граней.
	-- Кольорове скло має drawtype "allfaces_optional" і сюди не потрапляє.
	if def.drawtype == "glasslike_framed"
		or def.drawtype == "glasslike_framed_optional" then

		local base
		if type(def.tiles) == "table" and #def.tiles >= 2 then
			base = def.tiles[2]
		end

		if base then
			properties.tiles = { base, base, base, base, base, base }
		end
		properties.use_texture_alpha = "blend"
	end

	if def.groups then
		properties.groups = {}
		for gname, gvalue in pairs(def.groups) do
			properties.groups[gname] = gvalue
		end
	end

	return properties
end

-- ---------------------------------------------------------------------------
-- Реєстрація одного матеріалу
-- ---------------------------------------------------------------------------

function miniblocks.register_material(node_name)
	local def = minetest.registered_nodes[node_name]

	if not def then
		minetest.log("warning",
			"[miniblocks] Unknown material: " .. node_name)
		return
	end

	if miniblocks.materials[node_name] then
		return
	end

	local name = get_material_name(node_name)

	miniblocks.materials[node_name] = {
		name = name,
		node = node_name,
	}

	-- Частинка (не ставиться, не світиться в креативі)
	local particle_props = copy_material_properties(def)
	particle_props.description = def.description .. " " .. S("Mini Block Particle")
	particle_props.drawtype = "nodebox"
	particle_props.node_box = miniblocks.mask_to_node_box(1)
	particle_props.groups.not_in_creative_inventory = 1

	particle_props.walkable = false
	particle_props.pointable = false
	particle_props.sunlight_propagates = true
	particle_props.buildable_to = true

	particle_props.on_place = function(itemstack) return itemstack end
	particle_props.on_use = function(itemstack) return itemstack end
	particle_props.on_secondary_use = function(itemstack) return itemstack end

	minetest.register_node(":miniblocks:" .. name .. "_particle", particle_props)

	-- 21 форма
	for _, shape in ipairs(miniblocks.shapes) do
		local properties = copy_material_properties(def)

		properties.description = def.description .. " "
			.. S("Mini Block Form @1", shape.name)

		properties.drawtype = "nodebox"
		properties.node_box = miniblocks.mask_to_node_box(shape.mask)
		properties.paramtype2 = "facedir"

		minetest.register_node(
			":miniblocks:" .. name .. "_" .. shape.name,
			properties
		)
	end

	miniblocks.register_recipes(node_name)
end

-- ---------------------------------------------------------------------------
-- Автоматична реєстрація всіх підходящих нод
-- ---------------------------------------------------------------------------

local ALLOWED_GROUPS = {
	"stone", "wood", "sandstone", "tree", "glass", "metal",
	"brick", "clay", "cracky", "choppy", "snappy", "wool", "leaves",
}

local BLOCKED_GROUPS = {
	"water", "lava", "flora", "sapling", "flower", "ore",
	"not_in_creative_inventory", "dirt", "soil", "sand",
	"falling_node", "crumbly",
}

local BLOCKED_CALLBACKS = {
	"on_construct", "on_rightclick", "on_timer", "on_receive_fields",
	"on_metadata_inventory_put", "on_metadata_inventory_take",
	"on_metadata_inventory_move", "allow_metadata_inventory_put",
	"allow_metadata_inventory_take", "allow_metadata_inventory_move",
	"on_blast",
}

local BLOCKED_NODES = {
	["default:dirt_with_grass"]             = true,
	["default:dirt_with_dry_grass"]         = true,
	["default:dirt_with_rainforest_litter"] = true,
	["default:dirt_with_coniferous_litter"] = true,
	["default:permafrost"]                  = true,
	["default:permafrost_with_stones"]      = true,
	["default:permafrost_with_moss"]        = true,
}

local CUBE_DRAWTYPES = {
	normal                    = true,
	allfaces                  = true,
	allfaces_optional         = true,
	glasslike                 = true,
	glasslike_framed          = true,
	glasslike_framed_optional = true,
	glasslike_connected       = true,
}


function miniblocks.register_all_materials()
	for node_name, def in pairs(minetest.registered_nodes) do

		if node_name ~= "air" and def.drawtype ~= "airlike" then
			if not BLOCKED_NODES[node_name] then

				local has_allowed = false
				if def.groups then
					for _, group in ipairs(ALLOWED_GROUPS) do
						if def.groups[group] then
							has_allowed = true
							break
						end
					end
				end

				if has_allowed then

					local has_blocked = false
					if def.groups then
						for _, group in ipairs(BLOCKED_GROUPS) do
							if def.groups[group] then
								has_blocked = true
								break
							end
						end
					end

					if not has_blocked then

						local is_ore = false
						if def.drop and type(def.drop) == "string" then
							local drop_name = def.drop:match("^([^%s]+)")
							if drop_name
								and minetest.registered_items[drop_name]
								and not minetest.registered_nodes[drop_name] then
								is_ore = true
							end
						end

						if not is_ore then

							local has_logic = false
							for _, cb in ipairs(BLOCKED_CALLBACKS) do
								if def[cb] then
									has_logic = true
									break
								end
							end

							if not has_logic then

								local dt = def.drawtype or "normal"
								if CUBE_DRAWTYPES[dt] then

									if not miniblocks.materials[node_name] then
										miniblocks.register_material(node_name)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end