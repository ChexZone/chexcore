require "chexcore"


-- some of the constructors are still somewhat manual but they'll get cleaned up !

-- Scenes contain all the components of the game
function love.load2()


    -- BLIND BIRDS STUFF
    local scene = require"game.scenes.blindbirds.init"
    Chexcore.MountScene(scene)

    -- ADVENTURES END STUFF
    -- local scene = require"game.scenes.testzone.init"

    -- Chexcore:AddType("game.player.player")



    -- Chexcore.MountScene(scene)
end

-- -- some of the constructors are still somewhat manual but they'll get cleaned up !

-- -- Scenes contain all the components of the game
-- local scene = Scene.new{ MasterCanvas = Canvas.new(1920, 1080) }

-- -- Scenes have a list of Layers, which each hold their own Props
-- scene:AddLayer(Layer.new{
--     Name = "Gameplay",
--     Canvases = { Canvas.new(320, 180) }     -- pixel gameplay layer @ 320x180p
-- })

-- scene:AddLayer(Layer.new{s
--     Name = "GUI",
--     Canvases = { Canvas.new(1920, 1080) }  -- hd gui layer @ 1920x1080p
-- })

-- -- test collidable
-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate",
--     Solid = false, Visible = false,
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 64, 64 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
-- })



-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate",
--     Position = V{ 460, 180 } / 2,   -- V stands for Vector
--     Size = V{ 64, 64 },
--     AnchorPoint = V{ 0, 0 },
--     Rotation = 0,
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
-- })
-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate",
--     Position = V{ 200, 300 } / 2,   -- V stands for Vector
--     Size = V{ 64, 64 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
-- })
-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate",
--     Position = V{ 160, 240 } / 2,   -- V stands for Vector
--     Size = V{ 64, 64 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
-- })
-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate",
--     Position = V{ 80, 160 } / 2,   -- V stands for Vector
--     Size = V{ 64, 64 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
-- })
-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "BabyCrate",
--     Position = V{ 180, 50 },   -- V stands for Vector
--     Size = V{ 6, 6 },
--     Color = V{ 0.5, 0.5, 1, 1 },
--     AnchorPoint = V{ .5, .5 },
--     Velocity = V{ -1.2, 1.75 },
--     Acceleration = V{ -.1, 0.1 },
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Draw = function(self)
--         Prop.Draw(self)
--         --self.Rotation = self.Rotation + 0.01
--         -- caveman physics
--         self.Position = self.Position + self.Velocity / 144 * 5
--         self.Velocity = self.Velocity + self.Acceleration / 144 * 5



--         -- -- create a Ray facing down from the center of the object
--         local collisionRay = Ray.new(self.Position, math.rad(90) + self.Rotation, self.Size.Y/2)
--         -- -- cast the Ray to see if it hits anything
--         -- local hit, vec = collisionRay:Hits(scene:GetLayer("Gameplay"):GetChildren(), {self})

--         -- if hit then
--         --     self.Velocity.Y = 0
--         --     self.Velocity.X = self.Velocity.X * 0.99
--         --     -- use the hit vector to un-clip 
--         --     self.Position.Y = vec.Y - self.Size.Y/2 - 1
--         -- else
            
--         -- end
--         for hitObject, hitPos in collisionRay:Multicast(scene:GetLayer("Gameplay"), {self}) do
--             --print(hitObject)
--         end
--         -- print"------------------------"
--         --collisionRay:Draw(scene:GetLayer("Gameplay"):GetChildren(), {self}) -- for fun
--     end,
--     Update = function (self, dt)
--         for solid, hDist, vDist in self:CollisionPass(nil, true) do
--             -- print(hDist, vDist)
--             --local hitDirection = (hDist and vDist) and (math.abs(hDist) < math.abs(vDist) and "h" or math.abs(hDist) > math.abs(vDist) and "v" or "") or (not vDist) and "h" or (not hDist) and "v" or ""
--             local hitDirection = Prop.GetHitFace(hDist, vDist)



--             -- if hitDirection == "top" or hitDirection == "bottom" then
--             --     self.Position.Y = self.Position.Y - vDist
--             --     self.Velocity.Y = 0
--             -- elseif hitDirection == "left" or hitDirection == "right" then
--             --     self.Velocity.X = -self.Velocity.X/2
--             --     self.Position.X = self.Position.X - hDist
--             -- end

--             if hitDirection == "top" then
--                 self:SetEdge("bottom", solid:GetEdge("top"))
--                 self.Velocity.Y = 1
--             elseif hitDirection == "bottom" then
--                 self:SetEdge("top", solid:GetEdge("bottom"))
--                 self.Velocity.Y = 1
--             elseif hitDirection == "left" then
--                 self:SetEdge("right", solid:GetEdge("left"))
--                 self.Velocity.X = -self.Velocity.X
--             elseif hitDirection == "right" then
--                 self:SetEdge("left", solid:GetEdge("right"))
--                 self.Velocity.X = -self.Velocity.X
--             end










--             -- if math.abs(hDist) > 0 and (vDist == 0 or math.abs(vDist) > 1) then
--             --     self.Velocity.X = 0
--             --     self.Position.X = self.Position.X - hDist
--             -- end
--             -- if math.abs(vDist) > 0 and (hDist == 0 or math.abs(hDist) > 1) then
--             --     self.Velocity.Y = 0
--             --     self.Position.Y = self.Position.Y - vDist
--             -- end

--             -- -- or you could do it this way
--             -- local hFace, vFace = Prop.GetHitFaces(hDist, vDist) -- "left/top", "right/bottom", "inside", "outside"
--             -- if vFace == "top" then
--             --     self:SetBottomEdge(solid:GetTopEdge())
--             -- elseif vFace == "bottom" then
--             --     self:SetTopEdge(solid:GetBottomEdge())
--             -- end

--             -- if hFace == "left" and vFace == "inside" then
--             --     print(vFace)
--             --     self.Velocity.X = -self.Velocity.X
--             --     self:SetRightEdge(solid:GetLeftEdge())
--             -- elseif hFace == "right" and vFace == "inside" then
--             --     self:SetLeftEdge(solid:GetRightEdge())
--             -- end
--         end
        
--     end
-- })

-- Chexcore.MountScene(scene)

-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate8",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 64, 64 },
--     Color = V{1,1, 1, 0.5},
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Rotation = self.Rotation + 0.5 * dt
--         --print(self.Position, self:BottomFace())
--     end
-- })

-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate9",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 32, 128 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,0,0, 0.5},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Rotation = self.Rotation - 2 * dt
--         self.Position = self._parent:GetChild("Crate8"):GetPoint("bottomright", 0.5)
--     end
-- })

-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate10",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 16, 64 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,0,0 , 0.5},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Rotation = self.Rotation + 2 * dt
--         self.Position = self._parent:GetChild("Crate9"):GetPoint("bottom")
--     end
-- })

-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "Crate11",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 64, 64 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,0,1,.8},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         Prop.Update(self, dt)
--         self.Rotation = self.Rotation + 1 * dt
--         self.Position = self._parent:GetChild("Crate10"):GetPoint("topleft", 0.25)
--     end
-- })

-- local c11 = scene:GetLayer("Gameplay"):GetChild("Crate11")

-- c11:Adopt(Prop.new{
--     Name = "Crate12",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 16, 16 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,1,1},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         Prop.Update(self, dt)
--         self.Position = c11:GetPoint("topleft")
--     end
-- })
-- c11:Adopt(Prop.new{
--     Name = "Crate13",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 16, 16 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,1,1},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Position = c11:GetPoint("topright")
--     end
-- })
-- c11:Adopt(Prop.new{
--     Name = "Crate14",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 16, 16 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,1,1},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Position = c11:GetPoint("bottomleft")
--     end
-- })
-- scene:GetLayer("Gameplay"):GetChild("Crate11"):GetChild("Crate12"):Adopt(Prop.new{
--     Name = "Crate15",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 16, 16 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,1,1},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Position = self._parent._parent._parent:GetChild("Crate11"):GetPoint("bottomright")
--     end
-- })
-- scene:GetLayer("Gameplay"):GetChild("Crate11"):GetChild("Crate12"):GetChild("Crate15"):Adopt(Prop.new{
--     Name = "Crate16",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 16, 16 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,1,1},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Position = self._parent._parent._parent._parent:GetChild("Crate11"):GetPoint("bottomright")
--     end
-- })scene:GetLayer("Gameplay"):GetChild("Crate11"):GetChild("Crate12"):GetChild("Crate15"):Adopt(Prop.new{
--     Name = "Crate16",
--     Position = V{ 340, 220 } / 2,   -- V stands for Vector
--     Size = V{ 16, 16 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = 0,
--     Color = V{1,1,1},
--     Solid = true,
--     Texture = Texture.new("chexcore/assets/images/crate.png"),
--     Update = function (self, dt)
--         self.Position = self._parent._parent._parent._parent:GetChild("Crate11"):GetPoint("bottomright")
--     end
-- })

-- -- -- some of the constructors are still somewhat manual but they'll get cleaned up !

-- -- -- Scenes contain all the components of the game
-- -- local scene = Scene.new{ MasterCanvas = Canvas.new(1920, 1080) }

-- -- -- Scenes have a list of Layers, which each hold their own Props
-- -- scene:AddLayer(Layer.new{
-- --     Name = "Gameplay",
-- --     Canvases = { Canvas.new(320, 180) }     -- pixel gameplay layer @ 320x180p
-- -- })

-- -- scene:AddLayer(Layer.new{
-- --     Name = "GUI",
-- --     Canvases = { Canvas.new(1920, 1080) }  -- hd gui layer @ 1920x1080p
-- -- })

-- -- -- test collidable
-- -- scene:GetLayer("Gameplay"):Adopt(Prop.new{
-- --     Name = "Crate",
-- --     Position = V{ 320, 180 } / 2,   -- V stands for Vector
-- --     Size = V{ 64, 64 },
-- --     AnchorPoint = V{ 0.5, -2 },
-- --     Solid = true,
-- --     Texture = Texture.new("chexcore/assets/images/crate.png"),
-- --     Update = function (self, dt)
-- --        self.Rotation = self.Rotation + 0.0025
-- --     end,
-- --     Draw = function (self)
-- --         Prop.Draw(self)
-- --         Ray.new(self.Position, self.Rotation + math.rad(90), self.Size.Y * -self.AnchorPoint.Y):Draw()
-- --     end
-- -- })

-- -- for i = 1, 100 do
-- -- scene:GetLayer("Gameplay"):Adopt(Prop.new{
-- --     Name = "Crate2",
-- --     --Rotation = math.random(),
-- --     Position = V{ 320 / 8, 180 } / 2*(math.random() * 50) + V{250, 0},   -- V stands for Vector
-- --     Size = V{ 64, 64 },
-- --     RotVelocity = math.random() - 0.5,
-- --     AnchorPoint = V{ 0.5, 0.5 },
-- --     Solid = true,
-- --     Texture = Texture.new("chexcore/assets/images/crate.png"),
-- --     Update = function (self, dt)
-- --     self.Rotation = self.Rotation + self.RotVelocity*0.02
-- --     end,
-- --     Draw = function ()
        
-- --     end
-- -- })
-- -- end

-- -- ray origin
-- scene:GetLayer("Gameplay"):Adopt(Prop.new{
--     Name = "RayOrigin",
--     Position = V{100, 100},
--     Size = V{ 8, 8 },
--     AnchorPoint = V{ 0.5, 0.5 },
--     Rotation = math.rad(0),
--     Texture = Texture.new("chexcore/assets/images/arrow-right.png")
-- })

-- scene:GetLayer("Gameplay"):GetChild("RayOrigin").Draw = function(self, tx, ty)
--     love.graphics.setColor(self.Color)
--     --self.Texture:DrawToScreen(self.Position[1], self.Position[2], self.Rotation, self.Size[1], self.Size[2], self.AnchorPoint[1], self.AnchorPoint[2])
--     for i = 1, 100 do
--         local testRay = Ray.new(self.Position + V{0, 0}, Chexcore._clock/4 * i/2 - i*2, 128)
--         testRay:Draw(scene:GetLayer("Gameplay"), nil, tx, ty)
--         --local _, hitPos = testRay:Hits(scene:GetLayer("Gameplay"))
--         --print(hitPos)

--     end
--     --self._parent._children[1].Rotation = self._parent._children[1].Rotation + 0.001
-- end

-- -- mounting a Scene makes it automatically update/draw
-- -- Chexcore.MountScene(scene)




-- -- function love.update(dt)
-- --     Chexcore.Update(dt)
-- --     --print(1/dt)
-- --     local p = scene:GetLayer("Gameplay"):GetChild("Crate")   -- easy to navigate hierarchy
-- --     --p.Rotation = p.Rotation + 0.01  -- slowly rotate,,
-- -- end



-- -- local ParentCat = Cat.new{Name = "ParentCat"}
-- -- ParentCat:Adopt(Cat.new{Name = "ChildCat1", Val = 125})
-- -- ParentCat:Adopt(Cat.new{Name = "ChildCat2", SomeThing = true, Val = 75})
-- -- ParentCat:Adopt(Cat.new{Name = "ChildCat3", Val = 200})

-- -- print(ParentCat._childHash)

-- -- ParentCat:GetChild("ChildCat1"):Emancipate()
-- -- ParentCat:GetChild("ChildCat2"):Emancipate()
-- -- ParentCat:GetChild("ChildCat3"):Emancipate()

-- -- ParentCat:Adopt(Cat.new{Name = "ChildCat4", Val = 100})
-- -- ParentCat:Adopt(Cat.new{Name = "ChildCat5", Val = 50})
-- -- ParentCat:Adopt(Cat.new{Name = "ChildCat6", Val = 150})


-- -- ParentCat:SwapChildOrder(1, 3)
-- -- ParentCat:Disown(1)
-- -- ParentCat:Disown(ParentCat:GetChild(1))
-- -- ParentCat:Disown(3)

-- -- print(tostring(ParentCat._children, true))
-- -- print(ParentCat:Serialize())

-- -- for child in ParentCat:EachChild() do
-- --     print(child.Name, child.Val)
-- -- end

-- -- for child in ParentCat:EachChild() do
-- --     -- children that meet criteria
-- --     print(child.Name, child.Val)
-- -- end

-- --[[
-- local myScene = Scene.new{MasterCanvas = Canvas.new(1920,1080)}
-- myScene:AddLayer(Layer.new{Canvases = {Canvas.new(320*2, 180*2)}, Name = "Layer1"})
-- myScene:AddLayer(Layer.new{Canvases = {Canvas.new(1920, 1080)}, Name = "Layer2"})

-- Chexcore.MountScene(myScene)

-- local testProp = Prop.new{Size = V{64, 64}, AnchorPoint = V{0.5, 0.5}}

-- myScene:GetLayer(1):Adopt(testProp)


-- print(testProp.Texture:GetSize())


-- -- testing
-- function love.update(dt)
--     Chexcore.Update(dt)
    
--     V{math.random(255), math.random(255), math.random(255), math.random(255) ,math.random(255)}
--     --print(gcinfo())

--     local vec1 = V{ N{1}, N{2} }
--     local vec2 = V{ 3, 4 }
    
--     testProp.Position = testProp.Position + V{ 0.05, 0.055 }
--     testProp.Rotation = testProp.Rotation + 0.01
--     --print(vec1 + vec2) --> V{N{4}, N{6}}
--     print(#myScene._children)
-- end

-- function love.draw()
--     Chexcore.Draw()
    
-- end
-- ]]

-- --print( vec1 + vec2 ) --> V{ N{2}, N{4}, N{6} } 

-- --print(N{-5.4} - N{-5.5})

-- -- local specialNum = N{5.5}
-- -- local realNum = 5.5
-- -- print( specialNum == realNum ) --> false; can't do this!!
-- -- print( specialNum() == realNum) --> true

-- -- Chexcore.UnmountScene(myScene)

-- -- myScene:GetLayer(1):Emancipate()

-- -- local parent = Vector.new{Name="Parent", 1, 2, 3}
-- -- local child = Vector.new{}
-- -- parent:Adopt(child) -- parent is now the parent of child
-- -- local child2 = child:Clone()
-- -- print(child == child2) -- false; different Objects
-- -- print(child2:GetParent()) -- nil; parent was not preserved
-- -- local child3 = child:Clone(true)
-- -- print(child3:GetParent()) -- [Object] Parent

-- -- local myCanvas = Canvas.new()
-- -- myCanvas:SetSize(500, 500)




-- -- local myVec = V{0, 0, 0}
-- -- local myVec2 = myVec:Clone(true)
-- -- myVec:Adopt(myVec2)
-- -- print( #myVec:Clone():GetChildren() ) --> V{1, 2, 3}
-- -- local serial = [[
-- --     PACKAGE { chexcore/code/misc/example } |
    
-- --     rootTable, {
-- --         "example" = @example
-- --     } |
        
-- --     ROOT = rootTable
-- -- ]]

-- local test = deserialize(serial)
-- test.example() --> This is an example function!

print("test")