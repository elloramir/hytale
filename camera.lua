Camera = { }

Camera.position = Vector(-10, 10, -1)
Camera.target   = Vector(0, 0, 0)
Camera.up       = Vector(0, 1, 0)

Camera.viewMatrix = Matrix()
Camera.projMatrix = Matrix()

Camera.fov = math.rad(60)
Camera.yaw = 0
Camera.pitch = 0
Camera.roll = 0

local NEAR = 0.1
local FAR = 100

function Camera.update()
	-- Target vector based on euler angles
	local sinPitch = math.sin(Camera.pitch)
	local sinYaw = math.sin(Camera.yaw)
	local cosPitch = math.cos(Camera.pitch)
	local cosYaw = math.cos(Camera.yaw)

	Camera.target.x = Camera.position.x + cosYaw * cosPitch
	Camera.target.y = Camera.position.y + sinPitch
	Camera.target.z = Camera.position.z + sinYaw * cosPitch

	-- Computing camera matrices
	local width, height = love.graphics.getDimensions()
	local aspect = width/height

	Camera.projMatrix:perspective(Camera.fov, aspect, NEAR, FAR)
	Camera.viewMatrix:lookAt(Camera.position, Camera.target, Camera.up)
end

function Camera.mouseMoved(dx, dy)
	local sens = 1/1000

	Camera.yaw = Camera.yaw + dx * sens
	Camera.pitch = Camera.pitch - dy * sens
	Camera.pitch = Lume.clamp(Camera.pitch, -math.pi/2.1, math.pi/2.1)
end