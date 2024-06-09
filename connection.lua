Connection = {}
Connection.__index = Connection

function Connection:new(node1, node2)
    local connection = setmetatable({}, Connection)
    connection.node1 = node1
    connection.node2 = node2
    connection.moveSpeed = 50  -- Speed of the moving point in pixels per second
    connection.dots = {}
    connection.spawnTimer = 0
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
    self.startX = startX
    self.startY = startY
    self.endX = endX
    self.endY = endY
end

function Connection:update(dt)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= 1 then
        self.spawnTimer = self.spawnTimer - 1
        if self.node1.counter > 0 then
            self:spawnDot()
        end
    end

    -- Update dots positions along the line
    for i = #self.dots, 1, -1 do
        local dot = self.dots[i]
        dot.position = dot.position + self.moveSpeed * dt / self.length
        if dot.position >= 1 then
            -- Dot reached the end of the line
            self.node2.counter = self.node2.counter + 1
            table.remove(self.dots, i)
        end
    end
end

function Connection:spawnDot()
    if self.node1.counter > 0 then
        self.node1.counter = self.node1.counter - 1
        table.insert(self.dots, {position = 0})  -- Position on the line
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

    -- Draw dots
    for _, dot in ipairs(self.dots) do
        local dotX = startX + dot.position * (endX - startX)
        local dotY = startY + dot.position * (endY - startY)
        love.graphics.setColor(1, 1, 1)  -- White color for dots
        love.graphics.circle("fill", dotX, dotY, 5)
    end
end

function Connection:isClicked(x, y)
    -- Calculate the distance from the click to the line segment
    local dx = self.endX - self.startX
    local dy = self.endY - self.startY
    local lengthSquared = dx * dx + dy * dy
    local t = ((x - self.startX) * dx + (y - self.startY) * dy) / lengthSquared
    t = math.max(0, math.min(1, t))
    local closestX = self.startX + t * dx
    local closestY = self.startY + t * dy
    local distance = math.sqrt((closestX - x) ^ 2 + (closestY - y) ^ 2)

    return distance < 5  -- Return true if the click is within 5 pixels of the line
end

return Connection
