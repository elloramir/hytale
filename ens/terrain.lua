Terrain = Entity:extend()

function Terrain:new()
	Entity.new(self)

	-- Singleton
	assert(not Terrain.instance)
	Terrain.instance = self

	self.chunks = {}
	self.chunksX = 4
	self.chunksY = 4
	self.radius = (self.chunksX / 2) * Chunk.SIZE
	
	local startX = -math.floor(self.chunksX / 2)
	local startZ = -math.floor(self.chunksY / 2)
	local endX = startX + self.chunksX - 1
	local endZ = startZ + self.chunksY - 1
	
	self.centerX = ((startX + endX) / 2) * Chunk.SIZE + Chunk.SIZE / 2
	self.centerZ = ((startZ + endZ) / 2) * Chunk.SIZE + Chunk.SIZE / 2
	
	for i = startX, endX do
		for j = startZ, endZ do
			self:generateChunk(i, j)
		end
	end
end

function Terrain.getIndex(x, z)
	return x + z * 1e7
end

function Terrain:getChunk(x, z)
	return self.chunks[Terrain.getIndex(x, z)]
end

function Terrain:getVoxel(x, y, z)
	local cx = math.floor(x / Chunk.SIZE);
	local cz = math.floor(z / Chunk.SIZE);
	local chunk = self:getChunk(cx, cz);

	if not chunk then
		return Chunk.VOXEL_VOID;
	end

	local x0 = x - cx * Chunk.SIZE;
	local z0 = z - cz * Chunk.SIZE;

	return chunk:getVoxel(x0, y, z0);
end

function Terrain:generateChunk(x, z)
	if not self:getChunk(x, z) then
		local chunk = Chunk(x, z, self);

		if chunk.hasData then
			self.chunks[Terrain.getIndex(x, z)] = chunk

			-- Update neigbours chunks
			local c0 = self:getChunk(x - 1, z)
			local c1 = self:getChunk(x + 1, z)
			local c2 = self:getChunk(x, z - 1)
			local c3 = self:getChunk(x, z + 1)

			if c0 then c0:generateMesh() end
			if c1 then c1:generateMesh() end
			if c2 then c2:generateMesh() end
			if c3 then c3:generateMesh() end
		end
	end
end

function Terrain:draw3d()
	for _, chunk in pairs(self.chunks) do
		chunk:draw3d()
	end
end
