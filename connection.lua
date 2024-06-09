Connection = {}
Connection.__index = Connection

function Connection:new(node1, node2)
    local connection = setmetatable({}, Connection)
    connection.node1 = node1
    connection.node2 = node2
    connection.moveSpeed = 50  -- Speed of the moving point in pixels per second
    connection.position = 0  -- Position of the moving point along the line (0 to 1)
    connection:calculateLength()
    return connection
end

function Connection:calculateLength()
    local angle = math.atan2(self.node2.y - self.node1.y, self.node2.x - self.node1.x)
    local startX = self.node1.x + self.node1.radius * math.cos(angle)
    local startY = self.node1.y + self.node1.radius * math.sin(angle)
    local endX = self.node2.x - self.node2.radius * math.cos(angle)
    local endY = self.node2.y - self.node2.radius * math.sin(angle)

    self.length = math.sqrt((endX - startX) ^ 2 + (endY - startY) ^ 2)
end

function Connection:update(dt)
    self.position = self.position + self.moveSpeed * dt / self.length
    if self.position > 1 then
        self.position = 0
    end
end

function Connection:draw()
    local angle = math.atan2(self.node2.y - self.node1.y, self.node2.x - self.node1.x)
    local startX = self.node1.x + self.node1.radius * math.cos(angle)
    local startY = self.node1.y + self.node1.radius * math.sin(angle)
    local endX = self.node2.x - self.node2.radius * math.cos(angle)
    local endY = self.node2.y - self.node2.radius * math.sin(angle)

    if self.node1.selected or self.node2.selected then
        love.graphics.setColor(1, 0, 0)  -- Red color for the line if one of the nodes is selected
    else
        love.graphics.setColor(0, 1, 0)  -- Green color for the line otherwise
    end
    love.graphics.setLineWidth(4)  -- Line thickness doubled
    love.graphics.line(startX, startY, endX, endY)
    love.graphics.setLineWidth(1)  -- Reset line width to default

    -- Draw the moving point
    local pointX = startX + self.position * (endX - startX)
    local pointY = startY + self.position * (endY - startY)
    love.graphics.setColor(1, 1, 1)  -- White color for the moving point
    love.graphics.circle("fill", pointX, pointY, 5)
end

return Connection
