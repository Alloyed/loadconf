function love.conf(t)
	t.identity          = nil
	t.version           = "0.8.0"
	t.console           = false
	t.release           = false

	t.title             = "Untitled"
	t.author            = "Unnamed"
	t.screen.width      = 800
	t.screen.height     = 600
	t.screen.fullscreen = false
	t.screen.vsync      = true
	t.screen.fsaa       = 0

	t.modules.audio     = true
	t.modules.event     = true
	t.modules.graphics  = true
	t.modules.image     = true
	t.modules.joystick  = true
	t.modules.keyboard  = true
	t.modules.mouse     = true
	t.modules.physics   = true
	t.modules.sound     = true
	t.modules.timer     = true
	t.modules.thread    = true
end
