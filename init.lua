_G.Chexcore = {
    -- internal properties
    _clock = 0,             -- keeps track of total game run time
    _cpuTime = 0,           -- how long (seconds) the last frame took to process
    _preciseClock = 0,      -- return value of love.timer.getTime()
    _lastFrameTime = 0,     -- how long the previous frame actually took
    _graphicsStats = {},        -- the output of love.graphics.getStats()

    _frameDelay = 0,        -- (sec) add to this value to wait extra time before the next frame

    _types = {},            -- stores all type references
    _scenes = {},           -- stores all mounted Scene references
    _globalUpdates = {},    -- for any types that want independent update control
    _priorityGlobalUpdates = {},    -- for any types that want to update before globalUpdates do
    _globalDraws = {},      -- for any types that want independent draw control
    _recordingCanvases = {},    -- a container for any Canvas recorded with Canvas:Record(); ordered list items in format {progress, numFrames, canvas, outputPath}

    -- constants
    MAX_TABLE_OUTPUT_INDENT = 30, -- how many layers deep tostring() will expand a table into.
}

-- when an Object is indexed, this variable helps keep the referenced up the type chain
_G.OBJSEARCH = nil

-- set default LOVE values
love.graphics.setDefaultFilter("nearest", "nearest", 1)

-- helper functions to make life easier ~ 
require "chexcore.code.misc.helper"

function love.draw()
    
end

function love.update()
    
end

---------------- UPDATE LOOPS ------------------
function Chexcore.Update(dt)
    Chexcore._clock = Chexcore._clock + dt * 1
    

    for _, func in ipairs(Chexcore._priorityGlobalUpdates) do
        func(dt)
    end
    
    -- update all active Scenes
    for sceneid, scene in ipairs(Chexcore._scenes) do
        if scene.Active then
            scene:Update(dt)
        end
    end


    for _, func in ipairs(Chexcore._globalUpdates) do
        func(dt)
    end

    for i, tab in ipairs(Chexcore._recordingCanvases) do
        tab[1] = tab[1] + 1

        print(tab)
        tab[3]._drawable:newImageData():encode("png", makeDir(tab[4] .. "/" .. tostring(tab[1]) .. ".png"))

        if tab[1] == tab[2] then
            table.remove(Chexcore._recordingCanvases, i)
        end
    end
end

function Chexcore.Draw(params)

    params = params or {}
    
    -- draw all visible Scenes
    for id, scene in ipairs(Chexcore._scenes) do
        if scene.Visible then
            scene:Draw(params)
        end
    end

    for _, func in ipairs(Chexcore._globalDraws) do
        func()
    end

    Chexcore._graphicsStats = love.graphics.getStats()
end
------------------------------------------------



--------------- CORE METHODS -------------------
local typeBecauseIDecidedToUseABadName = type
function Chexcore:AddType(type)
    if typeBecauseIDecidedToUseABadName(type) == "string" then
        type = require(type)
    end
    -- check: if there is no type name, assign it to the default Object.Name
    type._type = type._type or type.Name or "NewObject"

    Chexcore._types[type._type] = type
    -- insert into global namespace, if needed
    if rawget(type, "_global") then
        _G[type._type] = type
    end
    
    if type._aliases then
        for _, alias in ipairs(type._aliases) do
            Chexcore._types[alias] = type

            if rawget(type, "_global") then
                _G[alias] = type
            end
        end
    end

    type._standardConstructor = function (properties)
        local obj = type:SuperInstance()
        if properties then
            for prop, val in pairs(properties) do
                obj[prop] = val
            end
        end
        return type:Connect(obj)
    end

    -- apply a basic constructor if one is not present
    if not (type._abstract or type.new) then
        type.new = type._standardConstructor
    elseif type._abstract then
        type.new = false
    end

    -- assume the type may not have a metatable yet
    local metatable = getmetatable(type) or {}

    if type._priorityGlobalUpdate then
        Chexcore._priorityGlobalUpdates[#Chexcore._priorityGlobalUpdates+1] = type._priorityGlobalUpdate
    end
    if type._globalUpdate then
        Chexcore._globalUpdates[#Chexcore._globalUpdates+1] = type._globalUpdate
    end
    if type._globalDraw then
        Chexcore._globalDraws[#Chexcore._globalDraws+1] = type._globalDraw
    end

    -- apply the supertype, if there is one
    -- Object's basic type has a special metatable, so it is ignored
    --print(type.Name .. ": ")
    --print(metatable)
    if type._type ~= "Object" then
        metatable.__index = Chexcore._types[type._super]
    end
    
    -- apply a reference to the supertype
    type._superReference = Chexcore._types[type._super]

    type.__index2 = function(obj, key)
        if rawget(type, key) then
            _G.OBJSEARCH = nil
            return rawget(type, key)
        else
            if not _G.OBJSEARCH then
                -- mount the object
                _G.OBJSEARCH = obj
            end
            
            return Chexcore._types[type._super][key]
        end
    end

    -- either set to a self-defined __index, or use the default __index2
    type.__index = type.__index or type.__index2
    
    type.__newindex = type.__newindex or type._superReference.__newindex

    return setmetatable(type, metatable)
end

function Chexcore.MountScene(scene)
    Chexcore._scenes[#Chexcore._scenes+1] = scene
end

function Chexcore.UnmountScene(scene)
    for i = 1, #Chexcore._scenes do
        if Chexcore._scenes[i] == scene then
            table.remove(Chexcore._scenes, i)
            return true
        end
    end
    return false
end

function Chexcore.RecordCanvas(canvas, numFrames, outputPath)
    Chexcore._recordingCanvases[#Chexcore._recordingCanvases+1] = {0, numFrames, canvas, outputPath}
end

local fps = 0
Chexcore.FrameLimit = 500
local frameTime = 0
-- local mode = "web"

local start_time = 0

local windows = nestVideo and nestVideo.getFramebuffers()

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    return function()
        Chexcore._preciseClock = love.timer.getTime()

        -- if mode ~= "web" then
            start_time = Chexcore._preciseClock
        -- end
        
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        Chexcore._lastFrameTime = dt
        
        local frameLimit = (Chexcore._scenes[1] and Chexcore._scenes[1].FrameLimit) or Chexcore.FrameLimit

        -- if mode == "web" then frameLimit = frameLimit * 1.4 end

        -- Call update and draw
        frameTime = frameTime + dt

        if frameTime >= 1/frameLimit and love.graphics and love.graphics.isActive() then
            frameTime = frameTime - 1/frameLimit

            if love.update then
                love.update(1/frameLimit)
            end
            Chexcore.Update(1/frameLimit)



            local screens = love.graphics.getScreens and love.graphics.getScreens()

            if windows then
                for _, screen in ipairs(windows) do
                    love.graphics.setActiveScreen(screen:getName())
                    

                    screen:renderTo(function()
                        Chexcore.Draw{screen = screen:getName()}
                        -- love.graphics.clear(love.graphics.getBackgroundColor())
                        
                        if love.draw then
                            love.draw(screen:getName())
                        end
                        
                        
                    end)
                    
                    screen:draw()
                    
                end
                
            elseif screens then
                for _, screen in ipairs(screens) do
                    love.graphics.origin()
                    love.graphics.setActiveScreen(screen)
                    
                    love.graphics.clear(love.graphics.getBackgroundColor())
                    if love.draw then love.draw(screen) end
                    Chexcore.Draw{screen = screen}
                end
            else
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())
                if love.draw then love.draw() end
                Chexcore.Draw{}
            end
            

            love.graphics.present()
        end


        
        local timeToWait = _G.TRUE_FPS and 1/_G.TRUE_FPS or 1/frameLimit
        -- local frameOverTime = dt - timeToWait --math.max(dt - timeToWait, 0)
        
        local end_time = love.timer.getTime()

        if love.timer then
            local waitTime = timeToWait - (end_time - start_time)
            if mode == "web" then
                waitTime = waitTime / 4
            end
            love.timer.sleep(waitTime + Chexcore._frameDelay)
        end

        Chexcore._cpuTime = (end_time - start_time)
        Chexcore._frameDelay = 0

        -- if mode == "web" then start_time = Chexcore._preciseClock end
    end
end


------------------------------------------------


-- !!!!!!!!!!!!!!!!!! INITIALIZATION STUFF !!!!!!!!!!!!!!!!!!!! --

-- load in some essential types
local types = {
    "chexcore.code.types.object",
    "chexcore.code.types.vector",
    "chexcore.code.types.constant",
    "chexcore.code.types.number",
    "chexcore.code.types.timer",
    "chexcore.code.types.input",
    "chexcore.code.types.ray",
    "chexcore.code.types.sound",
    "chexcore.code.types.texture",
    "chexcore.code.types.animation",
    "chexcore.code.types.font",
    "chexcore.code.types.prop",
    "chexcore.code.types.group",
    "chexcore.code.types.gui",
    "chexcore.code.types.text",
    "chexcore.code.types.particles",
    "chexcore.code.types.tilemap",
    "chexcore.code.types.camera",
    "chexcore.code.types.scene",
    "chexcore.code.types.layer",
    "chexcore.code.types.canvas",
    "chexcore.code.types.shader"
}

for _, type in ipairs(types) do
    Chexcore:AddType(require(type))
end


-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! --

return Chexcore