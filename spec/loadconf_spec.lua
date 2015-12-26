local loadconf = require 'loadconf'

describe("loadconf", function()
	it("can load and run conf.lua strings", function()
		local t, err = loadconf.parse_string([[
		function love.conf(t)
			t.identity = "foobar"
			return t
		end
		]])
		assert(t, err)
		assert.equal("foobar", t.identity)
	end)

	it("can load both 0.8 and 0.9 confs", function()
		local t1 = loadconf.parse_string([[
		function love.conf(t)
			t.version = "0.8.0"
			t.screen.fullscreen = true
			return t
		end
		]])

		local t2 = loadconf.parse_string([[
		function love.conf(t)
			t.version = "0.9.0"
			t.window.fullscreen = false
			return t
		end
		]])
		assert.equal(true, t1.screen.fullscreen)
		assert.equal(false, t2.window.fullscreen)
	end)

	it("can catch invalid conf.lua strings", function()
		local t, err
		t, err = loadconf.parse_string([[
		require "rocks/init"()
		function love.conf(t)
			t.version = "0.8.0"
			t.screen.fullscreen = true
			return t
		end
		]])
		assert.equal(nil, t)
		assert.equal('string', type(err))

		t, err = loadconf.parse_string([[
		local
		function love.conf(t)
			t.version = "0.8.0"
			t.screen.fullscreen = true
			return t
		end
		]])
		assert.equal(nil, t)
		assert.equal('string', type(err))
	end)

	it("can load and run conf.lua files", function()
		local fname = "/tmp/conf.lua"
		local f = io.open(fname, 'w')
		f:write([[
		function love.conf(t)
			t.identity = "foobar"
			return t
		end
		]])
		f:close()

		local t = loadconf.parse_file(fname)
		assert.equal("foobar", t.identity)

		local t2, err = loadconf.parse_file("/tmp/nonexistent/path/conf.lua")
		assert.equal(nil, t2)
		assert.equal('string', type(err))

		local t3, err2 = loadconf.parse_file("/tmp/nonexistent_path_conf.lua")
		assert.equal(nil, t3)
		assert.equal('string', type(err2))
	end)

	it("can create conf.lua strings from a config table", function()
		pending("TODO")
	end)

	local test_files = {
		"spec/test_confs/default.lua",
		"spec/test_confs/empty.lua",
		"spec/test_confs/iyfct.lua",
		"spec/test_confs/mari0.lua",
		"spec/test_confs/set_all_love08.lua",
		"spec/test_confs/set_all_love09.lua",
	}

	for _, fname in ipairs(test_files) do
		it(("can load and run %s"):format(fname), function()
			local t, err = loadconf.parse_file(fname)
			assert.equal(nil, err)
			assert.equal('table', type(t))
		end)
	end

--	local test_archives = {
--		"spec/test_confs/love09.love",
--		"spec/test_confs/love08.love",
--	}
--
--	for _, fname in ipairs(test_archives) do
--		it(("can load and run %s"):format(fname), function()
--			local t, err = loadconf.parse_archive(fname)
--			assert.equal(nil, err)
--			assert.equal('table', type(t))
--		end)
--	end
end)

