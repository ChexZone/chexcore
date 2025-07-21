local StreamSound = {
    -- properties
    Name = "StreamSound",

    SampleRate = 44100,
    BufferSize = 2048,
    Channels = 2,
    BitDepth = 16,
    BufferCount = 8,

    -- internal properties

    _source = nil,
    _soundData = nil,
    _position = 0,
    _lastBufferTimestamp = 0,
    _realPos = 0,

    _cache = setmetatable({}, {__mode = "k"}), -- cache has weak keys
    _super = "Sound",      -- Supertype
    _global = true
}

StreamSound._globalUpdate = function (dt)
    for sound in pairs(StreamSound._cache) do
        sound:PushBuffer()
    end
end

--local mt = {}
--setmetatable(Texture, mt)
local smt = setmetatable
function StreamSound.new(path, mode)
    -- local newSound = Sound.new(path,mode)

    

    local newSound = {}

    newSound.TestNoise = Sound.new("game/assets/sounds/basketball_1.wav")

    smt(newSound, StreamSound)

    newSound._soundData = love.sound.newDecoder(path, newSound.BufferSize)
    newSound.SampleRate = newSound._soundData:getSampleRate()
    newSound.Channels = newSound._soundData:getChannelCount()
    newSound.BitDepth = newSound._soundData:getBitDepth()

    newSound._bufferHistory = {}
    newSound._source = love.audio.newQueueableSource(newSound.SampleRate, newSound.BitDepth, newSound.Channels, newSound.BufferCount)
    StreamSound._cache[newSound] = true

    newSound:SetPitch(2)
    -- newSound._soundData:seek(15)
    return newSound
end

-- local set_fields = {
--     Pitch = function(self, v)
--         self:SetPitch(v)
--     end,

--     Volume = function (self, v)
--         self:SetVolume(v)
--     end,

--     Loop = function (self, l)
--         self:SetLoop(l)
--     end
-- }
-- local get_fields = {
    
-- }

-- function Sound:__newindex(k, v)
--     if set_fields[k] then
--         set_fields[k](self, v)
--     else
--         rawset(self, k, v)
--     end
-- end

-- function Sound:__index(k)
--     return rawget(self, k) or get_fields[k] and get_fields[k](self) or Sound.__index2(self, k)
-- end

-- function StreamSound:PushBuffer()
--     if self._source:getFreeBufferCount() > 0 and self._position < self._soundData:getSampleCount() then
--         local buffer = love.sound.newSoundData(self.BufferSize, self.SampleRate, self.BitDepth, self.Channels)
--         -- print("STARTIN")
--         for i = 0, self.BufferSize - 1 do
--             -- print("BUFFERIN")
--             for c = 0, self.Channels - 1 do
--                 local sample = 0
--                 -- print("CHECKIN", self._position + i, self._soundData:getSampleCount())
--                 if self._position + i < self._soundData:getSampleCount() then
--                     print(self._position + i, c, self._soundData:getChannelCount())
--                     sample = self._soundData:getSample(self._position + i, c)
--                 end
--                 buffer:setSample(i, c, sample)
--             end
--         end

--         self._position = self._position + self.BufferSize
--         self._source:queue(buffer)
--     end

--     if not self._source:isPlaying() then
--         self._source:play()
--     end
-- end

function StreamSound:PushBuffer(recurse)
    -- print(self._source:getProcessedBufferCount())
    local chunksPushed = 0
    while self._source:getFreeBufferCount() > 0 do
        
        self._lastBufferRealTime = Chexcore._realTime
        self._lastBufferSongTime = self._position / self.SampleRate
        -- print("QUEUEING",self._source:getFreeBufferCount(), "BUFFERS", self._lastBufferSongTime)
        -- print("EHEAHGEAHYUGHEGYHE")
        local chunk = self._soundData:decode(self.BufferSize)
        
        self._samplesAddedLastChunk = chunk and chunk:getSampleCount() or 0


        self._position = self._position + (chunk and chunk:getSampleCount() or 0)

        table.insert(self._bufferHistory, 1, {self._position, Chexcore._realTime})
        if self._bufferHistory[self.BufferCount+1] and self._bufferHistory[self.BufferCount+1][1] > self._bufferHistory[self.BufferCount][1] then
            self.TestNoise:Play()
        end
        self._bufferHistory[self.BufferCount+1] = nil

        if not chunk or chunk:getSampleCount() == 0 then
            -- Decoder is out of data; stop pushing
            self._soundData:seek(0)
            self._lastBufferSongTime = 0
            self._position = 0
            self._realPos = 0

            if not recurse then
                return self:PushBuffer(true) -- try one more time from the start
            elseif chunksPushed == 0 then
                return -- give up
            end

            -- chunk = self._soundData:decode(self.BufferSize)
            -- self._position = self._position + (chunk and chunk:getSampleCount() or 0)
            -- self._samplesAddedLastChunk = self._samplesAddedLastChunk + chunk:getSampleCount()
            -- -- If still empty, stop trying
            -- if not chunk or chunk:getSampleCount() == 0 then return end
        else
            chunksPushed = chunksPushed + 1
        end
        self._source:queue(chunk, chunk:getSize())
        if not self._source:isPlaying() then self._source:play() end
        
    end

    -- self._timePos = math.max((self._position - self._samplesAddedLastChunk), 0)/self.SampleRate + (Chexcore._preciseClock - self._lastBufferRealTime)
    
    
    self._realPos = math.max(
        math.max(self._bufferHistory[#self._bufferHistory][1], 0)/self.SampleRate + ((Chexcore._realTime - self._lastBufferRealTime)*(self.Pitch or 1))
    )
    -- local oldest = self._bufferHistory[#self._bufferHistory]
    -- local samplesSince = (Chexcore._preciseClock - oldest[2]) * self.SampleRate
    -- local currentSampleEstimate = oldest[1] + samplesSince
    -- local currentTimeEstimate = currentSampleEstimate / self.SampleRate
    -- self._realPos = currentTimeEstimate
    -- print("eek", samplesSince, oldest[1], currentTimeEstimate)
    -- self._realPos = self._lastBufferSongTime + (Chexcore._clock - self._lastBufferRealTime)
    
    -- self:SetPitch((math.sin(Chexcore._preciseClock)+1)/2)

    print("pos", self:Tell(), self._position / self.SampleRate)
    -- print(self._bufferHistory)
end

function StreamSound:Tell()
    return self._realPos
end

-- local draw = cdraw
-- function StreamSound:Play()
--     self._source:play()
-- end
-- function Sound:Pause()
--     self._source:pause()
-- end
-- function Sound:Stop()
--     self._source:stop()
-- end
-- function Sound:IsPlaying()
--     return self._source:isPlaying()
-- end
-- function Sound:SetPitch(pitch)
--     rawset(self, "Pitch", pitch)
--     self._source:setPitch(pitch)
-- end
-- function Sound:SetVolume(vol)
--     rawset(self, "Volume", vol)
--     self._source:setVolume(vol)
-- end
-- function Sound:SetLoop(loop)
--     rawset(self, "Loop", loop)
--     self._source:setLooping(loop)
-- end

return StreamSound