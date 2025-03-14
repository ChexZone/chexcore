local Tilemap = {
    -- properties
    Name = "Tilemap",           -- Easy identifier
    Atlas = nil,                -- Texture identifying the atlas
    Tiles = {},
    Layers = {{{}}},
    TileSize = 8,
    LayerParallax = {}, 
    LayerOffset = {},
    LayerColors = {},
    CollisionLayers = {},
    Solid = true,

    Scale = 1,

    SurfaceInfo = {
        --[[
            maps surface identifiers to real surface info
            EXAMPLE:

            Slab = {
                Bottom = {}, Top = {CollisionInset = 8}, Left = {}, Right = {}
            }
        ]]

        OnePixelHorizontalInset = {Left = {CollisionInset = 1}, Right = {CollisionInset = 1}},
        OnePixelVerticalInset = {Top = {CollisionInset = 1, Material = "Metal"}, Bottom = {CollisionInset = 1}},

        FourPixelHorizontalInset = {Left = {CollisionInset = 4}, Right = {CollisionInset = 4}},
        FourPixelVerticalInset = {Top = {CollisionInset = 4}, Bottom = {CollisionInset = 4}},

        SemisolidTop = {Bottom = {Passthrough = true}, Left = {Passthrough = true}, Right = {Passthrough = true}, Top = {Material = "Glass"}},
        SemisolidRight = {Bottom = {Passthrough = true}, Left = {Passthrough = true}, Top = {Passthrough = true}},
        SemisolidLeft = {Bottom = {Passthrough = true}, Right = {Passthrough = true}, Top = {Passthrough = true}},
        SemisolidBottom = {Left = {Passthrough = true}, Right = {Passthrough = true}, Top = {Passthrough = true}},

        RightEdge = {Left = {Passthrough = true}, Bottom = {Passthrough = true}, Top = {Passthrough = true}},

        Slab = {
            Bottom = {CollisionInset = 12}
        },

        SpringTop = {
            Bottom = {Passthrough = true}, 
            Left = {Passthrough = true}, 
            Right = {Passthrough = true},
            Top = {
                Passthrough = true,
                IsSpring = true,
                SpringPower = 8,
                ForceJumpHeldFrames = 60,
                RequiresActionReleased = false,
            },
        },

        Grass = {
            Top = {Material = "Grass"}
        },

        Glass = {
            Top = {Material = "Glass"}
        },

        Metal = {
            Top = {Material = "Metal"}, Left = {Material = "Metal"}, Right = {Material = "Metal"}, 
        },

        HalfTileTop = {
            Bottom = {
                CollisionInset = 8
            }
        },

        MiniTile = {
            Top = {CollisionInset = 4},
            Bottom = {CollisionInset = 4},
            Left = {CollisionInset = 4},
            Right = {CollisionInset = 4},
        },

        Ice = {
            Top = {Friction = 0.2, Material = "Glass", PreventJump = true, DustColor = V{1,1,1,0}},
            Left = {Material = "Glass"},
            Right = {Material = "Glass"},
        }
    },

    TileSurfaceMapping = {
        --[[
            maps tile IDs (from atlas) to surface identifiers
            EXAMPLE:

            [1] = "Slab"
        ]]
        [386] = "OnePixelHorizontalInset",
        [385] = "OnePixelVerticalInset",

        [358] = "Ice",
        [359] = "Ice",
        [361] = "Ice",
        [362] = "Ice",
        [363] = "Ice",

        [145] = "FourPixelHorizontalInset",
        [80] = "RightEdge",

        [273] = "SemisolidTop",
        [274] = "SemisolidTop",
        [275] = "SemisolidTop",

        [308] = "SemisolidRight",
        [340] = "SemisolidRight",
        [372] = "SemisolidRight",


        [304] = "SemisolidLeft",
        [336] = "SemisolidLeft",
        [368] = "SemisolidLeft",

        [401] = "SemisolidBottom",
        [402] = "SemisolidBottom",
        [403] = "SemisolidBottom",

        [214] = "SpringTop",

        [7] = "Grass", [8] = "Grass", [9] = "Grass",

        [289] = "Metal", [290] = "Metal",
        [321] = "Metal", [322] = "Metal",
        [353] = "Metal", [354] = "Metal",
        -- [385] = "Metal", [386] = "Metal",

        [266] = "Glass",

        [23] = "HalfTileTop", [55] = "HalfTileTop", 
        [142] = "HalfTileTop", [173] = "HalfTileTop", 

        [234] = "MiniTile"
    },

    -- internal properties
    _hasParallaxObjectLayers = false,   -- little optimization
    _numChunks = V{1, 1},
    _drawChunks = {},
    _chunkSize = 64, -- measured in tiles, not pixels
    _super = "Prop",      -- Supertype
    _cache = setmetatable({}, {__mode = "k"}), -- cache has weak keys
    _global = true
}

Tilemap._priorityGlobalUpdate = function (dt)
    for tilemap, _ in pairs(Tilemap._cache) do
        if tilemap._hasParallaxObjectLayers or tilemap.Position ~= tilemap._trackingOldPos then
            local camTilemapDist = tilemap:GetLayer():GetParent().Camera.Position - tilemap:GetPoint(0,0)
            
            if tilemap:HasChildren() then
                for group in tilemap:EachChild() do
                    
                    if group:HasChildren() and (group._parallax.X ~= 1 or group._parallax.X ~= 1) then
                        
                        for child in group:EachChild() do
                            if not child._tilemapOriginPoint then
                                child._tilemapOriginPoint = V{child.Position.X/(tilemap.TileSize*tilemap._dimensions[1]), child.Position.Y/(tilemap.TileSize*tilemap._dimensions[2])}
                            end
                            child.Position = tilemap.Position + (tilemap._dimensions * tilemap.TileSize) * child._tilemapOriginPoint + camTilemapDist * (-group._parallax+1)
                        end
                    end
                    
                end
            end
        end
        tilemap._trackingOldPos = tilemap.Position:Clone()
    end
end
--[[
    ex. usage
    local tilemap = Tilemap.new("atlasPath", 16, 128, 128) -- initializes a new 16px tile tilemap with 128x128 tiles
]]

local newQuad = love.graphics.newQuad
function Tilemap.new(atlasPath, tileSize, width, height, layers)
    local newTilemap = Tilemap:SuperInstance()
    
    newTilemap.Atlas = Texture.new(atlasPath)
    newTilemap.Tiles = {}
    newTilemap.LayerParallax = {}
    newTilemap.LayerOffset = {}
    newTilemap.CollisionLayers = {}
    newTilemap.ForegroundLayers = {}
    newTilemap.TileSize = tileSize

    newTilemap.Size[1] = width; newTilemap.Size[2] = height

    newTilemap._dimensions = V{width, height}
    
    if not layers then
        -- generate tiles
        newTilemap.Layers = {{}}
        local activeLayer = newTilemap.Layers[1]
        for i = 1, height do
            for j = 1, width do
                activeLayer[#activeLayer+1] = math.random(0,1)
            end
        end
    else
        newTilemap.Layers = layers
    end

    for i, _ in pairs(newTilemap.Layers) do
        newTilemap.CollisionLayers[i] = true
    end

    local rows, cols = newTilemap.Atlas:GetHeight()/tileSize, newTilemap.Atlas:GetWidth()/tileSize
    for row = 0, rows-1 do
        for col = 0, cols-1 do
            newTilemap.Tiles[#newTilemap.Tiles+1] = newQuad(col*tileSize, row*tileSize, tileSize, tileSize, cols*tileSize, rows*tileSize)
        end
    end

    setmetatable(newTilemap, Tilemap)

    -- set up canvases for segmented drawing
    newTilemap._drawChunks = {}
    newTilemap._numChunks = V{math.ceil(width/newTilemap._chunkSize), math.ceil(height/newTilemap._chunkSize)}

    newTilemap:GenerateChunks()

    
    Tilemap._cache[newTilemap] = true
    return newTilemap
end

function Tilemap:GetMap(n)
    return n and self.Layers[n] or self.Layers[1]
end

function Tilemap:DrawChunks(layer)
    for row = 1, self._numChunks[2] do
        for col = 1, self._numChunks[1] do
            if layer then self:DrawChunk(layer, col, row) else self:DrawChunk(col, row) end
        end
    end
end

function Tilemap:DrawChunk(layer, x, y)
    x, y, layer = y and x or layer, y or x, y and layer or nil
    for layerID = layer or 1, layer or #self.Layers do
        local currentChunk = self._drawChunks[layerID][x + (y-1)*self._numChunks[1]]
        currentChunk:Activate()
        love.graphics.clear()
        love.graphics.setColor(1,1,1,1)
        -- render this chunk's allotted tiles
        local yOfs = (y-1) * self._chunkSize + 1
        local xOfs = (x-1) * self._chunkSize + 1

        
        for ty = yOfs, math.min(yOfs + self._chunkSize - 1, self.Size[2]) do
            for tx = xOfs, math.min(xOfs + self._chunkSize - 1, self.Size[1]) do
                local tile = self:GetTile(layerID, tx, ty)
                --print(x,y, tile)
                if tile and tile > 0 then
                    cdrawquad(self.Atlas._drawable, self.Tiles[tile], self.TileSize, self.TileSize, (tx-xOfs)*self.TileSize, (ty-yOfs)*self.TileSize, 0, self.TileSize, self.TileSize)
                end
            end
        end

        currentChunk:Deactivate()
    end
end

function Tilemap:GenerateChunks()
    for layerID = 1, #self.Layers do
        self._drawChunks[layerID] = {}
        for col = 1, self._numChunks.X do
            for row = 1, self._numChunks.Y do
                self._drawChunks[layerID][#self._drawChunks[layerID]+1] = Canvas.new(
                    self._chunkSize * self.TileSize,
                    self._chunkSize * self.TileSize
                ):Properties{AlphaMode = "premultiplied"}
            end
        end
    end

    self:DrawChunks()
end

function Tilemap:GetTile(layer, x, y)
    x, y, layer = y and x or layer, y or x, y and layer or 1
    
    if x > self.Size[1] or y > self.Size[2] then
        return false
    else
        return self:GetMap(layer)[x + (y-1)*self.Size[1]]
    end
end

function Tilemap:SetTile(layer, x, y, val)
    x, y, layer, val = val and x or layer, val and y or x, val and layer or 1, val or y
    if x <= self.Size[1] and y <= self.Size[2] then
        self:GetMap(layer)[x + (y-1)*self.Size[1]] = val
        
        -- redraw the changed chunk
        self:DrawChunk(math.ceil(x/self._chunkSize), math.ceil(y/self._chunkSize))
    end
end

local floor = math.floor

local function drawLayer(self, layerID, camTilemapDist, sx, sy, ax, ay, tx, ty)

    local layer = self:GetLayer()
    local camera = layer:GetParent().Camera
    local cameraPos = camera.Position
    local cameraSize = layer.Canvases and (layer.Canvases[1]:GetSize() * layer.TranslationInfluence) * camera.Zoom or V{love.graphics.getDimensions()} * layer.TranslationInfluence * camera.Zoom

    love.graphics.setColor(self.Color * (self.LayerColors[layerID] or Constant.COLOR.WHITE))
    local parallaxX = self.LayerParallax[layerID] and self.LayerParallax[layerID][1] or 1
    local parallaxY = self.LayerParallax[layerID] and self.LayerParallax[layerID][2] or 1

    local offsetX = self.LayerOffset[layerID] and self.LayerOffset[layerID][1] or 0
    local offsetY = self.LayerOffset[layerID] and self.LayerOffset[layerID][2] or 0


    -- print(self, layerID)
    local leftChunkBound = 1
    local rightChunkBound = self._numChunks[1]
    local topChunkBound = 1
    local bottomChunkBound = self._numChunks[2]

    for row = 1, self._numChunks[2] do
        -- py is the ON-SCREEN y position of the top-right corner of the chunk
        local py = floor(self.Position[2] - ty + sy*(row-1) - ay + offsetY) + (camTilemapDist.Y) * (1 - parallaxY)

        local pyCamDist = camera.Position.Y - py
        
        local skipRow = false
        if py - cameraSize.Y/2 > cameraSize.Y/2 then -- this row is too low to be onscreen!!
            break -- we can just do this lol
        end
        if (py+sy) - cameraSize.Y/2 < -cameraSize.Y/2 then -- this row is too low to be onscreen!!
            skipRow = true
        end

        if not skipRow then
            for col = 1, self._numChunks[1] do
                -- px is the ON-SCREEN x position of the top-right corner of the chunk
                local px = floor(self.Position[1] - tx + sx*(col-1) - ax + offsetX) + (camTilemapDist.X) * (1 - parallaxX)
                
                local skipCol = false
                if px - cameraSize.X/2 > cameraSize.X/2 then -- this col is too low to be onscreen!!
                    break -- we can just do this lol
                end
                if (px+sx) - cameraSize.X/2 < -cameraSize.X/2 then -- this row is too low to be onscreen!!
                    skipCol = true
                end
                
                if not skipCol then
                    --print(row, col)
                    local currentChunk = self._drawChunks[layerID][col + (row-1)*self._numChunks[1]]
                    currentChunk:DrawToScreen(
                        px,
                        py,
                        self.Rotation,-- + Chexcore._clock,
                        sx, sy
                    )
                end
            end
        end
    end 
end

function Tilemap:Draw(tx, ty)
    if self.DrawOverChildren and self:HasChildren() then
        
        self:DrawChildren(tx, ty)
    end

    local sx = self._chunkSize * self.TileSize * self.Scale
    local sy = self._chunkSize * self.TileSize * self.Scale

    local ax, ay = self.Size[1]*self.TileSize*self.AnchorPoint[1]*self.Scale,
                   self.Size[2]*self.TileSize*self.AnchorPoint[2]*self.Scale

    
    local camTilemapDist = self:GetLayer():GetParent().Camera.Position - self:GetPoint(0,0)
    for layerID = 1, #self.Layers do
        if self.ForegroundLayers[layerID] then
            self:GetLayer():DelayDrawCall(self.ZIndex or 0, drawLayer, self, layerID, camTilemapDist, sx, sy, ax, ay, tx, ty)
        else
            drawLayer(self, layerID, camTilemapDist, sx, sy, ax, ay, tx, ty)
        end
    end

    if not self.DrawOverChildren and self:HasChildren() then
        self:DrawChildren(tx, ty)
    end
end

local function boxCollide(sLeftEdge,sRightEdge,sTopEdge,sBottomEdge,oLeftEdge,oRightEdge,oTopEdge,oBottomEdge)
    local hitLeft  = sRightEdge >= oLeftEdge
    local hitRight = sLeftEdge <= oRightEdge
    local hitTop   = sBottomEdge >= oTopEdge
    local hitBottom = sTopEdge <= oBottomEdge

    local hIntersect = hitLeft and hitRight
    local vIntersect = hitTop and hitBottom

    if hIntersect and vIntersect then

        local hDir, vDir, hFlag, vFlag
        if sLeftEdge >= oLeftEdge and sRightEdge <= oRightEdge then
            hDir = 0
        elseif sLeftEdge >= oLeftEdge then
            hDir = sLeftEdge - oRightEdge
            hFlag = true
        elseif sRightEdge <= oRightEdge then
            hDir = sRightEdge - oLeftEdge
            hFlag = true
        else
            hDir = false
        end

        if sTopEdge >= oTopEdge and sBottomEdge <= oBottomEdge then
            vDir = 0
        elseif sTopEdge >= oTopEdge then
            vDir = sTopEdge - oBottomEdge
            vFlag = true
        elseif sBottomEdge <= oBottomEdge then
            vDir = sBottomEdge - oTopEdge
            vFlag = true
        else
            vDir = false
        end

        if (hDir == 0 and hFlag) or (vDir == 0 and vFlag) then
            return false
        end

        return true, hDir, vDir
    end

    return false
end

local function getInfo(self, other, ss)
    if not self.Solid then return false end

    local sp, op = self.Position, other.Position
    local sap, oap = self.AnchorPoint, other.AnchorPoint
    local os = other.Size
    local sLeftEdge  = floor(sp[1] - ss[1] * sap[1])
    local sRightEdge = floor(sp[1] + ss[1] * (1 - sap[1]))
    local sTopEdge  = floor(sp[2] - ss[2] * sap[2])
    local sBottomEdge = floor(sp[2] + ss[2] * (1 - sap[2]))
    local oLeftEdge  = floor(op[1] - os[1] * oap[1])
    local oRightEdge = floor(op[1] + os[1] * (1 - oap[1]))
    local oTopEdge  = floor(op[2] - os[2] * oap[2])
    local oBottomEdge = floor(op[2] + os[2] * (1 - oap[2]))

    local success = boxCollide(sLeftEdge,sRightEdge,sTopEdge,sBottomEdge, oLeftEdge,oRightEdge,oTopEdge,oBottomEdge)

    return success, sLeftEdge,sRightEdge,sTopEdge,sBottomEdge, oLeftEdge,oRightEdge,oTopEdge,oBottomEdge
end

local function getSelfInfo(self, ss)

    local sp = self.Position
    local sap = self.AnchorPoint
    local sLeftEdge  = floor(sp[1] - ss[1] * sap[1])
    local sRightEdge = floor(sp[1] + ss[1] * (1 - sap[1]))
    local sTopEdge  = floor(sp[2] - ss[2] * sap[2])
    local sBottomEdge = floor(sp[2] + ss[2] * (1 - sap[2]))



    return sLeftEdge,sRightEdge,sTopEdge,sBottomEdge
end


function Tilemap:CollisionInfo(other, preference)
    local tilemapSize = self.Size*self.TileSize*self.Scale
    local success, sLeftEdge,sRightEdge,sTopEdge,sBottomEdge,
                   oLeftEdge,oRightEdge,oTopEdge,oBottomEdge = getInfo(self, other, tilemapSize)
    if not success then
        return false
    else
        local hitInfo = {}
        local camTilemapDist = self:GetLayer():GetParent().Camera.Position - self:GetPoint(0,0)
        for layerID, _ in ipairs(self.Layers) do   if self.CollisionLayers[layerID] then
            local parallaxX = self.LayerParallax[layerID] and self.LayerParallax[layerID][1] or 1
            local parallaxY = self.LayerParallax[layerID] and self.LayerParallax[layerID][2] or 1
    
            local offsetX = self.LayerOffset[layerID] and self.LayerOffset[layerID][1] or 0
            local offsetY = self.LayerOffset[layerID] and self.LayerOffset[layerID][2] or 0
            local realLeftEdge = sLeftEdge + (camTilemapDist.X) * (1 - parallaxX) + offsetX
            local realTopEdge = sTopEdge + (camTilemapDist.Y) * (1 - parallaxY) + offsetY

            local sWidth = sRightEdge - sLeftEdge
            local sHeight = sBottomEdge - sTopEdge
            local diffX = oLeftEdge - realLeftEdge
            local diffY = oTopEdge - realTopEdge
            local progX, progY = diffX/sWidth, diffY/sHeight
            
            local xStart = math.max(math.ceil(progX * self.Size[1]),1)
            local yStart = math.max(math.ceil(progY * self.Size[2]),1)
            
            diffX = oRightEdge - realLeftEdge
            diffY = oBottomEdge - realTopEdge
            progX, progY = math.min(diffX/sWidth, 1), math.min(diffY/sHeight, 1)

            local xEnd = math.ceil(progX * self.Size[1]) 
            local yEnd = math.ceil(progY * self.Size[2])

            local realTileX = tilemapSize[1]/self.Size[1]
            local realTileY = tilemapSize[2]/self.Size[2]
            
            local boxLeft, boxRight, boxTop, boxBottom, tileID

            local storeHit, storeHDist, storeVDist

                
                for x = xStart, xEnd do 
                    for y = yStart, yEnd do

                        tileID = self:GetTile(layerID, x, y)

                        local tileSurface = self.SurfaceInfo[self.TileSurfaceMapping[tileID]] or self._surfaceInfo
                        


                        if (tileID or 0) > 0 then
                            -- print(tileID)
                            boxLeft = realLeftEdge + realTileX * (x-1)     + ((tileSurface.Left or self._surfaceInfo.Left).CollisionInset or 0)
                            boxRight = realLeftEdge + realTileX * (x)      - ((tileSurface.Right or self._surfaceInfo.Right).CollisionInset or 0)
                            boxTop = realTopEdge + realTileY * (y-1)       + ((tileSurface.Top or self._surfaceInfo.Top).CollisionInset or 0)
                            boxBottom = realTopEdge + realTileY * (y)      - ((tileSurface.Bottom or self._surfaceInfo.Bottom).CollisionInset or 0)

                            local hit, hDist, vDist = boxCollide(boxLeft,boxRight,boxTop,boxBottom,oLeftEdge,oRightEdge,oTopEdge,oBottomEdge)


                            if hit then
                                -- local tileNo = 
                                hitInfo[#hitInfo+1] = {hDist, vDist, tileID, (x + (y-1)*self.Size[1]), layerID}
                            end
                        end
                    end
                end
            end;  end
        if #hitInfo > 0 then
            return hitInfo
        end
    end
end

local ceil = math.ceil
function Tilemap:GetTileCoordinatesFromIndex(i)
    local y = ceil(i / self.Size.X)
    local x = (i - 1) % self.Size.X + 1
    return x, y
end

-- Tilemap:GetEdge(edge): same as Prop:GetEdge(edge)
-- Tilemap:GetEdge(x, y, tileLayer): Gets the edge of a specific tile 
local Prop = Prop
function Tilemap:GetEdge(edge, x, y, layerID)
    if not (x or y or layerID) then
        -- Tilemap:GetEdge(edge)
        return Prop.GetEdge(self, edge)
    end
    if not layerID then
        -- Tilemap:GetEdge(edge, tileNo, tileLayer)
        layerID = y
        x, y = self:GetTileCoordinatesFromIndex(x)
    end

    -- Tilemap:GetEdge(edge, x, y, tileLayer)
    local camTilemapDist = self:GetLayer():GetParent().Camera.Position - self:GetPoint(0,0)
    local tilemapSize = self.Size*self.TileSize*self.Scale
    local sLeftEdge,_,sTopEdge,_ = getSelfInfo(self, tilemapSize)
    local parallaxX = self.LayerParallax[layerID] and self.LayerParallax[layerID][1] or 1
    local parallaxY = self.LayerParallax[layerID] and self.LayerParallax[layerID][2] or 1

    local offsetX = self.LayerOffset[layerID] and self.LayerOffset[layerID][1] or 0
    local offsetY = self.LayerOffset[layerID] and self.LayerOffset[layerID][2] or 0
    local realLeftEdge = sLeftEdge + (camTilemapDist.X) * (1 - parallaxX) + offsetX
    local realTopEdge = sTopEdge + (camTilemapDist.Y) * (1 - parallaxY) + offsetY


    local realTileX = tilemapSize[1]/self.Size[1]
    local realTileY = tilemapSize[2]/self.Size[2]

    local tileID = self:GetTile(layerID, x, y)
    local tileSurface = self.SurfaceInfo[self.TileSurfaceMapping[tileID]] or self._surfaceInfo
    local boxLeft = realLeftEdge + realTileX * (x-1)     + ((tileSurface.Left or self._surfaceInfo.Left).CollisionInset or 0)
    local boxRight = realLeftEdge + realTileX * (x)      - ((tileSurface.Right or self._surfaceInfo.Right).CollisionInset or 0)
    local boxTop = realTopEdge + realTileY * (y-1)       + ((tileSurface.Top or self._surfaceInfo.Top).CollisionInset or 0)
    local boxBottom = realTopEdge + realTileY * (y)      - ((tileSurface.Bottom or self._surfaceInfo.Bottom).CollisionInset or 0)

    return edge == "top" and boxTop
        or edge == "left" and boxLeft
        or edge == "right" and boxRight
        or edge == "bottom" and boxBottom
end

function Tilemap.import(tiledPath, atlasPath, properties)
    tiledPath = tiledPath or "game.scenes.testzone.tilemap"
    local tiled_export = require(tiledPath) --.layers[1].data

    local rows = tiled_export.height
    local cols = tiled_export.width

    local tileSize = tiled_export.tilewidth
    
    
    local newTilemap = Tilemap.new(atlasPath, tileSize, cols, rows)

    if properties then newTilemap:Properties(properties) end

    local objectsIndex = {} -- stores each created object by its id
    local connectionQueue = {} -- formatted {namespace, propertyName, objID}
    local n = 0
    for tiledLayerID, layer in ipairs(tiled_export.layers) do
        if layer.type == "tilelayer" then
            n = n + 1
            newTilemap.LayerParallax[n] = V{layer.parallaxx or 1, layer.parallaxy or 1}
            newTilemap.LayerOffset[n] = V{layer.offsetx or 0, layer.offsety or 0}

            if layer.properties then
                newTilemap.CollisionLayers[n] = not layer.properties.IgnoreCollision
                newTilemap.ForegroundLayers[n] = layer.properties.Foreground
            end

            if layer.tintcolor then
                newTilemap.LayerColors[n] = (V{layer.tintcolor[1], layer.tintcolor[2], layer.tintcolor[3]}/255):AddAxis(layer.opacity)
            else
                newTilemap.LayerColors[n] = V{1, 1, 1, layer.opacity}
            end

            newTilemap.Layers[n] = layer.data

        elseif layer.objects then
            local objLayerGroup = newTilemap:Adopt(Group.new{Solid = true, _parallax = V{layer.parallaxx or 1, layer.parallaxy or 1}})

            if layer.parallaxx ~= 1 or layer.parallaxy ~= 1 then
                newTilemap._hasParallaxObjectLayers = true
            end

            local isForegroundLayer
            if layer.properties then
                isForegroundLayer = layer.properties.Foreground
            end

            for _, objData in ipairs(layer.objects) do
                local class = objData.type ~= "" and objData.type or "Prop"
                
                if not Chexcore._types[class] then
                    print("COULDN'T IMPORT TILEMAP OBJECT: No class '"..class.."'")
                else
                    if objData.shape == "text" then class = "Text" end
                    local newObj = objLayerGroup:Adopt(Chexcore._types[class].new():Properties{
                        Position = V{objData.x, objData.y} * newTilemap.Scale,
                        Size = V{objData.width, objData.height} * newTilemap.Scale,
                        Name = objData.name,
                        -- Visible = true,
                        DrawInForeground = isForegroundLayer
                    })

                    

                    if objData.type == "" then
                        newObj.Color = V{1,1,1,0}
                    end

                    if objData.shape == "point" then
                        newObj.Size = V{0,0}
                    end
                    
                    -- correct for Tiled having (0, 1) AnchorPoint
                    newObj.Position.X = newObj.Position.X + newObj.Size.X * newObj.AnchorPoint.X
                    

                    -- print(newObj, newObj.AnchorPoint)

                    if objData.gid then
                        print(newObj, "1",  newObj.Size.Y * (newObj.AnchorPoint.Y), newObj.Position)
                        newObj.Position.Y = newObj.Position.Y - newObj.Size.Y * (1-newObj.AnchorPoint.Y)
                    else
                        print(newObj, "2")
                        newObj.Position.Y = newObj.Position.Y + newObj.Size.Y * newObj.AnchorPoint.Y
                    end

                    objectsIndex[objData.id] = newObj

                    if objData.properties then
                        local namespace = newObj
                        for k, v in pairs(objData.properties) do

                            if k:find("__") then
                                -- creating a new object
                                local out = k:split("__")
                                local type, fields = out[1], out[2]:split("%.")

                                local cSpace = namespace
                                for i = 1, #fields-1 do
                                    cSpace[fields[i]] = cSpace[fields[i]] or {}
                                    cSpace = cSpace[fields[i]]
                                end
                                local typeMT = _G[type] or Chexcore._types[type]
                                cSpace[fields[#fields]] = setmetatable(cSpace[fields[#fields]] or {}, typeMT)

                                for k2, v2 in pairs(cSpace[fields[#fields]]) do
                                    cSpace[fields[#fields]][k2] = nil
                                    cSpace[fields[#fields]][k2] = v2
                                end
                            else
                                -- filling a property
                                local fields = k:split("%.")
                                local cSpace = namespace
                                for i = 1, #fields-1 do
                                    cSpace[fields[i]] = cSpace[fields[i]] or {}
                                    cSpace = cSpace[fields[i]]
                                end

                                if type(v) == "table" then
                                    -- we'll set the references at the end
                                    connectionQueue[#connectionQueue+1] = cSpace
                                    connectionQueue[#connectionQueue+1] = fields[#fields]
                                    connectionQueue[#connectionQueue+1] = v.id
                                else
                                    cSpace[fields[#fields]] = v
                                end
                                
                                -- print(cSpace)
                            end
                            -- newObj[k] = v
                        end
                        newObj._tilemapOriginPoint = V{newObj.Position.X/(newTilemap.TileSize*newTilemap._dimensions[1]), newObj.Position.Y/(newTilemap.TileSize*newTilemap._dimensions[2])}
                    
                        -- newObj.Visible = rawget(newObj, "Visible") or false
                    end

                    if objData.shape == "text" then
                        newObj.FontSize = objData.pixelsize or 16
                        newObj.Text = objData.text
                        newObj.TextColor = objData.color and V(objData.color)/255 or Constant.COLOR.BLACK
                        newObj.Font = (objData.properties and objData.properties.Font and Font.new(objData.properties.Font, objData.pixelsize or 16)) or Font._paths[objData.fontfamily] and Font.new(Font._paths[objData.fontfamily], objData.pixelsize or 16) or nil
                        newObj.WordWrap = objData.wrap or false
                        newObj.AlignMode = objData.halign or nil


                    end

                    
                end
            end
        end
    end

    -- make those object references
    for i = 1, #connectionQueue, 3 do
        connectionQueue[i][connectionQueue[i+1]] = objectsIndex[connectionQueue[i+2]]
    end


    newTilemap:GenerateChunks()

    

    tiled_export = nil
    collectgarbage("collect")

    return newTilemap
end

function Tilemap:GetSurfaceInfo(tileID)
    local tileSurface = self.SurfaceInfo[self.TileSurfaceMapping[tileID]]

    return tileSurface and {
        Left = tileSurface.Left or self._surfaceInfo.Left,
        Right = tileSurface.Right or self._surfaceInfo.Right,
        Top = tileSurface.Top or self._surfaceInfo.Top,
        Bottom = tileSurface.Bottom or self._surfaceInfo.Bottom
    } or self._surfaceInfo
end

return Tilemap