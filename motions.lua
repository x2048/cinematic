local MOD_NAME = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(MOD_NAME) .. "/"
local utils = dofile(MOD_PATH .. "utils.lua")
local S = minetest.get_translator(MOD_NAME)
local get_speed = utils.get_speed

-- Position helpers
local position = utils.position

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
			speed = get_speed(params, {"l", "left"}, "right"),
			time = 0,
		}
	end,
	tick = function(player, state, dtime)
		state.time = state.time + dtime
		local delta_angle = state.speed * state.time * math.pi * 1 / 180
		if math.abs(delta_angle) > 1.0 then
			state.angle = state.angle + delta_angle
			delta_angle = 0.0
			state.time = 0.0
			if state.angle < 0 then state.angle = state.angle + 2 * math.pi end
			if state.angle > 2 * math.pi then state.angle = state.angle - 2 * math.pi end
		end

		local player_pos = vector.add(state.center, vector.new(state.distance * math.cos(state.angle + delta_angle), state.height, state.distance * math.sin(state.angle + delta_angle)))
		player:set_pos(player_pos)
		player:set_look_horizontal(state.angle + delta_angle + math.pi / 2)
	end
})

cinematic.register_motion("dolly", {
	initialize = function(player, params)
		return {
			speed = get_speed(params,{"b", "back", "backwards", "out"}, "forward"),
			direction = vector.normalize(vector.new(player:get_look_dir().x, 0, player:get_look_dir().z)),
			origin = player:get_pos(),
			time = 0,
		}
	end,
	tick = function(player, state, dtime)
		state.time = state.time + dtime

		local player_pos = vector.add(state.origin, vector.multiply(state.direction, state.time * state.speed))
		player:set_pos(player_pos)
	end
})

cinematic.register_motion("truck", {
	initialize = function(player, params)
		return {
			speed = get_speed(params,{"l", "left"}, "right"),
			direction = vector.normalize(vector.cross(vector.new(0,1,0), player:get_look_dir())),
			origin = player:get_pos(),
			time = 0,
		}
	end,
	tick = function(player, state, dtime)
		state.time = state.time + dtime

		local player_pos = vector.add(state.origin, vector.multiply(state.direction, state.time * state.speed))
		player:set_pos(player_pos)
	end
})

cinematic.register_motion("pedestal", {
	initialize = function(player, params)
		return {
			speed = get_speed(params,{"d", "down"}, "up"),
			direction = vector.new(0,1,0),
			origin = player:get_pos(),
			time = 0,
		}
	end,
	tick = function(player, state, dtime)
		state.time = state.time + dtime

		local player_pos = vector.add(state.origin, vector.multiply(state.direction, state.time * state.speed))
		player:set_pos(player_pos)
	end
})

cinematic.register_motion("pan", {
	initialize = function(player, params)
		return {
			speed = -get_speed(params,{"l", "left"}, "right"),
			angle = player:get_look_horizontal(),
			time = 0,
		}
	end,
	tick = function(player, state, dtime)
		state.time = state.time + dtime
		local delta_angle = state.speed * state.time * math.pi * 1 / 180
		if math.abs(delta_angle) > 1.0 then
			state.angle = state.angle + delta_angle
			delta_angle = 0.0
			state.time = 0.0
			if state.angle < 0 then state.angle = state.angle + 2 * math.pi end
			if state.angle > 2 * math.pi then state.angle = state.angle - 2 * math.pi end
		end

		player:set_look_horizontal(state.angle + delta_angle)
	end
})

cinematic.register_motion("tilt", {
	initialize = function(player, params)
		return {
			speed = -get_speed(params,{"d", "down"}, "up"),
			angle = player:get_look_vertical(),
			time = 0,
		}
	end,
	tick = function(player, state, dtime)
		state.time = state.time + dtime
		local delta_angle = state.speed * state.time * math.pi * 1 / 180
		if math.abs(delta_angle) > 1.0 then
			state.angle = state.angle + delta_angle
			delta_angle = 0.0
			state.time = 0.0
			if state.angle < 0 then state.angle = state.angle + 2 * math.pi end
			if state.angle > 2 * math.pi then state.angle = state.angle - 2 * math.pi end
		end

		player:set_look_vertical(state.angle + delta_angle)
	end
})

cinematic.register_motion("zoom", {
	initialize = function(player, params)
		return {
			speed = get_speed(params,{"out"}, "in"),
		}
	end,
	tick = function(player, state)
		-- Capture initial FOV at the tick
		-- This is not possible in initialize because the FOV modifier has not been applied yet
		if state.fov == nil then
			local fov = {player:get_fov()}
			minetest.chat_send_all(dump(fov,""))
			if fov[1] == 0 then
				fov[1] = 1
				fov[2] = true
			end
			fov[3] = 0
			state.fov = fov
		end
		state.fov[1] = state.fov[1] - 0.001 * state.speed
		player:set_fov(unpack(state.fov))
	end
})

cinematic.register_motion("stop", {
	initialize = function(player, params)
		minetest.chat_send_player(player:get_player_name(), S('@1 motion done', params.type))
		if params and type(params.onStop) == "function" then
			params.onStop(player, params)
		end
	end}
)
cinematic.register_motion("revert", {
	initialize = function(player, params)
		minetest.chat_send_player(player:get_player_name(), S('@1 motion done', params.type))
		position.restore(player, "auto")
		if params and type(params.onStop) == "function" then
			params.onStop(player, params)
		end
	end}
)

cinematic.register_motion("to", {
	initialize = function(player, params)
		local posEnd = params.pos
		local posStart = position.current(player)
		local speed = get_speed(params,{"l", "left"}, "right")
		local timeEnd
		local direction
		local angleSpeed
		if posEnd then
			local l = vector.distance(posStart.pos, posEnd.pos)
			timeEnd = l / speed
			if params.time then
				if params.speed == nil then
					local vSpeed = l / params.time
					speed = vSpeed * speed
				else
					params.time = math.min(params.time, timeEnd)
				end
			else
				params.time = timeEnd
			end
			direction = vector.direction(posStart.pos, posEnd.pos)
			angleSpeed = {
				h = (posEnd.look.h - posStart.look.h) / params.time,
				v = (posEnd.look.v - posStart.look.v) / params.time,
			}
		else
			direction = vector.normalize(vector.cross(vector.new(0,1,0), player:get_look_dir()))
		end
		return {
			speed = speed,
			direction = direction,
			origin = posStart,
			angleSpeed = angleSpeed,
			time = 0,
		}
	end,
	tick = function(player, state, dtime)
		state.time = state.time + dtime

		local player_pos = vector.add(state.origin.pos, vector.multiply(state.direction, state.time * state.speed))
		player:set_pos(player_pos)
		if state.angleSpeed then
			local delta_angle = state.angleSpeed.h * state.time
			player:set_look_horizontal(state.origin.look.h + delta_angle)
			delta_angle = state.angleSpeed.v * state.time
			player:set_look_vertical(state.origin.look.v + delta_angle)
		end
	end
})

cinematic.register_motion("wait", {
	initialize = function()
		return {}
	end,
	tick = function()
	end
})

