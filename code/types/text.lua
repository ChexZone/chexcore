local Text = {
    -- properties
    Name = "Text",
    AlignMode = "left", -- left, right, center, justify
    Text = "Example line of text, going going going", -- the text to draw to the screen
    TextColor = V{1,1,1}, -- the color of the Text
    Size = V{500, 64},
    WordWrap = true,    -- whether to enforce word wrapping beyond the Size.X width
    FontSize = nil,   -- can assign a specific font height (pixels)
    Font = Font.new(),
    Visible = true,

    -- internal properties
    _super = "Gui",      -- Supertype
    _global = true
}

-- function Text.__newindex(obj, key, val)
--     return Gui.__newindex(obj, key, val)
-- end

local function unformatText( text )
    if type(text) == "string" then return text end
    if type(text) == "table" then
        local out = ""
        for _, s in ipairs(text) do
            if type(s) == "string" then
                out = out .. s
            end
        end
        return out
    end
end

local rg = rawget
function Text.new(properties)
    local newText = Text:SuperInstance()
    newText.Size = nil
    
    if type(properties) == "table" then
        for prop, val in pairs(properties) do
            newText[prop] = val
        end
    elseif type(properties) == "string" then
        newText.Text = properties
    end

    Text:Connect(newText) -- apply Text class

    newText.Size = rg(newText, "Size") or V{
        newText.Font:GetWidth(unformatText(newText.Text)) * (newText.FontSize and newText.FontSize / newText.Font._fontSize or 1),
        newText.FontSize or newText.Font and newText.Font._fontSize or Text.Font._fontSize
    }
    
    return newText
end

local lg = love.graphics
local floor = math.floor

function Text:Draw(tx, ty, isForeground)
    
    if self.Shader then
        self.Shader:Activate()
    end
    if self.DrawOverChildren and self:HasChildren() then
        self:DrawChildren(tx, ty)
    end

    local  ox, oy = self.AnchorPoint()
    if rg(self, "Texture") then
        lg.setColor(self.Color)
        local sx = self.Size[1] * (self.DrawScale[1]-1)
        local sy = self.Size[2] * (self.DrawScale[2]-1)
        self.Texture:DrawToScreen(
            floor(self.Position[1] - tx),
            floor(self.Position[2] - ty),
            self.Rotation,
            self.Size[1] + sx,
            self.Size[2] + sy,
            ox, oy
        )
    end

    lg.setFont(self.Font._realFont)
    lg.setColor(self.TextColor)
    lg.setBlendMode("alpha","alphamultiply")
    local textScale = self.FontSize and self.FontSize / self.Font._fontSize or 1

    if self.WordWrap then
        lg.printf(
            self.Text,
            floor(self.Position[1] - tx),
            floor(self.Position[2] - ty),
            self.Size[1] / textScale,
            self.AlignMode,
            self.Rotation,
            self.DrawScale[1] * textScale,
            self.DrawScale[2] * textScale,
            ox and (ox <= 1 and self.Size[1] * ox or ox) / textScale,
            oy and (oy <= 1 and self.Size[2] * oy or oy) / textScale
        )
    else
        lg.print(
            self.Text,
            floor(self.Position[1] - tx),
            floor(self.Position[2] - ty),
            self.Rotation,
            self.DrawScale[1] * textScale,
            self.DrawScale[2] * textScale,
            ox and (ox <= 1 and self.Size[1] * ox or ox) / textScale,
            oy and (oy <= 1 and self.Size[2] * oy or oy) / textScale
        )
    end

    if not self.DrawOverChildren and self:HasChildren() then
        self:DrawChildren(tx, ty)
    end

    if self.Shader then
        self.Shader:Deactivate()
    end
end

return Text