-- CHEXCORE EXAMPLE SCENE
-- love.mouse.setVisible(false)
-- create a Scene with this syntax:
local scene = Scene.new()

-- Scenes need to have at least one Layer to do anything!
local layer = Layer.new("exampleLayer") -- specify the Name, and pixel width/height
-- attach the Layer to the Scene:
scene:Adopt(layer)

-- Scenes are made with a Camera object by default; let's focus our camera such that
-- the center of the screen is at position (500, 500):
local camPos = V{500, 500} -- Vectors are written in the format V{a, b, c, ...}
                              -- This is just a simple 2D vector for the Camera's Position.
scene.Camera.Position = camPos
scene.Camera.Zoom = 1
layer.ZoomInfluence = 1
layer.TranslationInfluence = 1
layer.AutoClearCanvas = true
-- Now that the Scene is ready, let's put something visible in; generally we use "props" for this.
-- Our code could look like this:
---  local prop = Prop.new()
---  layer:Adopt(prop)
-- however, we can use a shorthand to write this in one line:
local logo = layer:Adopt( Prop.new() )
logo.Visible = true

-- let's position the Prop so it's in the center of the Camera view we set up earlier:
logo.Position = V{400, 500}

-- we're going to give this Prop an an animated texture using a spritesheet.
-- first, we'll set the Prop to the same size as its texture (in this case, 750x300):
logo.Size = V{750, 300}

-- if you ran the scene up to this point, the prop would appear (with a default texture)
-- and it would be a little down and to the right, even though its position is the same as the Camera's.
-- this is because the engine needs to make a decision about what point on a Prop is considered the
-- "root" point of that Prop, the point whose position is actually set when updating the field.
-- Chexcore makes this decision using an "AnchorPoint" field on Props.
-- by default, the AnchorPoint is set to V{0,0}, putting the root at the top-left corner of the Prop.
-- We want our Prop's center to be its "root" point, so we'll set the AnchorPoint to 
-- 50% to the right and 50% down, or V{0.5, 0.5}
logo.AnchorPoint = V{0.5, 0.5}

-- now, we'll apply the texture. There is a simple "Texture" class we could apply, but
-- since we're using an animated texture, we'll be using the Animation class:
logo.Texture = Animation.new("chexcore/assets/images/flashinglogo.png", 1,         2) 
                            -- spritesheet path,                        rowCount,  columnCount

-- we'll set our animation to loop once every 2 seconds:
logo.Texture.Duration = 2



-- let's play around with some functionality!
-- you can add an update routine to any Prop by setting a function to its "Update" field:
function logo:Update(dt)
    -- let's have our image do some funky little rotation action:
    -- Chexcore._clock will always return how many seconds Chexcore has been running
    local lifetime = Chexcore._clock * 2 -- multiply by 2 to increase rotation speed

    -- we'll just set our image to rotate along the sine wave of the Chexcore's clock:
    self.Rotation = math.sin(lifetime) / 8 -- divide by 8 so it only rotates a little bit

    -- let's have our object be attracted to the mouse:
    local mousePos, inWindow = Input.GetMousePosition()
    -- mousePos is a 2D Vector normalized from 0-1. inWindow shows whether Chexcore thinks 
    -- the mouse has gone off the screen, but it doesn't know for sure.
    
    -- we'll place the new position of our object based on its origin:
    local goalPos = V{500, 400}

    if inWindow then
        -- right now, mousePos is normalized in the 0-1 range. 
        -- first we'll re-normalize the center to be 0 instead of 0.5.
        mousePos = mousePos - 0.5  -- this will subtract 0.5 from every axis of mousePos
        -- then we'll scale mousePos up so the range is (-100) to (100).
        mousePos = mousePos * 150  -- this will multiply every axis by 150.
        -- finally, apply the transformation to the goal position
        goalPos = goalPos - mousePos
    end

    -- we could set the position directly, but to make it look smoother, we'll 
    -- interpolate to some point in the middle
    local progress = 6*dt -- "dt" is the delta time from the last frame, a small fraction of a second
                          -- using this number lets us move at the same speed across different fps

    -- Vector1:Lerp(Vector2, distance)
    self.Position = self.Position:Lerp(goalPos, progress)
end

local button1 = layer:Adopt(Gui.new{
    Visible = true,
    Name = "Button1",
    AnchorPoint = V{.5, .5},
    Position = V{500, 700},
    Size = V{300, 100},
    Texture = Texture.new("chexcore/assets/images/square.png"),

    goalDrawScale = V{1,1}, -- user-defined
    goalColor = Constant.COLOR.PINK,   -- user-defined

    Update = function (self, dt)
        self.DrawScale = self.DrawScale:Lerp(self.goalDrawScale, 25*dt)
        self.Color = self.Color:Lerp(self.goalColor, 8*dt)

        self.Rotation = Chexcore._clock/2
    end,

    OnHoverStart = function (self)
        self.goalDrawScale = V{0.9, 0.9}
        self.goalColor.G = 0.5
    end,
    OnHoverEnd = function (self)
        self.goalDrawScale = V{1, 1}
        self.goalColor.G = 0
    end,

    OnSelectStart = function (self, button)
        self.DrawScale = V{1.1, 1.1}
        self.Color = Constant.COLOR.WHITE
    end,
})

for i = 1, 0 do
    local b2 = button1:Clone(true)
    b2.Position = button1.Position + V{math.random(-600,600)*2,math.random(-600,600)*2}
    b2 .Size = V{math.random(10, 200),math.random(10, 200)}
    b2.Color = ({Constant.COLOR.WHITE, Constant.COLOR.GREEN, Constant.COLOR.BLUE, Constant.COLOR.RED})[math.random(1, 4)]
    b2.goalColor =  ({Constant.COLOR.WHITE, Constant.COLOR.GREEN, Constant.COLOR.BLUE, Constant.COLOR.RED})[math.random(1, 4)]
    b2:SetMouseTracking(true)
end

local myButton = Gui.new{
    Size = V{100, 100},
    Position = V{100, 150},
    AnchorPoint = V{0.5, 0.5},

    OnHoverStart = function (self)
        print("Hovering over me!")
    end,
    OnHoverEnd = function (self)
        print("Stopped hovering over me!")
    end,

    OnSelectStart = function (self, button)
        print("I just got clicked by mouse button " .. button)
    end,
    OnSelectEnd = function (self, button)
        print("I just got released by mouse button " .. button)
    end,

    Update = function (self, dt)
        -- print(self:IsUnderMouse())
    end
}

layer:Adopt(myButton)

local layer2 = scene:Adopt( Layer.new("exampleLayer") ) -- specify the Name, and pixel width/height

-- local testText = layer2:Adopt(Text.new{
--     Name = "TestText",
--     Position = V{500, 500},
--     AlignMode = "justify",
--     Size = V{500, 200},
--     AnchorPoint = V{0.5, 0.5},
--     Texture = Texture.new("chexcore/assets/images/square.png"),
--     FontSize = 64,
--     Margin = 4,
--     TextColor = Constant.COLOR.WHITE,
--     Color = Constant.COLOR.WHITE,
--     Font = Font.new("chexcore/assets/fonts/chexfont_bold.ttf"),
--     Text = {Constant.COLOR.BLACK, "The quick brown ",
--             Constant.COLOR.ORANGE, "fox",
--             Constant.COLOR.BLACK, " bounded over the ninth earth"},

--     OnHoverStart = function (self)
--         self.DrawScale = V{0.95,0.95}
--     end,
--     OnHoverEnd = function (self)
--         self.DrawScale = V{1,1}
--     end,
--     OnSelectStart = function (self)
--         self.DrawScale = V{0.9, 1.1}
--     end,
--     OnSelectEnd = function (self)
--         if self:IsUnderMouse() then
--             self.DrawScale = V{0.95, 0.95}
--         else
--             self.DrawScale = V{1, 1}
--         end
--     end,
--     Update = function (self)
--         self.Text[3].R = 1-math.sin(Chexcore._clock*10 + 1)
--         self.Rotation = -Chexcore._clock * 0.25
--         -- self.Size = self.Size + math.sin(Chexcore._clock*2)*2
--         self.FontSize = self.FontSize + math.cos(Chexcore._clock*2)/3
--         self.DrawScale:SetXY(self.DrawScale.X + math.sin(Chexcore._clock*2 + 1)/150, self.DrawScale.Y + math.cos(Chexcore._clock)/30)
--     end
-- })

local cursor = layer:Adopt(Prop.new{
    Name = "Cursor",
    Texture = Texture.new("chexcore/assets/images/cursor.png"),
    AnchorPoint = V{0, 0},
    Position = V{500,500},
    Size = V{48,48},

    goalSize = V{48, 48}, -- custom field

    Update = function(self, dt)
        
        self.Position = self.Position:Lerp(self:GetParent():GetMousePosition(), 25*dt)
        self.Size = self.Size:Lerp(self.goalSize, 25*dt)

        if Input:JustPressed("m_1") then
            self.Size = V{64, 64}
        end
    end
})

-- layer:Adopt(CONST(V{1,2,3}):AddProperties{Update = function (self, dt)
--     print(self, Chexcore._clock)
-- end})


local obj = Object.new():Nest(layer):Properties{
    Name = "boom",
    Update = function (self, dt)
        -- print(self)
        -- print(Timer._timers)
    end
}


-- local v = layer:Adopt()

-- -- set up a timer that polls every second
-- local poller poller = function ()
--     if not obj.flagChecked then
--         Timer.ScheduleFrames(60, poller)
--         print("Polling...")
--     else
--         print("Polling complete")
--     end
-- end
-- poller()

-- Timer.Schedule(5, obj, "flagChecked", true)

Timer.ScheduleFrames(60, print, "hello world")

return scene