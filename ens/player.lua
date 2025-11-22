Player = Entity:extend()

function Player:new(x, y, z)
	Entity.new(self)

	self.position = Vector(x, y, z)
	self.velocity = Vector(0, 0, 0)
	self.acceleration = Vector(0, 0, 0)
	
	-- Movement
	self.walkSpeed = 8.317
	self.sprintSpeed = 12.612
	self.maxSpeed = self.walkSpeed
	self.accelRate = 40
	self.friction = 8

	-- Sprint configs
	self.doubleTapTime = 0.25
	self.lastForwardTap = -1
	self.isSprinting = false

	-- FOV when in sprint
	self.defaultFov = math.rad(60)
	self.sprintFov  = math.rad(72)
	self.fovLerpSpeed = 8
		
	-- Jump
	self.jumpForce = 12
	self.gravity = 40
	self.isGrounded = false
	
	-- Collision
	self.radius = 0.3
	self.height = 1.8
	
	self:updateCamera(true)
end

function Player:updateCamera(firstTime)
	Camera.position = self.position + Vector(0, self.height, 0)
	if firstTime then
		Camera.fov = self.defaultFov
	end
end

function Player:update(dt)
	self:handleMovement(dt)
	self:applyPhysics(dt)
	self:moveAndCollide(dt)
	self:updateCamera()
	self:updateCameraFov(dt)
end

function Player:handleMovement(dt)
	local forward = Camera.viewMatrix:forward()
	forward.y = 0 -- Ignore up/down influency
	local right = forward:cross(Camera.up):normalized()
	
	local moveDir = Vector(0, 0, 0)

	if Input:pressed("up") then
		local t = love.timer.getTime()
		-- Double foward input (sprint speed)
		if t - self.lastForwardTap <= self.doubleTapTime then
			self.isSprinting = true
		end
		self.lastForwardTap = t
	end

	if not Input:down("up") then
		self.isSprinting = false
	end

	-- Normal keyboard inputs
	if Input:down("up")    then moveDir = moveDir + forward end
	if Input:down("down")  then moveDir = moveDir - forward end
	if Input:down("right") then moveDir = moveDir + right   end
	if Input:down("left")  then moveDir = moveDir - right   end

	self.maxSpeed = self.isSprinting and self.sprintSpeed or self.walkSpeed

	if Input:down("jump") and self.isGrounded then
		self.velocity.y = self.jumpForce
	end

	self.acceleration = moveDir:length() > 0 and moveDir:normalized() * self.accelRate or Vector(0, 0, 0)
end

function Player:updateCameraFov(dt)
	local targetFov = self.isSprinting and self.sprintFov or self.defaultFov
	local t = math.min(self.fovLerpSpeed * dt, 1)
	Camera.fov = Camera.fov + (targetFov - Camera.fov) * t
end

function Player:applyPhysics(dt)
	self.velocity = self.velocity + self.acceleration * dt
	
	local hv = Vector(self.velocity.x, 0, self.velocity.z)
	if hv:length() > self.maxSpeed then
		hv = hv:normalized() * self.maxSpeed
		self.velocity.x = hv.x
		self.velocity.z = hv.z
	end
	
	if self.acceleration:length() == 0 then
		local friction = hv * -1 * self.friction * dt
		if friction:length() > hv:length() then
			self.velocity.x = 0
			self.velocity.z = 0
		else
			self.velocity.x = self.velocity.x + friction.x
			self.velocity.z = self.velocity.z + friction.z
		end
	end
	
	self.velocity.y = self.velocity.y - self.gravity * dt
end

function Player:moveAndCollide(dt)
	local terrain = Terrain.instance
	
	local newX = self.position.x + self.velocity.x * dt
	if self:canMoveTo(newX, self.position.y, self.position.z) then
		self.position.x = newX
	else
		self.velocity.x = 0
	end

	local newZ = self.position.z + self.velocity.z * dt
	if self:canMoveTo(self.position.x, self.position.y, newZ) then
		self.position.z = newZ
	else
		self.velocity.z = 0
	end
		
	-- Vertical is kind special, because we need to update "isGrounded" flag
	local newY = self.position.y + self.velocity.y * dt
	if self:canMoveTo(self.position.x, newY, self.position.z) then
		self.position.y = newY
		self.isGrounded = false
	else
		if self.velocity.y < 0 then
			self.isGrounded = true
		end
		self.velocity.y = 0
	end
end

function Player:canMoveTo(x, y, z)
	if self:isPlaceMeeting(x + self.radius, y, z) then return false end
	if self:isPlaceMeeting(x - self.radius, y, z) then return false end
	if self:isPlaceMeeting(x, y, z + self.radius) then return false end
	if self:isPlaceMeeting(x, y, z - self.radius) then return false end
	
	local headY = y + self.height
	if self:isPlaceMeeting(x + self.radius, headY, z) then return false end
	if self:isPlaceMeeting(x - self.radius, headY, z) then return false end
	if self:isPlaceMeeting(x, headY, z + self.radius) then return false end
	if self:isPlaceMeeting(x, headY, z - self.radius) then return false end

	return true
end

-- GameMaker allways follows me where I go 
function Player:isPlaceMeeting(terrain, x, y, z)
	local terrain = Terrain.instance
	local bx = math.floor(x + 0.5)
	local by = math.floor(y + 0.5)
	local bz = math.floor(z + 0.5)
	
	local voxel = terrain:getVoxel(bx, by, bz)
	return voxel ~= Chunk.VOXEL_AIR and voxel ~= Chunk.VOXEL_VOID
end
