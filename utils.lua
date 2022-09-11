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

local function get_speed(self, negative_dirs, default_dir)
	return (self.speed or 1) * (is_in(self.direction or default_dir, negative_dirs) and -1 or 1)
end

local function isDefaultFov(fov)
	return #fov >= 3 and fov[1] == 0 and fov[2] == false and fov[3] == 0
end

-- Motion helpers

local motion = {}

function motion.save(player, slot, value)
	player:get_meta():set_string("cc_m_"..slot, minetest.serialize(value))
end

function motion.import(player, motions)
	local meta = player:get_meta()
	for key, value in pairs(motions) do
		meta:set_string("cc_m_"..key, minetest.serialize(value))
	end
end

function motion.trim(value)
	for _, v in ipairs({"dir", "v", "r", "t", "n", "p"}) do
		value[v] = nil
	end
	local fov = value.pos and value.pos.fov
	if fov and isDefaultFov(fov) then value.pos.fov = nil end
end

function motion.export(player)
	local result = {}
	motion.forEach(player, function(key, value)
		motion.trim(value)
		result[key] = value
	end)
	return result
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
	local meta = player:get_meta()
  for key, value in pairs(meta:to_table().fields) do
		if starts_with(key, "cc_m_") then
			key = skip_prefix(key, "cc_m_")
			value = minetest.deserialize(value)
			fn(key, value, meta)
		end
	end
end

function motion.list(player)
	local result = {}
	motion.forEach(player, function(key, _)
		table.insert(result, key)
	end)
	return result
end

-- Position helpers

local position = {}
function position.current(player)
	local fov = {player:get_fov()}
	if isDefaultFov(fov) then fov = nil end
	return {
		pos = player:get_pos(),
		look = { h = player:get_look_horizontal(), v = player:get_look_vertical(), },
		fov = fov,
	}
end

function position.save(player, slot)
	local state = position.current(player)
	player:get_meta():set_string("cc_pos_"..slot, minetest.serialize(state))
end

function position.import(player, positions)
	local meta = player:get_meta()
	for key, value in pairs(positions) do
		meta:set_string("cc_pos_"..key, minetest.serialize(value))
	end
end

function position.export(player)
	local result = {}
	position.forEach(player, function(key, value)
		local fov = value.fov
		if isDefaultFov(fov) then value.fov = nil end
		result[key] = value
	end)
	return result
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
	local fov = state.fov or {0, false, 0}
	player:set_fov(unpack(fov))
	return true
end

function position.forEach(player, fn)
	local meta = player:get_meta()
  for key, value in pairs(meta:to_table().fields) do
		if starts_with(key, "cc_pos_") then
			key = skip_prefix(key, "cc_pos_")
			value = minetest.deserialize(value)
			fn(key, value, meta)
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
		table.insert(result, key)
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
	get_speed = get_speed,
}
