local Vector = {
    -- properties
    Name = "Vector",
    
    -- internal properties
    _super = "Object",      -- Supertype
    _aliases = {"V"},
    _global = true
}

-- Converts HSV to RGB. (input and output range: 0 - 1) (source: love2d help site)
local function hsv_to_rgb(h, s, v)
    if s <= 0 then return v,v,v end
    h = h*6
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r+m, g+m, b+m
end

local min, max = math.min, math.max
local function rgb_to_hsv(r, g, b)
    local max = max(r, g, b)
    local min = min(r, g, b)
    local h, s, v = 0, 0, max

    local d = max - min
    s = max == 0 and 0 or d / max

    if max == min then
        h = 0 -- achromatic (gray)
    else
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end







-- vector creation tries to be more optimized since it's frequent
local smt = setmetatable
function Vector.new(vec)
    return smt(vec, Vector)
end

function Vector.HSV(h, s, v)
    local vec
    if type(h) == "table" then
        vec =  h
        vec[1], vec[2], vec[3] = hsv_to_rgb(vec[1], vec[2], vec[3])
    else
        vec = {}
        vec[1], vec[2], vec[3] = hsv_to_rgb(h, s, v)
    end
    return smt(vec, Vector)
end
_G.HSV = Vector.HSV



-- SET A METATABLE FOR VECTOR FOR __call
setmetatable(Vector, {
    __call = function (_, vec)
        return smt(vec, Vector)
    end
})
-- custom indexing to react to X, Y, Z
local map, rg, rs, OBJ = {X = 1, Y = 2, Z = 3, A = 4, R = 1, G = 2, B = 3}, rawget, rawset, Object
local f_map_set = {
    H = function(vec, val)
        local _, s, v = rgb_to_hsv(vec[1], vec[2], vec[3])
        vec[1], vec[2], vec[3] = hsv_to_rgb(val, s, v)
    end,
    S = function(vec, val)
        local h, _, v = rgb_to_hsv(vec[1], vec[2], vec[3])
        vec[1], vec[2], vec[3] = hsv_to_rgb(h, val, v)
    end,
    V = function(vec, val)
        local h, s, _ = rgb_to_hsv(vec[1], vec[2], vec[3])
        vec[1], vec[2], vec[3] = hsv_to_rgb(h, s, val)
    end
}

local f_map_get = {
    H = function(vec)
        local h = rgb_to_hsv(vec[1], vec[2], vec[3])
        return h
    end,
    S = function(vec)
        local max, min = max(vec[1],vec[2],vec[3]), min(vec[1],vec[2],vec[3])  
        local d = max - min
        return max == 0 and 0 or d / max
    end,
    V = function(vec)
        return max(vec[1], vec[2], vec[3])
    end
}

function Vector.__index(t, d)
    return f_map_get[d] and f_map_get[d](t) or rg(t, map[d]) or rg(Vector, d) or Vector.__index2(t, d)
end
function Vector.__newindex(t, d, v)
    if f_map_set[d] then
        f_map_set[d](t, v)
    else
        rs(t, map[d] or d, v)
    end
end


-- also, Vectors can be __call()ed to unpack their data
local unpack = unpack
function Vector:__call()
    return unpack(self)
end

-- for normal people
function Vector:Unpack()
    return unpack(self)
end


-------------- regular methods ---------------------------------
local sin, cos =  math.sin, math.cos
function Vector.FromAngle(rad)
    return Vector{ cos(rad), sin(rad) }
end

local sqrt = math.sqrt
function Vector:Magnitude()
    local s = 0
    for _, v in ipairs(self) do
        s = s + v^2
    end
    return sqrt(s)
end

local ipairs = ipairs
function Vector:Filter(filter, ...)
    local nv = Vector{}
    for i = 1, #self do
        nv[i] = filter(self[i], ...)
    end
    return nv
end

function Vector:Normalize()
    return self / self:Magnitude()
end

-- returns a ratio of a Vector such that the first axis = 1.
function Vector:Ratio()
    local nv = Vector{1}
    for i = 2, #self do
        nv[i] = self[i]/self[1]
    end
    return nv
end

function Vector:ToAngle()
    return math.atan2(self[1], self[2])
end

function Vector:MoveXY(x, y)
    self[1] = self[1] + (x or 0)
    self[2] = self[2] + (y or 0)
end

function Vector:MoveXYZ(x, y, z)
    self[1] = self[1] + (x or 0)
    self[2] = self[2] + (y or 0)
    self[2] = self[3] + (z or 0)
end

function Vector:SetXY(x, y)
    self[1] = x or 0
    self[2] = y or 0
end

function Vector:SetXYZ(x, y, z)
    self[1] = x or 0
    self[2] = y or 0
    self[2] = z or 0
end
-- i could write code like this!~
function Vector:AddAxis(init)
    self[#self+1] = init or 0
    return self
end

-- basic linear interpolation
local clamp, abs = math.clamp, math.abs
local function lerp2(v1, v2, t, snapDelta)
    local v3 = Vector{}
    t = clamp(t, 0, 1)
    for i = 1, #v1 do
        v3[i] = v1[i] + ((v2[i] or v1[i]) - v1[i]) * t
        if abs(v3[i] - v2[i]) < snapDelta then
            v3[i] = v2[i]
        end
    end
    return v3
end


function Vector.Lerp(v1, v2, t, snapDelta)
    if snapDelta then return lerp2(v1, v2, t, snapDelta) end
    local v3 = Vector{}
    t = clamp(t, 0, 1)
    for i = 1, #v1 do
        v3[i] = v1[i] + ((v2[i] or v1[i]) - v1[i]) * t
    end
    return v3
end

-------------- relational operator stuff ----------------------------
-- addition
function Vector.__add(v1, v2)
    if type(v1) == "number" then -- number -> vector = number
        for i = 1, #v2 do
            v1 = v1 + v2[i]
        end
        return v1
    elseif type(v2) == "number" then -- vector -> number = vector
        local nVec = Vector.new{}
        for i = 1, #v1 do
            nVec[i] = v1[i] + v2
        end
        return nVec
    else -- vector -> vector = vector
        local nVec = Vector.new{}
            for i = 1, #v1 do
                nVec[i] = rg(v2, i) and v1[i] + v2[i] or v1[i]
            end
        return nVec
    end
end

-- subtraction
function Vector.__sub(v1, v2)
    if type(v1) == "number" then -- number -> vector = number
        for i = 1, #v2 do
            v1 = v1 - v2[i]
        end
        return v1
    elseif type(v2) == "number" then -- vector -> number = vector
        local nVec = Vector.new{}
        for i = 1, #v1 do
            nVec[i] = v1[i] - v2
        end
        return nVec
    else -- vector -> vector = vector
        local nVec = Vector.new{}
            for i = 1, #v1 do
                nVec[i] = rg(v2, i) and v1[i] - v2[i] or v1[i]
            end
        return nVec
    end
end

-- modulo
function Vector.__mod(v1, v2)
    if type(v1) == "number" then -- number -> vector = number
        for i = 1, #v2 do
            v1 = v1 % v2[i]
        end
        return v1
    elseif type(v2) == "number" then -- vector -> number = vector
        local nVec = Vector.new{}
        for i = 1, #v1 do
            nVec[i] = v1[i] % v2
        end
        return nVec
    else -- vector -> vector = vector
        local nVec = Vector.new{}
            for i = 1, #v1 do
                nVec[i] = rg(v2, i) and v1[i] % v2[i] or v1[i]
            end
        return nVec
    end
end

-- multiplication
function Vector.__mul(v1, v2)
    if type(v1) == "number" then -- number -> vector = number
        for i = 1, #v2 do
            v1 = v1 * v2[i]
        end
        return v1
    elseif type(v2) == "number" then -- vector -> number = vector
        local nVec = Vector.new{}
        for i = 1, #v1 do
            nVec[i] = v1[i] * v2
        end
        return nVec
    else -- vector -> vector = vector
        local nVec = Vector.new{}
            for i = 1, #v1 do
                nVec[i] = rg(v2, i) and v1[i] * v2[i] or v1[i]
            end
        return nVec
    end
end

-- division
function Vector.__div(v1, v2)
    if type(v1) == "number" then -- number -> vector = number
        for i = 1, #v2 do
            v1 = v1 / v2[i]
        end
        return v1
    elseif type(v2) == "number" then -- vector -> number = vector
        local nVec = Vector.new{}
        for i = 1, #v1 do
            nVec[i] = v1[i] / v2
        end
        return nVec
    else -- vector -> vector = vector
        local nVec = Vector.new{}
            for i = 1, #v1 do
                nVec[i] = rg(v2, i) and v1[i] / v2[i] or v1[i]
            end
        return nVec
    end
end

-- exponentiation
function Vector.__pow(v1, v2)
    if type(v1) == "number" then -- number -> vector = number
        for i = 1, #v2 do
            v1 = v1 ^ v2[i]
        end
        return v1
    elseif type(v2) == "number" then -- vector -> number = vector
        local nVec = Vector.new{}
        for i = 1, #v1 do
            nVec[i] = v1[i] ^ v2
        end
        return nVec
    else -- vector -> vector = vector
        local nVec = Vector.new{}
            for i = 1, #v1 do
                nVec[i] = rg(v2, i) and v1[i] ^ v2[i] or v1[i]
            end
        return nVec
    end
end

function Vector.__concat(v1, v2)
    if type(v1) == "table" then
        return v1:ToString() .. v2
    else
        return v1 .. v2:ToString()
    end
end

-- equality
function Vector.__eq(v1, v2)
    if #v1 ~= #v2 then return false end

    for i = 1, #v1 do
        if v1[i] ~= v2[i] then return false end
    end

    return true
end

-- negation
function Vector.__unm(v)
    return v * -1
end

local concat, tostring = table.concat, tostring
function Vector:ToString()
    local out = {}
    for _, item in ipairs(self) do
        out[#out+1] = tostring(item)
    end
    
    return "V{" .. concat(out, ", ") .. "}"
end

return Vector



