local SpecialObject = {
    -- properties
    Name = "SpecialObject",        -- Easy identifier
    Test = true,

    -- internal properties
    _super = "Object",      -- Supertype
    _global = true
}

---------------- Constructor -------------------
function SpecialObject.new()
    local myObj = SpecialObject:SuperInstance()
    
    return SpecialObject:Connect(myObj)
end
------------------------------------------------

------------------ Methods ---------------------
function SpecialObject:Update(dt)
    -- update stuff with dt
end

function SpecialObject:Draw(tx, ty)
    -- draw method with tx, ty offsets (draw at position minus tx, ty)
end
----------------------------------------

return SpecialObject