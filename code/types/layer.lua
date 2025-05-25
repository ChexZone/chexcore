local Layer = {
    -- properties

    Name = "Layer",
    Canvases = nil,         -- table of renderable canvases, created in constructor
    TranslationInfluence = 1,
    ZoomInfluence = 1,
    AutoClearCanvas = true,
    Static = false,         -- whether the top left corner of the canvas sits at V{0, 0} or not

    RenderCulling = false,  -- whether to cull offscreen objects. This changes how the Render order functions:
                           -- when false, the Layer will use old Chexcore handoff-style render order, where Props call Draw() methods on their own children.
                           -- when  true, the Layer will cull offscreen objects, then sort by the ZIndex then PropID. Similar, but not quite the same.

    Screen = "left",

    _collisionPartitionSize = 150, -- how many pixels (width*height) make up a square collision partition. 
                                   -- Bigger partitions mean less memory footprint, but more CPU usage in densely populated areas.
                                   -- So in theory, this value should be smaller the more densely packed objects are.

    _collisionPartitions = {},     -- hashtable of used partitions. Created in constructor.


    -- internal properties
    _delayedDrawcalls = {}, -- created in constructor
    _super = "Object",      -- Supertype
    _global = true
}

function Layer.new(properties, width, height, static)
    local newLayer = Layer:SuperInstance()
    if type(properties) == "table" then
        for prop, val in pairs(properties) do
            newLayer[prop] = val
        end
    elseif type(properties) == "string" then
        newLayer.Name = properties
        
        if width and height then
            newLayer.Canvases = { Canvas.new(width, height) }
        end
    end

    newLayer.Static = static or newLayer.Static
    -- newLayer.Canvases = newLayer.Canvases or {}
    newLayer._delayedDrawcalls = {}


    -- set up the collision partition container. new partitions are automatically generated when queried the first time
    newLayer._collisionPartitions = setmetatable({}, {
        __index = function(t, k)
            local new = {}
            rawset(t, k, new)
            return new
        end
    })

    return Layer:Connect(newLayer)
end

-- default update pipeline for a Layer
function Layer:Update(dt)
    -- loop through each child
    for child in self:EachDescendant("Active", true) do
        child:Update(dt)
    end
end


function Layer:SignalAdoption(child)
    self:SetPartitions(child)
    return Object.SignalAdoption(self, child)
end


function Layer:PartitionCoordAt(x, y)
    return math.floor(x / self._collisionPartitionSize), math.floor(y / self._collisionPartitionSize)
end

local function key(x, y)
    return x .. "_" .. y
end

function Layer:SetPartitions(child)
    local topLeft = child:GetPoint(0,0)
    local bottomRight = child:GetPoint(1,1)


    if child:IsA("LightSource") then
        local rad = child.Radius
        topLeft[1] = topLeft[1] - rad
        topLeft[2] = topLeft[2] - rad
        bottomRight[1] = bottomRight[1] + rad
        bottomRight[2] = bottomRight[2] + rad
    end

    -- just in case size is negative or rotated weird
    if topLeft[1] > bottomRight[1] then
        topLeft[1], bottomRight[1] = bottomRight[1], topLeft[1]
    end

    if topLeft[2] > bottomRight[2] then
        topLeft[2], bottomRight[2] = bottomRight[2], topLeft[2]
    end

    local partitionTLX, partitionTLY = self:PartitionCoordAt(topLeft[1], topLeft[2])
    local partitionBRX, partitionBRY = self:PartitionCoordAt(bottomRight[1], bottomRight[2])
    
    -- see if the partitions changed at all
    if  partitionTLX ~= child._partitionTLX or partitionTLY ~= child._partitionTLY or partitionBRX ~= child._partitionBRX or partitionBRY ~= child._partitionBRY then
        -- print("SETTING PARTITION FOR " .. tostring(child) .. " TO " .. tostring(V{partitionTLX, partitionTLY}) .. " to " .. tostring(V{partitionBRX, partitionBRY}) .. " from " .. tostring(topLeft) .. " and " .. tostring(bottomRight))

        -- erase object from its original partitions
        for x = child._partitionTLX or 0, child._partitionBRX or 0 do
            for y = child._partitionTLY or 0, child._partitionBRY or 0 do
                self._collisionPartitions[key(x, y)][child] = nil
            end
        end

        -- generate new partitions
        for x = partitionTLX or 0, partitionBRX or 0 do
            for y = partitionTLY or 0, partitionBRY or 0 do
                self._collisionPartitions[key(x, y)][child] = true
            end
        end



        child._partitionTLX, child._partitionTLY, child._partitionBRX, child._partitionBRY = partitionTLX, partitionTLY, partitionBRX, partitionBRY
    end
    -- print()
end


-- NOTE:
-- Because right now, PARTITIONS ARE HASH-BASED, not array-based, it's possible for this function to return objects in an arbitrary order.
-- It will always return objects in order of partition (top-left to bottom-right) but within partitions can be arbitrary. Should this become an issue,
-- it would be possible to ensure that partitions are filled out in order, but at the cost of the light memory footprint of the current system.
-- UPDATE TO ABOVE: silly boy, you just sort the table afterwards!
local sort = table.sort
local posCompareX = function(a, b)
    return a.Position[1] < b.Position[1]
end
function Layer:GetCollisionCandidates(arg1, arg2, arg3)
    local tlx, tly, brx, bry, sortFunc
    if arg1:IsA("Vector") then
        -- Layer:GetCollisionCandidates(topLeft, bottomRight, sortFunc)
        tlx, tly = self:PartitionCoordAt(arg1[1], arg1[2])
        brx, bry = self:PartitionCoordAt(arg2[1], arg2[2])
        sortFunc = arg3 or posCompareX
    else
        -- Layer:GetCollisionCandidates(child, sortFunc)
        self:SetPartitions(arg1) -- for good measure;
        tlx, tly = arg1._partitionTLX or 0, arg1._partitionTLY or 0
        brx, bry = arg1._partitionBRX or 0, arg1._partitionBRY or 0
        sortFunc = arg2 or posCompareX
    end

    
    
    local seen = {} -- track which candidates have already been added
    local candidates = {} -- this array is ORDERED!

    for x = tlx , brx do
        for y = tly, bry do
            for candidate in pairs(self._collisionPartitions[x .. "_" .. y]) do -- icky unpredictable pairs... but we sort it right after
                if not seen[candidate] then
                    seen[candidate] = true
                    candidates[#candidates+1] = candidate
                end
            end
        end
    end

    sort(candidates, sortFunc)
    return candidates
end


local function renderSort(a, b)
    if a.ZIndex ~= b.ZIndex then
        return a.ZIndex < b.ZIndex
    else
        return a._propID < b._propID
    end
end


-- the default rendering pipeline for a Layer
local lg = love.graphics
function Layer:Draw(tx, ty)
    -- tx, ty: translation values from camera (layers are responsible for handling this)

    -- default implementation is to draw all children to Canvases[1]
    if self.Canvases then
        self.Canvases[1]:Activate()
        if self.AutoClearCanvas then
            lg.clear()
        end
    end
    
    -- love.graphics.setColor(1,1,1,1)
    -- love.graphics.rectangle("fill", 0, 0, 1920,1080)

    local centerX, centerY
    if self.Canvases then
        centerX = self.Canvases[1]:GetWidth()/2
        centerY = self.Canvases[1]:GetHeight()/2
    else
        centerX = love.graphics.getWidth()/2
        centerY = love.graphics.getHeight()/2
    end

    if self.Static then
        tx, ty = 0, 0
    elseif type(self.TranslationInfluence) == "table" then
        tx = tx * self.TranslationInfluence[1] - centerX
        ty = ty * self.TranslationInfluence[2] - centerY
    else
        tx = tx * self.TranslationInfluence - centerX
        ty = ty * self.TranslationInfluence - centerY
    end
    
    if self.RenderCulling then
    ----------------------------------------------------------- NEW STYLE (OFFSCREEN CULLING) --------------------------------------------------
        local ofs = self.Canvases[1]:GetSize()
        
        

        for i, prop in ipairs(self:GetCollisionCandidates(V{tx - ofs.X, ty - ofs.Y}, V{tx + ofs.X, ty + ofs.Y}, renderSort)) do
            if prop.Visible then
                if prop.DrawInForeground then
                    self:DelayDrawCall(prop.ZIndex or 0, prop.Draw, prop, tx, ty, true)
                else
                    prop:Draw(tx, ty)
                end
            end
        end


    ----------------------------------------------------------- OLD STYLE (NO CULLING) --------------------------------------------------
    else
        -- loop through each Visible child
        for child in self:EachChild() do
            if child.Visible then
                if child.DrawInForeground then
                    self:DelayDrawCall(child.ZIndex or 0, child.Draw, child, tx, ty, true)
                else
                    child:Draw(tx, ty)
                end
                
            elseif child.DrawChildren then
                -- i don't know if this will work
                if child.DrawInForeground then
                    
                    self:DelayDrawCall(child.ZIndex or 0, child.DrawChildren, child, tx, ty)
                else
                    child:DrawChildren(tx, ty)
                end
            end
        end


    end
    ----------------------------------------------------------------------------------------------------------------------------------------

        -- catch any DelayDrawCall calls
        local delayedCallsList = {}
        for priority in pairs(self._delayedDrawcalls) do
            delayedCallsList[#delayedCallsList+1] = priority
        end
        table.sort(delayedCallsList)

        for _, priority in ipairs(delayedCallsList) do
            local callPairs = self._delayedDrawcalls[priority]
            for i = 1, #callPairs, 2 do
                callPairs[i](unpack(callPairs[i+1]))
            end
        end


        self._delayedDrawcalls = {}
    if self.Canvases then self.Canvases[1]:Deactivate() end
end

-- a Prop can choose to delay its drawcall to be drawn after everything else in the Layer
function Layer:DelayDrawCall(priority, drawFunc, ...)
    local args = {...}
    
    self._delayedDrawcalls[priority] = self._delayedDrawcalls[priority] or {}
    local priorityTable = self._delayedDrawcalls[priority]
    priorityTable[#priorityTable+1] = drawFunc
    priorityTable[#priorityTable+1] = args
end


local In = Input
function Layer:GetMousePosition(canvasID)
    local normalizedPos, inWindow = In:GetMousePosition()
    local activeCanvasSize = self.Canvases and self.Canvases[canvasID or 1]:GetSize() or V{love.graphics.getDimensions()}
    local cameraPosition = self.Static and activeCanvasSize/2 or self._parent.Camera.Position
    local cameraZoom = self._parent.Camera.Zoom
    local translationInfluence = self.TranslationInfluence
    local zoomInfluence = self.Static and 0 or self.ZoomInfluence
    local masterCanvasSize = self._parent.MasterCanvas:GetSize()
    
    local realScreenSize = getWindowSize()

    local screenToMasterRatio = 1/(masterCanvasSize:Ratio()/realScreenSize:Ratio())

    -- change mouse position normalization from (0,1) to (-0.5, 0.5)
    normalizedPos = (normalizedPos - 0.5)

    if screenToMasterRatio > 1 then -- increase y range for horizontal black bars
        normalizedPos[2] = normalizedPos[2] * screenToMasterRatio
    elseif screenToMasterRatio < 1 then -- increase x range for vertical black bars
        normalizedPos[1] = normalizedPos[1] / screenToMasterRatio
    end

    -- now we can actually use the normalizedPos of the mouse to find a spot onscreen
    local cameraSize = activeCanvasSize / ((cameraZoom-1) * zoomInfluence + 1)
    local finalPos = (cameraPosition * translationInfluence) + (normalizedPos * cameraSize)

    return finalPos, inWindow
end

function Layer:PositionOnMasterCanvas(layerPos, canvasID)
    local activeCanvasSize = self.Canvases and self.Canvases[canvasID or 1]:GetSize() or V{love.graphics.getDimensions()}
    local cameraPosition = self.Static and (activeCanvasSize / 2) or self._parent.Camera.Position
    local translationInfluence = self.TranslationInfluence
    local masterCanvasSize = self._parent.MasterCanvas:GetSize()
    
    local realScreenSize = getWindowSize()
    local screenToMasterRatio = 1 / (masterCanvasSize:Ratio() / realScreenSize:Ratio())
    
    -- Here, we remove any camera zoom influence by using activeCanvasSize directly.
    local modNorm = (layerPos - (cameraPosition * translationInfluence)) / activeCanvasSize
    
    local norm = modNorm:Clone()
    if screenToMasterRatio > 1 then
        norm[2] = norm[2] / screenToMasterRatio
    elseif screenToMasterRatio < 1 then
        norm[1] = norm[1] * screenToMasterRatio
    end
    
    norm = norm + 0.5
    
    local masterPos = V{
        norm[1] * masterCanvasSize[1],
        norm[2] * masterCanvasSize[2]
    }
    
    return masterPos
end


return Layer