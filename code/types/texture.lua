local Texture = {
    -- properties
    Name = "Texture",

    -- internal properties
    _drawable = nil,        -- default image

    _cache = setmetatable({}, {__mode = "v"}), -- cache has weak values
    _super = "Object",      -- Supertype
    _global = true
}

--local mt = {}
--setmetatable(Texture, mt)
local smt = setmetatable
function Texture.new(path)
    local newTexture

    if Texture._cache[path] then
        newTexture = Texture._cache[path]
    else
        
        newTexture = smt({}, Texture)
        if path then
            newTexture._drawable = love.graphics.newTexture and love.graphics.newTexture(path) or love.graphics.newImage(path)
            Texture._cache[path] = newTexture
        end
    end

    return newTexture
end

local draw = cdraw
function Texture:DrawToScreen(...)
    -- render the Texture
    draw(self._drawable, ...)
end

local V = Vector
function Texture:GetSize()
    return V{ self._drawable:getDimensions() }
end

function Texture:GetWidth()
    return self._drawable:getWidth()
end

function Texture:GetHeight()
    return self._drawable:getHeight()
end
return Texture