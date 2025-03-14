local Number = {
    Name = "Number",

    _super = "Object",
    _aliases = {"N"},
    _global = true,
}

local floor, abs = math.floor, math.abs
local function init(n)
    local int, overflow = floor(n[1]), floor(n[2] or 0)
    n[1], n[2] = int + overflow, (n[2] or 0) % 1 + n[1] % 1
    --print(int, overflow)
end

local smt = setmetatable
smt(Number, {
    __call = function (_, parts)
        init(parts)
        local newNum = smt(parts, Number)
        return newNum
    end
})
local rg = rawget
function Number.__index(t, d)
    return rg(Number, d) or Number.__index2(t, d)
end

-- casts the Number back to a lua number
function Number:__call()
    return self[1] + self[2]
end

function Number.new(parts)
    init(parts)
    local newNum = smt(parts, Number)
    return newNum
end

-- metamethods etc.
-- BTW, i know i could just use operator functions here to not rewrite everything.
-- i'm trying to squeeze runtime performance out of these, and there's function call overhead.
-- might not be substantial enough, but at least i have my reasons!

local type = type
function Number.__add(a, b)
    if type(b) == "number" then
        -- special type left side
        return Number{a[1], a[2] + b}
    elseif type(a) == "number" then
        -- special type right side
        return Number{b[1], b[2] + a}
    else
        -- both sides are special type
        return Number{a[1] + b[1], a[2] + b[2]}
    end
end

function Number.__sub(a, b)
    if type(b) == "number" then
        -- special type left side
        return Number{a[1], a[2] - b}
    elseif type(a) == "number" then
        -- special type right side
        return Number{b[1], b[2] - a}
    else
        -- both sides are special type
        return Number{a[1] - b[1], a[2] - b[2]}
    end
end

function Number.__mul(a, b)
    if type(b) == "number" then
        -- special type left side
        return Number{(a[1] + a[2]) * b}
    elseif type(a) == "number" then
        -- special type right side
        return Number{(b[1] + b[2]) * a}
    else
        -- both sides are special type
        return Number{(a[1] + a[2]) * (b[1] + b[2])}
    end
end

function Number.__div(a, b)
    if type(b) == "number" then
        -- special type left side
        return Number{(a[1] + a[2]) / b}
    elseif type(a) == "number" then
        -- special type right side
        return Number{(b[1] + b[2]) / a}
    else
        -- both sides are special type
        return Number{(a[1] + a[2]) / (b[1] + b[2])}
    end
end

function Number.__pow(a, b)
    if type(b) == "number" then
        -- special type left side
        return Number{(a[1] + a[2]) ^ b}
    elseif type(a) == "number" then
        -- special type right side
        return Number{(b[1] + b[2]) ^ a}
    else
        -- both sides are special type
        return Number{(a[1] + a[2]) ^ (b[1] + b[2])}
    end
end

function Number.__mod(a, b)
    if type(b) == "number" then
        -- special type left side
        return Number{(a[1] + a[2]) % b}
    elseif type(a) == "number" then
        -- special type right side
        return Number{(b[1] + b[2]) % a}
    else
        -- both sides are special type
        return Number{(a[1] + a[2]) % (b[1] + b[2])}
    end
end

function Number.__eq(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

function Number.__lt(a, b)
    return a[1] < b[1] or a[2] < b[2]
end

function Number.__le(a, b)
    return a < b or a == b
end

function Number.__concat(a, b)
    if type(a) == "table" then
        return a:ToString() .. b
    else
        return a .. b:ToString()
    end
end

function Number:ToString()
    return "N{" .. tostring(self[1] + self[2]) .. "}"
end

return Number