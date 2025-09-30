local Particles = {
    -- properties
    Name = "Particles",

    ParticleTexture = Animation.new("chexcore/assets/images/test/particle_test.png", 1, 5):Properties{
        Duration = 1,
    },
    
    RelativePosition = false,
    ParticleAnchorPoint = V{1, 1},   -- AnchorPoint of particles
    ParticlePosition = V{0, 0},
    ParticleVelocity = nil,-- V{0, 0},
    ParticleAcceleration = nil,-- V{0, 0},
    ParticleColor = V{1,1,1,0.5},
    ParticleSize = V{16, 16},
    ParticleSizeVelocity = nil,--V{0, 0},    -- set when needed
    ParticleColorVelocity = nil,--V{0,0,0,0},          -- set when needed
    ParticleRotation = 0,
    ParticleRotVelocity = 0,
    ParticleLifeTime = 1,   -- measured in seconds

    LoopAnim = true,       -- whether to loop animated particles


    
    -- internal properties
    _super = "Prop",      -- Supertype
    _global = true,
    _cache = setmetatable({}, {__mode = "k"}), -- cache has weak keys
    _systemStartTime = 0,   -- set in constructor, from Chexcore._clock
    _systemLifeTime = 0,    -- how long has this particle system been running? (based on _systemStartTime)
    
    _filledSlots = {},  -- set in constructor
    _vacantSlots = {},  -- set in constructor
    _deathTimes = {},   -- set in constructor
    _startTimes = {},   -- set in constructor

    _positions = nil,   -- set once a particle is created with its own Position
    _sizes = nil,
    _rotations = nil,
    _colors = nil,

    _velocities = nil,
    _rotVelocities = nil,
    _sizeVelocities = nil,
    _colorVelocities = nil,

    _accelerations = nil,
    _rotAccelerations = nil,
    _sizeAccelerations = nil,

    _customFuncs = nil,
}

local Chexcore = Chexcore

local initializers = {
    _positions = function (self)
        -- initialize "positions"
        self._positions = {}
            
        -- now EVERY particle needs one:
        for _, id in ipairs(self._filledSlots) do
            self._positions[id*2-1] = self.ParticlePosition[1]
            self._positions[id*2] = self.ParticlePosition[2]
        end
    end,

    _sizes = function (self)
        -- initialize "_sizes"
        self._sizes = {}
        -- now EVERY particle needs one:
        for _, id in ipairs(self._filledSlots) do
            self._sizes[id*2-1] = self.ParticleSize[1]
            self._sizes[id*2] = self.ParticleSize[2]
        end
    end,

    _colors = function (self)
        -- initialize "_colors"
        self._colors = {}
        -- now EVERY particle needs one:
        for _, id in ipairs(self._filledSlots) do
            self._colors[id*4-3] = self.ParticleColor[1] or 0
            self._colors[id*4-2] = self.ParticleColor[2] or 0
            self._colors[id*4-1] = self.ParticleColor[3] or 0
            self._colors[id*4] = self.ParticleColor[4] or 1
        end
    end,

    _rotations = function (self)
        -- initialize "_rotations"
        self._rotations = {}
            
        -- now EVERY particle needs one:
        for _, id in ipairs(self._filledSlots) do
            self._rotations[id] = self.ParticleRotation
        end
    end,

    _rotVelocities = function (self)
        -- initialize "_rotVelocities"
        self._rotVelocities = {}

        -- now EVERY particle needs one:
        for _, id in ipairs(self._filledSlots) do
            self._rotVelocities[id] = self.ParticleRotVelocity
        end
    end,

    _rotAccelerations = function (self)
        -- initialize "_rotAccelerations"
        self._rotAccelerations = {}

        -- now EVERY particle needs one:
        for _, id in ipairs(self._filledSlots) do
            self._rotAccelerations[id] = self.ParticleRotAcceleration
        end
    end,

    _velocities = function (self)
        -- initialize "_velocities"
        self._velocities = {}
            
        -- now EVERY particle needs one:
        local dvx = self.ParticleVelocity and self.ParticleVelocity[1] or 0
        local dvy = self.ParticleVelocity and self.ParticleVelocity[2] or 0
        for _, id in ipairs(self._filledSlots) do
            self._velocities[id*2-1] = dvx
            self._velocities[id*2] = dvy
        end
    end,

    _accelerations = function (self)
        -- initialize "_accelerations"
        self._accelerations = {}
            
        -- now EVERY particle needs one:
        local dvx = self.ParticleAcceleration and self.ParticleAcceleration[1] or 0
        local dvy = self.ParticleAcceleration and self.ParticleAcceleration[2] or 0
        for _, id in ipairs(self._filledSlots) do
            self._accelerations[id*2-1] = dvx
            self._accelerations[id*2] = dvy
        end
    end,

    _sizeVelocities = function (self)
        -- initialize "_sizeVelocities"
        self._sizeVelocities = {}
            
        -- now EVERY particle needs one:
        local dvx = self.ParticleSizeVelocity and self.ParticleSizeVelocity[1] or 0
        local dvy = self.ParticleSizeVelocity and self.ParticleSizeVelocity[2] or 0
        for _, id in ipairs(self._filledSlots) do
            self._sizeVelocities[id*2-1] = dvx
            self._sizeVelocities[id*2] = dvy
        end
    end,

    _sizeAccelerations = function (self)
        -- initialize "_sizeAccelerations"
        self._sizeAccelerations = {}
            
        -- now EVERY particle needs one:
        local dvx = self.ParticleSizeAcceleration and self.ParticleSizeAcceleration[1] or 0
        local dvy = self.ParticleSizeAcceleration and self.ParticleSizeAcceleration[2] or 0
        for _, id in ipairs(self._filledSlots) do
            self._sizeAccelerations[id*2-1] = dvx
            self._sizeAccelerations[id*2] = dvy
        end
    end,

    _colorVelocities = function (self)
        -- initialize "_colorVelocities"
        self._colorVelocities = {}
    
        -- now EVERY particle needs one:
        local dvr = self.ParticleColorVelocity and self.ParticleColorVelocity[1] or 0
        local dvg = self.ParticleSizeVelocity and self.ParticleSizeVelocity[2] or 0
        local dvb = self.ParticleSizeVelocity and self.ParticleSizeVelocity[3] or 0
        local dva = self.ParticleSizeVelocity and self.ParticleSizeVelocity[4] or 0
        for _, id in ipairs(self._filledSlots) do
            self._colorVelocities[id*4-3] = dvr
            self._colorVelocities[id*4-2] = dvg
            self._colorVelocities[id*4-1] = dvb
            self._colorVelocities[id*4] = dva
        end
    end,

    _customFuncs = function (self)
        -- initialize "_customFuncs"
        self._customFuncs = {}
        
        -- now EVERY particle needs one:
        for _, id in ipairs(self._filledSlots) do
            self._customFuncs[id] = self.ParticleCustomFunc
        end
    end,
}

local updateFuncs = {
    _velocities = function (self, slot, dt)
        local vx = (self._velocities and self._velocities[slot*2-1] or self.ParticleVelocity[1]) * dt
        local vy = (self._velocities and self._velocities[slot*2] or self.ParticleVelocity[2]) * dt
        self._positions[slot*2-1] = self._positions[slot*2-1] + vx
        self._positions[slot*2] = self._positions[slot*2] + vy
    end,

    _accelerations = function (self, slot, dt)
        
        local vx = (self._accelerations and self._accelerations[slot*2-1] or self.ParticleAcceleration[1]) * dt
        local vy = (self._accelerations and self._accelerations[slot*2] or self.ParticleAcceleration[2]) * dt
        
        self._velocities[slot*2-1] = self._velocities[slot*2-1] + vx
        self._velocities[slot*2] = self._velocities[slot*2] + vy

        -- print(self._velocities[slot*2-1], self._velocities[slot*2])
    end,

    _sizeVelocities = function (self, slot, dt)
        local vx = (self._sizeVelocities and self._sizeVelocities[slot*2-1] or self.ParticleSizeVelocity[1]) * dt
        local vy = (self._sizeVelocities and self._sizeVelocities[slot*2] or self.ParticleSizeVelocity[2]) * dt
        
        self._sizes[slot*2-1] = self._sizes[slot*2-1] + vx
        self._sizes[slot*2] = self._sizes[slot*2] + vy
    end,

    _sizeAccelerations = function (self, slot, dt)
        
        local vx = (self._sizeAccelerations and self._sizeAccelerations[slot*2-1] or self.ParticleSizeAcceleration[1]) * dt
        local vy = (self._sizeAccelerations and self._sizeAccelerations[slot*2] or self.ParticleSizeAcceleration[2]) * dt
        
        self._sizeVelocities[slot*2-1] = self._sizeVelocities[slot*2-1] + vx
        self._sizeVelocities[slot*2] = self._sizeVelocities[slot*2] + vy
    end,

    _colorVelocities = function (self, slot, dt)
        local vr = (self._colorVelocities and self._colorVelocities[slot*4-3] or self.ParticleColorVelocity[1]) * dt
        local vg = (self._colorVelocities and self._colorVelocities[slot*4-2] or self.ParticleColorVelocity[2]) * dt
        local vb = (self._colorVelocities and self._colorVelocities[slot*4-1] or self.ParticleColorVelocity[3]) * dt
        local va = (self._colorVelocities and self._colorVelocities[slot*4] or self.ParticleColorVelocity[4] or 0) * dt
        
        self._colors[slot*4-3] = self._colors[slot*4-3] + vr
        self._colors[slot*4-2] = self._colors[slot*4-2] + vg
        self._colors[slot*4-1] = self._colors[slot*4-1] + vb
        self._colors[slot*4] = self._colors[slot*4] + va
    end,

    _rotVelocities = function (self, slot, dt)
        local rx = (self._rotVelocities and self._rotVelocities[slot] or self.ParticleRotVelocity) * dt
        
        self._rotations[slot] = self._rotations[slot] + rx
    end,

    _rotAccelerations = function (self, slot, dt)
        local rx = (self._rotAccelerations and self._rotAccelerations[slot] or self.ParticleRotAcceleration) * dt
        
        self._rotVelocities[slot] = self._rotVelocities[slot] + rx
    end,

    _customFuncs = function (self, slot, dt)
        local func = self._customFuncs and self._customFuncs[slot] or self.ParticleCustomFunc
        if func then
            -- Call the custom function - it can modify the emitter's properties directly
            func(self, slot, dt)
        end
    end,
}

function Particles._globalUpdate(dt)
    for emitter in pairs(Particles._cache) do
        -- update particles for each emitter
        emitter._systemLifeTime = Chexcore._clock - emitter._systemStartTime
        
        -- local toUpdate = {}

        -- -- determine which properties have concrete values to update
        -- for fName, func in pairs(updateFuncs) do
        --     if emitter[fName] then
        --         toUpdate[#toUpdate+1] = fName
        --     end
        -- end

        -- for _, slot in ipairs(emitter._filledSlots) do
        --     for _, func in ipairs(toUpdate) do
        --         updateFuncs[func](slot)
        --     end
        -- end


        local usedUpdateFuncs = {} -- a list of update functions we're going to use
        local customFuncNeeded = false

        -- will we be using velocity?
        if (emitter._velocities or emitter.ParticleVelocity) then
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_velocities"]
            if not emitter._positions then
                -- we need to initialize individual positions to use velocity:
                initializers["_positions"](emitter)
            end
        end

        -- will we be using acceleration?
        if (emitter._accelerations or emitter.ParticleAcceleration) then
            
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_accelerations"]
            if not emitter._velocities then
                -- we need to initialize individual positions to use velocity:
                initializers["_velocities"](emitter)
            end
            if not emitter._positions then
                -- we need to initialize individual positions to use velocity:
                initializers["_positions"](emitter)
            end
        end

        -- will we be using sizevelocity?
        if (emitter._sizeVelocities or emitter.ParticleSizeVelocity) then
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_sizeVelocities"]
            if not emitter._sizes then
                -- we need to initialize individual sizes to use sizevelocity:
                initializers["_sizes"](emitter)
            end
        end

        -- will we be using sizeacceleration?
        if (emitter._sizeAccelerations or emitter.ParticleSizeAcceleration) then
    
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_sizeAccelerations"]
            if not emitter._sizeVelocities then
                -- we need to initialize individual positions to use velocity:
                initializers["_sizeVelocities"](emitter)
            end
            if not emitter._sizes then
                -- we need to initialize individual positions to use velocity:
                initializers["_sizes"](emitter)
            end
        end

        -- will we be using colorvelocity?
        if (emitter._colorVelocities or emitter.ParticleColorVelocity) then
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_colorVelocities"]
            if not emitter._colors then
                -- we need to initialize individual colors to use colorvelocity:
                initializers["_colors"](emitter)
            end
        end

        -- will we be using rotvelocity?
        if (emitter._rotVelocities or emitter.ParticleRotVelocity) then
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_rotVelocities"]
            if not emitter._rotations then
                -- we need to initialize individual rotations to use rotvelocity:
                initializers["_rotations"](emitter)
            end
        end

        -- will we be using rotacceleration?
        if (emitter._rotAccelerations or emitter.ParticleRotAcceleration) then
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_rotAccelerations"]
            if not emitter._rotVelocities then
                -- we need to initialize individual rotations to use rotvelocity:
                initializers["_rotVelocities"](emitter)
            end
            if not emitter._rotations then
                -- we need to initialize individual rotations to use rotvelocity:
                initializers["_rotations"](emitter)
            end
        end

        -- will we be using custom update?
        if (emitter._customFuncs or emitter.ParticleCustomFunc) then
            usedUpdateFuncs[#usedUpdateFuncs+1] = updateFuncs["_customFuncs"]
            if not emitter._customFuncs then
                initializers["_customFuncs"](emitter)
            end
        end

        for _, slot in ipairs(emitter._filledSlots) do
            -- lifetime handling
            if emitter._deathTimes[slot] <= emitter._systemLifeTime then
                emitter:Destroy(slot)
            else
                -- run only the relevant update functions
                for i, func in ipairs(usedUpdateFuncs) do
                    func(emitter, slot, dt)
                end
            end
        end

        -- print(emitter._vacantSlots)
    end
end


function Particles.new(properties)
    local newParticles = Particles:SuperInstance()
    if properties then
        for prop, val in pairs(properties) do
            newParticles[prop] = val
        end
    end

    newParticles._filledSlots = {}
    newParticles._vacantSlots = {}
    newParticles._systemStartTime = Chexcore._clock
    newParticles._deathTimes = {}
    newParticles._startTimes = {}

    Particles:Connect(newParticles)

    newParticles.ParticleTexture.Loop = false

    Particles._cache[newParticles] = true

    return newParticles
end


local funcs = {
    Position = function (self, pid, posToSet)
        if not self._positions then
            initializers["_positions"](self)
        end

        self._positions[pid*2-1] = posToSet[1]
        self._positions[pid*2] = posToSet[2]
    end,

    Size = function (self, pid, sizeToSet)
        if not self._sizes then
            initializers["_sizes"](self)
        end

        self._sizes[pid*2-1] = sizeToSet[1]
        self._sizes[pid*2] = sizeToSet[2]
    end,

    Color = function (self, pid, colToSet)
        if not self._colors then
            initializers["_colors"](self)
        end

        self._colors[pid*4-3] = colToSet[1] or 0
        self._colors[pid*4-2] = colToSet[2] or 0
        self._colors[pid*4-1] = colToSet[3] or 0
        self._colors[pid*4] = colToSet[4] or 0
    end,

    Rotation = function (self, pid, rotToSet)
        if not self._rotations then
            initializers["_rotations"](self)
        end

        self._rotations[pid] = rotToSet
    end,

    RotVelocity = function (self, pid, rotToSet)
        if not self._rotVelocities then
            initializers["_rotVelocities"](self)
        end

        self._rotVelocities[pid] = rotToSet
    end,

    RotAcceleration = function (self, pid, rotToSet)
        if not self._rotAccelerations then
            initializers["_rotAccelerations"](self)
        end

        self._rotAccelerations[pid] = rotToSet
    end,


    Velocity = function (self, pid, velToSet)
        if not self._velocities then
            initializers["_velocities"](self)
        end

        self._velocities[pid*2-1] = velToSet[1]
        self._velocities[pid*2] = velToSet[2]
    end,

    Acceleration = function (self, pid, accToSet)
        if not self._accelerations then
            initializers["_accelerations"](self)
        end

        self._accelerations[pid*2-1] = accToSet[1]
        self._accelerations[pid*2] = accToSet[2]
    end,

    SizeVelocity = function (self, pid, velToSet)
        if not self._sizeVelocities then
            initializers["_sizeVelocities"](self)
        end

        self._sizeVelocities[pid*2-1] = velToSet[1]
        self._sizeVelocities[pid*2] = velToSet[2]
    end,

    SizeAcceleration = function (self, pid, velToSet)
        if not self._sizeAccelerations then
            initializers["_sizeAccelerations"](self)
        end

        self._sizeAccelerations[pid*2-1] = velToSet[1]
        self._sizeAccelerations[pid*2] = velToSet[2]
    end,

    ColorVelocity = function (self, pid, velToSet)
        if not self._colorVelocities then
            initializers["_colorVelocities"](self)
        end

        self._colorVelocities[pid*4-3] = velToSet[1] or 0
        self._colorVelocities[pid*4-2] = velToSet[2] or 0
        self._colorVelocities[pid*4-1] = velToSet[3] or 0
        self._colorVelocities[pid*4] = velToSet[4] or 0
    end,

    LifeTime = function (self, pid, lifetime)
        self._deathTimes[pid] = self._systemLifeTime + lifetime
    end,

    CustomFunc = function (self, pid, funcToSet)
        if not self._customFuncs then
            initializers["_customFuncs"](self)
        end

        self._customFuncs[pid] = funcToSet
    end
}

local AUTOFILLS = {
    "_sizes", "Size", "ParticleSize",
    "_sizeVelocities", "SizeVelocity", "ParticleSizeVelocity",
    "_rotations", "Rotation", "ParticleRotation",
    "_rotVelocities", "RotVelocity", "ParticleRotVelocity",
    "_colors", "Color", "ParticleColor",
    "_customFuncs", "CustomFunc", "ParticleCustomFunc"
}


function Particles:Emit(properties)
    -- if true then return false end

    local newSlot
    if #self._vacantSlots == 0 then
        -- create new particle slot
        newSlot = #self._filledSlots+1
    else
        -- use a vacant particle slot
        newSlot = self._vacantSlots[#self._vacantSlots]
        self._vacantSlots[#self._vacantSlots] = nil
    end
    self._filledSlots[#self._filledSlots+1] = newSlot

    properties = properties or {}

    for i = 1, #AUTOFILLS, 3 do
        if self[AUTOFILLS[i]] and not properties[AUTOFILLS[i+1]] then
            properties[AUTOFILLS[i+1]] = self[AUTOFILLS[i+2]]
        end
    end
    

    for prop, val in pairs(properties) do
        if funcs[prop] then
            funcs[prop](self, newSlot, val)
        end
    end

    if not properties or not properties.LifeTime then
        -- add the default lifetime:
        self._deathTimes[newSlot] = self._systemLifeTime + self.ParticleLifeTime
    end

    

    -- record start time
    self._startTimes[newSlot] = self._systemLifeTime
end

local table_remove = table.remove
function Particles:Destroy(pid)
    
    local indexToRemove
    for i, id in ipairs(self._filledSlots) do
        if id == pid then
            indexToRemove = i
            break
        end
    end

    if indexToRemove then
        table_remove(self._filledSlots, indexToRemove)
        self._vacantSlots[#self._vacantSlots+1] = pid
    end
end

local floor, lg = math.floor, love.graphics
function Particles:Draw(tx, ty)
    local oldshader
    if self.Shader then
        self.Shader:Activate()
    end
    if self.DrawOverChildren and self:HasChildren() then
        self:DrawChildren(tx, ty)
    end
    lg.setColor(self.Color)
    local sx = self.Size[1] * (self.DrawScale[1]-1)
    local sy = self.Size[2] * (self.DrawScale[2]-1)
    self.Texture:DrawToScreen(
        floor(self.Position[1] - tx),
        floor(self.Position[2] - ty),
        self.Rotation,
        self.Size[1] + sx,
        self.Size[2] + sy,
        self.AnchorPoint[1],
        self.AnchorPoint[2]
    )


    -- now draw particles
    local anim = self.ParticleTexture

    local skipColors
    if not self._colors then
        skipColors = true
        lg.setColor(self.ParticleColor)
    end
    
    local pTex = self.ParticleTexture
    for _, slot in ipairs(self._filledSlots) do
        local px = self._positions and self._positions[slot*2-1] or self.ParticlePosition[1]
        local py = self._positions and self._positions[slot*2] or self.ParticlePosition[2] 
        local psx = (self._sizes and self._sizes[slot*2-1] or self.ParticleSize[1])
        local psy = (self._sizes and self._sizes[slot*2] or self.ParticleSize[2])
        local pr = (self._rotations and self._rotations[slot] or self.ParticleRotation)
        
        if not skipColors then
            -- print(self._colors, slot)
            lg.setColor(self._colors[slot*4-3],self._colors[slot*4-2],self._colors[slot*4-1],self._colors[slot*4])
        end
        

        if not self.LoopAnim then
            anim.Clock = math.min(self._systemLifeTime - self._startTimes[slot], anim.Duration)
        else
            anim.Clock = self._systemLifeTime - self._startTimes[slot]
        end

        pTex:DrawToScreen(
            floor(px - tx)  + (self.RelativePosition and self.Position[1] or 0),
            floor(py - ty)  + (self.RelativePosition and self.Position[2] or 0),
            pr,
            psx + (psx * (self.DrawScale[1]-1)),
            psy + (psy * (self.DrawScale[2]-1)),
            self.ParticleAnchorPoint[1],
            self.ParticleAnchorPoint[2]
        )
    end


    if not self.DrawOverChildren and self:HasChildren() then
        self:DrawChildren(tx, ty)
    end

    if self.Shader then
        self.Shader:Deactivate()
    end
end

-- Particle property getters and setters (methods on emitter)

-- Position methods
function Particles:GetPosition(slot)
    if not self._positions then
        return V{self.ParticlePosition[1], self.ParticlePosition[2]}
    end
    return V{self._positions[slot*2-1], self._positions[slot*2]}
end

function Particles:SetPosition(slot, pos)
    if not self._positions then
        initializers["_positions"](self)
    end
    self._positions[slot*2-1] = pos[1]
    self._positions[slot*2] = pos[2]
end

function Particles:SetPositionX(slot, x)
    if not self._positions then
        initializers["_positions"](self)
    end
    self._positions[slot*2-1] = x
end

function Particles:SetPositionY(slot, y)
    if not self._positions then
        initializers["_positions"](self)
    end
    self._positions[slot*2] = y
end

-- Velocity methods
function Particles:GetVelocity(slot)
    if not self._velocities then
        return self.ParticleVelocity and V{self.ParticleVelocity[1], self.ParticleVelocity[2]} or V{0, 0}
    end
    return V{self._velocities[slot*2-1], self._velocities[slot*2]}
end

function Particles:SetVelocity(slot, vel)
    if not self._velocities then
        initializers["_velocities"](self)
    end
    self._velocities[slot*2-1] = vel[1]
    self._velocities[slot*2] = vel[2]
end

function Particles:SetVelocityX(slot, vx)
    if not self._velocities then
        initializers["_velocities"](self)
    end
    self._velocities[slot*2-1] = vx
end

function Particles:SetVelocityY(slot, vy)
    if not self._velocities then
        initializers["_velocities"](self)
    end
    self._velocities[slot*2] = vy
end

-- Acceleration methods
function Particles:GetAcceleration(slot)
    if not self._accelerations then
        return self.ParticleAcceleration and V{self.ParticleAcceleration[1], self.ParticleAcceleration[2]} or V{0, 0}
    end
    return V{self._accelerations[slot*2-1], self._accelerations[slot*2]}
end

function Particles:SetAcceleration(slot, acc)
    if not self._accelerations then
        initializers["_accelerations"](self)
    end
    self._accelerations[slot*2-1] = acc[1]
    self._accelerations[slot*2] = acc[2]
end

function Particles:SetAccelerationX(slot, ax)
    if not self._accelerations then
        initializers["_accelerations"](self)
    end
    self._accelerations[slot*2-1] = ax
end

function Particles:SetAccelerationY(slot, ay)
    if not self._accelerations then
        initializers["_accelerations"](self)
    end
    self._accelerations[slot*2] = ay
end

-- Size methods
function Particles:GetSize(slot)
    if not self._sizes then
        return V{self.ParticleSize[1], self.ParticleSize[2]}
    end
    return V{self._sizes[slot*2-1], self._sizes[slot*2]}
end

function Particles:SetSize(slot, size)
    if not self._sizes then
        initializers["_sizes"](self)
    end
    self._sizes[slot*2-1] = size[1]
    self._sizes[slot*2] = size[2]
end

function Particles:SetSizeX(slot, sx)
    if not self._sizes then
        initializers["_sizes"](self)
    end
    self._sizes[slot*2-1] = sx
end

function Particles:SetSizeY(slot, sy)
    if not self._sizes then
        initializers["_sizes"](self)
    end
    self._sizes[slot*2] = sy
end

-- Size velocity methods
function Particles:GetSizeVelocity(slot)
    if not self._sizeVelocities then
        return self.ParticleSizeVelocity and V{self.ParticleSizeVelocity[1], self.ParticleSizeVelocity[2]} or V{0, 0}
    end
    return V{self._sizeVelocities[slot*2-1], self._sizeVelocities[slot*2]}
end

function Particles:SetSizeVelocity(slot, vel)
    if not self._sizeVelocities then
        initializers["_sizeVelocities"](self)
    end
    self._sizeVelocities[slot*2-1] = vel[1]
    self._sizeVelocities[slot*2] = vel[2]
end

function Particles:SetSizeVelocityX(slot, svx)
    if not self._sizeVelocities then
        initializers["_sizeVelocities"](self)
    end
    self._sizeVelocities[slot*2-1] = svx
end

function Particles:SetSizeVelocityY(slot, svy)
    if not self._sizeVelocities then
        initializers["_sizeVelocities"](self)
    end
    self._sizeVelocities[slot*2] = svy
end

-- Color methods
function Particles:GetColor(slot)
    if not self._colors then
        return V{self.ParticleColor[1], self.ParticleColor[2], self.ParticleColor[3], self.ParticleColor[4] or 1}
    end
    return V{self._colors[slot*4-3], self._colors[slot*4-2], self._colors[slot*4-1], self._colors[slot*4]}
end

function Particles:SetColor(slot, color)
    if not self._colors then
        initializers["_colors"](self)
    end
    self._colors[slot*4-3] = color[1]
    self._colors[slot*4-2] = color[2]
    self._colors[slot*4-1] = color[3]
    self._colors[slot*4] = color[4] or 1
end

function Particles:SetColorR(slot, r)
    if not self._colors then
        initializers["_colors"](self)
    end
    self._colors[slot*4-3] = r
end

function Particles:SetColorG(slot, g)
    if not self._colors then
        initializers["_colors"](self)
    end
    self._colors[slot*4-2] = g
end

function Particles:SetColorB(slot, b)
    if not self._colors then
        initializers["_colors"](self)
    end
    self._colors[slot*4-1] = b
end

function Particles:SetColorA(slot, a)
    if not self._colors then
        initializers["_colors"](self)
    end
    self._colors[slot*4] = a
end

-- Color velocity methods
function Particles:GetColorVelocity(slot)
    if not self._colorVelocities then
        return self.ParticleColorVelocity and V{self.ParticleColorVelocity[1], self.ParticleColorVelocity[2], self.ParticleColorVelocity[3], self.ParticleColorVelocity[4] or 0} or V{0, 0, 0, 0}
    end
    return V{self._colorVelocities[slot*4-3], self._colorVelocities[slot*4-2], self._colorVelocities[slot*4-1], self._colorVelocities[slot*4]}
end

function Particles:SetColorVelocity(slot, vel)
    if not self._colorVelocities then
        initializers["_colorVelocities"](self)
    end
    self._colorVelocities[slot*4-3] = vel[1]
    self._colorVelocities[slot*4-2] = vel[2]
    self._colorVelocities[slot*4-1] = vel[3]
    self._colorVelocities[slot*4] = vel[4] or 0
end

-- Rotation methods
function Particles:GetRotation(slot)
    if not self._rotations then
        return self.ParticleRotation
    end
    return self._rotations[slot]
end

function Particles:SetRotation(slot, rot)
    if not self._rotations then
        initializers["_rotations"](self)
    end
    self._rotations[slot] = rot
end

-- Rotation velocity methods
function Particles:GetRotVelocity(slot)
    if not self._rotVelocities then
        return self.ParticleRotVelocity
    end
    return self._rotVelocities[slot]
end

function Particles:SetRotVelocity(slot, rotvel)
    if not self._rotVelocities then
        initializers["_rotVelocities"](self)
    end
    self._rotVelocities[slot] = rotvel
end

-- Lifetime methods
function Particles:GetLifetime(slot)
    return self._systemLifeTime - self._startTimes[slot]
end

function Particles:GetMaxLifetime(slot)
    return self._deathTimes[slot] - self._startTimes[slot]
end

function Particles:SetMaxLifetime(slot, lifetime)
    self._deathTimes[slot] = self._startTimes[slot] + lifetime
end

function Particles:GetStartTime(slot)
    return self._startTimes[slot]
end

-- Custom function methods
function Particles:GetCustomFunc(slot)
    if not self._customFuncs then
        return self.ParticleCustomFunc
    end
    return self._customFuncs[slot]
end

function Particles:SetCustomFunc(slot, func)
    if not self._customFuncs then
        initializers["_customFuncs"](self)
    end
    self._customFuncs[slot] = func
end

return Particles