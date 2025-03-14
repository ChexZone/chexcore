local Camera = {
    -- properties
    Name = "Camera",
    Zoom = 1,
    
    -- internal properties
    _super = "Prop",      -- Supertype
    _global = true
}

function Camera.new(properties)
    local newCamera = Camera:SuperInstance()
    if properties then
        for prop, val in pairs(properties) do
            newCamera[prop] = val
        end
    end


    return Camera:Connect(newCamera)
end

return Camera