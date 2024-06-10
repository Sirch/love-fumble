local Dot = require("dot")

Connection = {}
Connection.__index = Connection

function Connection:new(node1, node2)
    local connection = setmetatable({}, Connection)
    connection.node1 = node1
    connection.node2 = node2
    connection.dots = {}
    connection:calculateLength()
    connection.spawnTimer = 0  -- Timer for managing dot spawning
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
    if self.spawnTimer > 1 then
        self.spawnTimer = self.spawnTimer - 1
        self:spawnDot()
    end

    for i = #self.dots, 1, -1 do
        self.dots[i]:update(dt)
    end
end

function Connection:spawnDot()
    if self.node1.value > 1 then
        self.node1.value = self.node1.value - 1
        table.insert(self.dots, Dot:new(self, 0, self.node1.owner))
    end
end

function Connection:removeDot(dot)
    for i = #self.dots, 1, -1 do
        if self.dots[i] == dot then
            table.remove(self.dots, i)
            break
        end
    end
end

function Connection:draw()
    self:drawLine()
    self:drawDots()
end

function Connection:drawLine()
    if self.node1.owner == "player" or self.node2.owner == "player" then
        love.graphics.setColor(1, 0, 0)  -- Red color if one of the nodes is owned by the player
    else
        love.graphics.setColor(0, 1, 0)  -- Green color otherwise
    end

    love.graphics.setLineWidth(4)  -- Line thickness doubled
    love.graphics.line(self.startX, self.startY, self.endX, self.endY)
    love.graphics.setLineWidth(1)  -- Reset line width to default
end

function Connection:drawDots()
    for _, dot in ipairs(self.dots) do
        dot:draw()
    end
end

function Connection:isClicked(x, y)
    local dx = self.endX - self.startX
    local dy = self.endY - self.startY
    local lengthSquared = dx * dx + dy * dy
    local t = ((x - self.startX) * dx + (y - self.startY) * dy) / lengthSquared
    t = math.max(0, math.min(1, t))
    local closestX = self.startX + t * dx
    local closestY = self.startY + t * dy
    local distance = math.sqrt((closestX - x) ^ 2 + (closestY - y) ^ 2)

    return distance < 5  -- True if the click is within 5 pixels of the line
end

return Connection
