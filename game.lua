Game = { }

function Game.init()
	Game.entities = {}
	Game.motion = 1
	Game.delay = 0

	-- Call resize atleast once
	Game.resizeScreen(love.graphics.getDimensions())
end

function Game.addEntity(entity)
	table.insert(Game.entities, entity)
	return entity
end

function Game.update(dt)
	dt = dt*Game.motion

	if Game.delay > 0 then
		Game.delay = math.max(0, Game.delay-dt)
		return
	end

	local entities = Game.entities

	for i = #entities, 1, -1 do
		local entity = entities[i]

		if not entity.isAlive then
			print("remove", entity.isAlive)
			table.remove(Game.entities, i)
		else
			entity:update(dt)
		end
	end
end

function Game.resizeScreen(width, height)
	Game.stencil = love.graphics.newCanvas(width, height, { format="depth16", readable=true })
	Game.screen = love.graphics.newCanvas(width, height)

	-- Bind that attachs stencil to screen canvas
	Game.screenBind = {
		{ Game.screen, layer = 1 },
		depthstencil = Game.stencil,
	}
end

function Game.draw()
	love.graphics.setCanvas(Game.screenBind)
	love.graphics.clear(0.3, 0.6, 0.9)

	for _, entity in ipairs(Game.entities) do
		entity:draw3d()
	end

	-- Render screen canvas to window
	love.graphics.setCanvas(nil)
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(Game.screen)
end

