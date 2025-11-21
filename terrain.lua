Terrain = Object:extend()

function Terrain:new()
	self.chunks = { }
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
		local chunk = Game.addEntity(Chunk(x, z, self));

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
