-- Copyright (c) 2021 Dmitry Kostenko. Licensed under AGPL v3
-- LUALOCALS < ---------------------------------------------------------
local minetest, pairs, ipairs, tonumber
    = minetest, pairs, ipairs, tonumber
-- LUALOCALS > ---------------------------------------------------------

local MOD_NAME = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(MOD_NAME) .. "/"
local S = minetest.get_translator(MOD_NAME)
local utils = dofile(MOD_PATH .. "utils.lua")
local starts_with = utils.starts_with
local skip_prefix = utils.skip_prefix
local string_split= utils.string_split
local get_speed = utils.get_speed
-- local cache_fov = minetest.settings:get("fov") --or 72

-- Motion helpers
local motion = utils.motion

-- Position helpers
local position = utils.position

-- Core API
-- local cinematic
cinematic = {
	DEFAULT_DELAY = 0.1, -- seconds
	motions = {},
	register_motion = function(name, definition)
		definition.name = name
		cinematic.motions[name] = definition
		local _tick = definition.tick
		if _tick then
			local _initialize = definition.initialize
			definition.initialize = function(player, params)
				local result = _initialize(player, params)
				if result then
					result.params = params
					result.timeStart = 0
					result.timeEnd = params.time
				end
				return result
			end
			definition.tick = function(player, state, dtime)
				local vTime = state.timeStart + dtime
				state.timeStart = vTime
				if state.timeEnd and vTime >= state.timeEnd then
					cinematic.stop(player, state.params)
				else
					_tick(player, state, dtime)
				end
			end
		end
		table.insert(cinematic.motions, definition)
	end,

	commands = {},
	register_command = function(name, definition)
		definition.name = name
		cinematic.commands[name] = definition
		table.insert(cinematic.commands, definition)
	end,

	players = {},
	start = function(player, motion, params)
		local player_name = player:get_player_name()
		-- Stop previous motion and clean up
		if cinematic.players[player_name] ~= nil then
			-- player:set_fov(unpack(cinematic.players[player_name].fov))
			cinematic.players[player_name] = nil
		end

		local state = cinematic.motions[motion].initialize(player, params)
		-- motion can return nil from initialize to abort the process
		if state ~= nil then
			if params.index == nil or params.index == 1 then
				position.save(player, "auto")
			end
			cinematic.players[player_name] = { player = player, motion = motion, state = state }

			if params.fov == "wide" then
				params.fov = 1.4
			elseif params.fov == "narrow" then
				params.fov = 0.5
			elseif params.fov ~= nil then
				params.fov = tonumber(params.fov)
			end
			if params.fov ~= nil then
				player:set_fov(params.fov, true)
			end
		end
	end,
	stop = function(player, params)
		cinematic.start(player, "stop", params or {})
	end,
}

-- Update loop

minetest.register_globalstep(function(dtime)
	for _, entry in pairs(cinematic.players) do
		cinematic.motions[entry.motion].tick(entry.player, entry.state, dtime)
	end
end)

-- include all motions
dofile(MOD_PATH .. "motions.lua")

cinematic.register_command("pos", {
	run = function(player, args)
		local slot = args[2]
		local ok = false
		local msg = nil

		if args[1] == "save" then
			slot = slot or "default"
			position.save(player, slot)
			ok = true
			msg = S("Current Position saved to @1", slot)
		elseif args[1] == "restore" then
			slot = slot or "default"
			ok, msg = position.restore(player, slot)
			if ok then msg = S("Position restored from @1", slot) end
		elseif args[1] == "clear" then
			position.clear(player, slot)
			ok = true
			if slot then
				msg = S("@1 position cleared.", slot)
			else
				msg = S("All positions cleared.")
			end
		elseif args[1] == "list" then
			ok = true
			msg = table.concat(position.list(player), "\n")
		else
			msg = S("Unknown subcommand @1", (args[1] or ""))
		end
		return ok, msg
	end
})

local function execCommand(player, cmdline)
	local params = {}
	local parts = string_split(cmdline, " ")

	local command = parts[1]
	table.remove(parts, 1)
	-- Handle commands
	if cinematic.commands[command] ~= nil then
		return cinematic.commands[command].run(player, parts)
	end

	if cinematic.motions[command] == nil then
		return false, S("Invalid command or motion, see /help cc")
	end

	-- Parse command line
	for i = 1,#parts do
		local parsed = false
		for _, setting in ipairs({"norun"}) do
			if parts[i] == setting then
				params.norun = true
				parsed = true
				break
			end
		end
		if not parsed then
			for _,setting in ipairs({
				"direction", "dir",
				"speed", "v",
				"radius", "r",
				"fov",
				"time", "t",
				"name", "n",
				"pos", "p",
			}) do
				if starts_with(parts[i], setting.."=") then
					params[setting] = skip_prefix(parts[i], setting.."=")
					parsed = true
					break
				end
			end
		end
		if not parsed then
			return false, S("Invalid parameter: @1", parts[i])
		end
	end

	-- Fix parameters
	params.direction = params.direction or params.dir
	params.speed = params.speed or params.v
	params.radius = params.radius or params.r
	params.time = params.time or params.t
	params.name = params.name or params.n
	params.pos = params.pos or params.p

	params.speed = (params.speed and tonumber(params.speed))
	params.radius = (params.radius and tonumber(params.radius))
	params.time = (params.time and tonumber(params.time))
	if params.pos then
		local pos = minetest.string_to_pos(params.pos)
		if pos == nil then
			params.pos = position.get(player, params.pos)
		else
			params.pos = position.current(player)
			params.pos.pos = pos
		end
	end

	params.get_speed = get_speed

	params.type = command
	if params.name then
		motion.save(player, params.name, params)
	end
	if params.norun ~= true then
		cinematic.start(player, command, params)
	end
	return true, S("Motion @1 Starting...", command)
end

cinematic.register_command("run", {
	run = function(player, args)
		local paramsList = {}
		for i, v in ipairs(args) do
			local mParams = nil
			local err = nil
			if starts_with(v, "wait") then
				--shortcut wait
				local _, delay = unpack(string_split(v, "="))
				if delay then delay = tonumber(delay) end
				if type(delay) ~= "number" then delay = 1 end
				mParams = {type="wait", time=delay}
			else
				mParams, err = motion.get(player, v)
			end

			if mParams then
				mParams.get_speed = get_speed
				mParams.index = i
				mParams.onStop = function(player, params)
					-- local delay = params.delay
					local nextId = params.index+1
					if nextId <= #paramsList then
						params = paramsList[nextId]
						minetest.after(cinematic.DEFAULT_DELAY, function()
							cinematic.start(player, params.type, params)
						end)
					end
				end
				table.insert(paramsList, mParams)
			elseif err then
				return false, S(err)
			end
	end
		if #paramsList then
			local params = paramsList[1]
			cinematic.start(player, params.type, params)
			return true
		else
			return false, S("No any named motions provided")
		end
	end
})

cinematic.register_command("motion", {
	run = function(player, args)
		local slot = args[2]
		local ok = false
		local msg

		if args[1] == "clear" then
			motion.clear(player, slot)
			ok = true
			if slot then
				msg = S("@1 motion cleared.", slot)
			else
				msg = S("All motions cleared.")
			end
		elseif args[1] == "list" then
			ok = true
			local motions = motion.list(player)
			table.insert(motions, 1, "---MOTION LIST---")
			msg = table.concat(motions, "\n")
		else
			msg = S("Unknown subcommand @1", (args[1] or ""))
		end
		return ok, msg
	end
})

-- Chat command handler

minetest.register_chatcommand("cc", {
	params = "((360|tilt|pan|truck|dolly|pedestal) [direction=(right|left|in|out|up|down)] [speed=<speed>] [radius=<radius>] [name=<named_motion>] | pos ((save|restore|clear [<name>])|list)) | (stop|revert) | motion ((|clear [<name>])|list)) | (run <motions>)",
	description = S("Simulate cinematic camera motion"),
	privs = { fly = true },
	func = function(name, cmdline)
		local player = minetest.get_player_by_name(name)
		return execCommand(player, cmdline)
	end
})

