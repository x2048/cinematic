-- Core API

local cinematic
cinematic = {
	motions = {},
	players = {},
	register_motion = function(name,definition)
		definition.name = name
		cinematic.motions[name] = definition
		table.insert(cinematic.motions, definition)
	end,
	start = function(player, motion, params)
		local player_name = player:get_player_name()
		if motion == "stop" then
			cinematic.players[player_name] = nil
		else
			local state = cinematic.motions[motion].initialize(player, params)
			-- motion can return nil from initialize to abort the process
			if state ~= nil then
				cinematic.players[player_name] = { player = player, motion = motion, state = state }
			end
		end
	end,
	stop = function(player)
		cinematic.start(player, "stop", {})
	end,
}

-- Update loop

minetest.register_globalstep(function()
	for _, entry in pairs(cinematic.players) do
		cinematic.motions[entry.motion].tick(entry.player, entry.state)
	end
end)

-- Motions

cinematic.register_motion("360", {
	initialize = function(player, params)
		local player_pos = player:get_pos()
		local center = vector.add(player_pos, vector.multiply(vector.normalize(player:get_look_dir()), params.radius or 50))
		return {
			center = center,
			distance = vector.distance(vector.new(center.x, 0, center.z), vector.new(player_pos.x, 0, player_pos.z)),
			angle = minetest.dir_to_yaw(vector.subtract(player_pos, center)) + math.pi / 2,
			height = player_pos.y - center.y,
			speed = params:get_speed({"l", "left"}, "right"),
		}
	end,
	tick = function(player, state)
		state.angle = state.angle + state.speed * math.pi / 3600
		if state.angle < 0 then state.angle = state.angle + 2 * math.pi end
		if state.angle > 2 * math.pi then state.angle = state.angle - 2 * math.pi end

		player_pos = vector.add(state.center, vector.new(state.distance * math.cos(state.angle), state.height, state.distance * math.sin(state.angle)))
		player:set_pos(player_pos)
		player:set_look_horizontal(state.angle + math.pi / 2)
	end
})

cinematic.register_motion("dolly", {
	initialize = function(player, params)
		return {
			speed = params:get_speed({"b", "back", "backwards", "out"}, "forward"),
			direction = vector.normalize(player:get_look_dir()),
		}
	end,
	tick = function(player, state)
		local player_pos = player:get_pos()

		player_pos = vector.add(player_pos, vector.multiply(state.direction, state.speed * 0.05))
		player:set_pos(player_pos)
	end
})

cinematic.register_motion("truck", {
	initialize = function(player, params)
		return {
			speed = params:get_speed({"l", "left"}, "right"),
			direction = vector.normalize(vector.cross(vector.new(0,1,0), player:get_look_dir())),
		}
	end,
	tick = function(player, state)
		local player_pos = player:get_pos()

		player_pos = vector.add(player_pos, vector.multiply(state.direction, state.speed * 0.05))
		player:set_pos(player_pos)
	end
})

cinematic.register_motion("pedestal", {
	initialize = function(player, params)
		return {
			speed = params:get_speed({"d", "down"}, "up"),
			direction = vector.new(0,1,0)
		}
	end,
	tick = function(player, state)
		local player_pos = player:get_pos()

		player_pos = vector.add(player_pos, vector.multiply(state.direction, state.speed * 0.05))
		player:set_pos(player_pos)
	end
})

cinematic.register_motion("pan", {
	initialize = function(player, params)
		return {
			speed = params:get_speed({"l", "left"}, "right"),
			angle = player:get_look_horizontal()
		}
	end,
	tick = function(player, state)
		state.angle = state.angle - state.speed * math.pi / 3600
		if state.angle < 0 then state.angle = state.angle + 2 * math.pi end
		if state.angle > 2 * math.pi then state.angle = state.angle - 2 * math.pi end
		player:set_look_horizontal(state.angle)
	end
})

cinematic.register_motion("tilt", {
	initialize = function(player, params)
		return {
			speed = params:get_speed({"d", "down"}, "up"),
			angle = player:get_look_vertical()
		}
	end,
	tick = function(player, state)
		state.angle = state.angle - state.speed * math.pi / 3600
		if state.angle < 0 then state.angle = state.angle + 2 * math.pi end
		if state.angle > 2 * math.pi then state.angle = state.angle - 2 * math.pi end
		player:set_look_vertical(state.angle)
	end
})

cinematic.register_motion("stop", {initialize = function() end})

-- Parsing utilities

local function starts_with(str, prefix)
	return str:sub(1, #prefix) == prefix
end

local function skip_prefix(str, prefix)
	return str:sub(#prefix + 1)
end

local function string_split(str, char)
	result = {}
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

-- Chat command handler

minetest.register_chatcommand("cc", {
	params = "(360|tilt|pan|truck|dolly|pedestal|stop) [direction=<right|left|in|out>] [speed=<speed>] [radius=<radius>]",
	description = "Move your camera with cinematic effects.",
	privs = { fly = true },
	func = function(name, cmdline)
		local player = minetest.get_player_by_name(name)
		local command
		local params = {}
		local parts = string_split(cmdline, " ")
		-- Parse command line
		for i = 1,#parts do
			if command == nil then
				command = parts[i]
			else
				for _,setting in ipairs({ "direction", "speed", "radius" }) do
					if starts_with(parts[i], setting.."=") then
						params[setting] = skip_prefix(parts[i], setting.."=")
					end
				end
			end
		end
		
		-- Fixup numeric settings
		params.speed = (params.speed and tonumber(params.speed))
		params.radius = (params.radius and tonumber(params.radius))

		params.get_speed = function(self, negative_dirs, default_dir)
			return (self.speed or 1) * (is_in(self.direction or default_dir, negative_dirs) and -1 or 1)
		end

		if cinematic.motions[command] == nil then
			return false, "Invalid command, see /help cc"
		end

		cinematic.start(player, command, params)
		return true,""
	end
})

