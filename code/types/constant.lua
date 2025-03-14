local Constant = {
    -- properties
    Name = "Constant",
    -- internal properties
    _super = "Object",      -- Supertype

    _cache = setmetatable({}, {__mode = "k"}), -- keys are constant refs, values are originals
    _global = true,

    -- anything listed in the blacklist (string field name, or function reference) will return nil when indexed
    _blacklist = {
        [Object.AddProperties] = true
    }
}
local deepCopy = deepCopy
local cache = Constant._cache

local isObject = isObject
local blacklist = Constant._blacklist
Constant.__index =  function(t, k)
    if Constant._cache[t] then -- just in case..
        local origVal = Constant._cache[t][k]
        if blacklist[origVal] or blacklist[k] then 
            error("You can't use " .. k .. " on a Constant!", 2)
        end
        if type(origVal) == "function" then
            return function (self, ...)
                if Constant._cache[self] then
                    return origVal( Constant._cache[self], ... )
                else
                    return origVal(self, ...)
                end
            end
        end
        -- if isObject(Constant._cache[t]) and k == "ToString" then return interceptToString end
        return deepCopy( Constant._cache[t][k] )
    else
        print("you screwed up the constant whatever metatable mode thing !! deal with it loser")
    end
end

Constant.__call = function(t, ...)
    if cache[t] then
        return cache[t](...)
    end
end

Constant.__len = function(t)
    if Constant._cache[t] then
        return #Constant._cache[t]
    end
end

Constant.__unm = function (t1)
    return cache[t1] and -cache[t1] or -{}
end

Constant.__add = function (t1, t2)
    return (cache[t1] or t1) + (cache[t2] or t2)
end

Constant.__sub = function (t1, t2)
    return (cache[t1] or t1) - (cache[t2] or t2)
end

Constant.__mul = function (t1, t2)
    return (cache[t1] or t1) * (cache[t2] or t2)
end

Constant.__div = function (t1, t2)
    return (cache[t1] or t1) / (cache[t2] or t2)
end

Constant.__mod = function (t1, t2)
    return (cache[t1] or t1) % (cache[t2] or t2)
end

Constant.__pow = function (t1, t2)
    return (cache[t1] or t1) ^ (cache[t2] or t2)
end

Constant.__eq = function (t1, t2)
    return (cache[t1] or t1) == (cache[t2] or t2)
end

Constant.__lt = function (t1, t2)
    return (cache[t1] or t1) < (cache[t2] or t2)
end

Constant.__le = function (t1, t2)
    return (cache[t1] or t1) <= (cache[t2] or t2)
end

Constant.__concat = function (t1, t2)
    return (cache[t1] or t1) .. (cache[t2] or t2)
end

Constant.__newindex =  function() end -- lol

local CONST_MT = {
    __newindex = Constant.__newindex,
    __index = Constant.__index,
    __call = Constant.__call,
    __len = Constant.__len,
    __unm = Constant.__unm,
    __add = Constant.__add,
    __sub = Constant.__sub,
    __mul = Constant.__mul,
    __div = Constant.__div,
    __mod = Constant.__mod,
    __pow = Constant.__pow,
    __eq = Constant.__eq,
    __lt = Constant.__lt,
    __le  = Constant.__le,
    __concat = Constant.__concat
}

function Constant.new(tab)
    local newConstant = setmetatable({}, CONST_MT)

    Constant._cache[newConstant] = tab

    return newConstant
end
_G.CONST = Constant.new

-- some constants
Constant.COLOR = CONST({
    RED = V{1, 0, 0},
    PINK = V{255 / 255, 105 / 255, 180 / 255 },
    ORANGE = V{255 / 255, 165 / 255, 0},
    YELLOW = V{255 / 255, 215 / 255, 0},
    GREEN = V{0, 1, 0},
    BLUE = V{0, 0, 1},
    INDIGO = V{75 / 255, 0, 130 / 255},
    PURPLE = V{ 155 / 255, 48 / 255, 255/ 255},
    VIOLET = V{138 / 255, 43 / 255, 226 / 255},
    WHITE = V{1, 1, 1},
    BLACK = V{0, 0, 0},
    GRAY = V{0.5, 0.5, 0.5}
})
return Constant