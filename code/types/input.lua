local Input = {
    -- properties
    Name = "Input",           -- Easy identifier

    Active = true,            -- will only take input while Active
    CustomMap = nil,

    LeftStickThreshold = 0.5,
    RightStickThreshold = 0.5,
    LeftTriggerThreshold = 0.7,
    RightTriggerThreshold = 0.7,


    -- internal properties
    _isDown = {},
    _justPressed = {},
    _gamepadAxes = {},
    _cache = setmetatable({}, {__mode = "k"}), -- cache has weak keys
    _super = "Object",      -- Supertype
    _global = true
}

-- love.mouse = love.mouse or {}

Input._globalUpdate = function (dt)
    -- get joystick axis info
    local gamepadInfo = {}
    local gamepadIds = {}
    for i, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            gamepadIds[#gamepadIds+1] = i
            gamepadInfo["gp"..i.."_leftx"] = joystick:getGamepadAxis("leftx")
            gamepadInfo["gp"..i.."_lefty"] = joystick:getGamepadAxis("lefty")
            gamepadInfo["gp"..i.."_rightx"] = joystick:getGamepadAxis("rightx")
            gamepadInfo["gp"..i.."_righty"] = joystick:getGamepadAxis("righty")
            gamepadInfo["gp"..i.."_triggerleft"] = joystick:getGamepadAxis("triggerleft")
            gamepadInfo["gp"..i.."_triggerright"] = joystick:getGamepadAxis("triggerright")
        end
    end



    -- for global non-instanced input
    for k, _ in pairs(Input._justPressed) do
        Input._justPressed[k] = nil
    end

    -- for all input objects
    for listener in pairs(Input._cache) do
        if listener.Active then
            for k, _ in pairs(listener._justPressed) do
                listener._justPressed[k] = nil
            end

            
            for _, gamepadId in ipairs(gamepadIds) do
                local lx, ly, rx, ry, tl, tr = "gp"..gamepadId.."_leftx", "gp"..gamepadId.."_lefty",
                                              "gp"..gamepadId.."_rightx", "gp"..gamepadId.."_righty",
                                              "gp"..gamepadId.."_triggerleft", "gp"..gamepadId.."_triggerright"

                if listener._gamepadAxes then
                    -- left stick right
                    if (gamepadInfo[lx] >= listener.LeftStickThreshold) and
                    not ((listener._gamepadAxes[lx] or 0) >= listener.LeftStickThreshold) and
                    not listener._justPressed["gp_lsright"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_lsright")
                    elseif listener._isDown["gp_lsright"] and ((listener._gamepadAxes[lx] or 0) >= listener.LeftStickThreshold) and
                    not (gamepadInfo[lx] >= listener.LeftStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_lsright")
                    end

                    -- left stick left
                    if (gamepadInfo[lx] <= -listener.LeftStickThreshold) and
                    not ((listener._gamepadAxes[lx] or 0) <= -listener.LeftStickThreshold) and
                    not listener._justPressed["gp_lsleft"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_lsleft")
                    elseif listener._isDown["gp_lsleft"] and ((listener._gamepadAxes[lx] or 0) <= -listener.LeftStickThreshold) and
                    not (gamepadInfo[lx] <= -listener.LeftStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_lsleft")
                    end

                    -- left stick up
                    if (gamepadInfo[ly] <= -listener.LeftStickThreshold) and
                    not ((listener._gamepadAxes[ly] or 0) <= -listener.LeftStickThreshold) and
                    not listener._justPressed["gp_lsup"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_lsup")
                    elseif listener._isDown["gp_lsup"] and ((listener._gamepadAxes[ly] or 0) <= -listener.LeftStickThreshold) and
                    not (gamepadInfo[ly] <= -listener.LeftStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_lsup")
                    end

                    -- left stick down
                    if (gamepadInfo[ly] >= listener.LeftStickThreshold) and
                    not ((listener._gamepadAxes[ly] or 0) >= listener.LeftStickThreshold) and
                    not listener._justPressed["gp_lsdown"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_lsdown")
                    elseif listener._isDown["gp_lsdown"] and ((listener._gamepadAxes[ly] or 0) >= listener.LeftStickThreshold) and
                    not (gamepadInfo[ly] >= listener.LeftStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_lsdown")
                    end

                    -- right stick right
                    if (gamepadInfo[rx] >= listener.RightStickThreshold) and
                    not ((listener._gamepadAxes[rx] or 0) >= listener.RightStickThreshold) and
                    not listener._justPressed["gp_rsright"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_rsright")
                    elseif listener._isDown["gp_rsright"] and ((listener._gamepadAxes[rx] or 0) >= listener.RightStickThreshold) and
                    not (gamepadInfo[rx] >= listener.RightStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_rsright")
                    end

                    -- right stick left
                    if (gamepadInfo[rx] <= -listener.RightStickThreshold) and
                    not ((listener._gamepadAxes[rx] or 0) <= -listener.RightStickThreshold) and
                    not listener._justPressed["gp_rsleft"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_rsleft")
                    elseif listener._isDown["gp_rsleft"] and ((listener._gamepadAxes[rx] or 0) <= -listener.RightStickThreshold) and
                    not (gamepadInfo[rx] <= -listener.RightStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_rsleft")
                    end

                    -- right stick up
                    if (gamepadInfo[ry] <= -listener.RightStickThreshold) and
                    not ((listener._gamepadAxes[ry] or 0) <= -listener.RightStickThreshold) and
                    not listener._justPressed["gp_rsup"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_rsup")
                    elseif listener._isDown["gp_rsup"] and ((listener._gamepadAxes[ry] or 0) <= -listener.RightStickThreshold) and
                    not (gamepadInfo[ry] <= -listener.RightStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_rsup")
                    end

                    -- right stick down
                    if (gamepadInfo[ry] >= listener.RightStickThreshold) and
                    not ((listener._gamepadAxes[ry] or 0) >= listener.RightStickThreshold) and
                    not listener._justPressed["gp_rsdown"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_rsdown")
                    elseif listener._isDown["gp_rsdown"] and ((listener._gamepadAxes[ry] or 0) >= listener.RightStickThreshold) and
                    not (gamepadInfo[ry] >= listener.RightStickThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_rsdown")
                    end

                    -- left trigger
                    if (gamepadInfo[tl] >= listener.LeftTriggerThreshold) and
                    not ((listener._gamepadAxes[tl] or 0) >= listener.LeftTriggerThreshold) and
                    not listener._justPressed["gp_lefttrigger"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_lefttrigger")
                    elseif listener._isDown["gp_lefttrigger"] and ((listener._gamepadAxes[tl] or 0) >= listener.LeftTriggerThreshold) and
                    not (gamepadInfo[tl] >= listener.LeftTriggerThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_lefttrigger")
                    end

                    -- right trigger
                    if (gamepadInfo[tr] >= listener.RightTriggerThreshold) and
                    not ((listener._gamepadAxes[tr] or 0) >= listener.RightTriggerThreshold) and
                    not listener._justPressed["gp_lefttrigger"] then
                        listener:VirtualPress("gp"..gamepadId, "gp_lefttrigger")
                    elseif listener._isDown["gp_lefttrigger"] and ((listener._gamepadAxes[tr] or 0) >= listener.RightTriggerThreshold) and
                    not (gamepadInfo[tr] >= listener.RightTriggerThreshold) then
                        listener:VirtualRelease("gp"..gamepadId, "gp_lefttrigger")
                    end
                end
            end

            listener._gamepadAxes = gamepadInfo
        end
    end
end

local function sendInputDown(device, key)
    
    Input._isDown[key] = true
    Input._justPressed[key] = true
    
    for listener in pairs(Input._cache) do
        if listener.Active then
            listener:VirtualPress(device, key)
        end
    end
end

local function sendInputUp(device, key)
    Input._isDown[key] = false

    for listener in pairs(Input._cache) do
        if listener.Active then
            listener:VirtualRelease(device, key)
        end
    end
end

function Input.new(map)
    local newListener = setmetatable({}, Input)
    Input._cache[newListener] = true

    newListener.CustomMap = map
    newListener._isDown = {}
    newListener._justPressed = {}

    return newListener
end


function love.keypressed(key, scancode)
    sendInputDown("kb", key)
end

function love.keyreleased(key, scancode)
    sendInputUp("kb", key)
end

function love.gamepadpressed(joystick, button)
    local name = joystick:getName()
    local index = joystick:getConnectedIndex()
    sendInputDown("gp"..index, "gp_"..button)
    
end

function love.gamepadreleased(joystick, button)
    local name = joystick:getName()
    local index = joystick:getConnectedIndex()
    sendInputUp("gp"..index, "gp_"..button)
end

if love._console ~= "3ds" then
    function love.mousepressed(x, y, button, isTouch)
        sendInputDown("mouse", "m_"..tostring(button))
    end

    function love.mousereleased(x, y, button, isTouch)
        sendInputUp("mouse", "m_"..tostring(button))
    end

    function love.wheelmoved(x, y)
        if y > 0 then
            sendInputDown("mouse", "m_wheelup")
            sendInputUp("mouse", "m_wheelup")
        elseif y < 0 then
            sendInputDown("mouse", "m_wheeldown")
            sendInputUp("mouse", "m_wheeldown")
        end
    end
end

function Input:IsDown(key)
    return self.Active and (self._isDown[key] or false)
end

function Input:JustPressed(key)
    return self.Active and (self._justPressed[key] or false)
end


function Input:VirtualPress(device, key)
    self._isDown[key] = true
    if self.CustomMap and self.CustomMap[key] then
        self:Press(device, self.CustomMap[key])
        self._isDown[self.CustomMap[key]] = true
        self._justPressed[self.CustomMap[key]] = true
    else
        self:Press(device, key)
        self._isDown[key] = true
        self._justPressed[key] = true
    end
end

function Input:VirtualRelease(device, key)
    self._isDown[key] = false
    if self.CustomMap and self.CustomMap[key] then
        self:Release(device, self.CustomMap[key])
        self._isDown[self.CustomMap[key]] = false
    else
        self:Release(device, key)
    end
end

function Input:Press(device, key)
    -- dummy
end

function Input:Release(device, key)
    -- dummy
end

local getMousePos
if love._console == "3ds" then
    getMousePos = function ()
        return 0,0
    end
else
    getMousePos = love.mouse and love.mouse.getPosition or function() return 0, 0 end
end

local getScreenSize = love.graphics.getDimensions
local vec = V

local oldX, oldY = 0, 0

-- returns a 2D vector with a 0-1 float range showing the XY position of the mouse on the screen.
-- also returns a boolean as a second argument, "true" if Chexcore thinks the mouse is on-screen and "false" otherwise 
function Input:GetMousePosition()
    local px, py = getMousePos()
    local sx, sy = getScreenSize()


    if oldX == px and oldY == py then
        if (px == sx-1 or px == 0) or (py == sy-1 or py == 0) then
            return vec{px/sx, py/sy}, false
        end
    end

    oldX = px; oldY = py
    return vec{px/sx, py/sy}, true
end


return Input