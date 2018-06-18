local M = {}


PALETTE = {
	[0] = { r =   0, g =   0, b =   0 },	-- black
	[1] = { r =  29, g =  43, b =  83 },	-- dark-blue
	[2] = { r = 126, g =  37, b =  83 },	-- dark-purple
	[3] = { r =   0, g = 135, b =  81 },	-- dark-green
	[4] = { r = 171, g =  82, b =  54 },	-- brown
	[5] = { r =  95, g =  87, b =  79 },	-- dark-grey
	[6] = { r = 194, g = 195, b = 199 },	-- light-grey
	[7] = { r = 255, g = 241, b = 232 },	-- white
	[8] = { r = 255, g =   0, b =  77 },	-- red
	[9] = { r = 255, g = 163, b =   0 },	-- orange
	[10] = { r = 255, g = 236, b =  39 },	-- yellow
	[11] = { r =   0, g = 228, b =  54 },	-- green
	[12] = { r =  41, g = 173, b = 255 },	-- blue
	[13] = { r = 131, g = 118, b = 156 },	-- indigo
	[14] = { r = 255, g = 119, b = 168 },	-- pink
	[15] = { r = 255, g = 204, b = 170 },	-- peach
}

local state = {
	host_time = 0,
	buffer_info = nil,
	stat = {},
	buttons = {},
	draw = {
		color = 0,
		camera = {
			x = 0,
			y = 0,
		},
		cursor = {
			x = 0,
			y = 0,
		},
		clipping = {
		},
		palette = {
		},
		fill_pattern = nil,
	}
}

for player=0,7 do
	state.buttons[player] = {}
	for button=0,5 do
		state.buttons[player][button] = {}
	end
end

local function get_color(i)
	return PALETTE[math.min(math.max(math.floor(i or state.draw.color), 0), 15)]
end


function M.init(buffer_info)
	state.buffer_info = buffer_info
end


function M.run(cart)
	if type(cart) == "string" then
		-- +=, -=, *= and /=
		cart = string.gsub(cart, "([%a_][%a%d_]-)(%b[])([%+%-%*%/])=", "%1%2=%1%2%3")
		cart = string.gsub(cart, "([%a_][%a%d_]-)([%+%-%*%/])=", "%1=%1%2")
		
		-- single line if-else
		cart = string.gsub(cart, "if%s-(%b())(.-)\n", "if %1 then %2 end\n")

		-- =.32 -> =0.32
		cart = string.gsub(cart, "([,=%+%-&*%/])%.(%d-)", "%10.%2")
				
		-- fix compact assignments c=64q=96w=127l=line
		cart = string.gsub(cart, "([%a_][%a%d_]-)=(%d+%.?%d*)", "%1=%2 ")

		-- t=t+0.01cls(1) -> t=t+0.01 cls(1)
		cart = string.gsub(cart, "(%d+%.?%d+)(%a)", "%1 %2")

		-- !=
		cart = string.gsub(cart, "%!%=", "~=")

		-- load cart
		cart = assert(loadstring(cart))
	end
		
	local env = {}
	env.cos = function(angle) return math.cos((angle or 0)*(math.pi*2)) end
	env.sin = function(angle) return math.sin(-(angle or 0)*(math.pi*2)) end
	env.atan2 = function(x, y) return (0.75 + math.atan2(x,y) / (math.pi * 2)) % 1.0 end
	env.sqrt = math.sqrt
	env.srand = function(seed)
		seed = seed or 1
		if seed == 0 then seed = 1 end
		math.randomseed(math.floor(seed*32768))
	end
	env.rnd = function(max)
		if not max then return math.random() else return math.random(0, max - 1) end
	end
	env.max = math.max
	env.min = math.min
	env.flr = math.floor
	env.abs = math.abs
	env.color = function(color)
		state.draw.color = get_color(color)
	end
	env.camera = function(x, y)
		state.draw.camera.x = x
		state.draw.camera.y = y
	end
	env.cls = function(color)
		state.draw.cursor.x = 0
		state.draw.cursor.y = 0
		local col = get_color(color)
		drawpixels.fill(state.buffer_info, col.r, col.g, col.b)
	end
	env.circ = function(x, y, r, color)
		local col = get_color(color)
		x = x - state.draw.camera.x
		y = (128 - y) - state.draw.camera.y
		drawpixels.circle(state.buffer_info, x, y, r * 2, col.r, col.g, col.b)
	end
	env.circfill = function(x, y, r, color)
		local col = get_color(bit.band(color, 0x0F))
		x = x - state.draw.camera.x
		y = (128 - y) - state.draw.camera.y
		drawpixels.filled_circle(state.buffer_info, x, y, r * 2, col.r, col.g, col.b)
	end
	env.rect = function(x_upperleft, y_upperleft, x_lowerright, y_lowerright, color)
		local col = get_color(color)
		local xmin, xmax = math.min(x_upperleft, x_lowerright), math.max(x_upperleft, x_lowerright)
		local ymin, ymax = math.min(y_upperleft, y_lowerright), math.max(y_upperleft, y_lowerright)
		local w = xmax - xmin
		local h = ymax - ymin
		local x = xmin + (w / 2) - state.draw.camera.x
		local y = (128 - ymax) + (h / 2) - state.draw.camera.y
		drawpixels.rect(state.buffer_info, x, y, w, h, col.r, col.g, col.b)
	end
	env.rectfill = function(x_upperleft, y_upperleft, x_lowerright, y_lowerright, color)
		local col = get_color(bit.band(color, 0x0F))
		local xmin, xmax = math.min(x_upperleft, x_lowerright), math.max(x_upperleft, x_lowerright)
		local ymin, ymax = math.min(y_upperleft, y_lowerright), math.max(y_upperleft, y_lowerright)
		local w = xmax - xmin
		local h = ymax - ymin
		local x = xmin + (w / 2) - state.draw.camera.x
		local y = (128 - ymax) + (h / 2) - state.draw.camera.y
		drawpixels.filled_rect(state.buffer_info, x, y, w, h, col.r, col.g, col.b, nil, nil)
	end
	env.pset = function(x, y, color)
		x = x - state.draw.camera.x
		y = (128 - y) - state.draw.camera.y
		local col = get_color(color)
		drawpixels.pixel(state.buffer_info, x, y, col.r, col.g, col.b)
	end
	env.pget = function(x, y, color)
		x = x - state.draw.camera.x
		y = (128 - y) - state.draw.camera.y
		local r, g, b = drawpixels.color(state.buffer_info, x, y)
		for i=0,#PALETTE do
			if PALETTE[i].r == r and PALETTE[i].g == g and PALETTE[i].b == b then
				return i
			end
		end
		return 0
	end
	env.line = function(x0, y0, x1, y1, color)
		local col = get_color(color)
		x0 = x0 - state.draw.camera.x
		y0 = (128 - y0) - state.draw.camera.y
		x1 = x1 - state.draw.camera.x
		y1 = (128 - y1) - state.draw.camera.x
		drawpixels.line(state.buffer_info, x0, y0, x1, y1, col.r, col.g, col.b)
	end
	env.t = function() return state.host_time end
	env.time = env.t
	env.poke = function() print("Unsupported function poke") end
	env.fillp = function(pat)
		state.draw.fill = pat
	end
	env.cursor = function(x, y)
		state.draw.cursor.x = x
		state.draw.cursor.y = y
	end
	env.flip = function()
		coroutine.yield()
	end
	env.add = table.insert
	env.stat = function(i) return state.stat[i] end
	env.btn = function(button, player) return state.buttons[player][button].pressed end

	setmetatable(env, { __index = _G })
	setfenv(cart, env)
	
	state.host_time = 0
	state.co = coroutine.create(cart)
end


function M.update(dt)
	state.host_time = state.host_time + dt
	if state.host_time > 65536 then state.host_time = state.host_time - 65536 end

	if state.co and coroutine.status(state.co) == "suspended" then
		local ok, err = coroutine.resume(state.co)
		if not ok then
			print(err)
			state.co = nil
		end
	end
end

-- http://pico-8.wikia.com/wiki/Btn
function M.on_input(action_id, action)
	if not action_id or action_id == hash("touch") then
		state.stat[32] = action.x / 4
		state.stat[33] = 128 - (action.y / 4)
	-- player 0
	elseif action_id == hash("key_left") then
		state.buttons[0][0] = action
	elseif action_id == hash("key_right") then
		state.buttons[0][1] = action
	elseif action_id == hash("key_up") then
		state.buttons[0][2] = action
	elseif action_id == hash("key_down") then
		state.buttons[0][3] = action
	elseif action_id == hash("key_z") or action_id == hash("key_c") or action_id == hash("key_n") then
		state.buttons[0][4] = action
	elseif action_id == hash("key_x") or action_id == hash("key_v") or action_id == hash("key_m") then
		state.buttons[0][5] = action
	-- player 1
	elseif action_id == hash("key_s") then
		state.buttons[1][0] = action
	elseif action_id == hash("key_f") then
		state.buttons[1][1] = action
	elseif action_id == hash("key_e") then
		state.buttons[1][2] = action
	elseif action_id == hash("key_d") then
		state.buttons[1][3] = action
	elseif action_id == hash("key_lshift") or action_id == hash("key_tab") then
		state.buttons[1][4] = action
	elseif action_id == hash("key_a") or action_id == hash("key_q") then
		state.buttons[1][5] = action
	end
end


return M