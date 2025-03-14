local Ray = {
    Name = "Ray",

    Angle = 0,            -- radians
    Length = 500,         -- we can't just make them go forever ..

    Position = V{ 0, 0 }, -- set in constructor
    _super = "Object",
    _global = true,
}


-- local rg = rawget
-- function Number.__index(t, d)
--     return rg(Number, d) or Number.__index2(t, d)
-- end

local smt = setmetatable
function Ray.new(origin, direction, length)
    local newRay = smt({
        Angle = direction,
        Position = origin:Clone(),
        Length = length
    }, Ray)

    return newRay
end

local originTexture
function Ray:Draw(container, ignore, tx, ty)
    tx = tx or 0
    ty = ty or 0
    love.graphics.setColor(1,1,1,1)
    originTexture = originTexture or Texture.new("chexcore/assets/images/arrow-right.png")
    originTexture:DrawToScreen(self.Position[1] - tx, self.Position[2] - ty, self.Angle, 8, 8, .5, .5)
    local ux, uy = math.cos(self.Angle), math.sin(self.Angle)
    local ex, ey = self.Position.X + ux*self.Length, self.Position.Y + uy*self.Length
    local _, hitPos
    if container then
        _, hitPos = self:Cast(container, ignore, true, tx, ty)

    end
    love.graphics.setColor(1,1,1,1)

    if hitPos then
        cdrawline(self.Position.X, self.Position.Y, hitPos.X, hitPos.Y, 2, 0)

        love.graphics.setColor(1,0,0)
        love.graphics.circle("fill", hitPos.X - tx, hitPos.Y - ty, 2)
    else
        cdrawline(self.Position.X - tx, self.Position.Y - ty, ex - tx, ey - ty, 2, 0)

        love.graphics.setColor(1,1,1,0.5)
        love.graphics.circle("line", self.Position.X - tx, self.Position.Y - ty, self.Length)
    end

end

local rm, floor = table.remove, math.floor
local HUGE, THRESHOLD, MAX_PASSES = math.huge, .5, 50
function Ray:Cast(containerObject, ignore, visualize, tx, ty)
    -- containerObject holds the object whose children we are going to iterate through
    -- ignore is ignore list or ignore function
    local angleVector = Vector.FromAngle(self.Angle)
    local movingVector = self.Position + 0
    local searchList = containerObject._type and containerObject:GetDescendants("Solid", true) or containerObject
    local bestMatch
    local distMoved = 0

    if type(ignore) == "table" then
        local holder = {}
        for _, item in ipairs(ignore) do
            holder[item] = true
        end
        ignore = function (solid)
            return holder[solid] and true or false
        end
    elseif type(ignore) ~= "function" then
        ignore = function () return false end
    end

    local stepSize
    local pass = 0
    while(#searchList > 0 and pass < MAX_PASSES) do
        pass = pass + 1
        stepSize = HUGE
        for _, solid in ipairs(searchList) do
            if not ignore(solid) then
                local dist = solid:DistanceFromPoint(movingVector)
                if dist < stepSize then
                    stepSize = dist
                    bestMatch = solid
                end
            end
        end

        if visualize then
            love.graphics.setColor(1,1,1,0.5)
            love.graphics.circle("line", movingVector[1] - (tx or 0), movingVector[2] - (ty or 0), stepSize)
            movingVector[1] = movingVector[1] + angleVector[1] * stepSize
            movingVector[2] = movingVector[2] + angleVector[2] * stepSize
            love.graphics.setColor(0.5,0.5,1,1)
            love.graphics.circle("line", movingVector[1] - (tx or 0), movingVector[2] - (ty or 0), 2)
        else
            movingVector[1] = movingVector[1] + angleVector[1] * stepSize
            movingVector[2] = movingVector[2] + angleVector[2] * stepSize
        end
        --movingVector = movingVector + (angleVector * stepSize)


        --if (movingVector - self.Position):Magnitude() > self.Length then return false end
        distMoved = distMoved + stepSize
        if distMoved > self.Length then return false end

        if stepSize < THRESHOLD then
            return bestMatch, (movingVector + 1):Filter(floor)
        end
    end
    
    if pass >= MAX_PASSES then
        print("WARNING: Raycast aborted: took more than " .. tostring(MAX_PASSES) .. " passes")
    end
    return false
end

function Ray:Multicast(containerObject, ignore)
    ignore = ignore or {}
    local searchList = containerObject._type and containerObject:GetChildren("Solid", true) or containerObject
    
    return function ()
        local hitObject, hitPos = self:Cast(searchList, ignore)
        if hitObject then
            ignore[#ignore+1] = hitObject
            return hitObject, hitPos
        else
            return nil
        end
    end
end

-- an experimental, flawed approach to the ray game i tried

-- function Ray:Hits2(containerObject)
--     -- get the angle to march along
--     local angleVector = Vector.FromAngle(self.Angle)
    
--     -- only Solid Objects collide
--     local searchList = containerObject:GetChildren("Solid", true)
--     local bestMatches
--     local pos = self.Position
--     local point = {pos[1] + angleVector[1], pos[2] + angleVector[2]}
--     local bestSize
--     for i = 1, #searchList do
--         local solid = searchList[i]
--         local distChange = solid:DistanceFromPoint(pos) - solid:DistanceFromPoint(point)
        
--         if not bestSize or distChange > bestSize then
--             bestSize = distChange
--             bestMatches = {solid}
--         elseif distChange == bestSize then
--             print(distChange, bestSize)
--             bestMatches[#bestMatches+1] = solid
--         end

--     end
--     print(#bestMatches, bestMatches[1])
--     -- algo to pick the closest one etc
--     local bestMatch, bestDist = bestMatches[1], math.huge
--     for _, match in ipairs(bestMatches) do
--         local dist = match:DistanceFromPoint(pos)
--         if dist < bestDist then
--             bestMatch = match
--             bestDist = dist
--         end
--     end
    
--     local marcher = self.Position + 0

--     local dist, oldDist = THRESHOLD + 1, math.huge
--     while dist < oldDist and dist > THRESHOLD do
--         dist = bestMatch:DistanceFromPoint(marcher)
--         marcher = marcher + angleVector * dist
        
--     end
--     print("E")

--     if dist < THRESHOLD then
--         return bestMatch, marcher
--     end

--     return bestMatch, marcher
-- end

return Ray