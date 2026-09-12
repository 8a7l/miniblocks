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

-- tool_cutter.lua
-- Утримання ПКМ відповідним інструментом по блоку MiniBlocks:
--   * сокира  → choppy-матеріали (дерево)
--   * кирка   → cracky-матеріали (камінь, метали, скло)
--   * лопата  → crumbly-матеріали (глина, гравій)
--   * меч     → snappy-матеріали (вовна, листя)
--
-- Під час різання: анімація руки, звук, частинки.
-- Після завершення: блок зникає, видається 8 частинок,
-- інструмент зношується.

local CUT_GROUPS = {
	choppy  = true,
	cracky  = true,
	crumbly = true,
	snappy  = true,
}

-- Мінімальний час різання (секунди)
local MIN_CUT_TIME = 0.5

-- Інтервал між звуком і частинками під час різання
local FX_INTERVAL = 0.15

-- ---------------------------------------------------------------------------
-- Визначення групи інструменту для матеріалу
-- ---------------------------------------------------------------------------

local function get_material_tool_group(groups)
	if not groups then return nil end

	-- Вовна/листя — snappy, навіть якщо мають choppy
	if groups.wool or groups.snappy or groups.leaves then
		return "snappy"
	end

	if groups.choppy or groups.wood or groups.tree then
		return "choppy"
	end
	if groups.cracky or groups.stone or groups.metal or groups.glass then
		return "cracky"
	end
	if groups.crumbly or groups.dirt or groups.soil or groups.sand then
		return "crumbly"
	end

	return nil
end

-- ---------------------------------------------------------------------------
-- Час різання
-- ---------------------------------------------------------------------------

local function get_cut_time(node_def, tool_def, tool_group)
	local hardness = (node_def.groups and node_def.groups[tool_group]) or 1
	local gc = tool_def.tool_capabilities
		and tool_def.tool_capabilities.groupcaps
		and tool_def.tool_capabilities.groupcaps[tool_group]

	if not gc or not gc.times then
		return MIN_CUT_TIME
	end

	local base = gc.times[hardness] or gc.times[1] or MIN_CUT_TIME
	return math.max(MIN_CUT_TIME, base)
end

-- ---------------------------------------------------------------------------
-- Частинки
-- ---------------------------------------------------------------------------

local function get_particle_texture(node_def)
	if not node_def.tiles then return nil end
	if type(node_def.tiles) == "string" then
		return node_def.tiles
	end
	return node_def.tiles[1]
end


local function spawn_crack_particles(pos, tex)
	if not tex then return end

	minetest.add_particlespawner({
		amount = 20,
		time = 0.2,
		minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
		maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
		minvel = {x = -1.5, y = 1.0, z = -1.5},
		maxvel = {x = 1.5, y = 2.5, z = 1.5},
		minacc = {x = 0, y = -6, z = 0},
		maxacc = {x = 0, y = -6, z = 0},
		minexptime = 0.4,
		maxexptime = 0.9,
		minsize = 0.6,
		maxsize = 1.6,
		texture = tex,
		collisiondetection = false,
		vertical = false,
	})
end

-- ---------------------------------------------------------------------------
-- Завершення різання
-- ---------------------------------------------------------------------------

local cutting = {}  -- [player_name] = стан різання

local function finish_cut(state, placer, itemstack)
	local pos = state.pos
	local node = minetest.get_node(pos)
	if node.name ~= state.node_name then return end

	minetest.remove_node(pos)

	local node_def = minetest.registered_nodes[node.name]
	local tex = node_def and get_particle_texture(node_def)
	spawn_crack_particles(pos, tex)

	-- Видаємо 8 частинок
	local particle_name = "miniblocks:" .. state.mat_name .. "_particle"
	local stack = ItemStack(particle_name .. " 8")
	local inv = placer:get_inventory()

	if inv and inv:room_for_item("main", stack) then
		inv:add_item("main", stack)
	else
		minetest.add_item(pos, stack)
	end

	-- Зношуємо інструмент
	local tool_def = minetest.registered_tools[itemstack:get_name()]
	if tool_def then
		local gc = tool_def.tool_capabilities.groupcaps[state.tool_group]
		local uses = (gc and gc.uses) or 100
		local wear = math.max(1, math.floor(65535 / uses))

		if itemstack:get_wear() + wear >= 65535 then
			minetest.sound_play("default_tool_breaks",
				{pos = placer:get_pos()})
			placer:set_wielded_item(ItemStack(""))
		else
			itemstack:add_wear(wear)
			placer:set_wielded_item(itemstack)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Основний цикл (перевірка утримання ПКМ)
-- ---------------------------------------------------------------------------

local function get_pointed_node(player)
	local pos = player:get_pos()
	local eye_h = player:get_properties().eye_height or 1.5
	local eye = {x = pos.x, y = pos.y + eye_h, z = pos.z}
	local dir = player:get_look_dir()
	local reach = 4

	local target = {
		x = eye.x + dir.x * reach,
		y = eye.y + dir.y * reach,
		z = eye.z + dir.z * reach,
	}

	local ray = minetest.raycast(eye, target, false, true)
	local pointed = ray:next()

	if pointed and pointed.type == "node" then
		return pointed.under
	end
	return nil
end


local function reset_player(player_name)
	if cutting[player_name] then
		cutting[player_name] = nil
		local player = minetest.get_player_by_name(player_name)
		if player then
			player:set_animation({x = 0, y = 0}, 0, 0, false)
		end
	end
end


-- Обробка одного гравця за один тік.
-- Використовуємо return замість goto continue —
-- для сумісності з PUC Lua 5.1 (де goto відсутній).
local function process_player(player, dtime)
	local name = player:get_player_name()
	local control = player:get_player_control()

	-- ПКМ не утримується — скидаємо стан
	if not control.place then
		reset_player(name)
		return
	end

	local wielded = player:get_wielded_item()
	local tool_def = minetest.registered_tools[wielded:get_name()]

	if not tool_def or not tool_def.tool_capabilities then
		reset_player(name)
		return
	end

	local node_pos = get_pointed_node(player)

	if not node_pos then
		reset_player(name)
		return
	end

	local node = minetest.get_node(node_pos)

	if not miniblocks.materials[node.name] then
		reset_player(name)
		return
	end

	local node_def = minetest.registered_nodes[node.name]
	local mat_group = get_material_tool_group(node_def and node_def.groups)
	local gc = tool_def.tool_capabilities.groupcaps

	if not mat_group or not gc or not gc[mat_group] then
		reset_player(name)
		return
	end

	-- Отримуємо або створюємо стан різання
	local st = cutting[name]

	if not st
		or st.pos.x ~= node_pos.x
		or st.pos.y ~= node_pos.y
		or st.pos.z ~= node_pos.z
		or st.node_name ~= node.name then

		st = {
			pos = node_pos,
			node_name = node.name,
			mat_name = miniblocks.materials[node.name].name,
			tool_group = mat_group,
			cut_time = get_cut_time(node_def, tool_def, mat_group),
			elapsed = 0,
			next_fx = 0,
		}
		cutting[name] = st
	end

	st.elapsed = st.elapsed + dtime

	-- Періодичні звук і частинки
	if st.elapsed >= st.next_fx then
		st.next_fx = st.elapsed + FX_INTERVAL

		minetest.sound_play("default_dig_" .. mat_group, {
			pos = node_pos,
			gain = 0.5,
			max_hear_distance = 16,
		})
		spawn_crack_particles(node_pos,
			get_particle_texture(node_def))
	end

	player:set_animation({x = 189, y = 198}, 30, 0, false)

	-- Завершення
	if st.elapsed >= st.cut_time then
		finish_cut(st, player, wielded)
		player:set_animation({x = 0, y = 0}, 0, 0, false)
		cutting[name] = nil
	end
end


minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		process_player(player, dtime)
	end
end)

-- ---------------------------------------------------------------------------
-- Перехоплення on_place, щоб ПКМ не ставив блоки
-- ---------------------------------------------------------------------------

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_tools) do
		local gc = def.tool_capabilities and def.tool_capabilities.groupcaps

		if gc then
			local is_cutter = false
			for group, _ in pairs(gc) do
				if CUT_GROUPS[group] then
					is_cutter = true
					break
				end
			end

			if is_cutter then
				local old_on_place = def.on_place

				minetest.override_item(name, {
					on_place = function(itemstack, placer, pointed_thing)
						-- Якщо ціль — наш блок, не ставимо нічого
						if pointed_thing and pointed_thing.type == "node" then
							local node = minetest.get_node(pointed_thing.under)
							if miniblocks.materials
								and miniblocks.materials[node.name] then
								return itemstack
							end
						end

						if old_on_place then
							return old_on_place(itemstack, placer, pointed_thing)
						end
						return itemstack
					end
				})
			end
		end
	end
end)