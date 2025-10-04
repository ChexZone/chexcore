local Texture = {
    -- properties
    Name = "Texture",

    -- internal properties
    _drawable = nil,        -- default image
    _materialMap = nil,

    _bakeMatMapShader = Shader.new("chexcore/assets/shaders/bake-materialmap.glsl"),
    _dummyTexture = love.graphics.newCanvas(1,1),

    _cache = setmetatable({}, {__mode = "v"}), -- cache has weak values
    _super = "Object",      -- Supertype
    _global = true
}

--local mt = {}
--setmetatable(Texture, mt)
local smt = setmetatable
local newTextureFunc = love.graphics.newTexture or love.graphics.newImage
function Texture.new(path, normalPath, specularPath, emissivePath)
    local newTexture

    if Texture._cache[path] then
        newTexture = Texture._cache[path]
    else
        
        newTexture = smt({}, Texture)
        if path then
            newTexture._drawable = newTextureFunc(path)
            Texture._cache[path] = newTexture
            if normalPath or specularPath or emissivePath then
                newTexture._materialMap = love.graphics.newCanvas(newTexture._drawable:getDimensions())
                local oc = love.graphics.getCanvas()
                love.graphics.setCanvas(newTexture._materialMap)

                -- local normalMap = normalPath and  or Texture._dummyTexture
                -- local specularMap = specularPath and newTextureFunc(specularPath) or Texture._dummyTexture
                -- local emissiveMap = emissivePath and newTextureFunc(emissivePath) or Texture._dummyTexture
                local normalMap, specularMap, emissiveMap
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
                if emissivePath then
                    emissiveMap = newTextureFunc(emissivePath)
                    bakeMatMapShader:Send("emissiveMap", emissiveMap)
                    bakeMatMapShader:Send("emissiveWeight", 1)
                else
                    bakeMatMapShader:Send("emissiveMap", dummyTexture)
                    bakeMatMapShader:Send("emissiveWeight", 0)
                end
                love.graphics.draw(newTexture._drawable, 0, 0)
                bakeMatMapShader:Deactivate()
                love.graphics.setCanvas(oc)
            end
        end

    end

    return newTexture
end

local draw = cdraw

function Texture:DrawToScreen(...)
    if self._materialMap then
        if not CurrentCanvas._materialMap then
            CurrentCanvas:InitMaterialMap()
        end
        MULTI_RENDER_SHADER:Send("albedoTexture", self._drawable)
        MULTI_RENDER_SHADER:Send("materialTexture", self._materialMap)
        draw(self._drawable, self._materialMap, ...)
    else
        -- if CurrentCanvas and MULTI_RENDER_SHADER then
        --     CurrentCanvas.
        -- end
        MULTI_RENDER_SHADER:Send("albedoTexture", self._dummyTexture)
        MULTI_RENDER_SHADER:Send("materialTexture", self._drawable)
        draw(self._drawable, (self._materialMap or false), ...)
    end
    
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