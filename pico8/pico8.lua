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
}

function M.init(buffer_info)
	state.buffer_info = buffer_info
end


function M.run(cart)
	if type(cart) == "string" then
		cart = string.gsub(cart, "([%a_][%a%d_]-)(%b[])([%+%-])=", "%1%2=%1%2%3")
		cart = string.gsub(cart, "([%a_][%a%d_]-)([%+%-])=", "%1=%1%2")
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
	env.rnd = math.random
	env.max = math.max
	env.cls = function(color)
		color = color or 0
		local col = PALETTE[math.floor(color)]
		drawpixels.fill(state.buffer_info, col.r, col.g, col.b)
	end
	env.circ = function(x, y, r, color)
		color = color or 0
		local col = PALETTE[math.floor(color)]
		drawpixels.circle(state.buffer_info, x, y, r * 2, col.r, col.g, col.b)
	end
	env.circfill = function(x, y, r, color)
		color = color or 0
		local col = PALETTE[math.floor(color)]
		drawpixels.filled_circle(state.buffer_info, x, y, r * 2, col.r, col.g, col.b)
	end
	env.pset = function(x, y, color)
		color = color or 0
		local col = PALETTE[math.floor(color)]
		drawpixels.rect(state.buffer_info, x, y, 1, 1, col.r, col.g, col.b)
	end
	env.line = function(x0, y0, x1, y1, color)
		color = color or 0
		local col = PALETTE[math.floor(color)]
		drawpixels.line(state.buffer_info, x0, y0, x1, y1, col.r, col.g, col.b)
	end
	env.t = function() return state.host_time end
	env.time = t
	env.poke = function() print("Unsupported function poke") end
	env.fillp = function() end
	env.flip = function()
		coroutine.yield()
	end
	env.add = table.insert

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


return M