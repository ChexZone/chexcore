_G._tostring = _G.tostring
local oldtostring = tostring
local replaceCoreLuaFunctions = true
local pcall = pcall

-- first, some undoubtedly cool stuff

local defaultSort = function (a, b)
    a = type(a) == "table" and tostring(a) or a
    b = type(b) == "table" and tostring(b) or b
    return a < b
end

-- adapted from https://www.lua.org/pil/19.3.html
-- iterator which traverses a table in alphabetical order:
function _G.sortedPairs(t, f)
    f = f or defaultSort
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end
local sortedPairs = _G.sortedPairs

local function getTableAddress(tab) -- omits "0x"
   return oldtostring(tab):sub(10, 30)
end

local function pickStringChar(str)
    if str:find([["]]) then
        -- either [[]] or ''
        if str:find([[']]) then
            -- must be [[]]
            return '[['
        else--if str:find("]]") then
            -- must be ''
            return [[']]
        end
    elseif str:find([[']]) then
        -- either [[]] or ""
        if str:find([["]]) then
            -- must be [[]]
            return '[['
        else--if str:find("]]") then
            -- must be ""
            return [["]]
        end
    else
        -- both "" and '' are safe to use; use ""
        return [["]]
    end
end

local charList = {["'"] = {"'", "'"}, ['"'] = {'"', '"'}, ["[["] = {"[[", "]]"}}
local function makeStringString(str)
    local pick = charList[pickStringChar(str)]
    return pick[1] .. str .. pick[2]
end

local function serializeValue(val, queue, checklist)
    local out
    if type(val) == "table" then
        local tag = getTableAddress(val)
        if not checklist[tag] then
            queue[#queue+1] = val
            checklist[tag] = true
        end
        out = "@" .. tag
    elseif type(val) == "string" then
        out = makeStringString(val)
    else
        out = oldtostring(val)
    end
    return out
end

-- Serializes a table into a string. Records all referenced tables as well!
local function rawSerialize(tab, upcast)
    local baseTag = getTableAddress(tab)
    local output = {} -- output may be multiple strings
    local queue = {tab} -- the current list of tables to serialize
    local checklist = {[baseTag] = true} -- hash of completed table values

    while queue[1] do
        local currentTable = queue[1]
        local currentTag = getTableAddress(currentTable)

        -- add tag name to output buffer
        output[#output+1] = currentTag .. ", "

        -- check for a metatable
        local mt = getmetatable(currentTable)
        -- confirm that there is a metatable, its __index is a table
        if mt and ((type(mt.__index) == "table" and not mt.__index._isObject) or not mt.__index) then
            
            local mtTag = getTableAddress(mt)
            -- add the metatable to the queue only if it is unserialized
            if not checklist[mtTag] then
                queue[#queue+1] = mt
                checklist[mtTag] = true
            end
            output[#output+1] = mtTag .. ", "
        else
            output[#output+1] = ""
        end

        -- go through the table, store all primitives, and add any more tables to the queue
        local counter = 0
        output[#output+1] = "{\n  "
        for key, value in pairs(currentTable) do
            if counter > 0 then
                output[#output+1] = ",\n  "
            end

            -- serialize the key and value, and place them in the output buffer
            output[#output+1] = serializeValue(key, queue, checklist)
            output[#output+1] = " = "
            output[#output+1] = serializeValue(value, queue, checklist)

            -- remove the table from the queue if it is a parent
            if key == "_parent" and not upcast and queue[#queue] == currentTable._parent and currentTable._isObject then
                queue[#queue] = nil
            end

            counter = counter + 1
        end
        -- determine if the table is an Object or not, and apply its type if so
        if currentTable._isObject and currentTable.GetType then
            if counter > 0 then
                output[#output+1] = ",\n  "
            end
            output[#output+1] = serializeValue("_type", queue, checklist)
            output[#output+1] = " = "
            output[#output+1] = serializeValue(currentTable:GetType(), queue, checklist)

        end

        output[#output+1] = "\n}|\n\n"

        -- remove the table from the queue
        table.remove(queue, 1)
    end
    
    output[#output+1] = "ROOT = " .. baseTag
    
    return table.concat(output)
end

function _G.serialize(tab, upcast)
    local status, result = pcall(rawSerialize, tab, upcast)
    return type(result) == "string" and result or nil
end

local function getStringBounds(s)
    local i = 1
    local out = {}
    
    while i <= #s do
        local delimPos = s:find("[\"%[']", i) -- matches either ', ", or [
        if delimPos then
            local delimiter = s:sub(delimPos, delimPos)
            if delimiter == '"' or delimiter == "'" then
                out[#out+1] = delimPos
                -- doesn't really matter, but for safety, put the other index at the end if not found:
                i = (s:find(delimiter, delimPos+1, true) or (#s-1)) + 1
                out[#out+1] = i-1
            elseif s:sub(delimPos, delimPos+1) == "[[" then
                out[#out+1] = delimPos
                i = (s:find("]]", delimPos+1, true) or (#s-1)) + 1
                out[#out+1] = i-1
            else
                -- it was probably a square bracket unrelated to strings
                i = delimPos + 1
            end
        else
            i = #s + 1
        end
    end

    return out
end

local function indexIsWithin(x, indices)
    for i = 1, #indices, 2 do
        if x >= indices[i] and x <= indices[i+1] then
            return true
        elseif x < indices[i] then
            return false
        end
    end
    return false
end

--------------------------------- SPECIAL SPLIT FUNCTIONS ----------------------------
-- !! HIGHLY NICHE FUNCTION - ONLY USE IF YOU KNOW !! --
local function splitByIndices(str, indices)
    local out = {}
    if #indices == 0 then return out end

    for i = 1, #indices do
        out[#out+1] = str:sub((indices[i-1] or 0) + 1, indices[i] - 1):trim()
    end

    out[#out+1] = str:sub(indices[#indices]+1, #str):trim()
    -- note: if you're trying to genericize this function, use this line instead of the above one:
    -- out[#out+1] = str:sub(indices[#indices]+1, #str):gsub("[\n\r]", ""):trim()
    
    return out
end

local function getSplitIndices(str, d, indices)
    local out = {}
    local left, right = 1, 0
    while right do
        left = right + 1
        repeat
            right = str:find(d, right+1, true)
        until not right or not indexIsWithin(right, indices)

        if right then
            out[#out+1] = right
        end
    end
    return out
end
--------------------------------- END SPECIAL SPLIT FUNCTIONS ----------------------------

local function merge(l1, l2)
    local p2 = 1
    local out = {}
    for p1, _ in ipairs(l1) do
        while l2[p2] and l2[p2] <= l1[p1] do
            out[#out+1] = l2[p2]
            p2 = p2 + 1
        end
        out[#out+1] = l1[p1]
    end
    for p2 = p2, #l2 do
        out[#out+1] = l2[p2]
    end
    return out
end

local stringDelims = {['"'] = true, ["'"] = true, ["["] = true}
local presetValues = {
    ['true'] = true,
    ['false'] = false,
    ['nil'] = nil
}


local function deserializeValue(val, referenceList)
    local identifier = val:sub(1,1)
    if tonumber(val) then
        -- value is a number
        val = tonumber(val)
    elseif identifier == "@" then
        -- value is a table reference
        val = val:sub(2, #val)
        if not referenceList[val] then
            -- create a new table
            referenceList[val] = {}
        end
        val = referenceList[val]

    elseif stringDelims[identifier] then
        -- value is a string
        if identifier == "[" then
            val = val:sub(3, #val-2)
        else
            val = val:sub(2, #val-1)
        end
    else
        -- value is some constant identifier
        val = presetValues[val]
    end

    return val
end

-- Deserializes a string back into a family of tables. 
local function rawDeserialize(serial)
    -- split by } + (whitespace) + ;
    local tableList = serial:split("}%s*|", true)
    local referenceList = {} -- list of table tags (keys) mapped to their tables (vals)
    local complete = {} -- list of references to complete tables
    local tbl -- saves the last created table in scope
    for _i, tblStr in ipairs(tableList) do
        if _i < #tableList then
            -- separate the table from metatata
            local metaTableSplit = tblStr:split("{", true, 1)

            -- table tag is first, metatable tag is second
            local metadata = metaTableSplit[1]:split(",", true)
            local tableTag, metaTag = metadata[1], (metadata[2] and metadata[2]:trim() or "")
            if tableTag:sub(1,2) == "F_" then
                -- this line should be interpreted as a function!
                tbl = loadstring("return ".. -- we're being pretty lazy about this right now
                    tblStr:sub(                        -- substring from...
                        tblStr:find("{") + 1,          -- the opening curly...
                        #tblStr                        -- the end of tblStr   
                ))()                               -- or just, the body of the function
                -- from here we should be able to add it to the reference table as normal
                referenceList[tableTag] = tbl
            elseif tableTag == "PACKAGE" then
                -- this is a function package!
                local path = tblStr:sub(tblStr:find("{") + 1, #tblStr)
                local package = require(path:trim())
                for k, f in pairs(package) do
                    referenceList[k] = f
                end
            else
                -- this line is a table as normal
                -- create a new table, if a reference to this one doesn't exist already
                tbl = referenceList[tableTag] or {}
                
                -- apply the metatable if it exists
                if #metaTag > 0 then
                    setmetatable(tbl, deserializeValue("@"..metaTag, referenceList))
                end

                -- now let's find out where those damned strings are...
                local valuesStr = metaTableSplit[2]
                
                local stringBounds = getStringBounds(valuesStr)
                local commaIndices = getSplitIndices(valuesStr, ",", stringBounds)
                local equalIndices = getSplitIndices(valuesStr, "=", stringBounds)
                local allIndices = merge(commaIndices, equalIndices)


                local finalValueSplit = splitByIndices(valuesStr, allIndices)

                

                for i = 1, #finalValueSplit, 2 do
                    local key = deserializeValue(finalValueSplit[i], referenceList)
                    local val = deserializeValue(finalValueSplit[i+1], referenceList)
                    
                    tbl[key or "_UNDEFINED"] = val
                end
                
                -- turn table into an object, if necessary
                if tbl._type and Chexcore._types[tbl._type] then
                    setmetatable(tbl, Chexcore._types[tbl._type])
                end

                -- add the table to the reference list
                referenceList[tableTag] = tbl
            end



            
            
        else
            -- we're at the "ROOT" definition (end)

            local rootReference = tblStr:split("%s*=%s*")[2]
            tbl = referenceList[rootReference] or tbl
        end
    end
    return tbl
end

function _G.deserialize(serial)
    local status, ret = pcall(rawDeserialize, serial)
    return ret or nil
end

-- new string methods:
local stringmt = getmetatable""

-- Limits a string to a set number of characters and appends with ' ...'
function stringmt.__index:limit(maxLength, ellipses)
    ellipses = ellipses == nil and true or false
    return #self <= maxLength and self or (self:sub(1, maxLength)..(ellipses and " ..." or ""))
end


-- Adapted from PiL2 20.4
-- Trims all whitespace/newlines from the beginning and end of a string
function stringmt.__index:trim()
    return self:gsub("^%s*(.-)%s*$", "%1")
end
local trim = stringmt.__index.trim


-- Splits a string into a table of strings with a custom delimiter (or "\n")
-- Converts number strings into numbers
-- If the delimiter exists multiple times in a row, it will be treated as a single delimiter
-- if 'trimWhitespace' is true, all whitespace before and after each substring will be removed
local tonumber = tonumber
local huge = math.huge
function stringmt.__index:split(pattern, trimWhitespace, limit, toIgnore)
    pattern = pattern or "\n"
    limit = limit or huge
    local out = {}
    local pos, count = 1, 0

    local left, right = 0, 0
    repeat
        if toIgnore then
            -- make sure we aren't within certain indices
            local tPos
            repeat
                tPos = right + 1
                left, right = self:find(pattern, tPos)
            until not left or not indexIsWithin(left, toIgnore)
        else
            -- standard find
            left, right = self:find(pattern, pos)
        end

        if left then
            -- capture from the last string position to the beginning
            out[#out+1] = trimWhitespace and trim(self:sub(pos, left-1)) or self:sub(pos, left-1)

            pos = right + 1
        else
            -- load the rest of the string into the output
            out[#out+1] = trimWhitespace and trim(self:sub(pos, #self)) or self:sub(pos, #self)
        end
        count = count + 1

        -- check if we've reached our max splits count
        if count >= limit then
            out[#out+1] = trimWhitespace and trim(self:sub(pos, #self)) or self:sub(pos, #self)
            break
        end
    until not left

    return out
end

if replaceCoreLuaFunctions then
    -- new tostring function which provides better table visualizations and Object support!
    local function ctostring(tab, breaks, indent)
        
        if type(tab) ~= "table" then return oldtostring(tab) end
        if tab._isObject then
            if indent then
                return tab:ToString()
            else
                -- passing along 'indent' because it may act as the 'noTypeLabels' bool
                return tab:ToString(breaks, indent)
            end
        end

        indent = indent or 0
        if indent > Chexcore.MAX_TABLE_OUTPUT_INDENT then return "..." end

        local output = breaks and ("{ # " .. _tostring(tab):sub(8, 22) .. "\n") or "{"

        local searched = 0
        for k, v in sortedPairs(tab) do
            searched = searched + 1
            local vVal = type(v) == "table" and "" .. ctostring(v, breaks, indent + 2) or (type(v) == "string" and ('"' .. ctostring(v) .. '"') or ctostring(v))
            output = output .. (breaks and (" "):rep(indent + (breaks and 2 or 0)) or "") .. ctostring(k) .. ": " .. vVal .. (breaks and ",\n" or ", ")
        end

        -- empty table visual
        if searched == 0 then
            return breaks and (output:sub(1, #output-1) .. " }") or (output .. " # ".._tostring(tab):sub(8, 22) .. " }")
        end

        return output:sub(1, #output-2) .. (breaks and (searched > 0 and ("\n" .. (" "):rep(indent)) or " ") or "") .. "}"
    end
    _G.tostring = ctostring
end

function _G.isObject(t)
    return type(t) == "table" and t._type and true or false
end
local isObject = _G.isObject

--[[  
    filteredListIterator()
     - returns the full list of an object's children
    filteredListIterator( name )
     - returns the subset of children with the given name
    filteredListIterator( property, value )
     - returns the subset of children with the given property and value
    filteredListIterator( { property = val, ...} [, inclusive] )
     - searches for multiple properties. If inclusive is false, all properties must match.
    filteredListIterator( func )
     - returns the subset of children for which func(child) returns true

     The above signatures make up a wrapper signature referred to as "<FilterArg>"
]]
local STOP = 1000000
function _G.filteredListIterator(self, arg1, arg2, children)
    
    


    if not (arg1 or arg2) then  -- get entire set
        local i = 0; local nest
        if children then
            return function ()
                if nest then
                    local res = nest()
                    if res then return res else nest = nil end
                end
                i = i + 1
                if isObject(self[i]) and self[i]:HasChildren() then
                    nest = self[i]:EachDescendant(arg1, arg2, true)
                end
                return self[i]
            end
        else
            return function()
                i = i + 1
                return self[i]
            end
        end
    end

    
    

    -- if not (arg1 or arg2) then  -- get entire set
    --     for i, ref in ipairs(self) do
    --         list[#list+1] = ref
    --         if children and isObject(ref) and ref:HasChildren() then
    --             ref:GetGrandchildren(arg1, arg2, list)
    --         end
    --     end
    --     return list
    -- end
    
    if type(arg1) == "table" then
        
        -- filteredListIterator( { property = val, ...} [, inclusive] )
        if not arg2 then
            
            -- exclusive
            --print(self, children)
            local i = 0; local nest
            return function()
                
                if nest then
                    local res = nest()
                    if res then return res else nest = nil end
                end
                
                while STOP - i > 0 do
                    
                    i = i + 1
                    if children and isObject(self[i]) and self[i]:HasChildren() then                        
                        nest = self[i]:EachDescendant(arg1, arg2, true)
                    end
                    local c = self[i]
                    if not c then return nil end
                    local match = true
                    for property, val in pairs(arg1) do
                        if c[property] ~= val then
                            match = false; break
                        end
                    end
                    if match then return c end

                    if nest then
                        local res = nest()
                        if res then return res else nest = nil end
                    end
                end
            end
        else
            -- inclusive
            local i = 0; local nest
            return function()
                
                if nest then
                    local res = nest()
                    if res then return res else nest = nil end
                end
                while STOP - i > 0 do
                    i = i + 1
                    if children and isObject(self[i]) and self[i]:HasChildren() then
                        nest = self[i]:EachDescendant(arg1, arg2, true)
                    end
                    local c = self[i]
                    if not c then return nil end
                    local match = false
                    for property, val in pairs(arg1) do
                        if c[property] == val then
                            match = true; break
                        end
                    end
                    if match then return c end
                    if nest then
                        local res = nest()
                        if res then return res else nest = nil end
                    end
                end
            end
        end
    elseif type(arg1) == "function" then
        -- filteredListIterator( func, arg )
        
        
        local i = 0; local nest
        return function()
            if nest then
                local res = nest()
                if res then return res else nest = nil end
            end
            while STOP - i > 0 do
                i = i + 1
                if children and isObject(self[i]) and self[i]:HasChildren() then
                    nest = self[i]:EachDescendant(arg1, arg2, true)
                end
                local c = self[i]
                if not c then return nil end

                if arg1(c, arg2) then
                    return c
                end

                if nest then
                    local res = nest()
                    if res then return res else nest = nil end
                end
            end
        end
    elseif arg2 ~= nil then
        -- filteredListIterator( property, value )
        
        local i = 0; local nest
        return function()
            if nest then
                local res = nest()
                if res then return res else nest = nil end
            end
            while STOP - i > 0 do
                i = i + 1
                if children and isObject(self[i]) and self[i]:HasChildren() then
                    nest = self[i]:EachDescendant(arg1, arg2, true)
                end
                local c = self[i]
                if not c then return nil end
                if c[arg1] == arg2 then
                    return c
                end

                if nest then
                    local res = nest()
                    if res then return res else nest = nil end
                end
            end
        end
    
    end
end

local rawGetSize = love.graphics.getDimensions
-- just returns screen size as a vector
function _G.getWindowSize()
    return V{rawGetSize()}
end

-- simple clamp
function math.clamp(n, min, max)
    return n < min and min or n > max and max or n
end
local clamp, abs = math.clamp, math.abs


-- return a list of numbers (start, stop, step [, cmp])
-- step can be a number or a function
-- cmp can be specified as a custom comparison function
local cmp1 = function(i, stop) return i <= stop end
local cmp2 = function(i, stop) return i >= stop end
function math.series(start, stop, step, cmp)
    step = step or 1
    if step == 0 then error"infinite series fucked u up" end
    local out = {start}
    cmp = cmp or (((type(step) == "function" or step > 0) and start < stop) and cmp1) or cmp2
    if type(step) == "function" then
        while cmp(out[#out], stop) do
            out[#out+1] = step(out[#out])
        end
    else
        while cmp(out[#out], stop) do
            out[#out+1] = out[#out] + step
        end
    end

    out[#out] = nil -- kill final result (oopsie)
    return out
end

-- print"math.series(1,10)"
-- print("     "..tostring(math.series(1,10)))
-- print("------------------------")
-- print"math.series(1,10, 3)"
-- print("     "..tostring(math.series(1,10, 3)))
-- print("------------------------")
-- print"math.series(10, -10, -5)"
-- print("     "..tostring(math.series(10, -10, -5)))
-- print("------------------------")
-- print("math.series(1,10, function(i) return i * 1.1 end, function(i, stop) return i < stop * 2 end)")
-- print("     "..tostring(math.series(1,10, function(i) return i * 1.1 end, function(i, stop) return i < stop * 2 end)))
local function lerp2(a,b,t,s)
    local n = a + (b - a) * clamp(t,0,1)
    if abs(n-b) < s then
        return b
    else
        return n
    end
end

function math.lerp(a, b, t, s)
    if s then return lerp2(a,b,t,s) end
    return a + (b - a) * clamp(t,0,1)
end

-- simple round
local floor = math.floor
function math.round(n)
    return floor(n+0.5)
end

-- Too lazy to redocument. Same deal as above, just does the whole list at once
function _G.filteredList(self, arg1, arg2, children, list)
    list = list or {}
    
    if not (arg1 or arg2) then  -- get entire set
        for i, ref in ipairs(self) do
            list[#list+1] = ref
            if children and isObject(ref) and ref:HasChildren() then
                ref:GetDescendants(arg1, arg2, list)
            end
        end
        return list
    end

    if type(arg1) == "table" then
        -- filteredList( { property = val, ...} [, inclusive] )
        if not arg2 then
            -- exclusive
            for _, child in ipairs(self) do
                local match = true
                for property, val in pairs(arg1) do
                    if child[property] ~= val then
                        match = false; break
                    end
                end
                if match then
                    list[#list+1] = child
                end
                if children and isObject(child) and child:HasChildren() then
                    child:GetDescendants(arg1, arg2, list)
                end
            end
        else
            -- inclusive
            for _, child in ipairs(self) do
                local match = false
                for property, val in pairs(arg1) do
                    if child[property] == val then
                        match = true; break
                    end
                end
                if match then
                    list[#list+1] = child
                end
                if children and isObject(child) and child:HasChildren() then
                    child:GetDescendants(arg1, arg2, list)
                end
            end
        end
    elseif arg2 ~= nil then
            -- filteredList( property, value )
            for _, child in ipairs(self) do
                if child[arg1] == arg2 then
                    list[#list+1] = child
                end
                if children and isObject(child) and child:HasChildren() then
                    child:GetDescendants(arg1, arg2, list)
                end
            end
    elseif type(arg1) == "function" then
        -- filteredList( func, arg )
        for index, child in ipairs(self) do
            if arg1(child, arg2) then
                list[#list+1] = child
            end
            if children and isObject(child) and child:HasChildren() then
                child:GetDescendants(arg1, arg2, list)
            end
        end
    end

    return list
end

local smt, gmt, type, pairs = setmetatable, getmetatable, type, pairs
local function deepCopy(tab)
    if type(tab) ~= "table" then return tab end
    
    local nt = smt({}, gmt(tab))
    for k, v in pairs(tab) do
        if type(v) == "table" then
            print(v)
            if k ~= "_parent" then nt[k] = deepCopy(v) end
        else
            nt[k] = v
        end
    end
    return nt
end
_G.deepCopy = deepCopy

_G.sign = function (n)
    return n < 0 and -1 or n > 0 and 1 or 0
end



--- Draw stuff 

local love_graphics_draw = love.graphics.draw
local floor = math.floor
-- negative sx and sy values do default behavior; positive values are pixel measurements
-- ox and oy values between 0 and 1 will be treated as a ratio to image size (anchor point)

local love_graphics_setcolor = love.graphics.setColor
function _G.setcolor(r, g, b, a)
    love_graphics_setcolor(r, g, b, a)
end

local lg = love.graphics
_G.cdraw = function(drawable, x, y, r, sx, sy, ox, oy, kx, ky, ignoreSnap)
    -- lg.push()
    love_graphics_draw(
        drawable,
        ignoreSnap and (x or 0) or floor(x or 0),
        ignoreSnap and (y or 0) or floor(y or 0), r,
        1 / drawable:getWidth() * (sx or 1),
        1 / drawable:getHeight() * (sy or 1),
        ox and (ox <= 1 and drawable:getWidth() * ox or ox),
        oy and (oy <= 1 and drawable:getHeight() * oy or oy),
        kx, ky
    )
    -- lg.pop()
end

_G.cdrawquad = function(drawable, quad, qx, qy, x, y, r, sx, sy, ox, oy, kx, ky, ignoreSnap)
    love_graphics_draw(
        drawable,
        quad,
        ignoreSnap and (x or 0) or floor(x or 0), 
        ignoreSnap and (y or 0) or floor(y or 0), r,
        1 / qx * (sx or 1),
        1 / qy * (sy or 1),
        ox and (ox <= 1 and qx * ox or ox),
        oy and (oy <= 1 and qy * oy or oy),
        kx, ky
    )
end

-- ox/oy and sx/sy alternate rules always apply here
_G.cdraw2 = function(drawable, x, y, r, sx, sy, ox, oy, kx, ky, ignoreSnap)
    love_graphics_draw(
        drawable,
        ignoreSnap and (x or 0) or math.floor(x or 0), ignoreSnap and (y or 0) or math.floor(y or 0), r,
        sx,
        sy,
        ox and drawable:getWidth() * ox,
        oy and drawable:getHeight() * oy,
        kx, ky
    )
end

local max, abs, drawPoints = math.max, math.abs, love.graphics.points
function _G.cdrawline(x1, y1, x2, y2, length, offset)
    length = length or -1
    offset = offset or 0
    local points = {}

    local dx, dy = x2 - x1, y2 - y1
    local len = max(abs(dx), abs(dy))

    for i = 0, len do -- including first and last points
        if (offset-i) % (length*2) < length or length == -1 then
            points[#points+1] = x1 + dx * i/len
            points[#points+1] = y1 + dy * i/len
        end
    end
    drawPoints(points)
  end

local love_graphics_circle = love.graphics.circle
function _G.cdrawlinethick(x1, y1, x2, y2, thickness, length, offset)
    length = length or -1
    offset = offset or 0

    if thickness == 0 then
        return cdrawline(x1, y1, x2, y2, length, offset)
    end

    local dx, dy = x2 - x1, y2 - y1
    local len = max(abs(dx), abs(dy))

    for i = 0, len do -- including first and last points
        if (offset-i) % (length*2) < length or length == -1 then
            love_graphics_circle("fill", x1 + dx * i/len, y1 + dy * i/len, thickness)
        end
    end
end

-- Ellipse in general parametric form 
-- (See http://en.wikipedia.org/wiki/Ellipse#General_parametric_form)
-- (Hat tip to IdahoEv: https://love2d.org/forums/viewtopic.php?f=4&t=2687)
--
-- The center of the ellipse is (x,y)
-- a and b are semi-major and semi-minor axes respectively
-- phi is the angle in radians between the x-axis and the major axis

print("FLOOR", math.floor(1.2))

function love.graphics.ellipse2(mode, x, y, a, b, phi, points)
    phi = phi or 0
    points = points or 10
    if points <= 0 then points = 1 end
  
    local two_pi = math.pi*2
    local angle_shift = two_pi/points
    local theta = 0
    local sin_phi = math.sin(phi)
    local cos_phi = math.cos(phi)
  
    local coords = {}
    for i = 1, points do
      theta = theta + angle_shift
      coords[2*i-1] = x + a * math.cos(theta) * cos_phi 
                        - b * math.sin(theta) * sin_phi
      coords[2*i] = y + a * math.cos(theta) * sin_phi 
                      + b * math.sin(theta) * cos_phi
    end
  
    coords[2*points+1] = coords[1]
    coords[2*points+2] = coords[2]
  
    love.graphics.polygon(mode, coords)
  end

function _G.cdrawcircle(mode, x, y, radius)
    if radius > 0 then
        love_graphics_circle(mode, x, y, radius)
    else
        drawPoints(x, y)
    end
end