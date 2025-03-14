local Font = {
    -- properties
    Name = "Font",

    -- internal properties
    _realFont = nil,        -- love2d internal font
    _fontSize = 64,         -- internal font size

    _paths = {
        Chexfont = "chexcore/assets/fonts/chexfont_bold.ttf"
    },

    _cache = setmetatable({}, {__mode = "v"}), -- cache has weak values
    _super = "Object",      -- Supertype
    _global = true
}

--local mt = {}
--setmetatable(Texture, mt)
local smt = setmetatable
function Font.new(path, fontSize, hintingMode)
    local newFont

    if type(path) == "number" then
        fontSize = path
        path = ""
    elseif not path then
        path = ""
        fontSize = Font.FontSize
    end

    local fontID = path .. "-" .. tostring(fontSize or Font.FontSize)

    if Font._cache[fontID] then
        
        newFont = Font._cache[fontID]
    else
        
        newFont = smt({}, Font)
        if #path>0 then -- non-default font
        
            newFont._realFont = love.graphics.newFont(path, fontSize or Font._fontSize, hintingMode)
        else -- default font
            newFont._realFont = love.graphics.newFont(fontSize or Font._fontSize, hintingMode)
        end
        Font._cache[fontID] = newFont
        newFont._fontSize = fontSize
    end

    return newFont
end

function Font:GetWidth( text )
    return self._realFont:getWidth(text)
end

function Font:GetHeight()
    return self._fontSize
end

return Font