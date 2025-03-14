-- CHEXCORE EXAMPLE SCENE
local scene = Scene.new{
    FrameLimit =  150,
    selectedModeButton = nil,
}

love.mouse.setVisible(false)

local CANVAS_SIZE = V{1280, 720}
local BG_COLOR, BRUSH_COLOR = V{0.8,0.85,0.95,1}, V{0,0,0,1}
local MAX_HISTORY = 150
local lastDrawnPixel -- Vector
local rightClickOrigin -- Vector
local middleClickOrigin -- Vector
local cameraOrigin -- Vector
local cameraOriginZoom -- Vector
local cameraGoalZoom -- number
local cameraGoalPos -- Vector
local mouseWasPressed = false

local brushWidth = 1
local drawMode = "brush"

-- start with a Layer for the image:
local imageLayer = scene:Adopt( Layer.new("Image", CANVAS_SIZE.X, CANVAS_SIZE.Y) )

-- we'll use a Prop as a "canvas" to draw on:
local drawingCanvas = imageLayer:Adopt( Prop.new{
    Name = "DrawingCanvas",
    Size = CANVAS_SIZE:Clone(),
    Texture = Canvas.new( imageLayer.Canvases[1]:GetSize():Unpack() ),
    history = {},
    currentCanvas = 1,
    Position = imageLayer.Canvases[1]:GetSize()/2,
    DrawScale = V{1, 1},
    AnchorPoint = V{0.5, 0.5}
})

drawingCanvas.history[1] = drawingCanvas.Texture

-- initialize the canvas with a color:
drawingCanvas.Texture:Activate()
    love.graphics.setColor(BG_COLOR:Unpack())
    love.graphics.rectangle("fill", 0, 0, CANVAS_SIZE.X, CANVAS_SIZE.Y)
drawingCanvas.Texture:Deactivate()

scene.Camera.Position = CANVAS_SIZE/2

cameraGoalZoom = scene.Camera.Zoom
cameraGoalPos = scene.Camera.Position

function scene.Camera:Update(dt)
    cameraGoalZoom = math.clamp(cameraGoalZoom, 0.2, 100)
    self.Zoom = V{self.Zoom}:Lerp(V{cameraGoalZoom}, 30*dt)()
    self.Position = self.Position:Lerp(cameraGoalPos, 30*dt)
end



local guiLayer = Layer.new("GUI", 1280/2, 720/2, true):Nest(scene)

local one = V{1,1}

local dragger = Gui.new{
    active = false,
    originPos = nil,
    originMousePos = nil,
    timePressed = 0,
    drawChildren = true,
    goalRotation = 0,

    Size = V{64, 16},
    Position = V{300, 300},
    AnchorPoint = V{0.5, 1},
    Texture = Animation.new("chexcore/assets/images/grab_bar.png", 1, 3):Properties{
        Loop = false,
        LeftBound = 1,
        RightBound = 1
    },
    OnHoverStart = function (self)
        if not self.active then
            self.Texture:SetBounds(2)
        end
    end,
    OnHoverEnd = function (self)
        if not self.active then
            self.Texture:SetBounds(1)
        end
    end,
    OnSelectStart = function (self)
        self.Texture:SetBounds(3)
        self.active = true
        self.originPos = self.Position
        self.originMousePos = self:GetLayer():GetMousePosition()
    end,
    OnHoverWhileSelected = function (self)
        self:OnSelectStart()
    end,
    OnSelectEnd = function (self)
        self.Texture:SetBounds(1)
        self.active = false
        if self.timePressed < 0.3 and (self.originPos - self.Position):Magnitude() < 20 then
            self.Position = self.originPos
            self.drawChildren = not self.drawChildren
            self.DrawScale = V{1.2, 0.8}
        end
        self.timePressed = 0
    end,
    Update = function (self, dt)
        if self.active then
            self.timePressed = self.timePressed + dt
            local newPos = self.Position:Lerp(self.originPos + (self:GetLayer():GetMousePosition() - self.originMousePos), 50*dt)
            local xDiff = newPos.X - self.Position.X
            self.goalRotation = self.goalRotation + xDiff/500
            self.Position = newPos

            local size = guiLayer.Canvases[1]:GetSize()
            self:SetEdge("left", math.max(self:GetEdge("left"), 0))
            self:SetEdge("right", math.min(self:GetEdge("right"), size[1]))
            self:SetEdge("top", math.max(self:GetEdge("top"), 0))
            self:SetEdge("bottom", math.min(self:GetEdge("bottom"), size[2]))
        end

        self.DrawScale = self.DrawScale:Lerp(one, 5*dt)

        self.Rotation = math.lerp(self.Rotation, self.goalRotation, 25*dt, 0.005)
        self.goalRotation = math.lerp(self.goalRotation, 0, 20*dt, 0.005)
    end
}:Nest(guiLayer)


local v1, v2 = V{32, 32}, V{0,0}
local brushButton = Gui.new{
    selected = true,

    goalScale = V{1, 1},
    goalRotation = 0,
    lastSelectedButton = nil,

    Name = "BrushButton",
    Size = V{64, 64},
    RelativePosition = V{0.25, 2},
    AnchorPoint = V{0.5, 0.5},
    Texture = Animation.new("chexcore/assets/images/brush_button.png", 1, 8):Properties{
        Loop = false,
        Duration = 0.2,
        LeftBound = 6,
        RightBound = 6
    },

    Update = function (self, dt)
        self.DrawScale = self.DrawScale:Lerp(self.goalScale, 10*dt)
        self.Rotation = math.lerp(self.Rotation - dragger.Rotation, self.goalRotation, 15*dt) + dragger.Rotation
        -- if dragger.active or not self._init then self._init = true self.Position = dragger:GetPoint(self.RelativePosition()) end
        self.Position = dragger:GetPoint(self.RelativePosition())
        self.Size = self.Size:Lerp(dragger.drawChildren and v1 or v2, 20*dt)
    end,

    OnHoverStart = function (self)
        -- self.goalScale = V{0.95, 0.95}
        self.Texture:SetBounds(self.selected and 7 or 3)
    end,
    OnHoverEnd = function (self)
        self.goalScale = V{1, 1}
        self.Texture:SetBounds(self.selected and 6 or 2)
    end,
    OnSelectStart = function (self, button)
        if button == 1 then
            self.goalScale = V{0.9, 0.9}
            self.Texture:SetBounds(self.selected and 8 or 4)
        end
    end,
    OnHoverWhileSelected = function (self, button)
        self:OnSelectStart(button)
    end,
    OnSelectEnd = function (self, button)
        if button == 1 and self:IsUnderMouse() then
            if self.selected then
                if self.lastSelectedButton then
                    self.lastSelectedButton.selected = true
                    self.lastSelectedButton.lastSelectedButton = self
                    self.lastSelectedButton:ClickVisual()
                end
                self.selected = false
                scene.selectedModeButton = self.lastSelectedButton
            else
                self.selected = true
                if scene.selectedModeButton then
                    self.lastSelectedButton = scene.selectedModeButton
                    scene.selectedModeButton.selected = false
                    scene.selectedModeButton:ClickVisual()
                end
                scene.selectedModeButton = self
            end

            self:ClickVisual()
        end
    end,
    ClickVisual = function (self)
        self.Rotation = math.rad((math.random(0,2)-1)*10)
        if self.upsideDown then self.Rotation = self.Rotation + math.rad(180) end
        self.goalScale = V{1, 1}
        self.DrawScale = V{1.15, 1.15}
        if self.selected then
            self.Texture:SetBounds(5, 6)
            self.Texture:SetFrame(5)
        else
            self.Texture:SetBounds(1, 2)
            self.Texture:SetFrame(1)
        end
        self.Texture.IsPlaying = true
    end
}:Nest(dragger)
scene.selectedModeButton = brushButton




local eraseButton = brushButton:Clone(true):Properties{
    selected = false,
    Name = "EraseButton",
    RelativePosition = V{0.75, 2},
    Texture = Animation.new("chexcore/assets/images/erase_button.png", 1, 8):Properties{
        Loop = false,
        Duration = 0.2,
        LeftBound = 2,
        RightBound = 2
    },
}

local undoButton = brushButton:Clone(true):Properties{
    selected = false,
    Name = "UndoButton",
    RelativePosition = V{0.25, 4},
    Texture = Animation.new("chexcore/assets/images/undo_button.png", 1, 4):Properties{
        Loop = false,
        Duration = 0.2,
        LeftBound = 2,
        RightBound = 2
    },
    OnSelectEnd = function (self, button)
        if button == 1 and self:IsUnderMouse() then
            self:ClickVisual()
            drawingCanvas:ChangeCanvas(drawingCanvas.currentCanvas-1)
            drawingCanvas.DrawScale = V{1.025, 1.025}
            
            
        end
    end
}

local redoButton = undoButton:Clone(true):Properties{
    Name = "RedoButton",
    upsideDown = true,
    RelativePosition = V{0.75, 4},
    goalRotation = math.rad(180),
    Texture = Animation.new("chexcore/assets/images/undo_button.png", 1, 4):Properties{
        Loop = false,
        Duration = 0.2,
        LeftBound = 2,
        RightBound = 2
    },
    OnSelectEnd = function (self, button)
        if button == 1 and self:IsUnderMouse() then
            self:ClickVisual()
            drawingCanvas:ChangeCanvas(drawingCanvas.currentCanvas+1)
            drawingCanvas.DrawScale = V{1.05, 1.05}
        end
    end
}

-- local eraseButton = brushButton:Clone(true):Properties{
--     selected = false,
--     Name = "EraseButton",
--     Position = V{160, 32},
--     Texture = Animation.new("chexcore/assets/images/erase_button.png", 1, 8):Properties{
--         Loop = false,
--         Duration = 0.2,
--         LeftBound = 2,
--         RightBound = 2
--     },
-- }


local mouseLayer = scene:Adopt( Layer.new("Cursor", CANVAS_SIZE.X, CANVAS_SIZE.Y) ) -- specify the Name, and pixel width/height
mouseLayer.ZoomInfluence = 1

local cursor = mouseLayer:Adopt(Prop.new{
    Name = "Cursor",

    idleScale = V{1,1},
    pressedScale = V{.8, .8},
    goalColor = V{1, 0, 0.5, 0.5},

    AnchorPoint = V{0.5, 0.5},
    Size = V{16,16},
    Color =  V{3,1,1,0.2},
    Texture = Texture.new("chexcore/assets/images/crosshair.png"),
    Update = function(self, dt)
        self.Position = self.Position:Lerp(self:GetParent():GetMousePosition(), 1000*dt)
        -- self.Rotation = self.Rotation + dt

        self.Color = self.Color:Lerp(self.goalColor, 2*dt)

        if Input:IsDown("m_1") then
            self.DrawScale = self.DrawScale:Lerp(self.pressedScale, 10*dt)
        else
            self.DrawScale = self.DrawScale:Lerp(self.idleScale, 10*dt)
        end
    end
})

-- now that we have the cursor, we can use its position to draw stuff
function drawingCanvas:Update(dt)

    self.DrawScale = self.DrawScale:Lerp(one, 15*dt)

    local newMousePos = imageLayer:GetMousePosition()
  
    drawMode = scene.selectedModeButton == brushButton and "brush" or "erase"

    

    if Input:IsDown("m_1") and not Gui.UsingMouse() then
        
        drawingCanvas.Texture:Activate()
            love.graphics.setColor(drawMode == "brush" and BRUSH_COLOR or drawMode == "erase" and BG_COLOR)

            if Input:JustPressed("m_1") then
                
                cdrawcircle("fill", math.floor(lastDrawnPixel[1]), math.floor(lastDrawnPixel[2]), brushWidth)
            end
            
            cdrawlinethick(math.floor(lastDrawnPixel[1]), math.floor(lastDrawnPixel[2]), math.floor(newMousePos[1]), math.floor(newMousePos[2]), brushWidth)
            lastDrawnPixel = newMousePos
        drawingCanvas.Texture:Deactivate()
        mouseWasPressed = true
    else
        if mouseWasPressed then
            drawingCanvas:RecordChange()
        end
        mouseWasPressed = false
    end

    if Input:IsDown("m_2") then
        cameraGoalZoom = cameraOriginZoom + (rightClickOrigin - newMousePos).Y/100
    elseif Input:IsDown("m_3") then
        cameraGoalPos = cameraOrigin + (middleClickOrigin - newMousePos)
    end

    -- print(drawingCanvas.history, drawingCanvas.currentCanvas, drawingCanvas.history[drawingCanvas.currentCanvas] == drawingCanvas.Texture)
end

function drawingCanvas:RecordChange()
    self.currentCanvas = self.currentCanvas + 1

    
    self.history[self.currentCanvas] = self.Texture
    -- self.Texture = self.Texture:Clone()

    for i = self.currentCanvas + 1, #self.history do
        self.history[i] = nil
    end

    if #self.history > MAX_HISTORY then
        table.remove(self.history, 1)
        self.currentCanvas = self.currentCanvas - 1
    end

    
    self:ChangeCanvas(self.currentCanvas)
end

function drawingCanvas:ChangeCanvas(n)
    -- print(n)
    n = math.clamp(n, 1, #self.history)
    self.Texture = self.history[n]:Clone()
    self.currentCanvas = n
end


local keyResponses = { ["m_1"] = function()  lastDrawnPixel = imageLayer:GetMousePosition()  end,
                       ["m_2"] = function()
                            rightClickOrigin = imageLayer:GetMousePosition()
                            cameraOriginZoom = scene.Camera.Zoom
                        end,
                        ["m_3"] = function ()
                            middleClickOrigin = imageLayer:GetMousePosition()
                            cameraOrigin = scene.Camera.Position
                        end,
                        ["kp+"] = function()  cameraGoalZoom = cameraGoalZoom + 0.5  end,
                        ["kp-"] = function()  cameraGoalZoom = cameraGoalZoom - 0.5  end,
                        ["m_wheelup"] = function() cameraGoalZoom = cameraGoalZoom + 0.2  end,
                        ["m_wheeldown"] = function() cameraGoalZoom = cameraGoalZoom - 0.2  end,
                        ["e"] = function ()  drawMode = "erase"  end,
                        ["b"] = function ()  drawMode = "brush"  end,
                        ["c"] = function () cameraGoalPos = CANVAS_SIZE/2 end,
                        ["l"] = function () drawingCanvas:ChangeCanvas(drawingCanvas.currentCanvas-1) end,
                        ["r"] = function () drawingCanvas:ChangeCanvas(drawingCanvas.currentCanvas+1) end  }
scene.Input = Input.new()
function scene.Input:Press(device, key)
    if keyResponses[key] then keyResponses[key]() end
    if tonumber(key) then  brushWidth = tonumber(key)  end
    if key == "m_1" then
        cursor.goalColor.A = 0.2
        cursor.DrawScale = V{0.5, 0.5}
    end
end

function scene.Input:Release(device, key)
    if key == "m_1" then
        cursor.goalColor.A = 0.6
        cursor.DrawScale = V{1.5, 1.5}
    end
end

drawingCanvas:ChangeCanvas(1)


return scene