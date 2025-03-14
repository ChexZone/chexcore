local Gui = {
    -- properties
    Name = "Gui",
    
    -- internal properties
    _trackingMouse = false,   -- internal flag for if the Gui is tracking the mouse
    _isUnderMouse = false,    -- NOT always being polled! Use Gui:IsUnderMouse() instead
    _selectedBy = {},       -- list of currently clicked mouse buttons on the gui (set in constructor)
    _beingUsed = false,     -- (internal only, for performance) is the gui active with the mouse right now?

    _usingMouse = false,    -- (internal only) whether the mouse is interacting with the gui system


    _super = "Prop",      -- Supertype
    _global = true,

    -- list of "active" gui elements (as referenced by whether they have "OnHover" methods, etc)
    _hoverEvents = setmetatable({}, {__mode = "k"}),
    _selectEvents = setmetatable({}, {__mode = "k"})
}
local rg, rs = rawget, rawset
local Input = Input
local isUnderMouse = Prop.IsUnderMouse

Gui._priorityGlobalUpdate = function ()
    Gui._usingMouse = false

    for guiElement, _ in pairs(Gui._hoverEvents) do
        local newHoverStatus = isUnderMouse(guiElement)

        if newHoverStatus ~= guiElement._isUnderMouse then
            if newHoverStatus == true then -- hover entered
                if guiElement.OnHoverStart then guiElement:OnHoverStart() end
                if guiElement.OnHoverWhileSelected and next(guiElement._selectedBy) then
                    for n in pairs(guiElement._selectedBy) do
                        guiElement:OnHoverWhileSelected(n)
                    end
                end
            else                            -- hover exited
                if guiElement.OnHoverEnd then guiElement:OnHoverEnd() end
            end
            guiElement._isUnderMouse = newHoverStatus
        end
    end

    for guiElement, _ in pairs(Gui._selectEvents) do
        if guiElement._isUnderMouse then
            guiElement._beingUsed = true
            Gui._usingMouse = true

            -- deactivate any ended mouse clicks
            for n in pairs(guiElement._selectedBy) do
                if not Input:IsDown("m_"..n) then
                    guiElement._selectedBy[n] = nil
                    if guiElement.OnSelectEnd then guiElement:OnSelectEnd(n) end
                end
            end

            for i = 1, 5 do
                if Input:JustPressed("m_"..i) then
                    if guiElement.OnSelectStart then guiElement:OnSelectStart(i) end
                    guiElement._selectedBy[i] = true
                end
            end
        elseif guiElement._beingUsed then -- there might still be mouse selection
            local c = 0
            for n in pairs(guiElement._selectedBy) do
                if not Input:IsDown("m_"..n) then
                    guiElement._selectedBy[n] = nil
                    if guiElement.OnSelectEnd then guiElement:OnSelectEnd(n) end
                else
                    Gui._usingMouse = true
                end
                
                c = c + 1
            end

            if c == 0 then -- set the gui as "not in use" if all buttons are released
                guiElement._beingUsed = false
            end
        end
    end
end

function Gui.UsingMouse()
    return Gui._usingMouse
end




local listeners = {
    OnHoverStart = function (obj, key, val)
        rs(obj, key, val)
        Gui._hoverEvents[obj] = true
        obj._trackingMouse = true
        rs(obj, "_isUnderMouse", rg(obj, "_isUnderMouse") or false)
    end,
    OnHoverEnd = function (obj, key, val)
        rs(obj, key, val)
        Gui._hoverEvents[obj] = true
        obj._trackingMouse = true
        rs(obj, "_isUnderMouse", rg(obj, "_isUnderMouse") or false)
    end,
    OnSelectStart = function (obj, key, val)
        rs(obj, key, val)
        Gui._hoverEvents[obj] = true
        Gui._selectEvents[obj] = true
        obj._trackingMouse = true
        rs(obj, "_isUnderMouse", rg(obj, "_isUnderMouse") or false)
    end,
    OnSelectEnd = function (obj, key, val)
        rs(obj, key, val)
        Gui._hoverEvents[obj] = true
        Gui._selectEvents[obj] = true
        obj._trackingMouse = true
        rs(obj, "_isUnderMouse", rg(obj, "_isUnderMouse") or false)
    end,
    OnHoverWhileSelected = function (obj, key, val)
        rs(obj, key, val)
        Gui._hoverEvents[obj] = true
        Gui._selectEvents[obj] = true
        obj._trackingMouse = true
        rs(obj, "_isUnderMouse", rg(obj, "_isUnderMouse") or false)
    end,
}


function Gui.__newindex(obj, key, val)
    if listeners[key] then
        listeners[key](obj, key, val)
    else
        rs(obj, key, val)
    end
end

function Gui.new(properties)
    local newGui = Gui:Connect( Gui:SuperInstance() )
    
    if properties then
        for prop, val in pairs(properties) do
            newGui[prop] = val
        end
    end

    newGui._selectedBy = rg(newGui, "_selectedBy") or {}

    return newGui
end

function Gui:IsUnderMouse()
    return Gui._hoverEvents[self] and self._isUnderMouse or Prop.IsUnderMouse(self)
end

function Gui:GetMouseTracking()
    return self._trackingMouse
end

function Gui:SetMouseTracking(b)
    if b then
        self._trackingMouse = true
        Gui._hoverEvents[self] = true
        Gui._selectEvents[self] = true
    else
        self._trackingMouse = false
        Gui._hoverEvents[self] = nil
        Gui._selectEvents[self] = nil
    end
end


return Gui