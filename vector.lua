Vector = Object:extend()

function Vector:new(x, y, z)
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0
end

function Vector:copy()
    return Vector(self.x, self.y, self.z)
end

function Vector:length()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector:normalized()
	local len = self:length()

	if len > 0 then
		return Vector(self.x / len, self.y / len, self.z / len)
	end

	return Vector(0, 0, 0)
end

function Vector:cross(other)
    return Vector(
    	self.y * other.z - self.z * other.y,
    	self.z * other.x - self.x * other.z,
    	self.x * other.y - self.y * other.x)
end

function Vector:dot(other)
	return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vector:__add(other)
    if type(other) == "number" then
        return Vector(self.x + other, self.y + other, self.z + other)
    else
        return Vector(self.x + other.x, self.y + other.y, self.z + other.z)
    end
end

function Vector:__sub(other)
    if type(other) == "number" then
        return Vector(self.x - other, self.y - other, self.z - other)
    else
        return Vector(self.x - other.x, self.y - other.y, self.z - other.z)
    end
end

function Vector:__mul(other)
    if type(other) == "number" then
        return Vector(self.x * other, self.y * other, self.z * other)
    else
        return Vector(self.x * other.x, self.y * other.y, self.z * other.z)
    end
end

function Vector:__div(other)
    if type(other) == "number" then
        return Vector(self.x / other, self.y / other, self.z / other)
    else
        return Vector(self.x / other.x, self.y / other.y, self.z / other.z)
    end
end

function Vector:__eq(other)
    return self.x == other.x and self.y == other.y and self.z == other.z
end

Vector.ZERO = Vector(0, 0, 0)
