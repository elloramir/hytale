Matrix = Object:extend()

function Matrix:new()
	self:setIdentity()
end

function Matrix:setIdentity()
	self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
	self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
	self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
	self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

function Matrix:perspective(fov, aspect, near, far)
	local top = near * math.tan(fov / 2)
	local bottom = -top
	local right = top * aspect
	local left = -right

	self[1],  self[2],  self[3],  self[4]  = 2*near/(right-left), 0, (right+left)/(right-left), 0
	self[5],  self[6],  self[7],  self[8]  = 0, 2*near/(top-bottom), (top+bottom)/(top-bottom), 0
	self[9],  self[10], self[11], self[12] = 0, 0, -1*(far+near)/(far-near), -2*far*near/(far-near)
	self[13], self[14], self[15], self[16] = 0, 0, -1, 0
end

function Matrix:lookAt(eye, target, up)
    local z = (eye - target):normalized()
    local x = up:cross(z):normalized()
    local y = z:cross(x)

    self[1],  self[2],  self[3],  self[4]  = x.x, x.y, x.z, -x:dot(eye)
    self[5],  self[6],  self[7],  self[8]  = y.x, y.y, y.z, -y:dot(eye)
    self[9],  self[10], self[11], self[12] = z.x, z.y, z.z, -z:dot(eye)
    self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

function Matrix:forward()
    return Vector(-self[9], -self[10], -self[11]):normalized()
end

function Matrix:translate(v)
	self[4]  = self[1] * v.x + self[2] * v.y + self[3] * v.z + self[4]
	self[8]  = self[5] * v.x + self[6] * v.y + self[7] * v.z + self[8]
	self[12] = self[9] * v.x + self[10] * v.y + self[11] * v.z + self[12]
end