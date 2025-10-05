local Texture = {
    -- properties
    Name = "Texture",

    -- internal properties
    _drawable = nil,        -- default image

    _bakeMatMapShader = Shader.new("chexcore/assets/shaders/bake-materialmap.glsl"),
    _dummyTexture = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),

    _cache = setmetatable({}, {__mode = "v"}), -- cache has weak values
    _super = "Object",      -- Supertype
    _global = true
}

--local mt = {}
--setmetatable(Texture, mt)
local smt = setmetatable
local newTextureFunc = love.graphics.newTexture or love.graphics.newImage
function Texture.new(path, normalPath, specularPath, heightPath, emissionPath, occlusionPath, userPath1, userPath2)
    local newTexture
    
    if Texture._cache[path] then
        return Texture._cache[path]
    end
        
    newTexture = smt({}, Texture)
    if path then
        local baseTexture = newTextureFunc(path)
        local width, height = baseTexture:getDimensions()

        newTexture._drawable = love.graphics.newCanvas(width, height, 3, Chexcore._canvasSettings)

        local oc = love.graphics.getCanvas()

        -- Render albedo to layer 0
        love.graphics.setCanvas{{newTexture._drawable, layer = 1}}
        local shader = love.graphics.getShader()
        love.graphics.setShader()
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(baseTexture, 0, 0)
        love.graphics.setCanvas()
        -- Render material map to layer 1 if any material maps exist
        if normalPath or specularPath or heightPath then             
            love.graphics.setCanvas{{newTexture._drawable, layer = 2}}

            local normalMap, specularMap, heightMap
            local bakeMatMapShader, dummyTexture = Texture._bakeMatMapShader, Texture._dummyTexture
            bakeMatMapShader:Activate()

            if normalPath then
                normalMap = newTextureFunc(normalPath)
                bakeMatMapShader:Send("normalMap", normalMap)
                bakeMatMapShader:Send("normalWeight", 1)
            else
                bakeMatMapShader:Send("normalMap", dummyTexture)
                bakeMatMapShader:Send("normalWeight", 0)
            end
            if specularPath then
                specularMap = newTextureFunc(specularPath)
                bakeMatMapShader:Send("specularMap", specularMap)
                bakeMatMapShader:Send("specularWeight", 1)
            else
                bakeMatMapShader:Send("specularMap", dummyTexture)
                bakeMatMapShader:Send("specularWeight", 0)
            end
            if heightPath then
                heightMap = newTextureFunc(heightPath)
                bakeMatMapShader:Send("heightMap", heightMap)
                bakeMatMapShader:Send("heightWeight", 1)
            else
                bakeMatMapShader:Send("heightMap", dummyTexture)
                bakeMatMapShader:Send("heightWeight", 0)
            end
            love.graphics.draw(baseTexture, 0, 0)
            bakeMatMapShader:Deactivate()
            
            if normalMap then normalMap:release() end
            if specularMap then specularMap:release() end
            if heightMap then heightMap:release() end
        end
        love.graphics.setCanvas(oc)
        love.graphics.setShader(shader)
        Texture._cache[path] = newTexture
    end
    
    return newTexture
end

local draw = cdraw

function Texture:DrawToScreen(...)
    draw(self._drawable, ...)
end

local V = Vector
function Texture:GetSize()
    return V{ self._drawable:getDimensions() }
end

function Texture:GetWidth()
    return self._drawable:getWidth()
end

function Texture:GetHeight()
    return self._drawable:getHeight()
end
return Texture