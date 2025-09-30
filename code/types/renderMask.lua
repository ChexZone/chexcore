-- i didnt know what to call it. its a prop that allows for shader passes and automatic render to texture
local RenderMask = {
    Name = "RenderMask",
    _super = "Prop",
    _global = true,

    Size = V{512, 512},
    AnchorPoint = V{0.5,0.5},

    _debug = true,
    _shadersWithStep = {},

    RenderPipeline = {Prop, Shader},
}

function RenderMask.new(...)
    -- local newProp = setmetatable(_G[RenderMask._super].new(...), RenderMask)
    local newProp = Prop._standardConstructor(...)

    newProp.Size = rawget(newProp, "Size") or RenderMask.Size
    newProp.AnchorPoint = rawget(newProp, "AnchorPoint") or RenderMask.AnchorPoint
    newProp.Canvas1 = Canvas.new(newProp.Size())
    newProp.Canvas2 = Canvas.new(newProp.Size())
    newProp.RenderPipeline = newProp.RenderPipeline or {}
    newProp.Color = V{1,1,1,0.25}
     -- go thru all the RenderPipeline to see if there are shaders with steps, and auto-set them based on canvas size
     newProp._shadersWithStep = {}
     for _, phase in ipairs(newProp.RenderPipeline) do
        if phase:IsA("Shader") then -- try to send a step
            local success, err = pcall(function()
                phase:Send("step", {1/newProp.Size.X, 1/newProp.Size.Y})
            end)
            
        end
     end

    return setmetatable(newProp, RenderMask)
end

function RenderMask:Draw(tx, ty)
    love.graphics.setBlendMode("alpha")
    -- Prop.Draw(self,tx,ty)
    self.Canvas1:Activate()
    -- love.graphics.setBlendMode("replace")
    love.graphics.setColor(1,1,1,1)
    love.graphics.clear()
    -- love.graphics.rectangle("line", 0, 0, self.Size.X, self.Size.Y)
    for _, phase in ipairs(self.RenderPipeline) do
        if phase:IsA("Prop") then
            local pdiff = (phase.Position - self.Position)
            phase:Draw(phase.Position.X - pdiff.X - self.Size.X*self.AnchorPoint.X, phase.Position.Y - pdiff.Y - self.Size.Y*self.AnchorPoint.Y)
            
        elseif phase:IsA("Shader") then
            self.Canvas1:Deactivate()
            phase:Activate()
            self.Canvas2:CopyFrom(self.Canvas1)
            phase:Deactivate()
            self.Canvas1, self.Canvas2 = self.Canvas2, self.Canvas1
            self.Canvas1:Activate()
        end

    end
    self.Canvas1:Deactivate()

    local sx = self.Size[1] * (self.DrawScale[1]-1)
    local sy = self.Size[2] * (self.DrawScale[2]-1)
    self.Canvas1:DrawToScreen(
        math.floor(self.Position[1] - tx),
        math.floor(self.Position[2] - ty),
        self.Rotation,
        self.Size[1] + sx,
        self.Size[2] + sy,
        self.AnchorPoint[1],
        self.AnchorPoint[2]
    )
    -- return Prop.Draw(self, tx, ty)
end

return RenderMask