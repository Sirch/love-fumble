Node = {}
Node.__index = Node

function Node:new(x, y, radius, owner)
    local node = setmetatable({}, Node)
    node.x = x
    node.y = y
    node.radius = radius
    node.owner = owner or "neutral"  -- owner can be "player" or "neutral"
    node.value = owner == "player" and 0 or math.random(10, 100)  -- Initial value
    node.valueTime = 0
    node.connections = {}
    return node
end

function Node:update(dt)
    if self.owner == "player" then
        self.valueTime = self.valueTime + dt
        if self.valueTime >= 1 then
            self.value = self.value + 1
            self.valueTime = self.valueTime - 1
        end
    end
end

function Node:hit(x)
    local oldValue = self.value
    self.value = math.max(0, self.value - x)
    print(string.format("Node hit: value decreased from %d to %d", oldValue, self.value))
    if self.value == 0 then
        self.owner = "neutral"
        print("Node ownership changed to neutral")
    end
end

function Node:support(x)
    local oldValue = self.value
    self.value = self.value + x
    print(string.format("Node support: value increased from %d to %d", oldValue, self.value))
end

function Node:draw()
    self:drawNode()
    self:drawValue()
end

function Node:drawNode()
    if self.owner == "player" then
        love.graphics.setColor(1, 0, 0)  -- Red color for player's node
    else
        love.graphics.setColor(1, 1, 1)  -- White color for neutral nodes
    end
    love.graphics.circle("line", self.x, self.y, self.radius)
end

function Node:drawValue()
    love.graphics.setColor(1, 1, 1)  -- White color for text
    local font = love.graphics.getFont()
    local text = tostring(self.value)
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, self.x - textWidth / 2, self.y - textHeight / 2)
end

function Node:isInside(x, y)
    local dx = x - self.x
    local dy = y - self.y
    return dx * dx + dy * dy <= self.radius * self.radius
end

function Node:addConnection(connection)
    table.insert(self.connections, connection)
end

function Node:drawConnections()
    for _, connection in ipairs(self.connections) do
        connection:draw()
    end
end

return Node
