local Dot = require("dot")

Connection = {}
Connection.__index = Connection

--- Creates a new Connection object
-- @param node1 table The first node
-- @param node2 table The second node
-- @return table The new Connection object
function Connection:new(node1, node2)
    local connection = setmetatable({}, Connection)
    connection.node1 = node1
    connection.node2 = node2
    connection.dots = {}
    connection:calculateLength()
    connection.spawnTimer = 0  -- Timer for managing dot spawning
    return connection
end

--- Calculates the length and start/end points of the connection
function Connection:calculateLength()
    local angle = math.atan2(self.node2.y - self.node1.y, self.node2.x - self.node1.x)
    self.startX, self.startY = self:getPointOnCircle(self.node1, angle)
    self.endX, self.endY = self:getPointOnCircle(self.node2, angle + math.pi)
    self.length = self:calculateDistance(self.startX, self.startY, self.endX, self.endY)
end

--- Returns a point on the circumference of a node
-- @param node table The node
-- @param angle number The angle in radians
-- @return number, number The x and y coordinates
function Connection:getPointOnCircle(node, angle)
    return node.x + node.radius * math.cos(angle), node.y + node.radius * math.sin(angle)
end

---Calculates the distance between two points
--@param x1 number The x coordinate of the first point
--@param y1 number The y coordinate of the first point
--@param x2 number The x coordinate of the second point
--@param y2 number The y coordinate of the second point
--@return number The distance between the points
function Connection:calculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

--- Updates the connection and its dots
-- @param dt number The delta time since the last update
function Connection:update(dt)
    self:updateSpawnTimer(dt)
    self:updateDots(dt)
end

--- Updates the spawn timer and spawns a dot if needed
-- @param dt number The delta time since the last update
function Connection:updateSpawnTimer(dt)
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer > 1 then
        self.spawnTimer = self.spawnTimer - 1
        self:spawnDot()
    end
end

function Connection:sameOwner()
    if self.node1.owner == self.node2.owner then
        return true
    else
        return false
    end
    
end

--- Spawns a new dot if conditions are met
function Connection:spawnDot()
    if self.node1.value > 1 and not self:sameOwner() then
        self.node1.value = self.node1.value - 1
        table.insert(self.dots, Dot:new(self, 0, self.node1.owner))
    end
end

--- Updates all dots
-- @param dt number The delta time since the last update
function Connection:updateDots(dt)
    for i = #self.dots, 1, -1 do
        self.dots[i]:update(dt)
    end
end

--- Removes a dot from the connection
-- @param dot table The dot to remove
function Connection:removeDot(dot)
    for i = #self.dots, 1, -1 do
        if self.dots[i] == dot then
            table.remove(self.dots, i)
            break
        end
    end
end

--- Draws the connection and its dots
function Connection:draw()
    self:drawLine()
    self:drawDots()
end

--- Draws the connection line
function Connection:drawLine()
    if self.node1.owner == "player" or self.node2.owner == "player" then
        love.graphics.setColor(1, 0, 0)  -- Red colour if one of the nodes is owned by the player
    else
        love.graphics.setColor(0, 1, 0)  -- Green colour otherwise
    end

    love.graphics.setLineWidth(4)  -- Line thickness doubled
    love.graphics.line(self.startX, self.startY, self.endX, self.endY)
    love.graphics.setLineWidth(1)  -- Reset line width to default
end

--- Draws all dots
function Connection:drawDots()
    for _, dot in ipairs(self.dots) do
        dot:draw()
    end
end

--- Determines if a click is near the connection line
-- @param x number The x coordinate of the click
-- @param y number The y coordinate of the click
-- @return boolean True if the click is near the line, false otherwise
function Connection:isClicked(x, y)
    local closestX, closestY = self:getClosestPointOnLine(x, y)
    local distance = self:calculateDistance(closestX, closestY, x, y)
    return distance < 5  -- True if the click is within 5 pixels of the line
end

--- Calculates the closest point on the line segment to a given point
-- @param x number The x coordinate of the point
-- @param y number The y coordinate of the point
-- @return number, number The x and y coordinates of the closest point
function Connection:getClosestPointOnLine(x, y)
    local dx = self.endX - self.startX
    local dy = self.endY - self.startY
    local lengthSquared = dx * dx + dy * dy
    local t = ((x - self.startX) * dx + (y - self.startY) * dy) / lengthSquared
    t = math.max(0, math.min(1, t))
    return self.startX + t * dx, self.startY + t * dy
end

return Connection
