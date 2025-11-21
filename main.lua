Object = require("libs.classic")
Baton = require("libs.baton")
Lume = require("libs.lume")
Tick = require("libs.tick")
Flux = require("libs.flux")

require("input")
require("vector")
require("matrix")
require("camera")
require("sheet")
require("model")
require("entity")
require("game")
require("ens.chunk")
require("ens.player")
require("ens.terrain")
require("assets")


function love.load()
	math.randomseed(os.time())

	love.graphics.setMeshCullMode("back")
	love.graphics.setLineStyle("rough")
	love.graphics.setDepthMode("lequal", true)
	love.mouse.setRelativeMode(true)

	Assets.load()

	Game.init()
	Game.resizeScreen(love.graphics:getDimensions())
	Game.addEntity(Player(10, 10, 10))
	Game.addEntity(Terrain())
end

function love.resize(width, height)
	Game.resizeScreen(width, height)
end

function love.update(dt)
	Input:update()
	Camera.update()
	Game.update(dt)
end

function love.draw()
	Game.draw()
end

function love.mousemoved(_, _, dx,dy)
	Camera.mouseMoved(dx, dy)
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end
