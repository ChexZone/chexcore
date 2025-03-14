local Scene = {
    -- properties
    
    -- CHILDREN represent the Scene's Layers. Layers are added/removed
    -- via Adopt() and Disown() methods.

    Name = "Scene",
    Active = true,           -- A Scene only updates when it's active
    Visible = true,          -- A Scene only renders when it's visible
    MasterCanvas = nil,      -- The final canvas rendered to the screen
    Camera = Camera.new(),   -- Created in constructor
    DrawSize = V{640, 360},-- Created in constructor

    -- internal properties
    _super = "Object",      -- Supertype
    _global = true
}
if love._console == "3ds" then
    Scene.DrawSize = V{400,240}
end

function Scene.new(properties)
    local newScene = Scene:SuperInstance()
    
    if properties then
        for k, v in pairs(properties) do
            newScene[k] = v
        end
    end

    newScene.Camera = newScene.Camera or Scene.Camera:Clone()
    newScene.DrawSize = newScene.DrawSize or Scene.DrawSize:Clone()
    newScene.MasterCanvas = newScene.MasterCanvas or Canvas.new(newScene.DrawSize.X, newScene.DrawSize.Y):AddProperties{AlphaMode = "premultiplied"}

    return Scene:Connect(newScene)
end

-- default update pipeline for a Scene
function Scene:Update(dt)
    for layer in self:EachChild() do
        layer:Update(dt)
    end

    if self.Camera.Update then
        self.Camera:Update(dt)
    end
end

-- the default rendering pipeline for a Scene
local lg = love.graphics
function Scene:Draw(params)
    
    local usingCanvases = false
    -- go through all the Layers uh... think about it chex !!
    local tx, ty = self.Camera.Position:Filter(math.floor)()

    if params.screen then
        -- for love potion
        for layer in self:EachChild("Screen", params.screen) do
            layer:Draw(tx, ty)
            if layer.Canvases then
                usingCanvases = true
            end
        end
    else
        for layer in self:EachChild() do
            layer:Draw(tx, ty)
            if layer.Canvases then
                usingCanvases = true
            end
        end
    end
    
    -- we use this later
    local windowSize = V{lg.getDimensions()}

    -- make sure the MasterCanvas exists (lazy solution for now)
    self.MasterCanvas = self.MasterCanvas or Canvas.new(self.DrawSize.X, self.DrawSize.Y):AddProperties{AlphaMode = "premultiplied"}
    
    if self.MasterCanvas:GetSize() ~= self.DrawSize then
        self.MasterCanvas = Canvas.new(self.DrawSize.X, self.DrawSize.Y):AddProperties{AlphaMode = "premultiplied"}
    end
    
    if usingCanvases then
        local canvasSize = self.MasterCanvas:GetSize()

        -- render all layers to the MasterCanvas
        self:CombineLayers()

        -- draw the MasterCanvas
    
        local canvasRatio, windowRatio = canvasSize.X / canvasSize.Y, windowSize.X / windowSize.Y
        local scaleByWidth = canvasRatio > windowRatio
        local pixelWidth = scaleByWidth and windowSize.X or windowSize.Y * canvasRatio
        local pixelHeight = scaleByWidth and windowSize.X/canvasRatio or windowSize.Y

        -- claim render space and draw
        lg.setCanvas()
        lg.setColor(1,1,1,1)
        self.MasterCanvas:DrawToScreen(windowSize.X/2, windowSize.Y/2, 0, pixelWidth, pixelHeight, 0.5, 0.5)
    end
end

-- the default implementation of layer combination for the MasterCanvas. No I/O, just apply all the Layers to Canvases
function Scene:CombineLayers()
    self.MasterCanvas:Activate()
    lg.clear()
    lg.setColor(1,1,1,1)

    -- collect a list of all Canvases from all Layers
    local masterCanvasSize = self.MasterCanvas:GetSize()
    for layer in self:EachChild() do
        if layer.Canvases then
            if layer.Shader then layer.Shader:Activate() end
            for _, canvas in ipairs(layer.Canvases) do
                -- canvases[#canvases+1] = canvas
                        -- by default, we'll just stretch each Canvas to fit the MasterCanvas. 
            -- maybe make this a property later ?
            local zoomInfluence = layer.Static and 0 or layer.ZoomInfluence
            canvas:DrawToScreen(
                masterCanvasSize.X/2,
                masterCanvasSize.Y/2, 0,
                masterCanvasSize.X + masterCanvasSize.X * (self.Camera.Zoom-1) * zoomInfluence,
                masterCanvasSize.Y + masterCanvasSize.Y * (self.Camera.Zoom-1) * zoomInfluence,
                0.5, 0.5
            )
            if layer.Shader then layer.Shader:Deactivate() end
            end
        end
    end


    self.MasterCanvas:Deactivate()
end

-- function aliases
Scene.AddLayer = Object.Adopt
Scene.RemoveLayer = Object.Disown
Scene.SwapLayers = Object.SwapChildOrder
Scene.GetLayer = Object.GetChild


return Scene