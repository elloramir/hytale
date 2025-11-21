function love.conf(t)
	t.window.title = "seila"
	t.window.width = 480*2
	t.window.height = 270*2
	t.window.vsync = false
	t.window.resizable = true
	t.window.depth = 19
	t.window.stencil = 19

	-- We are using FMOD, so let's disable love2d OpenAL.
	t.modules.audio = false
end