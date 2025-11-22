Chunk = Entity:extend()

Chunk.SIZE = 32
Chunk.HEIGHT = 8

Chunk.VOXEL_VOID = 0
Chunk.VOXEL_AIR = 1
Chunk.VOXEL_DIRT = 2
Chunk.VOXEL_DIRT_GRASS = 3
Chunk.VOXEL_STONE = 4	
Chunk.VOXEL_SAND = 5

local NOISE_SMOOTHNESS = 10
local AO_CURVE = { 1.0, 0.8, 0.6, 0.4 }

function Chunk:new(x, z, terrain)
	Entity.new(self)

	self.x = x
	self.z = z
	
	self.absX = x * Chunk.SIZE
	self.absZ = z * Chunk.SIZE

	self.texture = Assets.get("sprites/basic")
	self.terrain = terrain
	self.data = {}

	self.hasData = true

	self:generateData()
	self:generateMesh()
end

function Chunk.getIndex(x, y, z)
	return x + (z * Chunk.SIZE) + (y * Chunk.SIZE * Chunk.SIZE)
end

function Chunk:getVoxel(x, y, z)
	if y < 0 or y >= Chunk.HEIGHT then
		return Chunk.VOXEL_AIR
	end

	if x < 0 or x >= Chunk.SIZE or z < 0 or z >= Chunk.SIZE then
		return self.terrain:getVoxel(self.absX + x, y, self.absZ + z);
	end

	return self.data[Chunk.getIndex(x, y, z)];
end

function Chunk:isTransparent(x, y, z)
	local voxel = self:getVoxel(x, y, z)
	return voxel == Chunk.VOXEL_AIR
end

function Chunk:fill(voxel)
	for i = 0, (Chunk.SIZE * Chunk.SIZE * Chunk.HEIGHT) - 1 do
		self.data[i] = voxel
	end
end

function Chunk:generateData()
	local radius = self.terrain.radius
	local sandPercent = 0.30
	local sandThickness = math.max(1, radius * sandPercent)
	
	local centerX = self.terrain.centerX
	local centerZ = self.terrain.centerZ
	
	self:fill(Chunk.VOXEL_AIR)
	
	for x = 0, Chunk.SIZE - 1 do
		for z = 0, Chunk.SIZE - 1 do
			local absx = self.absX + x
			local absz = self.absZ + z
			local noiseX = absx / NOISE_SMOOTHNESS
			local noiseZ = absz / NOISE_SMOOTHNESS
			
			---------------------------------------------------------------------
			-- TERRAIN BASE: LARGE CANYONS AND CONTINUOUS FORMS
			---------------------------------------------------------------------
			local base = love.math.noise(noiseX * 0.15, noiseZ * 0.15)
			local canyonNoise = love.math.noise(noiseX * 0.2, noiseZ * 0.2)
			local canyon = math.abs(canyonNoise - 0.5) * 1.4
			local combined = base - canyon * 0.55
			combined = combined * combined
			local plateau = math.max(0, math.min(1, combined * 2.2))
			local height = math.floor(plateau * Chunk.HEIGHT)
			
			---------------------------------------------------------------------
			-- ISLAND FORMAT: CIRCULAR, BUT WITH PROCEDURAL CUTOUTS
			---------------------------------------------------------------------
			local shapeFreq1 = 0.02
			local shapeFreq2 = 0.08
			local shapeAmp1 = 0.28
			local shapeAmp2 = 0.08
			local minRadiusFactor = 0.55
			
			local shapeNoise =
				love.math.noise(noiseX * shapeFreq1, noiseZ * shapeFreq1) * 0.7 +
				love.math.noise(noiseX * shapeFreq2, noiseZ * shapeFreq2) * 0.3
			shapeNoise = (shapeNoise - 0.5) * 2
			
			-- Slight jitter only for the coastline (breaks straight lines)
			local shoreJitterFreq = 0.2   -- jitter frequency (higher = more fine ripples)
			local shoreJitterAmp  = 0.08  -- amplitude relative to the radius (adjust up/down)
			local shoreJitter =
				(love.math.noise(noiseX * shoreJitterFreq + 437.13, noiseZ * shoreJitterFreq + 913.37) - 0.5) * 2
			
			local localRadius = radius * (1 + shapeNoise * shapeAmp1 + (shapeNoise * 0.5) * shapeAmp2)
			localRadius = localRadius + shoreJitter * (radius * shoreJitterAmp)
			localRadius = math.max(localRadius, radius * minRadiusFactor)
			
			---------------------------------------------------------------------
			-- CALCULATE DISTANCE FROM THE CORRECT CENTER OF THE ISLAND
			---------------------------------------------------------------------
			local dx = absx - centerX
			local dz = absz - centerZ
			local dist = math.sqrt(dx * dx + dz * dz)
			
			---------------------------------------------------------------------
			-- COMPARISON WITH DISTANCE, SAND IN UNITS
			---------------------------------------------------------------------
			if dist < localRadius then
				-- beach: if it is within the sand thickness range
				if dist >= (localRadius - sandThickness) then
					-- place sand only in the top layer (y == 0)
					self.data[Chunk.getIndex(x, 0, z)] = Chunk.VOXEL_SAND
				else
					-----------------------------------------------------------------
					-- VERTICAL FILLING OF THE TERRAIN (INTERIOR)
					-----------------------------------------------------------------
					for y = 0, Chunk.HEIGHT - 1 do
						local index = Chunk.getIndex(x, y, z)
						if y >= height then
							self.data[index] = Chunk.VOXEL_AIR
						elseif y == height - 1 then
							self.data[index] = Chunk.VOXEL_DIRT_GRASS
						else
							self.data[index] = Chunk.VOXEL_DIRT
						end
						if y == 0 then
							self.data[index] = Chunk.VOXEL_DIRT_GRASS
						end
					end
				end
			end
		end
	end
end

-- @TODO(ellora): If model already exists we should unload it?
function Chunk:generateMesh()
	local vertices = {}

	for x = 0, Chunk.SIZE - 1 do
		for z = 0, Chunk.SIZE - 1 do
			for y = 0, Chunk.HEIGHT - 1 do
				local block = self:getVoxel(x, y, z)

				if block ~= Chunk.VOXEL_AIR then
					if self:isTransparent(x, y, z - 1) then self:appendQuad(vertices, "north", block, x, y, z) end
					if self:isTransparent(x, y, z + 1) then self:appendQuad(vertices, "south", block, x, y, z) end
					if self:isTransparent(x + 1, y, z) then self:appendQuad(vertices, "east", block, x, y, z) end
					if self:isTransparent(x - 1, y, z) then self:appendQuad(vertices, "west", block, x, y, z) end
					if self:isTransparent(x, y + 1, z) then self:appendQuad(vertices, "top", block, x, y, z) end
					if self:isTransparent(x, y - 1, z) and y > 0 then self:appendQuad(vertices, "bottom", block, x, y, z) end
				end
			end
		end
	end

	if #vertices > 0 then
		self.model = Model(vertices, Assets.get("sprites/basic").img)
		self.model.transform:translate(Vector(self.absX, 0, self.absZ))
	else
		self.hasData = false
	end
end

function Chunk.vertexAO(side1, side2, corner)
	if side1 == 1 and side2 == 1 then
		return 0
	end
	return 3 - (side1 + side2 + corner)
end

function Chunk:isSolid(x, y, z)
	local voxel = self:getVoxel(x, y, z)
	if voxel ~= Chunk.VOXEL_VOID and voxel ~= Chunk.VOXEL_AIR then
		return 1
	end
	return 0
end

function Chunk:appendQuad(vertices, side, block, x, y, z)
	local xp = x + 0.5
	local xn = x - 0.5
	local yp = y + 0.5
	local yn = y - 0.5
	local zp = z + 0.5
	local zn = z - 0.5

	local dir = side ~= "top" and side ~= "bottom" and "side" or side
	local u0, v0, u1, v1 = unpack(Assets.voxelAtlas[block][dir])
	local ao00, ao10, ao11, ao01

	if side == "north" then
		local nz = z - 1
		local t = self:isSolid(x, y + 1, nz)
		local b = self:isSolid(x, y - 1, nz)
		local l = self:isSolid(x - 1, y, nz)
		local r = self:isSolid(x + 1, y, nz)
		local tl = self:isSolid(x - 1, y + 1, nz)
		local tr = self:isSolid(x + 1, y + 1, nz)
		local bl = self:isSolid(x - 1, y - 1, nz)
		local br = self:isSolid(x + 1, y - 1, nz)

		ao00 = AO_CURVE[Chunk.vertexAO(r, t, tr) + 1]
		ao10 = AO_CURVE[Chunk.vertexAO(r, b, br) + 1]
		ao11 = AO_CURVE[Chunk.vertexAO(l, b, bl) + 1]
		ao01 = AO_CURVE[Chunk.vertexAO(l, t, tl) + 1]

		table.insert(vertices, {xp, yp, zn, 0, 0, -1, u1, v1, ao00}) -- V0
		table.insert(vertices, {xp, yn, zn, 0, 0, -1, u1, v0, ao10}) -- V1
		table.insert(vertices, {xn, yn, zn, 0, 0, -1, u0, v0, ao11}) -- V2
		table.insert(vertices, {xp, yp, zn, 0, 0, -1, u1, v1, ao00}) -- V0
		table.insert(vertices, {xn, yn, zn, 0, 0, -1, u0, v0, ao11}) -- V2
		table.insert(vertices, {xn, yp, zn, 0, 0, -1, u0, v1, ao01}) -- V3

	elseif side == "south" then
		local nz = z + 1
		local t = self:isSolid(x, y + 1, nz)
		local b = self:isSolid(x, y - 1, nz)
		local l = self:isSolid(x - 1, y, nz)
		local r = self:isSolid(x + 1, y, nz)
		local tl = self:isSolid(x - 1, y + 1, nz)
		local tr = self:isSolid(x + 1, y + 1, nz)
		local bl = self:isSolid(x - 1, y - 1, nz)
		local br = self:isSolid(x + 1, y - 1, nz)

		ao00 = AO_CURVE[Chunk.vertexAO(l, t, tl) + 1]
		ao10 = AO_CURVE[Chunk.vertexAO(l, b, bl) + 1]
		ao11 = AO_CURVE[Chunk.vertexAO(r, b, br) + 1]
		ao01 = AO_CURVE[Chunk.vertexAO(r, t, tr) + 1]

		table.insert(vertices, {xn, yp, zp, 0, 0, 1, u0, v1, ao00}) -- V0
		table.insert(vertices, {xn, yn, zp, 0, 0, 1, u0, v0, ao10}) -- V1
		table.insert(vertices, {xp, yn, zp, 0, 0, 1, u1, v0, ao11}) -- V2
		table.insert(vertices, {xn, yp, zp, 0, 0, 1, u0, v1, ao00}) -- V0
		table.insert(vertices, {xp, yn, zp, 0, 0, 1, u1, v0, ao11}) -- V2
		table.insert(vertices, {xp, yp, zp, 0, 0, 1, u1, v1, ao01}) -- V3

	elseif side == "east" then
		local nx = x + 1
		local t = self:isSolid(nx, y + 1, z)
		local b = self:isSolid(nx, y - 1, z)
		local l = self:isSolid(nx, y, z - 1)
		local r = self:isSolid(nx, y, z + 1)
		local tl = self:isSolid(nx, y + 1, z - 1)
		local tr = self:isSolid(nx, y + 1, z + 1)
		local bl = self:isSolid(nx, y - 1, z - 1)
		local br = self:isSolid(nx, y - 1, z + 1)

		ao00 = AO_CURVE[Chunk.vertexAO(l, t, tl) + 1]
		ao10 = AO_CURVE[Chunk.vertexAO(r, b, br) + 1]
		ao11 = AO_CURVE[Chunk.vertexAO(l, b, bl) + 1]
		ao01 = AO_CURVE[Chunk.vertexAO(r, t, tr) + 1]

		table.insert(vertices, {xp, yp, zn, 1, 0, 0, u1, v1, ao00}) -- V0
		table.insert(vertices, {xp, yn, zp, 1, 0, 0, u0, v0, ao10}) -- V1
		table.insert(vertices, {xp, yn, zn, 1, 0, 0, u1, v0, ao11}) -- V2
		table.insert(vertices, {xp, yp, zp, 1, 0, 0, u0, v1, ao01}) -- V3
		table.insert(vertices, {xp, yn, zp, 1, 0, 0, u0, v0, ao10}) -- V1
		table.insert(vertices, {xp, yp, zn, 1, 0, 0, u1, v1, ao00}) -- V0

	elseif side == "west" then
		local nx = x - 1
		local t = self:isSolid(nx, y + 1, z)
		local b = self:isSolid(nx, y - 1, z)
		local l = self:isSolid(nx, y, z - 1)
		local r = self:isSolid(nx, y, z + 1)
		local tl = self:isSolid(nx, y + 1, z - 1)
		local tr = self:isSolid(nx, y + 1, z + 1)
		local bl = self:isSolid(nx, y - 1, z - 1)
		local br = self:isSolid(nx, y - 1, z + 1)

		ao00 = AO_CURVE[Chunk.vertexAO(l, t, tl) + 1]
		ao10 = AO_CURVE[Chunk.vertexAO(l, b, bl) + 1]
		ao11 = AO_CURVE[Chunk.vertexAO(r, b, br) + 1]
		ao01 = AO_CURVE[Chunk.vertexAO(r, t, tr) + 1]

		table.insert(vertices, {xn, yp, zn, -1, 0, 0, u0, v1, ao00}) -- V0
		table.insert(vertices, {xn, yn, zn, -1, 0, 0, u0, v0, ao10}) -- V1
		table.insert(vertices, {xn, yn, zp, -1, 0, 0, u1, v0, ao11}) -- V2
		table.insert(vertices, {xn, yp, zp, -1, 0, 0, u1, v1, ao01}) -- V3
		table.insert(vertices, {xn, yp, zn, -1, 0, 0, u0, v1, ao00}) -- V0
		table.insert(vertices, {xn, yn, zp, -1, 0, 0, u1, v0, ao11}) -- V2

	elseif side == "top" then 
		local ny = y + 1
		local n = self:isSolid(x, ny, z - 1)
		local s = self:isSolid(x, ny, z + 1)
		local w = self:isSolid(x - 1, ny, z)
		local e = self:isSolid(x + 1, ny, z)
		local nw = self:isSolid(x - 1, ny, z - 1)
		local ne = self:isSolid(x + 1, ny, z - 1)
		local sw = self:isSolid(x - 1, ny, z + 1)
		local se = self:isSolid(x + 1, ny, z + 1)

		ao00 = AO_CURVE[Chunk.vertexAO(w, s, sw) + 1]
		ao10 = AO_CURVE[Chunk.vertexAO(e, s, se) + 1]
		ao11 = AO_CURVE[Chunk.vertexAO(w, n, nw) + 1]
		ao01 = AO_CURVE[Chunk.vertexAO(e, n, ne) + 1]

		table.insert(vertices, {xn, yp, zp, 0, 1, 0, u0, v0, ao00}) -- V0
		table.insert(vertices, {xp, yp, zp, 0, 1, 0, u1, v0, ao10}) -- V1
		table.insert(vertices, {xn, yp, zn, 0, 1, 0, u0, v1, ao11}) -- V2
		table.insert(vertices, {xn, yp, zn, 0, 1, 0, u0, v1, ao11}) -- V2
		table.insert(vertices, {xp, yp, zp, 0, 1, 0, u1, v0, ao10}) -- V1
		table.insert(vertices, {xp, yp, zn, 0, 1, 0, u1, v1, ao01}) -- V3

	elseif side == "bottom" then
		local ny = y - 1
		local n = self:isSolid(x, ny, z - 1)
		local s = self:isSolid(x, ny, z + 1)
		local w = self:isSolid(x - 1, ny, z)
		local e = self:isSolid(x + 1, ny, z)
		local nw = self:isSolid(x - 1, ny, z - 1)
		local ne = self:isSolid(x + 1, ny, z - 1)
		local sw = self:isSolid(x - 1, ny, z + 1)
		local se = self:isSolid(x + 1, ny, z + 1)

		ao00 = AO_CURVE[Chunk.vertexAO(w, s, sw) + 1]
		ao10 = AO_CURVE[Chunk.vertexAO(w, n, nw) + 1]
		ao11 = AO_CURVE[Chunk.vertexAO(e, s, se) + 1]
		ao01 = AO_CURVE[Chunk.vertexAO(e, n, ne) + 1]

		table.insert(vertices, {xn, yn, zp, 0, -1, 0, u0, v1, ao00}) -- V0
		table.insert(vertices, {xn, yn, zn, 0, -1, 0, u0, v0, ao10}) -- V1
		table.insert(vertices, {xp, yn, zp, 0, -1, 0, u1, v1, ao11}) -- V2
		table.insert(vertices, {xn, yn, zn, 0, -1, 0, u0, v0, ao10}) -- V1
		table.insert(vertices, {xp, yn, zn, 0, -1, 0, u1, v0, ao01}) -- V3
		table.insert(vertices, {xp, yn, zp, 0, -1, 0, u1, v1, ao11}) -- V2
	end
end

function Chunk:draw3d()
	self.model:draw(Assets.get("baseShader"))
end

function Chunk:__tostring()
	return "Chunk"
end