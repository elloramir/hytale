Model = Object:extend()


local format = {
    {"VertexPosition", "float", 3},
    {"VertexNormal",   "float", 3},
    {"VertexTexCoord", "float", 2},
    {"AmbientOcclusion", "float", 1},
}


function Model:new(vertices, texture)
    self.mesh = love.graphics.newMesh(format, vertices, "triangles", "static")
    self.mesh:setTexture(texture)
    self.transform = Matrix()
end


function Model:draw(shader)
    shader:send("projectionMatrix", Camera.projMatrix)
    shader:send("viewMatrix", Camera.viewMatrix)
    shader:send("modelMatrix", self.transform)
    shader:send("isCanvasEnabled", love.graphics.getCanvas() ~= nil)

    love.graphics.setShader(shader)
    love.graphics.draw(self.mesh)
    love.graphics.setShader()
end