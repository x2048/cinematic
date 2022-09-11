-- Parsing utilities

local function starts_with(str, prefix)
	return str:sub(1, #prefix) == prefix
end

local function skip_prefix(str, prefix)
	return str:sub(#prefix + 1)
end

local function string_split(str, char)
	local result = {}
	for part in str:gmatch("[^"..char.."]+") do
		table.insert(result, part)
	end
	return result
end

local function is_in(item, set)
	for _,valid in ipairs(set) do
		if item == valid then return true end
	end
	return false
end

-- Motion helpers

local motion = {}
function motion.save(player, slot, value)
	player:get_meta():set_string("cc_m_"..slot, minetest.serialize(value))
end

function motion.get(player, slot)
	local result = player:get_meta():get_string("cc_m_"..slot)
	if result == nil then
		return nil, "Saved motion not found"
	end

  result = minetest.deserialize(result)
	if result == nil then
		return nil, "Saved motion could not be restored"
	end

	return result
end

function motion.clear(player, slot)
	local meta = player:get_meta()
	if slot then
		meta:set_string("cc_m_"..slot, "")
	else
		motion.forEach(player, function(key, _)
			meta:set_string(key, "")
		end)
	end
end

function motion.forEach(player, fn)
  for key, value in pairs(player:get_meta():to_table().fields) do
		if starts_with(key, "cc_m_") then
			fn(key, value)
		end
	end
end

function motion.list(player)
	local result = {}
	motion.forEach(player, function(key, _)
		table.insert(result, skip_prefix(key, "cc_m_"))
	end)
	return result
end

-- Position helpers

local position = {}
function position.current(player)
	return {
		pos = player:get_pos(),
		look = { h = player:get_look_horizontal(), v = player:get_look_vertical(), },
		fov = {player:get_fov()},
	}
end

function position.save(player, slot)
	local state = position.current(player)
	player:get_meta():set_string("cc_pos_"..slot, minetest.serialize(state))
end

function position.get(player, slot)
	local state = player:get_meta():get_string("cc_pos_"..slot)
	if state == nil then
		return nil, "Saved position not found"
	end

	state = minetest.deserialize(state)
	if state == nil then
		return nil, "Saved position could not be restored"
	end

	return state
end

function position.restore(player, slot)
	local state,message = position.get(player, slot)
	if state == nil then
		-- minetest.chat_send_player(player:get_player_name(), message)
		return false, message
	end

	player:set_pos(state.pos)
	player:set_look_horizontal(state.look.h)
	player:set_look_vertical(state.look.v)
	player:set_fov(unpack(state.fov))
	return true
end

function position.forEach(player, fn)
  for key, value in pairs(player:get_meta():to_table().fields) do
		if starts_with(key, "cc_pos_") then
			fn(key, value)
		end
	end
end

function position.clear(player, slot)
	local meta = player:get_meta()
	if slot then
		meta:set_string("cc_pos_"..slot, "")
	else
		position.forEach(player, function(key, _)
			meta:set_string(key, "")
		end)
	end
end

function position.list(player)
	local result = {}
	position.forEach(player, function(key, _)
		table.insert(result, skip_prefix(key, "cc_pos_"))
	end)
	return result
end

return {
	motion = motion,
	position = position,
  starts_with = starts_with,
  skip_prefix = skip_prefix,
  string_split = string_split,
  is_in = is_in,
}
