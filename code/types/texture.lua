local Texture = {
    -- properties
    Name = "Texture",

    -- internal properties
    _drawable = nil,        -- default image

    _bakeMatMapShader = Shader.new("chexcore/assets/shaders/bake-materialmap.glsl"),
    _bakeMatMap2Shader = Shader.new("chexcore/assets/shaders/bake-materialmap2.glsl"),
    _dummyTexture = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),
    _dummyTexture2 = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),
    _dummyNormalMap = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),
    _dummySpecularMap = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),
    _dummyHeightMap = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),
    _dummyShadowMap = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),
    _dummyLightMap = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),
    _dummyRotationMap = love.graphics.newCanvas(1,1, Chexcore._canvasSettings),

    _hasNormalMap = false,
    _hasSpecularMap = false,
    _hasHeightMap = false,
    _hasLightMap = false,
    _hasShadowMap = false,


    _cache = setmetatable({}, {__mode = "v"}), -- cache has weak values
    _super = "Object",      -- Supertype
    _global = true
}

-- these dummies represent the default maps going INTO the bake shader!
Texture._dummyTexture:renderTo(function ()
    love.graphics.clear(1,0,0,0)
end)
Texture._dummyTexture2:renderTo(function ()
    love.graphics.clear(1,0,0,0)
end)
Texture._dummyNormalMap:renderTo(function ()
    love.graphics.clear(0,0,0,0)
    
end)
Texture._dummySpecularMap:renderTo(function ()
    love.graphics.clear(0,0,0,0)
    
end)
Texture._dummyHeightMap:renderTo(function ()
    love.graphics.clear(0,0,0,0)
end)
Texture._dummyShadowMap:renderTo(function ()
    love.graphics.clear(0,0,0,0)
end)
Texture._dummyLightMap:renderTo(function ()
    -- love.graphics.clear(0,0,0,1)
    love.graphics.clear(0,0,0,0)
end)
Texture._dummyRotationMap:renderTo(function ()
    love.graphics.clear(0,0,0,0)
end)
--local mt = {}
--setmetatable(Texture, mt)
local smt = setmetatable
local newTextureFunc = love.graphics.newTexture or love.graphics.newImage
function Texture.new(path, normalPath, specularPath, heightPath, emissionPath, occlusionPath)
    if type(path)=="table" then
        if Texture._cache[path[1]] or Texture._cache[path.path] then
            return Texture._cache[path[1]] or Texture._cache[path.path]
        end
        print("YES", _tostring(path), path[1], path.occlusionPath)
        normalPath = path.normalPath
        specularPath = path.specularPath
        heightPath = path.heightPath
        emissionPath = path.emissionPath
        occlusionPath = path.occlusionPath
        userPath1 = path.userPath1
        userPath2 = path.userPath2
        path = path.path or path[1]
    end
    print("YES 2", path)
    local newTexture
    
    if Texture._cache[path] then
        return Texture._cache[path]
    end
        
    newTexture = smt({}, Texture)
    if path then
        print("YES 3", occlusionPath)
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

        -- Render material map to layer 1
        love.graphics.setCanvas{{newTexture._drawable, layer = 2}}

        local normalMap, specularMap, heightMap
        local bakeMatMapShader, dummyTexture = Texture._bakeMatMapShader, Texture._dummyTexture
        bakeMatMapShader:Activate()

        if normalPath then
            normalMap = newTextureFunc(normalPath)
            bakeMatMapShader:Send("normalMap", normalMap)
            bakeMatMapShader:Send("normalWeight", 1)
            newTexture._hasNormalMap = true
        else
            bakeMatMapShader:Send("normalMap", Texture._dummyNormalMap)
            bakeMatMapShader:Send("normalWeight", 1)
            newTexture._hasNormalMap = false
        end
        if specularPath then
            specularMap = newTextureFunc(specularPath)
            bakeMatMapShader:Send("specularMap", specularMap)
            bakeMatMapShader:Send("specularWeight", 1)
            newTexture._hasSpecularMap = true
        else
            bakeMatMapShader:Send("specularMap", Texture._dummySpecularMap)
            bakeMatMapShader:Send("specularWeight", 1)
            newTexture._hasSpecularMap = false
        end

        love.graphics.draw(baseTexture, 0, 0)
        bakeMatMapShader:Deactivate()
        
        if normalMap then normalMap:release() end
        if specularMap then specularMap:release() end
        if heightMap then heightMap:release() end

        
        -- Render additional material maps to layer 3
        love.graphics.setCanvas{{newTexture._drawable, layer = 3}}

        local emissionMap, occlusionMap, userMap1, userMap2
        local bakeMatMap2Shader, dummyTexture = Texture._bakeMatMap2Shader, Texture._dummyTexture
        bakeMatMap2Shader:Activate()

        if emissionPath then
            emissionMap = newTextureFunc(emissionPath)
            bakeMatMap2Shader:Send("emissionMap", emissionMap)
            bakeMatMap2Shader:Send("emissionWeight", 1)
            newTexture._hasLightMap = true
        else
            bakeMatMap2Shader:Send("emissionMap", Texture._dummyLightMap)
            bakeMatMap2Shader:Send("emissionWeight", 1)
            newTexture._hasLightMap = false
        end
        
        if occlusionPath then
            
            occlusionMap = newTextureFunc(occlusionPath)
            bakeMatMap2Shader:Send("occlusionMap", occlusionMap)
            bakeMatMap2Shader:Send("occlusionWeight", 1)
            newTexture._hasShadowMap = true
        else
            bakeMatMap2Shader:Send("occlusionMap", Texture._dummyShadowMap)
            bakeMatMap2Shader:Send("occlusionWeight", 1)
            newTexture._hasShadowMap = false
        end

        if heightPath then
            heightMap = newTextureFunc(heightPath)
            bakeMatMap2Shader:Send("heightMap", heightMap)
            bakeMatMap2Shader:Send("heightWeight", 1)
            newTexture._hasHeightMap = false
        else
            bakeMatMap2Shader:Send("heightMap", Texture._dummyHeightMap)
            bakeMatMap2Shader:Send("heightWeight", 1)
            newTexture._hasHeightMap = true
        end
      
        love.graphics.draw(baseTexture, 0, 0)
        bakeMatMap2Shader:Deactivate()
        
        if emissionMap then emissionMap:release() end
        if occlusionMap then occlusionMap:release() end

        love.graphics.setCanvas(oc)
        love.graphics.setShader(shader)
        Texture._cache[path] = newTexture
    end
    
    return newTexture
end

local draw = cdraw

function Texture:DrawToScreen(...)
    -- love.graphics.setShader(Canvas.DEFAULT_SHADER._realShader)
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