Node = {}
Node.__index = Node

function Node:new(x, y, radius)
    local node = setmetatable({}, Node)
    node.x = x
    node.y = y
    node.radius = radius
    node.selected = false
    node.counter = 1
    node.counterTime = 0
    node.connections = {}
    return node
end

function Node:update(dt)
    self.counterTime = self.counterTime + dt
    if self.counterTime >= 1 then
        self.counter = self.counter + 1
        self.counterTime = self.counterTime - 1
    end
end

function Node:draw()
    if self.selected then
        love.graphics.setColor(1, 0, 0)  -- Red color for selected node
    else
        love.graphics.setColor(1, 1, 1)  -- White color for other nodes
    end
    love.graphics.circle("line", self.x, self.y, self.radius)

    -- Draw the counter in the center of the selected node
    if self.selected then
        love.graphics.setColor(1, 1, 1)  -- White color for text
        local font = love.graphics.getFont()
        local text = tostring(self.counter)
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight()  -- Corrected this line to remove the redundant parameter
        love.graphics.print(text, self.x - textWidth / 2, self.y - textHeight / 2)
    end
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
