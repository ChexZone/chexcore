local Sound = {
    -- properties
    Name = "Sound",

    -- internal properties
    _source = nil,

    _super = "Object",      -- Supertype
    _global = true
}

--local mt = {}
--setmetatable(Texture, mt)
local smt = setmetatable
function Sound.new(path, mode)
    local newSound = smt({}, Sound)
    newSound._source = love.audio.newSource(path, mode or "static")
    return newSound
end

local set_fields = {
    Pitch = function(self, v)
        self:SetPitch(v)
    end,

    Volume = function (self, v)
        self:SetVolume(v)
    end,

    Loop = function (self, l)
        self:SetLoop(l)
    end
}
local get_fields = {
    
}

function Sound:__newindex(k, v)
    if set_fields[k] then
        set_fields[k](self, v)
    else
        rawset(self, k, v)
    end
end

function Sound:__index(k)
    return rawget(self, k) or get_fields[k] and get_fields[k](self) or Sound.__index2(self, k)
end

local draw = cdraw
function Sound:Play()
    self._source:play()
end
function Sound:Pause()
    self._source:pause()
end
function Sound:Stop()
    self._source:stop()
end
function Sound:IsPlaying()
    return self._source:isPlaying()
end
function Sound:SetPitch(pitch)
    rawset(self, "Pitch", pitch)
    self._source:setPitch(pitch)
end
function Sound:SetVolume(vol)
    rawset(self, "Volume", vol)
    self._source:setVolume(vol)
end
function Sound:SetLoop(loop)
    rawset(self, "Loop", loop)
    self._source:setLooping(loop)
end

return Sound