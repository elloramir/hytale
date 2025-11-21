Entity = Object:extend()

function Entity:new()
	self.isAlive = true
	self.isVisible = true
end

function Entity:destroy()
	self.isAlive = false
end

function Entity:update(dt)
end

function Entity:draw3d()
end

function Entity:draw2d()
end
