local Cat = {
    -- properties
    Name = "Cat",           -- Easy identifier
    Age = 1,                -- other custom properties
    Breed = "Maine Coon",   -- whatever
    Position = {x = 0, y = 0},
    BestFriend = nil,       -- :3

    -- internal properties
    _super = "Object",      -- Supertype
    _global = true
}

function Cat:Meow()
    print(self.Name .. " says 'meow :3'")
end

return Cat