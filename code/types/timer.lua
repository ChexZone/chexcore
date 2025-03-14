local Timer = { -- mini timer system!
    -- properties
    Name = "Timer",
    -- internal properties
    _timers = {},
    _frameDelta = 1/Chexcore.FrameLimit,

    _super = "Object",      -- Supertype
    _global = true
}


-- USAGE:
-- Timer.Schedule(secondsDuration, callback, [arg, arg, ...])
--      After `secondsDuration`, will `callback(arg, arg, ...)`

-- Timer.Schedule(secondsDuration, table, key, value, [key, value, ...])
--      After `secondsDuration`, will `table[key] = value` for all [key, value]

-- Timer.ScheduleFrames() is there too

local pairs, type = pairs, type
Timer._globalUpdate = function(dt)
    local time = Chexcore._clock
    for timer, endTime in pairs(Timer._timers) do
        if time >= endTime then -- timer expired!
            Timer._timers[timer] = nil
            if type(timer[1]) == "function" then -- function call variant
                timer[1](unpack(timer[2]))
            else -- key/value pair variant
                for i = 2, #timer[2], 2 do
                    timer[1][timer[2][i-1]] = timer[2][i]
                end
            end
        end
    end
end

function Timer.Schedule(duration, funcOrObj, ...)
    Timer._timers[{funcOrObj, {...}}] = Chexcore._clock + duration
end

function Timer.ScheduleFrames(frames, ...)
    Timer.Schedule(frames*Timer._frameDelta, ...)
end

return Timer