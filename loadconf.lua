--- A module for loading LOVE conf.lua files.
--
-- @module loadconf

local loadconf = {}

local function xload(str, name, env)
	local chunk, err
	if setfenv then -- lua 5.1
		chunk, err = loadstring(str, name)
		if not chunk then return nil, err end
		setfenv(chunk, env)
	else -- lua 5.2, 5.3
		chunk, err = load(str, name, "bt", env)
		if not chunk then return nil, err end
	end
	return chunk
end

local sandbox = {
	assert=assert,
	error=error,
	getmetatable=getmetatable,
	ipairs=ipairs,
	next=next,
	pairs=pairs,
	pcall=pcall,
	print=print,
	rawequal=rawequal,
	rawget=rawget,
	rawset=rawset,
	select=select,
	setmetatable=setmetatable,
	tonumber=tonumber,
	tostring=tostring,
	type=type,
	unpack=unpack,
	_VERSION=_VERSION,
	xpcall=xpcall,
	coroutine=coroutine,
	string=string,
	table=table,
	math=math,
	os = {
		clock=os.clock,
		date=os.date,
		difftime=os.difftime,
		getenv=os.getenv,
		time=os.time,
		tmpname=os.tmpname
	},
	newproxy=os.newproxy
}

sandbox._G = sandbox

local function merge(from, into)
	for k, v in pairs(from) do
		if type(v) == 'table' then
			merge(v, into[k])
		elseif not into[k] then
			into[k] = v
		end
	end
end

--- Given the string contents of a conf.lua, returns a table containing the
--  configuration it represents.
--  @param str The contents of conf.lua
--  @return The configuration table, or `nil, err` if an error occured
function loadconf.parse_string(str)
	local ok, err
	local env = setmetatable({love = {}}, {__index = sandbox})
	ok, err = pcall(xload, str, "conf.lua", env)
	if not ok then
		return nil, err
	end
	local chunk = err

	ok, err = pcall(chunk)
	if not ok then
		return nil, err
	end

	if not env.love.conf then
		return {} -- No configuration
	end

	local t = { window = {}, screen = {}, modules = {} }
	ok, err = pcall(env.love.conf, t)
	if ok then
		if not t.version then
			t.version = loadconf.latest_stable_version
		end
		if loadconf.defaults[t.version] then
			--merge(loadconf.defaults[t.version], t)
		end
		return t
	else
		return nil, err
	end
end

--- Given the filename of a valid conf.lua file, returns a table containing the
--  configuration it represents.
--  @param fname The path to the conf.lua file
--  @return the configuration table, or `nil, err` if an error occured.
function loadconf.parse_file(fname)
	local f, str, err

	f, err = io.open(fname, 'r')
	if not f then return nil, err end

	str, err = f:read('*a')
	if not str then return nil, err end

	f:close()

	return loadconf.parse_string(str)
end

function loadconf.write(orig, changes)
	error("TODO")
end

loadconf.defaults = {}

-- default values for 0.9.2 {{{
loadconf.defaults["0.9.2"] = {
	identity = nil,
	version = "0.9.2",
	console = false,
	window = {
		title          = "Untitled",
		icon           = nil,
		width          = 800,
		height         = 600,
		borderless     = false,
		resizable      = false,
		minwidth       = 1,
		minheight      = 1,
		fullscreen     = false,
		fullscreentype = "normal",
		vsync          = true,
		fsaa           = 0,
		display        = 1,
		highdpi        = false,
		srgb           = false,
		x              = nil,
		y              = nil
	},
	modules = {
		audio         = true,
		event         = true,
		graphics      = true,
		image         = true,
		joystick      = true,
		keyboard      = true,
		math          = true,
		mouse         = true,
		physics       = true,
		sound         = true,
		system        = true,
		timer         = true,
		window        = true,
		thread        = true,
	}
}
-- }}}

-- default values for 0.8.0 {{{
loadconf.defaults["0.8.0"] = {
	identity = nil,
	version = "0.8.0",
	console = false,
	release = false,
	title = "Untitled",
	author = "Unnamed",
	screen = {
		width = 800,
		height = 600,
		fullscreen = false,
		vsync = true,
		fsaa = 0
	},
	modules = {
		audio     = true,
		event     = true,
		graphics  = true,
		image     = true,
		joystick  = true,
		keyboard  = true,
		mouse     = true,
		physics   = true,
		sound     = true,
		timer     = true,
		thread    = true
	}
}
-- }}}

return loadconf
