Player = Entity:extend()

function Player:new(x, y, z)
	Entity.new(self)
	self.position = Vector(x, y, z)
	self.velocity = Vector(0, 0, 0)
	self.acceleration = Vector(0, 0, 0)
	self.maxSpeed = 10
	self.accelRate = 30
	self.friction = 5
end

function Player:update(dt)
	self:handleInput(dt)
	self:applyPhysics(dt)
	self:updatePosition(dt)
	self:updateCamera()
end

function Player:handleInput(dt)
	local moveDir = self:getMovementDirection()
	
	if Input:pressed("jump") and self.isGrounded then
		self.velocity.y = self.jumpForce
	end
	
	if moveDir:length() > 0 then
		self.acceleration = moveDir:normalized() * self.accelRate
	else
		self.acceleration = Vector(0, 0, 0)
	end
end

function Player:getMovementDirection()
	local forward = self:getCameraForward()
	local right = forward:cross(Camera.up):normalized()
	local moveDir = Vector(0, 0, 0)
	
	if Input:down("up")    then moveDir = moveDir + forward end
	if Input:down("down")  then moveDir = moveDir - forward end
	if Input:down("right") then moveDir = moveDir + right   end
	if Input:down("left")  then moveDir = moveDir - right   end
	if Input:down("jump")   then moveDir = moveDir + Vector(0, 1, 0) end
	if Input:down("crouch") then moveDir = moveDir - Vector(0, 1, 0) end
	
	return moveDir
end

function Player:getCameraForward()
	local forward = Camera.viewMatrix:forward()
	forward.y = 0
	return forward:normalized()
end

function Player:applyPhysics(dt)
	self.velocity = self.velocity + self.acceleration * dt
	self:clampVelocity()
	self:applyFriction(dt)
end

function Player:clampVelocity()
	local hv = Vector(self.velocity.x, 0, self.velocity.z)
	if hv:length() > self.maxSpeed then
		hv = hv:normalized() * self.maxSpeed
		self.velocity.x = hv.x
		self.velocity.z = hv.z
	end
	
	if math.abs(self.velocity.y) > self.maxSpeed then
		self.velocity.y = Lume.sign(self.velocity.y) * self.maxSpeed
	end
end

function Player:applyFriction(dt)
	if self.acceleration.x == 0 and self.acceleration.z == 0 then
		local hv = Vector(self.velocity.x, 0, self.velocity.z)
		local friction = hv * -1 * self.friction * dt
		
		if friction:length() > hv:length() then
			self.velocity.x = 0
			self.velocity.z = 0
		else
			self.velocity.x = self.velocity.x + friction.x
			self.velocity.z = self.velocity.z + friction.z
		end
	end
	
	if self.acceleration.y == 0 then
		local friction = -self.velocity.y * self.friction * dt
		
		if math.abs(friction) > math.abs(self.velocity.y) then
			self.velocity.y = 0
		else
			self.velocity.y = self.velocity.y + friction
		end
	end
end

function Player:updatePosition(dt)
	self.position.x = self.position.x + self.velocity.x * dt
	self.position.y = self.position.y + self.velocity.y * dt
	self.position.z = self.position.z + self.velocity.z * dt
end

function Player:updateCamera()
	Camera.position = self.position
end