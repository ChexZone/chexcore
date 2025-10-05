local Canvas = {
    -- properties
    Name = "Canvas",
    
    BlendMode = "alpha",    -- the LOVE BlendMode to apply to a Canvas when drawing it
    AlphaMode = "alphamultiply",    -- same as above, but AlphaBlendMode

    -- internal properties
    _oldShader = nil,
    _oldCanvas = nil,
    _renderTarget = nil,    -- set in constructor
    _drawable = nil,       -- Love2D "real canvas" created in constructor
    _size = V{320, 180},    -- Vector2 positional storage (created in constructor)
    _super = "Texture",      -- Supertype
    _global = true,

    DEFAULT_SHADER = Shader.new("chexcore/assets/shaders/default.glsl")
}


local lg = love.graphics

-- constructor
local newRealCanvas = love.graphics.newCanvas
function Canvas.new(width, height)
    local newCanvas = Canvas:SuperInstance()
    newCanvas._size = V{width or Canvas._size[1], height or Canvas._size[2]}
    newCanvas._drawable = newRealCanvas(newCanvas._size.X, newCanvas._size.Y, 3, Chexcore._canvasSettings)
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
    self._drawable = newRealCanvas(self._size[1], self._size[2], 3, Chexcore._canvasSettings)
end


local draw, setBlendMode, getBlendMode = cdraw, lg.setBlendMode, lg.getBlendMode
local drawLayer = cdrawlayer
function Canvas:DrawToScreen(...)
    -- prepare the Canvas's render conditions
    local mode, alphaMode = getBlendMode()
    setBlendMode(self.BlendMode == "ignore" and mode or self.BlendMode, self.AlphaMode == "ignore" and alphaMode or self.AlphaMode)

    

    -- render the Canvas    
    draw(self._drawable, ...)
    -- love.graphics.setShader()
    -- drawLayer(self., 1, ...)
    -- love.graphics.setShader(Canvas.DEFAULT_SHADER._realShader)

    setBlendMode(mode, alphaMode)
end

local setCanvas, setShader = lg.setCanvas, lg.setShader
function Canvas:Activate(layers)
    self._oldCanvas = _G.CurrentCanvas

    if layers then
        local c = {}
        for _, layer in ipairs(layers) do
            c[#c+1] = {self._drawable, layer=layer}
        end
        _G.CurrentCanvas = c
    else
        _G.CurrentCanvas = {{self._drawable, layer=1},{self._drawable, layer=2},{self._drawable, layer=3}}
    end

  
    Canvas.DEFAULT_SHADER:Activate()
    setCanvas(_G.CurrentCanvas)


    if self.Shader then
        self.Shader:Activate()
    end
end

function Canvas:Deactivate()
    if self.Shader then
        self.Shader:Deactivate()
    end
    self.DEFAULT_SHADER:Deactivate()

    setCanvas(self._oldCanvas)
    
    _G.CurrentCanvas = self._oldCanvas
    self._oldCanvas = nil
end

function Canvas:Clone()
    local clone = Object.Clone(self)
    
    clone._drawable = love.graphics.newCanvas(clone._drawable:getWidth(),clone._drawable:getHeight(),3)
    clone:CopyFrom(self)

    return clone
end

-- function Canvas:CopyFrom(other, shader)
--     self._drawable:renderTo(function ()
--         if shader then shader:Activate() end
--         love.graphics.clear()
--         love.graphics.setColor(1,1,1)
--         love.graphics.draw(other._drawable, 0, 0)
--         if shader then shader:Deactivate() end
--     end)
-- end

function Canvas:CopyFrom(other, shader)
    -- Save the current canvas
    local previous = _G.CurrentCanvas
    
    -- Set this canvas as the active render target
    love.graphics.setCanvas({{self._drawable, layer=1},{self._drawable, layer=2},{self._drawable, layer=3}})
    
    if shader then 
        shader:Activate()
    else
        Canvas.DEFAULT_SHADER:Activate()
    end
    
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(other._drawable, 0, 0)
    if shader then 
        shader:Deactivate()
    else
        Canvas.DEFAULT_SHADER:Deactivate()
    end
    
    -- Restore the previous canvas
    love.graphics.setCanvas(_G.CurrentCanvas)
end

function Canvas:Record(numFrames, outputPath)
    Chexcore.RecordCanvas(self, numFrames, outputPath)
end

function Canvas:RecordMatMap(numFrames, outputPath)
    Chexcore.RecordCanvasMatMap(self, numFrames, outputPath)
end

return Canvas