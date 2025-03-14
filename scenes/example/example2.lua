-- CHEXCORE EXAMPLE SCENE

local scene = Scene.new()
local layer =Layer.new("main", 1280, 720):Nest(scene)
-- local text = Text.new("ExampleButton"):Properties{
--     goalColor = Constant.COLOR.GRAY,
--     goalSize = V{1, 1},
--     goalRotation = 0,
--     AnchorPoint = V{0.5, 0.5},
--     Update = function (self, dt)
--         self.TextColor = self.TextColor:Lerp(self.goalColor, 10*dt)
--         self.DrawScale = self.DrawScale:Lerp(self.goalSize, 10*dt)
--         self.Rotation = math.lerp(self.Rotation, self.goalRotation, 10*dt)
--     end,
--     OnHoverStart = function (self)
--         self.goalColor = Constant.COLOR.WHITE
--         self.goalSize = V{0.9, 0.9}
--     end,
--     OnHoverEnd = function (self)
--         self.goalColor = Constant.COLOR.GRAY
--         self.goalSize = V{1, 1}
--     end,
--     OnSelectStart = function (self)
--         self.TextColor = Constant.COLOR.GREEN
--         self.Rotation = self.Rotation + math.rad(math.random(-30, 30))
--         self.DrawScale = self.DrawScale + V{0.2 * math.random(2), 0.1}
--     end
-- }--:Nest(layer)


local cube = Prop.new{
    Texture = Texture.new("chexcore/assets/images/crate.png"),
    Size = V{300, 300},
    AnchorPoint = V{0.5, 0.5},
    Update = function (self, dt)
        self.Rotation = self.Rotation + dt
    end
}:Nest(layer)

local point = Prop.new{
    Texture = Texture.new("chexcore/assets/images/cursor.png"),
    AnchorPoint = V{0,0},
    Size = V{100, 100},
    Update = function (self)
        self.Position = self:GetParent():GetPoint(1, 1)
    end
}:Nest(cube)


return scene