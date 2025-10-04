local Canvas = {
    -- properties
    Name = "Canvas",
    
    BlendMode = "alpha",    -- the LOVE BlendMode to apply to a Canvas when drawing it
    AlphaMode = "alphamultiply",    -- same as above, but AlphaBlendMode

    IgnoreMaterialMap = false,

    -- internal properties
    _oldShader = nil,
    _oldCanvas = nil,
    _drawable = nil,       -- Love2D "real canvas" created in constructor
    _materialMap = nil,
    _size = V{320, 180},    -- Vector2 positional storage (created in constructor)
    _super = "Texture",      -- Supertype
    _global = true,

    MULTI_RENDER_SHADER = Shader.new("chexcore/assets/shaders/render-albedo-materialmap.glsl")
}
_G.MULTI_RENDER_SHADER = Canvas.MULTI_RENDER_SHADER


local lg = love.graphics

-- constructor
local newRealCanvas = love.graphics.newCanvas
function Canvas.new(width, height, noMaterialMap)
    local newCanvas = Canvas:SuperInstance()

    newCanvas._size = V{width or Canvas._size[1], height or Canvas._size[2]}
    newCanvas._drawable = newRealCanvas(newCanvas._size.X, newCanvas._size.Y)
    newCanvas.IgnoreMaterialMap = noMaterialMap
    return Canvas:Connect(newCanvas)
end

-- size getters...
function Canvas:GetWidth()
    return self._size.X
end

function Canvas:GetHeight()
    return self._size.Y
end

function Canvas:GetSize()
    return V{self._size[1], self._size[2]}
end

-- size setter
function Canvas:SetSize(width, height)
    self._size[1], self._size[2] = width or self._size[1], height or self._size[2]
    self._drawable = newRealCanvas(self._size[1], self._size[2])
end


local draw, setBlendMode, getBlendMode = cdraw, lg.setBlendMode, lg.getBlendMode
function Canvas:DrawToScreen(...)
    -- prepare the Canvas's render conditions
    local mode, alphaMode = getBlendMode()
    setBlendMode(self.BlendMode == "ignore" and mode or self.BlendMode, self.AlphaMode == "ignore" and alphaMode or self.AlphaMode)

    

    -- render the Canvas
    -- draw(self._drawable, (self._materialMap or false), ...)
    
    if CurrentCanvas and self._materialMap and not CurrentCanvas.IgnoreMaterialMap then
        if not CurrentCanvas._materialMap then
            CurrentCanvas:InitMaterialMap()
        end
        MULTI_RENDER_SHADER:Send("albedoTexture", self._drawable)
        MULTI_RENDER_SHADER:Send("materialTexture", self._materialMap)
        draw(self._drawable, self._materialMap, ...)
    else
        MULTI_RENDER_SHADER:Send("albedoTexture", self._drawable)
        MULTI_RENDER_SHADER:Send("materialTexture", Texture._dummyTexture)
        draw(self._drawable, (self._materialMap or false), ...)
    end

    setBlendMode(mode, alphaMode)
end

local setCanvas, setShader = lg.setCanvas, lg.setShader
function Canvas:Activate()
    self._oldCanvas = _G.CurrentCanvas
    _G.CurrentCanvas = self
    if self._materialMap and not self.Shader then
        setCanvas(self._drawable, self._materialMap)
        
        MULTI_RENDER_SHADER:Activate()
        
    else
        if self._oldCanvas and self._oldCanvas._materialMap then
            MULTI_RENDER_SHADER:Deactivate()
        end
        setCanvas(self._drawable)
    end
    
    if self.Shader then
        self.Shader:Activate()
    end
end

function Canvas:InitMaterialMap()
    self._materialMap = newRealCanvas(self:GetSize()())
end

function Canvas:Deactivate()
    if self.Shader then
        self.Shader:Deactivate()
    elseif self._materialMap then
        self.MULTI_RENDER_SHADER:Deactivate()
    end

    if self._oldCanvas and self._oldCanvas._materialMap and not self._oldCanvas.Shader then
        setCanvas(self._oldCanvas._drawable, self._oldCanvas._materialMap)
        Canvas.MULTI_RENDER_SHADER:Activate()
    else
        setCanvas(self._oldCanvas and self._oldCanvas._drawable or nil)
    end
    
    _G.CurrentCanvas = self._oldCanvas
    self._oldCanvas = nil
end

function Canvas:Clone()
    local clone = Object.Clone(self)
    
    clone._drawable = love.graphics.newCanvas(clone._drawable:getDimensions())
    clone._drawable:renderTo(function ()
        love.graphics.setColor(1,1,1)
        love.graphics.draw(self._drawable, 0, 0)
    end)

    return clone
end

function Canvas:CopyFrom(other, shader)
    self._drawable:renderTo(function ()
        if shader then shader:Activate() end
        love.graphics.clear()
        love.graphics.setColor(1,1,1)
        love.graphics.draw(other._drawable, 0, 0)
        if shader then shader:Deactivate() end
    end)
end

function Canvas:Record(numFrames, outputPath)
    Chexcore.RecordCanvas(self, numFrames, outputPath)
end

function Canvas:RecordMatMap(numFrames, outputPath)
    Chexcore.RecordCanvasMatMap(self, numFrames, outputPath)
end

return Canvas