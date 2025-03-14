local Group = {
    -- properties
    Name = "Group",

    Size = V{0, 0},
    Visible = false,
    
    -- internal properties
    _super = "Prop",      -- Supertype
    _global = true
}

function Group.new(properties)
    local newGroup = Group:SuperInstance()

    newGroup.Size.X = Group.Size.X
    newGroup.Size.Y = newGroup.Size.Y

    if type(properties) == "string" then
        newGroup.Name = properties
    elseif properties then
        for prop, val in pairs(properties) do
            newGroup[prop] = val
        end
    end


    return Group:Connect(newGroup)
end

function Group:CollisionInfo()
    return false
end

return Group