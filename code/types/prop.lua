local Prop = {
    -- properties
    Name = "Prop",

    Size = V{ 16, 16 },     -- created in constructor
    Position = V{ 0, 0 },   -- created in constructor
    Color = V{ 1, 1, 1, 1 },-- created in constructor; values range from 0-1
    AnchorPoint = V{ 0, 0 },-- created in constructor; values range from 0-1
    Rotation = 0,
    DrawScale = V{1, 1},    -- only works with AnchorPoint = V{0.5, 0.5}
    DrawOverChildren = false,
    Visible = true,         -- whether or not the Prop's :Draw() method is called
    Active = true,          -- whether or not the Prop's :Update() method is called
    Solid = false,          -- is the object collidable?
    Anchored = true,        -- follows its Parent ?

    

    Texture = Texture.new("chexcore/assets/images/square.png"),    -- default sample texture

    -- internal properties

    _surfaceInfo = { -- basic props generally have preset surface info
        Top = {
            CollisionInset = 0,
        },
        Bottom = {
            CollisionInset = 0,
        },
        Left = {
            CollisionInset = 0,
        },
        Right = {
            CollisionInset = 0,
        }
    },
    
    _super = "Object",      -- Supertype
    _global = true
}

-- constructor
local rg, V = rawget, V
function Prop.new(properties)
    local newProp = Prop._standardConstructor(properties)
    
    newProp.Position = rg(newProp, "Position") or V{ Prop.Position.X, Prop.Position.Y }
    newProp.Size = rg(newProp, "Size") or V{ Prop.Size.X, Prop.Size.Y }
    newProp.Color = rg(newProp, "Color") or V{ Prop.Color.X, Prop.Color.Y, Prop.Color.Z, Prop.Color.A }
    newProp.AnchorPoint = rg(newProp, "AnchorPoint") or V{ Prop.AnchorPoint.X, Prop.AnchorPoint.Y }
    newProp.DrawScale = rg(newProp, "DrawScale") or V{ Prop.DrawScale.X, Prop.DrawScale.Y }

    return newProp
end


function Prop:DrawChildren(tx, ty, isForeground)

    for _, child in ipairs(self._children) do
        -- if self:IsA("Group") then
        --     print(child, child.Visible)
        -- end
        if child.Visible then

            if not isForeground and child.DrawInForeground then
                self:GetLayer():DelayDrawCall(self.ZIndex or 1, child.Draw, child, tx, ty, true)
            else
                child:Draw(tx, ty)
            end
        end
    end
end

local sin, cos, abs, max, sqrt, floor = math.sin, math.cos, math.abs, math.max, math.sqrt, math.floor
local lg = love.graphics
function Prop:Draw(tx, ty, isForeground)
    
    -- if self.DrawInForeground and not isForeground then
    --     print(self)
    --     self:GetLayer():DelayDrawCall(Prop.Draw, self, tx, ty, true)
    --     return 
    -- end
    
    local oldshader
    if self.Shader then
        self.Shader:Activate()
    end
    if self.DrawOverChildren and self:HasChildren() then
        self:DrawChildren(tx, ty)
    end
    lg.setColor(self.Color)
    local sx = self.Size[1] * (self.DrawScale[1]-1)
    local sy = self.Size[2] * (self.DrawScale[2]-1)
    self.Texture:DrawToScreen(
        floor(self.Position[1] - tx),
        floor(self.Position[2] - ty),
        self.Rotation,
        self.Size[1] + sx,
        self.Size[2] + sy,
        self.AnchorPoint[1],
        self.AnchorPoint[2]
    )
    if not self.DrawOverChildren and self:HasChildren() then
        self:DrawChildren(tx, ty)
    end

    if self.Shader then
        self.Shader:Deactivate()
    end
end


function Prop:Update(dt)

end


local isA = Object.IsA
function Prop:GetLayer()
    return self:GetAncestor(isA, "Layer")
end

function Prop:GetScene()
    return self:GetAncestor(isA, "Scene")
end

-- quickly detect if the mouse is currently hovering over this prop
function Prop:IsUnderMouse()
    local mousePos = self:GetLayer():GetMousePosition()
    return self:DistanceFromPoint(mousePos) == 0
end

local d90 = math.rad(90)
function Prop:GetPoint(x, y)
    local v1 = Vector.FromAngle(self.Rotation) * (self.Size.X * (x - self.AnchorPoint.X))
    local v2 = Vector.FromAngle(self.Rotation + d90) * (self.Size.Y * (y - self.AnchorPoint.Y))
    return self.Position + v1 + v2
end

-- moves current object and all Anchored Descendants
function Prop:SetPosition(x, y)
    local dx = x - self.Position[1]
    local dy = y - self.Position[2]
    self.Position[1] = x
    self.Position[2] = y

    if self:HasChildren() then
        for child in self:EachDescendant(function(s)return s:IsA("Prop") and s.Anchored end) do
            child.Position[1] = child.Position[1] + dx
            child.Position[2] = child.Position[2] + dy
        end
    end
end

local getEdge = {
    left = function (self)
        return floor(self.Position[1] - self.Size[1] * self.AnchorPoint[1])
    end,
    right = function (self)
        return floor(self.Position[1] + self.Size[1] * (1 - self.AnchorPoint[1]))
    end,
    top = function (self)
        return floor(self.Position[2] - self.Size[2] * self.AnchorPoint[2])
    end,
    bottom = function (self)
        return floor(self.Position[2] + self.Size[2] * (1 - self.AnchorPoint[2]))
    end
}
function Prop:GetEdge(edge)
    return getEdge[edge](self)
end

local setEdge = {
    left = function (self, x)
        self.Position[1] = x + self.Size[1] * self.AnchorPoint[1]
    end,
    right = function (self, x)
        self.Position[1] = x - self.Size[1] * (1 - self.AnchorPoint[1])
    end,
    top = function (self, y)
        self.Position[2] = y + self.Size[2] * self.AnchorPoint[2]
    end,
    bottom = function (self, y)
        self.Position[2] = y - self.Size[2] * (1 - self.AnchorPoint[2])
    end
}
function Prop:SetEdge(edge, n)
    return setEdge[edge](self, n) -- left, right, top or bottom
end


-- only works with axis-aligned bounding boxes !! i dont feel like doing all that math
-- use Rays for weird rotatey collision idk
function Prop:CollidesAABB(other)
    if not self.Solid then return false end

    local sp, op = self.Position, other.Position
    local sap, oap = self.AnchorPoint, other.AnchorPoint
    local ss, os = self.Size, other.Size
    local sLeftEdge  = floor(sp[1] - ss[1] * sap[1])
    local sRightEdge = floor(sp[1] + ss[1] * (1 - sap[1]))
    local sTopEdge  = floor(sp[2] - ss[2] * sap[2])
    local sBottomEdge = floor(sp[2] + ss[2] * (1 - sap[2]))
    local oLeftEdge  = floor(op[1] - os[1] * oap[1])
    local oRightEdge = floor(op[1] + os[1] * (1 - oap[1]))
    local oTopEdge  = floor(op[2] - os[2] * oap[2])
    local oBottomEdge = floor(op[2] + os[2] * (1 - oap[2]))
    
    local hitLeft  = sRightEdge >= oLeftEdge
    local hitRight = sLeftEdge <= oRightEdge
    local hitTop   = sBottomEdge >= oTopEdge
    local hitBottom = sTopEdge <= oBottomEdge

    local hIntersect = hitLeft and hitRight
    local vIntersect = hitTop and hitBottom

    return hIntersect and vIntersect
end

-- this function is more expensive but also returns direction info
function Prop:CollisionInfo(other)
    if not self.Solid then return false end

    local selfSurfaceInfo = self._surfaceInfo

    local sp, op = self.Position, other.Position
    local sap, oap = self.AnchorPoint, other.AnchorPoint
    local ss, os = (self.CollisionSize or self.Size), (other.CollisionSize or other.Size)
    local sLeftEdge  = floor(sp[1] + ((selfSurfaceInfo.Left or Prop._surfaceInfo.Left).CollisionInset or 0) - ss[1] * sap[1])
    local sRightEdge = floor(sp[1] - ((selfSurfaceInfo.Right or Prop._surfaceInfo.Right).CollisionInset or 0) + ss[1] * (1 - sap[1]))
    local sTopEdge  = floor(sp[2] + ((selfSurfaceInfo.Top or Prop._surfaceInfo.Top).CollisionInset or 0) - ss[2] * sap[2])
    local sBottomEdge = floor(sp[2] - ((selfSurfaceInfo.Bottom or Prop._surfaceInfo.Bottom).CollisionInset or 0) + ss[2] * (1 - sap[2]))
    local oLeftEdge  = floor(op[1] - os[1] * oap[1])
    local oRightEdge = floor(op[1] + os[1] * (1 - oap[1]))
    local oTopEdge  = floor(op[2] - os[2] * oap[2])
    local oBottomEdge = floor(op[2] + os[2] * (1 - oap[2]))
    
    local hitLeft  = sRightEdge >= oLeftEdge
    local hitRight = sLeftEdge <= oRightEdge
    local hitTop   = sBottomEdge >= oTopEdge
    local hitBottom = sTopEdge <= oBottomEdge

    local hIntersect = hitLeft and hitRight
    local vIntersect = hitTop and hitBottom

    local res = hIntersect and vIntersect

    if res then

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
local collisionInfo = Prop.CollisionInfo

function Prop.GetHitFace(hDist, vDist, usingItWrong)
    if usingItWrong then
        print("Make sure to use Prop.GetHitFace() and not Prop:GetHitFace()!!")
        hDist, vDist = vDist, usingItWrong
    end

    

    if not hDist and not vDist then return false end

    if hDist and vDist then
        if hDist == 0 then
            return vDist > 0 and "top" or vDist < 0 and "bottom" or "none"
        elseif vDist == 0 then
            return hDist > 0 and "left" or hDist < 0 and "right" or "none"
        elseif abs(hDist) < 1.1 and abs(vDist) < 1.1 then
            return "none"
        elseif abs(hDist) > abs(vDist) then
            return vDist > 0 and "top" or vDist < 0 and "bottom" or "none"
        else
            return hDist > 0 and "left" or hDist < 0 and "right" or "none"
        end
    elseif not vDist and hDist then -- object is taller than collidable
        return hDist > 0 and "left" or hDist < 0 and "right" or "none"
    elseif vDist and not hDist then -- object is wider than collidable
        return vDist > 0 and "top" or vDist < 0 and "bottom" or "none"
    else
        return "none"
    end
end

-- BTW, `isSingleObject` is mainly for doing a collision pass along a single tilemap
-- (or any other Solid Prop which can return multiple collisions)
function Prop:CollisionPass(container, deep, preference, isSingleObject)
    local nsf = function(c) return c ~= self end
    
    if isSingleObject then
        container = {container}
    elseif not container then
        container = deep and self._parent:GetDescendants(nsf) or self._parent:GetChildren(nsf)
    elseif container._type then
        if self._parent == container then
            container = deep and container:GetDescendants(nsf) or container:GetChildren(nsf)
        else
            container = deep and container:GetDescendants() or container:GetChildren()
        end
    end

    local hit, hDir, vDir, ex, ex2, ex3
    local i = 1
    local queue, queuePos, queueOwner
    return function ()
        if not container[i] and (not queue or not queue[queuePos+1]) then return nil end
        if queue then
            
            queuePos = queuePos + 1
            if queue[queuePos] then
                return queueOwner, queue[queuePos][1], queue[queuePos][2], queue[queuePos][3], queue[queuePos][4], queue[queuePos][5]
            else
                queue = nil; queuePos = nil; queueOwner = nil
            end
        end
        
        repeat
            if container[i].CollisionInfo then
                hit, hDir, vDir, ex, ex2, ex3 = container[i]:CollisionInfo(self, preference)
            end
            i = i + 1
            
        until not container[i] or hit

        if type(hit) == "table" then
            queue = hit
            
            queuePos = 1
            queueOwner = container[i-1]
            
            return queueOwner, queue[1][1], queue[1][2], queue[1][3], queue[1][4], queue[1][5]
        elseif hit then
            
            return container[i-1], hDir, vDir, ex, ex2, ex3
        else
            return nil
        end
    end
end



function Prop:GetTouching(container)
    -- container is either the children of the input Object, or the input list directly, or the child's parent by default
    local nsf = function(c) return c ~= self end
    container = not container and self._parent._children or container._type and container._children or container
    
    local touchList = {}
    for _, item in ipairs(container) do
        if item.Solid and item ~= self and self:CollidesAABB(item) then
            touchList[#touchList+1] = item
        end
    end

    return touchList
end

-- -- expanded version
-- function Prop:DistanceFromPoint3(p)
--     local sx, sy = self.Size[1], self.Size[2]
--     local ox = sx * (0.5 - self.AnchorPoint[1])
--     local oy = sy * (0.5 - self.AnchorPoint[2])
--     local r = -self.Rotation
--     local rx = ox*cos(r) + oy*sin(r)
--     local ry = ox*sin(r) - oy*cos(r)
--     local relx = p[1]-rx-self.Position[1]
--     local rely = p[2]+ry-self.Position[2]
--     local rotx = relx*cos(r) - rely*sin(r)
--     local roty = relx*sin(r) + rely*cos(r)
--     local dx = max(abs(rotx) - sx / 2, 0)
--     local dy = max(abs(roty) - sy / 2, 0)
--     return sqrt(dx * dx + dy * dy)
-- end

-- shortened version
local function distanceFromPoint3(self, p)
    local sx, sy = self.Size[1], self.Size[2]
    local ox = sx * ( self.AnchorPoint[1] <= 1 and (0.5 - self.AnchorPoint[1]) or (self.AnchorPoint[1] - 1) )
    local oy = sy * ( self.AnchorPoint[2] <= 1 and (0.5 - self.AnchorPoint[2]) or (self.AnchorPoint[2] - 1) )
    local r = -self.Rotation
    local relx = p[1]-(ox*cos(r) + oy*sin(r))-self.Position[1]
    local rely = p[2]+(ox*sin(r) - oy*cos(r))-self.Position[2]
    local dx = max(abs(relx*cos(r) - rely*sin(r)) - sx / 2, 0)
    local dy = max(abs(relx*sin(r) + rely*cos(r)) - sy / 2, 0)
    return sqrt(dx * dx + dy * dy)
end

local function distanceFromPoint2(self, p)
    -- if dealing with custom anchors, move to a heavier function
    if self.AnchorPoint[1] ~= 0.5 or self.AnchorPoint[2] ~= 0.5 then return distanceFromPoint3(self, p) end

    local sx, sy = self.Size[1], self.Size[2]
    local cx = self.Position[1]
    local cy = self.Position[2]
    local relx = p[1]-cx
    local rely = p[2]-cy
    local r = -self.Rotation
    local rotx = relx*cos(r) - rely*sin(r)
    local roty = relx*sin(r) + rely*cos(r)
    local dx = max(abs(rotx) - sx / 2, 0)
    local dy = max(abs(roty) - sy / 2, 0)
    return sqrt(dx * dx + dy * dy)
end

function Prop:DistanceFromPoint(p)
    -- if dealing with rotation, move to a heavier function
    if self.Rotation ~= 0 then return distanceFromPoint2(self, p) end

    local sx, sy = self.Size[1], self.Size[2]
    local cx = self.Position[1] + sx * (0.5 - self.AnchorPoint[1])
    local cy = self.Position[2] + sy * (0.5 - self.AnchorPoint[2])
    local dx = max(abs(p[1] - cx) - sx/2, 0)
    local dy = max(abs(p[2] - cy) - sy/2, 0)
    return sqrt(dx * dx + dy * dy)
end

function Prop:GetSurfaceInfo()
    return {
        Top = self._surfaceInfo.Top or Prop._surfaceInfo.Top,
        Bottom = self._surfaceInfo.Bottom or Prop._surfaceInfo.Bottom,
        Left = self._surfaceInfo.Left or Prop._surfaceInfo.Left,
        Right = self._surfaceInfo.Right or Prop._surfaceInfo.Right,
    }
end

return Prop