Assets = {}

Assets.loaded = { }

local function loadRecursive(path, callback)
    for _, item in ipairs(love.filesystem.getDirectoryItems(path)) do
        local itemPath = path .. "/" .. item
        local info = love.filesystem.getInfo(itemPath)

        if info.type == "file" then
            callback(itemPath)
        elseif info.type == "directory" then
            loadRecursive(itemPath, callback)
        end
    end
end

function Assets.load()
	local basePath = "data"

	loadRecursive("data", function(filename)
		local relative = filename:sub(#basePath + 2)
		local name, ext = relative:match("(.+)%.([^%.]+)$")

		if ext == "png" then
            -- @note: The format is: "name_wxh.png"
            local w, h = name:match("_(%d+)x(%d+)")
            
            w = tonumber(w)
            h = tonumber(h)

            if w and h then
                name = name:gsub("_%d+x%d+", "")
            end
            
            Assets.loaded[name] = Sheet(filename, w, h)

        elseif ext == "frag" then
            Assets.loaded[name] = love.graphics.newShader(filename)
		end
	end)

    Assets.loaded["love_font"] = love.graphics.newFont(12)
    Assets.loaded["baseShader"] = love.graphics.newShader(
        "data/shaders/base.frag",
        "data/shaders/base.vert")

    -- Creating an atlas for the voxel blocks
    local atlasTexture = Assets.loaded["sprites/basic"]
    local function create(i0, i1, i2)
        return {
            top    = { atlasTexture:getUV(i0) },
            side   = { atlasTexture:getUV(i1) },
            bottom = { atlasTexture:getUV(i2) }
        }
    end

    Assets.voxelAtlas = {
        [Chunk.VOXEL_DIRT_GRASS] = create(14, 43, 52),
        [Chunk.VOXEL_DIRT] = create(52, 52, 52),
        [Chunk.VOXEL_STONE] = create(39, 39, 39),
        [Chunk.VOXEL_SAND] = create(57, 57, 57),
    }

	Lume.trace(("Assets loaded: %d"):format(Lume.count(Assets.loaded)))
end

function Assets.get(name)
	return Assets.loaded[name] or error(name)
end