local Animation = {
    -- properties
    Name = "Animation",

    Clock = 0,
    CurrentFrame = 1,
    LeftBound = 1,
    RightBound = 1,
    Duration = 1,
    PlaybackScaling = 1,
    Loop = true,
    IsPlaying = true,



    -- internal properties
    _cache = setmetatable({}, {__mode = "k"}), -- cache has weak keys
    _quadSize = V{0,0}, -- the amount of pixels in the spritesheet
    _quadSizeFrames = V{0, 0}, -- the amount of frames in the spritesheet
    _frameCallbacks = nil,  -- set when calling Animation:AddCallback() for the first time
    _frames = nil,
    _texture = nil,
    _super = "Object",      -- Supertype
    _global = true
}
Animation._globalUpdate = function (dt)
    for anim in pairs(Animation._cache) do
        if anim.IsPlaying then
            anim:Update(dt * anim.PlaybackScaling)
        end
    end
end

--local mt = {}
--setmetatable(Texture, mt)
local smt, newQuad = setmetatable, love.graphics.newQuad
function Animation.new(spritesheetPath, rows, cols)
    local newAnimation = smt({}, Animation)

    newAnimation._texture = Texture.new(spritesheetPath)
    newAnimation._frames = {}
    -- newAnimation._frameCallbacks = {}

    local sx = newAnimation._texture:GetWidth()
    local sy = newAnimation._texture:GetHeight()
    local segx = sx / cols
    local segy = sy / rows

    for row = 0, rows-1 do
        for col = 0, cols-1 do
            newAnimation._frames[#newAnimation._frames+1] = newQuad(col*segx, row*segy, segx, segy, sx, sy)
        end
    end

    newAnimation._quadSize = V{segx, segy}
    newAnimation._quadSizeFrames = V{rows, cols}
    newAnimation.LeftBound = 1
    newAnimation.RightBound = #newAnimation._frames

    Animation._cache[newAnimation] = true

    return newAnimation
end

local draw = cdrawquad

local clamp = function(n, min, max)
    return n < min and min or n > max and max or n
end

local floor = math.floor
function Animation:DrawToScreen(...)
    -- render the Texture
    
    local range = self.RightBound - self.LeftBound + 1
    local prog = self:GetProgress()
    if prog < 1 then
        self.CurrentFrame = self.LeftBound + floor(range * prog)
    else -- special case for progress == 1
        self.CurrentFrame = self.RightBound
    end

    draw(self._texture._drawable, self._frames[clamp(self.CurrentFrame,1,#self._frames)], self._quadSize[1], self._quadSize[2], ...)
end

-- by default, animation progress is based on delta time; returns 0-1
function Animation:GetProgress()
    -- + 0.001 because if Clock == Duration, then the % will eval to 0 which is wrong
    return (self.Clock%(self.Duration + 0.001)) / self.Duration
end

function Animation:SetFrame(frameNo)
    self.CurrentFrame = frameNo
    local frameProgress = (frameNo - self.LeftBound) / (self.RightBound - self.LeftBound)
    self.Clock = self.Duration * frameProgress
end

function Animation:SetBounds(left, right)
    self.LeftBound = left
    self.RightBound = right or left
end

function Animation:Update(dt)
    -- print(self.Clock)
    if self.Loop then
        self.Clock = (self.Clock + dt) % self.Duration
    else
        self.Clock = (self.Clock + dt)
        if self.Clock >= self.Duration then
            self.IsPlaying = false
            self.Clock = self.Clock - dt
        end
    end


    if self._frameCallbacks then
        local range = self.RightBound - self.LeftBound + 1
        local prog = self:GetProgress()
        local cframe = self.CurrentFrame
        if prog < 1 then
            self.CurrentFrame = self.LeftBound + floor(range * prog)
        else -- special case for progress == 1
            self.CurrentFrame = self.RightBound
        end

        if cframe ~= self.CurrentFrame then
            if self._frameCallbacks[self.CurrentFrame] then
                self._frameCallbacks[self.CurrentFrame](self.CurrentFrame)
            end
        end
    end


    -- if self._frameCallbacks then
    --     local range = self.RightBound - self.LeftBound + 1
    --     local prog = self:GetProgress()
    --     local newFrame
    --     if prog < 1 then
    --         newFrame = self.LeftBound + floor(range * prog)
    --     else -- special case for progress == 1
    --         newFrame = self.RightBound
    --     end
    --     print(newFrame, self.CurrentFrame, self)
    --     if newFrame ~= self.CurrentFrame then
            
    --     end
    -- end

end

function Animation:AddCallback(frameNo, callback)
    print("FRAMENO",frameNo)
    self._frameCallbacks = self._frameCallbacks or {}

    if type(frameNo) == "number" then
        self._frameCallbacks[frameNo] = callback
    else
        for _, v in ipairs(frameNo) do
            self._frameCallbacks[v] = callback
        end
    end
    
end

function Animation:GetSize()
    return self._quadSize:Clone()
end

function Animation:GetWidth()
    return self._quadSize[1]
end

function Animation:GetHeight()
    return self._quadSize[2]
end
return Animation