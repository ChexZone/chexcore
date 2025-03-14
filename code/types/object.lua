local Object = {
    -- properties
    Name = "Object",        -- Easy identifier
    Active = true,
    -- internal properties
    _isObject = true,       -- true for all Objects
    _super = "Object",      -- Supertype
    _superReference = nil,  -- Created at construction
    _parent = nil,          -- Reference to parent Object
    _children = nil,        -- Table of references to child Objects. Created at construction
    _childHash = nil,       -- Used to get quick access to Child objects
    _type = "Object",       -- the internal type of the object.
    _abstract = false,      -- Abstract types should not have instantiation
    _global = true,          -- Is this type important enough to be globally referenced?
}


-- Object metatable
local blankTables = {_children = true, _childHash = true}
Object.__index = function(self, key)
    

    return rawget(Object, key) or blankTables[key] and {} or nil
end

setmetatable(Object, {
    __index = function(self, key)

        if blankTables[key] and _G.OBJSEARCH then
            -- print("Objectifying " .. key .. " for " .. tostring(_G.OBJSEARCH.Name))
            
            local newTab = {}
            _G.OBJSEARCH[key] = newTab
            _G.OBJSEARCH = nil
            return newTab
        end

        _G.OBJSEARCH = nil
    end
})

---------------- Constructor -------------------

-- !!!!! IMPORTANT !!!!! --- 
-- This constructor is not meant to be inherited.
-- It only applies to basic Objects! Custom constructors
-- are made for types created with Core:AddType().
-- See chexcore/init.lua!
function Object.new(properties)
    local obj = setmetatable({}, Object)
    if properties then
        for prop, val in pairs(properties) do
            obj[prop] = val
        end
    end
    return obj
end

------------------------------------------------

------------------ Methods ---------------------
function Object:Connect(instance)
    return setmetatable(instance, self)
end

local deepCopy = deepCopy
function Object:Clone(sameParent)
    local t = deepCopy(self)
    if sameParent and self._parent then
        self._parent:Adopt(t)
    end
    return t
end


function Object:Update(dt) end

local function advancedType(name, var)
    local out
    if name:sub(1,1) == "_" then
        out =  "Internal"
    elseif type(var) == "table" then
        out =  var._type or "table"
    elseif var == nil then
        out = "boolean"
    else
        out =  type(var)
    end
    return out
end

local renderMax = 30
function Object:ToString(properties, typeLabels, displayMethods)
    if typeLabels ~= false then
        typeLabels = true
    end
    local out
    if properties then
        out = ("           [%s]%s%s           "):format(self._type, (" "):rep(math.min(35, 35-#self.Name-#self._type)), self.Name)
        local length = #out
        out = out .. "\n|" .. ("_"):rep(length-2) .. "|\n"
                  .. "|"..(" "):rep(length-2).."|\n"
        local sortedProperties = {}

        if type(properties) == "table" then
            -- list of properties
            for _, property in ipairs(properties) do
                local pType = advancedType(property, self[property])
                sortedProperties[pType] = sortedProperties[pType] or {}
                sortedProperties[pType][#sortedProperties[pType]+1] = property
            end
        else
            -- all properties 
            local propertiesAdded = {}

            for property, _ in pairs(self) do
                local pType = advancedType(property, self[property])
                sortedProperties[pType] = sortedProperties[pType] or {}
                sortedProperties[pType][#sortedProperties[pType]+1] = property
                propertiesAdded[property] = true
            end

            for property, _ in pairs(getmetatable(self)) do
                if not propertiesAdded[property] then
                    local pType = advancedType(property, self[property])
                    sortedProperties[pType] = sortedProperties[pType] or {}
                    sortedProperties[pType][#sortedProperties[pType]+1] = property
                end
            end
        end

        local ignore = {Internal = 0, userdata = 1, boolean = 2, number = 3, string = 4, ["function"] = 5}
        
        -- first print Object types (greedy)
        for propertyType, list in sortedPairs(sortedProperties) do
            if not ignore[propertyType] then
                if typeLabels then
                    local t = "| [" .. propertyType .. "]:"
                    out = out .. t .. (" "):rep(length-#t-1) .. "|\n"
                            .. "|" .. ("="):rep(#propertyType + 6) .. (" "):rep(length-#propertyType-8) .. "|\n"
                end

                for _, property in ipairs(list) do
                    out = out .. ("| %s%s%s |\n"):format(property, (" "):rep(length-4-#property-#tostring(self[property]):limit(renderMax)), tostring(self[property]):limit(renderMax))
                end

                if typeLabels then
                    out = out .. "|" .. ("- "):rep((length-2)/2) .. (length%2==1 and "-" or "") .. "|\n"
                end
            end
        end

        local priority = displayMethods and {"function",  "string", "number", "boolean", "userdata", "Internal"}
                                        or  {"string", "number", "boolean", "userdata", "Internal"}

        for _, propertyType in ipairs(priority) do
            if sortedProperties[propertyType] then
                table.sort(sortedProperties[propertyType])
                if typeLabels then
                    local t = "| [" .. propertyType .. "]:"
                    out = out .. t .. (" "):rep(length-#t-1) .. "|\n"
                            .. "|" .. ("="):rep(#propertyType + 6) .. (" "):rep(length-#propertyType-8) .. "|\n"
                end

                for _, property in ipairs(sortedProperties[propertyType]) do
                    local propertyString = tostring(self[property] and type(self[property]) == "table" and type(self[property].ToString) == "function" and self[property]:ToString() or type(self[property]) == "string" and ('"'..self[property]..'"') or self[property]):limit(renderMax)
                    out = out .. ("| %s%s%s |\n"):format(property, (" "):rep(length-4-#property-#propertyString), propertyString)
                end

                if typeLabels then
                    out = out .. "|" .. ("- "):rep((length-2)/2) .. (length%2==1 and "-" or "") .. "|\n"
                end
            end
        end

    else
        -- no properties, inline
        out = "["..self._type.."] "..self.Name
    end

    return out
end

-- for inline definition stuff
function Object:Set(...)
    local key
    for i, v in ipairs{...} do
        if i % 2 == 1 then -- v is key
            key = v
        else -- set
            self[key] = v
        end
    end
    return self
end


--[[
    Object:GetChild( id )
     - returns the child at the given internal index.
    Object:GetChild( name )
     - returns the child with the given name, or nil if not found
    Object:GetChild( property, value )
     - returns the child with the given property and value, or nil if not found
    Object:GetChild( { property = val, ...} [, inclusive] )
     - searches for multiple properties. If inclusive is false, all properties must match.
    Object:GetChild( func )
     - returns the first child for which func(child) returns true
]]
function Object:GetChild(arg1, arg2)
    if type(arg1) == "number" then
        return self._children[arg1]
    elseif type(arg1) == "table" then
        -- Object:GetChild( { property = val, ...} [, inclusive] )
        if not arg2 then
            -- exclusive
            for index, child in ipairs(self._children) do
                local match = true
                for property, val in pairs(arg1) do
                    if child[property] ~= val then
                        match = false; break
                    end
                end
                if match then
                    return child, index
                end
            end
        else
            -- inclusive
            for index, child in ipairs(self._children) do
                local match = false
                for property, val in pairs(arg1) do
                    if child[property] == val then
                        match = true; break
                    end
                end
                if match then
                    return child, index
                end
            end
        end
    elseif arg2 ~= nil then
            -- Object:GetChild( property, value )
            for index, child in ipairs(self._children) do
                if child[arg1] == arg2 then
                    return child, index
                end
            end
    elseif type(arg1) == "function" then
        -- Object:GetChild( func )
        for index, child in ipairs(self._children) do
            if arg1(child) then
                return child, index
            end
        end
    else
        -- Object:GetChild( name )
        for index, child in ipairs(self._children) do
            if child.Name == arg1 then
                return child, index
            end
        end
    end

    return nil
end

function Object:GetDescendant(arg1, arg2)
    
    return self:EachDescendant(arg1, arg2)()
end

--[[  
    Object:GetChildren()
     - returns the full list of an object's children
    Object:GetChildren( name )
     - returns the subset of children with the given name
    Object:GetChildren( property, value )
     - returns the subset of children with the given property and value
    Object:GetChildren( { property = val, ...} [, inclusive] )
     - searches for multiple properties. If inclusive is false, all properties must match.
    Object:GetChildren( func )
     - returns the subset of children for which func(child) returns true
]]
local filter = filteredList
local type2 = type
function Object:GetChildren(arg1, arg2)
    local s = self._children -- just to be damn safe
    if not arg2 and type2(arg1) == "string" then
        return filter(self._children, "Name", arg1)
    end
    return filter(self._children, arg1, arg2)
end

function Object:GetDescendants(arg1, arg2, current)
    local s = self._children -- just to be damn safe
    if not arg2 and type2(arg1) == "string" then
        return filter(self._children, "Name", arg1, true, current)
    end
    return filter(self._children, arg1, arg2, true, current)
end

local function getAncestorRecursive(self, arg1, arg2)
    -- GetAncestor(name)
    if not arg2 and type2(arg1) == "string" and self.Name == arg1 then return self
    
    -- GetAncestor(func, arg2)
    elseif type2(arg1) == "function" and arg1(self, arg2) then return self

    -- GetAncestor({property = val, ...}, [inclusive])
    elseif type2(arg1) == "table" then
        if arg2 then -- inclusive
            for k, v in pairs(arg1) do
                if self[k] == v then return self end
            end
        else -- exclusive
            local disqualify = false
            for k, v in pairs(arg1) do
                if self[k] ~= v then disqualify = true; break; end
            end
            if not disqualify then return self end
        end

    -- GetAncestor(property, value)
    elseif arg1 ~= nil and arg2 ~= nil and self[arg1] == arg2 then return self end

    -- if none of this worked, check for ancestry in parent:
    if self._parent then
        return getAncestorRecursive(self._parent, arg1, arg2)
    end

    return nil
end

function Object:GetAncestor(arg1, arg2)
    if self._parent then return getAncestorRecursive(self._parent, arg1, arg2) end
    
    return nil
end

--[[  
    Object:EachChild() has the same signatures as Object:GetChildren(),
    but returns an iterator rather than building the entire list.
    Example usage:

    for child in myObject:EachChild() do
        print(child.Name)
    end
]]
local iterFilter = filteredListIterator
function Object:EachChild(arg1, arg2)

    -- OK what the hell about that line above. The reason this line is here
    -- is because the child table just, fucking, disappears??? if it is not
    -- observed. i have no idea what this is or what terrible omens it carries
    if not arg2 and type2(arg1) == "string" then
        return iterFilter(self._children, "Name", arg1)
    end
    
    return iterFilter(self._children, arg1, arg2)
end

function Object:EachDescendant(arg1, arg2)
    if not arg2 and type2(arg1) == "string" then
        return iterFilter(self._children, "Name", arg1, true)
    end

    return iterFilter(self._children, arg1, arg2, true)
end

function Object:GetParent()
    return self._parent
end

local rg = rawget
function Object:Adopt(child)
    if child._parent then
        child._parent:Disown(child)
    end

    self._childHash = rg(self, "_childHash") or {}
    self._children = rg(self, "_children") or {}
    local newPos = #self._children + 1

    self._childHash[child] = newPos
    self._children[newPos] = child

    child._parent = self

    return child
end

-- inverse of Adopt()
function Object:Nest(parent)
    return parent:Adopt(self)
end

-- same as Adopt(), but returns the parent instead of the child
function Object:With(child)
    self:Adopt(child)
    return self
end

-- same as Nest(), but returns the parent instead of the child
function Object:Into(parent)
    parent:Adopt(self)
    return parent
end

--[[ USAGE OF ADOPT/NEST/WITH/INTO
    child = parent:Adopt(child)
    child = child:Nest(parent)
    parent = parent:With(child)
    parent = child:Into(parent)
]]

function Object:HasChildren()
    return rg(self, "_children") and #self._children > 0
end

function Object:GetChildID()
    return self._parent and self._parent._childHash[self] or 0
end

local trm = table.remove
function Object:Disown(child)
    if type(child) == "table" then
        -- Object:Disown( child )
        local index = self._childHash[child]

        -- fix all hash IDs (more expensive the farther left you are removing)
        for i = index+1, #self._children do
            self._childHash[self._children[i]] = self._childHash[self._children[i]] - 1
        end

        trm(self._children, index)
        self._childHash[child] = nil

        return child
    else
        -- Object:Disown( index )

        -- fix all hash IDs (more expensive the farther left you are removing)
        for i = child+1, #self._children do
            self._childHash[self._children[i]] = self._childHash[self._children[i]] - 1
        end

        local obj = self._children[child]
        self._childHash[obj] = nil
        trm(self._children, child)
        
        return obj
    end
end

-- basically reverse Disown()
function Object:Emancipate()
    local parent = self._parent
    if parent then
        parent:Disown(self)
    end
    return parent
end

function Object:SwapChildOrder(c1, c2)
    c1 = type(c1) == "number" and c1 or c1:GetChildID()
    c2 = type(c2) == "number" and c2 or c2:GetChildID()

    -- Object:SwapChildOrder(index1, index2)
    self._childHash[self._children[c1]], self._childHash[self._children[c2]] = 
        self._childHash[self._children[c2]], self._childHash[self._children[c1]]
    self._children[c1], self._children[c2] = self._children[c2], self._children[c1]

end

function Object:AddProperties(properties)
    for prop, val in pairs(properties) do
        self[prop] = val
    end
    return self
end
Object.Properties = Object.AddProperties

function Object:IsA(type)
    if self._type == type then
        return true
    elseif self == Object then
        return false
    else
        return self._superReference:IsA(type)
    end
end



function Object:IsChildOf(parent)
    -- return parent._childHash[self] and true or false
    -- i'm keeping this line here   bc   it was the original implementation and 
    --                                                               wow what  
    return parent == self._parent
end

function Object:IsAncestorOf(descendant)
    local p = descendant
    repeat p = p._parent until p == self or not p
    return p and true or false
end

function Object:IsDescendantOf(ancestor)
    return ancestor:IsAncestorOf(self)
end

function Object:GetType()
    return self._type
end

function Object:SuperInstance()
    return self._superReference.new()
end

local serialize = serialize
function Object:Serialize(upcast)
    return serialize(self, upcast)
end
------------------------------------------------

return Object