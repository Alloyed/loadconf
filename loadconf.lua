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
	newproxy=newproxy
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

-- format complex strings.
local function complex_fmt(str, data, shape)
	shape = shape or {}
	-- FIXME: ignore escaped {}
	return str:gsub("%b{}", function(k)
		k = k:sub(2, -2)
		local s = data[k]
		assert(s ~= nil)
		if not shape[k] then
			-- no shape given, just use tostring
			s = tostring(s)
		elseif type(shape[k]) == 'string' then
			-- assume shape is a format string
			s = string.format(shape[k], s)
		else
			-- assume shape is callable and returns a valid string
			s = shape[k](s)
		end
		return s
	end)
end

local function slurp(fname)
	local f, s, err
	f, err = io.open(fname, 'r')
	if not f then return nil, err end

	s, err = f:read('*a')
	if not s then return nil, err end
	f:close()

	return s
end

local function line_of(body, n)
	local err
	if body:sub(1, 1) == '@' then
		body, err = slurp(body:sub(2))
		if not body then
			return nil, err
		end
	end

	if body:sub(-1) ~= '\n' then body = body..'\n' end

	local line_i = 1
	for line in string.gmatch(body, "(.-)\n") do
		if n == line_i then
			return line
		end
		line_i = line_i + 1
	end
	return nil, "line out of range"
end

local friendly_msg = [[
{conf} could not be safely loaded.
If {conf} works inside LOVE but not here, then maybe {conf}
has more complex behavior than {program} can recognize.
In that case you should wrap that behavior in a guard, like so:

    if love.filesystem then
        {broken_line}
    end

Actual error:
{orig}
]]

-- Tells the user that they should guard against complex behavior
local function friendly_error(opts)
	if opts.friendly ~= true then
		return function(...) return ... end
	end

	return function(err)
		local info = debug.getinfo(2, 'lS')
		if info.short_src:match("loadconf.lua") then
		    -- this is actually an internal error
		    return err
		end

		local line = line_of(info.source, info.currentline)
		if not line then
		    -- could not retrieve source data, return internal err
		    -- instead
		    return err
		end
		line = line:gsub("^%s+", "")
		return complex_fmt(friendly_msg, {
			conf = info.short_src,
			program = opts.program or "loadconf",
			broken_line = line,
			orig = err
		})
	end
end

--- Given the string contents of a conf.lua, returns a table containing the
--  configuration it represents.
--  @param str The contents of conf.lua
--  @param name The name of conf.lua used in error messages. Uses same format as `load`.
--  @param[type=options] opts
--  @return `love_config`
--  @error
function loadconf.parse_string(str, name, opts)
	opts = opts or {}
	name = name or "conf.lua"

	local ok, err
	local env = setmetatable({love = {}}, {__index = sandbox})
	ok, err = pcall(xload, str, name, env)
	if not ok then return nil, err end
	local chunk = err

	ok, err = xpcall(chunk, friendly_error(opts))
	if not ok then return nil, err end

	if not env.love.conf then
		return {} -- No configuration
	end

	local t = { window = {}, screen = {}, modules = {} }
	ok, err = xpcall(function()
		env.love.conf(t)
	end, friendly_error(opts))

	if ok then
		if not t.version then
			t.version = loadconf.latest_stable_version
		end

		if opts.include_defaults == true and loadconf.defaults[t.version] then
			merge(loadconf.defaults[t.version], t)
		end
		return t
	else
		return nil, err
	end
end

--- Given the filename of a valid conf.lua file, returns a table containing the
--  configuration it represents.
--  @param fname The path to the conf.lua file
--  @param[type=options] opts
--  @return `love_config`
--  @error
function loadconf.parse_file(fname, opts)
	opts = opts or {}
	local str, err = slurp(fname)
	if not str then return nil, err end

	return loadconf.parse_string(str, "@"..fname)
end

--- The configuration tables produced by running `love.conf`.
-- @table love_config
-- @see love/Config_Files


--- The optional table all loadconf functions take. customize according to your
--  use case.
--  @table options
--  @field[opt="loadconf"] program What is the program called? Used for friendly errors
--  @field[opt=false] friendly Enable user-friendly errors
--  @field[opt=false] include_defaults Enable default values in returned configs
local opts_defaults = {
	program          = "loadconf",
	friendly         = false,
	include_defaults = false
}

--- The current stable love version. please submit an issue/pull request if
--  this is out of date, sorry~
loadconf.stable_love = "0.10.1"

--- A table containing the default config tables for each version of love.
--  @usage assert(loadconf.defaults["0.9.2"].window.fullscreentype == "normal")
loadconf.defaults = {}

local function default_copy(old_v, version)
	local old = loadconf.defaults[old_v]
	local t = {}
	for k, v in pairs(old) do
		t[k] = v
	end
	t.version = version
	loadconf.defaults[version] = t
end

-- default values for 0.10.X {{{
loadconf.defaults["0.10.1"] = {
	identity = nil,
	version = "0.10.1",
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
		fullscreentype = "desktop",
		vsync          = true,
		msaa           = 0,
		display        = 1,
		highdpi        = false,
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
		touch         = true,
		video         = true,
		window        = true,
		thread        = true,
	}
}

default_copy("0.10.1", "0.10.0")
-- }}}

-- default values for 0.9.X {{{
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

default_copy("0.9.2", "0.9.1")
default_copy("0.9.2", "0.9.0")
-- }}}

-- default values for 0.8.X {{{
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

local Loadconf = {}

--- An object-oriented instance of the loadconf module. This carries
--  configuration state internally so you can set-and-forget the `options`
--  table.
--
--  @type Loadconf

--- @see loadconf.parse_string
function Loadconf:parse_string(str, name)
	return loadconf.parse_file(str, name, self)
end

--- @see loadconf.parse_file
function Loadconf:parse_file(fname)
	return loadconf.parse_file(fname, self)
end

local Loadconf_mt = {__index = Loadconf}
--- 
--  @param[type=options] opts
--  @return a Loadconf instance
function loadconf.new(opts)
	local t = {}
	for k, v in pairs(opts) do t[k] = v end
	return setmetatable(t, Loadconf_mt)
end

return loadconf
