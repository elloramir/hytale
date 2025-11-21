local FRAG_TOKEN = "#fragment"
local VERT_TOKEN = "#vertex"

local function startsWith(str1, str2)
	return str1:sub(1, #str2) == str2
end

local function emptyToNil(str)
	if #str ~= 0 then
		return str
	end
end

function ShaderParser(filename)
	local content = love.filesystem.read(filename)

	if not content then
		error(("Could not load the shader file: %s"):format(filename))
	end

	local fragLines = {}
	local vertLines = {}
	local actualContext

	for line in content:gmatch("[^\r\n]+") do
		if startsWith(line, FRAG_TOKEN) then
			actualContext = fragLines
		elseif startsWith(line, VERT_TOKEN) then
			actualContext = vertLines
		elseif actualContext then
			table.insert(actualContext, line)
		end
	end

	local shader = love.graphics.newShader(
		emptyToNil(table.concat(fragLines, "\n")),
		emptyToNil(table.concat(vertLines, "\n"))
	)

	return shader
end