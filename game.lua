local Node = require("node")
local Connection = require("connection")
local Utils = require("utils")

Game = {}
Game.__index = Game

function Game:new()
    local game = setmetatable({}, Game)
    game.nodes = {}
    game.selectedNode = nil
    game.isDrawingLine = false
    game.lineEnd = {x = 0, y = 0}
    game.retractingLine = nil
    return game
end

function Game:initializeNodes(numNodes, radius)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local minDistance = 2 * radius * 2

    -- Initialize "your" circle
    local x, y = self:getRandomPosition(radius, screenWidth, screenHeight, minDistance)
    local myNode = Node:new(x, y, radius, "player")
    table.insert(self.nodes, myNode)

    -- Initialize neutral circles
    for i = 2, numNodes do
        local x, y = self:getRandomPosition(radius, screenWidth, screenHeight, minDistance)
        local node = Node:new(x, y, radius, "neutral")
        table.insert(self.nodes, node)
    end

    self.selectedNode = myNode
end

function Game:getRandomPosition(radius, screenWidth, screenHeight, minDistance)
    while true do
        local x = math.random(radius, screenWidth - radius)
        local y = math.random(radius, screenHeight - radius)
        if self:isValidPosition(x, y, radius, minDistance) then
            return x, y
        end
    end
end

function Game:isValidPosition(x, y, radius, minDistance)
    for _, node in ipairs(self.nodes) do
        local dx = x - node.x
        local dy = y - node.y
        if math.sqrt(dx * dx + dy * dy) < minDistance then
            return false
        end
    end
    return true
end

-- Update methods
function Game:update(dt)
    self:updateNodes(dt)
    self:updateConnections(dt)
    self:updateLineRetraction(dt)
end

function Game:updateNodes(dt)
    for _, node in ipairs(self.nodes) do
        node:update(dt)
    end
end

function Game:updateConnections(dt)
    for _, node in ipairs(self.nodes) do
        for _, connection in ipairs(node.connections) do
            if node.owner == "player" then
                connection:update(dt)
            end
        end
    end
end

function Game:updateLineRetraction(dt)
    if self.retractingLine then
        local dx = self.retractingLine.endX - self.retractingLine.startX
        local dy = self.retractingLine.endY - self.retractingLine.startY
        local distance = math.sqrt(dx * dx + dy * dy)
        local moveDistance = self.retractingLine.speed * dt

        if moveDistance >= distance then
            self.retractingLine = nil
        else
            local angle = math.atan2(dy, dx)
            self.retractingLine.startX = self.retractingLine.startX + moveDistance * math.cos(angle)
            self.retractingLine.startY = self.retractingLine.startY + moveDistance * math.sin(angle)
        end
    end
end

-- Drawing methods
function Game:draw()
    self:drawConnections()
    self:drawNodes()
    self:drawDrawingLine()
    self:drawRetractingLine()
end

function Game:drawConnections()
    for _, node in ipairs(self.nodes) do
        node:drawConnections()
    end
end

function Game:drawNodes()
    for _, node in ipairs(self.nodes) do
        node:draw()
    end
end

--- Returns a point on the circumference of a node
-- @param x number The x coordinate of the node
-- @param y number The y coordinate of the node
-- @param radius number The radius of the node
-- @param angle number The angle in radians
-- @return number, number The x and y coordinates on the circumference
function Game:getPointOnCircle(x, y, radius, angle)
    return x + radius * math.cos(angle), y + radius * math.sin(angle)
end

function Game:drawDrawingLine()
    if self.isDrawingLine and self.selectedNode then
        local angle = math.atan2(self.lineEnd.y - self.selectedNode.y, self.lineEnd.x - self.selectedNode.x)
        local startX, startY = self:getPointOnCircle(self.selectedNode.x, self.selectedNode.y, self.selectedNode.radius, angle)

        -- Initialize the end coordinates as the mouse position
        local endX, endY = self.lineEnd.x, self.lineEnd.y

        -- Calculate the distance between the start and end points
        local dx = endX - startX
        local dy = endY - startY
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Only draw the line if its length is greater than the radius of the starting node
        if distance >= self.selectedNode.radius then
            -- Adjust the end coordinates to handle intersections with nodes and connections
            endX, endY = self:adjustLineForNodeIntersections(startX, startY, endX, endY)
            endX, endY = self:adjustLineForConnectionIntersections(startX, startY, endX, endY)

            -- Draw the line up to the intersection point
            love.graphics.setColor(1, 0, 0)
            love.graphics.setLineWidth(4)
            love.graphics.line(startX, startY, endX, endY)
            love.graphics.setLineWidth(1)
        end
    end
end

function Game:drawRetractingLine()
    if self.retractingLine then
        local angle = math.atan2(self.retractingLine.endY - self.retractingLine.startY, self.retractingLine.endX - self.retractingLine.startX)
        local endX, endY = self:getPointOnCircle(self.retractingLine.endX, self.retractingLine.endY, self.selectedNode.radius, angle + math.pi)
        love.graphics.setColor(1, 0, 0)
        love.graphics.setLineWidth(4)
        love.graphics.line(self.retractingLine.startX, self.retractingLine.startY, endX, endY)
        love.graphics.setLineWidth(1)
    end
end

-- Mouse handling methods
function Game:handleMousePressed(x, y, button)
    if button == 1 then  -- Left mouse button
        self:handleLeftClick(x, y)
    elseif button == 2 then  -- Right mouse button
        self:handleRightClick(x, y)
    end
end

function Game:handleLeftClick(x, y)
    for _, node in ipairs(self.nodes) do
        if node:isInside(x, y) then
            if node.owner == "player" then
                self.selectedNode = node
                break
            else
                return
            end
        end
    end

    if self.selectedNode then
        local angle = math.atan2(y - self.selectedNode.y, x - self.selectedNode.x)
        local startX, startY = self:getPointOnCircle(self.selectedNode.x, self.selectedNode.y, self.selectedNode.radius, angle)
        self.isDrawingLine = true
        self.lineEnd.x = x
        self.lineEnd.y = y
    end
end

function Game:handleRightClick(x, y)
    for _, node in ipairs(self.nodes) do
        for i = #node.connections, 1, -1 do
            local connection = node.connections[i]
            if connection:isClicked(x, y) then
                table.remove(node.connections, i)
                break
            end
        end
    end
end

function Game:handleMouseMoved(x, y)
    if self.isDrawingLine then
        self.lineEnd.x = x
        self.lineEnd.y = y
    end
end

function Game:handleMouseReleased(x, y, button)
    if button == 1 then  -- Left mouse button
        if self.isDrawingLine then
            self:handleLineRelease(x, y)
        end
    end
end


--- Checks if a line between two nodes intersects any existing connections
-- @param sourceNode table The source node
-- @param destinationNode table The destination node
-- @return boolean True if the line intersects any existing connections, false otherwise
function Game:doesLineIntersectAnyConnection(sourceNode, destinationNode)
    for _, node in ipairs(self.nodes) do
        for _, connection in ipairs(node.connections) do
            if Utils.doLineSegmentsIntersect(
                sourceNode.x, sourceNode.y, destinationNode.x, destinationNode.y,
                connection.startX, connection.startY, connection.endX, connection.endY
            ) then
                return true
            end
        end
    end
    return false
end

--- Checks if a connection can be made between two nodes
-- @param sourceNode table The source node
-- @param destinationNode table The destination node
-- @return boolean True if the connection can be made, false otherwise
function Game:canConnect(sourceNode, destinationNode)
    if sourceNode == destinationNode then
        return false
    elseif self:connectionExists(sourceNode, destinationNode) then
        return false
    elseif Utils.doesLineIntersectAnyNode(self, sourceNode, destinationNode) then
        return false
    elseif self:doesLineIntersectAnyConnection(sourceNode, destinationNode) then
        return false
    else
        return true
    end
end

function Game:handleLineRelease(x, y)
    self.isDrawingLine = false
    local joinedNode = self:getNodeAt(x, y)
    if joinedNode and self:canConnect(self.selectedNode, joinedNode) then
        self.selectedNode:addConnection(Connection:new(self.selectedNode, joinedNode))
    else
        self:startLineRetraction(x, y)
    end
end

function Game:getNodeAt(x, y)
    for _, node in ipairs(self.nodes) do
        if node:isInside(x, y) then
            return node
        end
    end
    return nil
end

--- Check if a connection exists between two nodes.
-- @param node1 table The first node.
-- @param node2 table The second node.
-- @return boolean True if the connection exists, false otherwise.
function Game:connectionExists(node1, node2)
    -- Helper function to check connections
    local function hasConnection(node, target)
        for _, connection in ipairs(node.connections) do
            if (connection.node1 == node and connection.node2 == target) or
               (connection.node1 == target and connection.node2 == node) then
                return true
            end
        end
        return false
    end

    -- Check connections in both nodes
    return hasConnection(node1, node2) or hasConnection(node2, node1)
end

function Game:startLineRetraction(x, y)
    self.retractingLine = {
        startX = x,
        startY = y,
        endX = self.selectedNode.x,
        endY = self.selectedNode.y,
        speed = 600
    }
end

--- Calculates the closest point of intersection between a line segment and a circle
-- @param x1 number The x coordinate of the first point of the line segment
-- @param y1 number The y coordinate of the first point of the line segment
-- @param x2 number The x coordinate of the second point of the line segment
-- @param y2 number The y coordinate of the second point of the line segment
-- @param cx number The x coordinate of the circle center
-- @param cy number The y coordinate of the circle center
-- @param radius number The radius of the circle
-- @return number, number The x and y coordinates of the closest intersection point
function Game:getClosestPointOnCircleIntersection(x1, y1, x2, y2, cx, cy, radius)
    local dx, dy = x2 - x1, y2 - y1
    local fx, fy = x1 - cx, y1 - cy
    local a = dx * dx + dy * dy
    local b = 2 * (fx * dx + fy * dy)
    local c = fx * fx + fy * fy - radius * radius
    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return x2, y2
    end
    local t = (-b - math.sqrt(discriminant)) / (2 * a)
    return x1 + t * dx, y1 + t * dy
end

--- Calculates the closest point of intersection between two line segments
-- @param x1 number The x coordinate of the first point of the first line segment
-- @param y1 number The y coordinate of the first point of the first line segment
-- @param x2 number The x coordinate of the second point of the first line segment
-- @param y2 number The y coordinate of the second point of the first line segment
-- @param x3 number The x coordinate of the first point of the second line segment
-- @param y3 number The y coordinate of the first point of the second line segment
-- @param x4 number The x coordinate of the second point of the second line segment
-- @param y4 number The y coordinate of the second point of the second line segment
-- @return number, number The x and y coordinates of the intersection point
function Game:getClosestPointOnLineIntersection(x1, y1, x2, y2, x3, y3, x4, y4)
    local denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    if denom == 0 then
        return x2, y2 -- Lines are parallel or coincident
    end
    local ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
    return x1 + ua * (x2 - x1), y1 + ua * (y2 - y1)
end

--- Checks and adjusts the line end coordinates for intersections with nodes
-- @param startX number The x coordinate of the start point
-- @param startY number The y coordinate of the start point
-- @param endX number The x coordinate of the end point
-- @param endY number The y coordinate of the end point
-- @return number, number The adjusted end coordinates
function Game:adjustLineForNodeIntersections(startX, startY, endX, endY)
    for _, node in ipairs(self.nodes) do
        if node ~= self.selectedNode then
            if Utils.lineIntersectsCircle(startX, startY, endX, endY, node.x, node.y, node.radius) then
                return self:getClosestPointOnCircleIntersection(startX, startY, endX, endY, node.x, node.y, node.radius)
            end
        end
    end
    return endX, endY
end

--- Checks and adjusts the line end coordinates for intersections with existing connections
-- @param startX number The x coordinate of the start point
-- @param startY number The y coordinate of the start point
-- @param endX number The x coordinate of the end point
-- @param endY number The y coordinate of the end point
-- @return number, number The adjusted end coordinates
function Game:adjustLineForConnectionIntersections(startX, startY, endX, endY)
    for _, node in ipairs(self.nodes) do
        for _, connection in ipairs(node.connections) do
            if connection.node1 ~= self.selectedNode and connection.node2 ~= self.selectedNode then
                if Utils.doLineSegmentsIntersect(startX, startY, endX, endY, connection.startX, connection.startY, connection.endX, connection.endY) then
                    return self:getClosestPointOnLineIntersection(startX, startY, endX, endY, connection.startX, connection.startY, connection.endX, connection.endY)
                end
            end
        end
    end
    return endX, endY
end


--- Draws the line from the selected node to the current mouse position, considering intersections
-- @param startX number The x coordinate of the start point
-- @param startY number The y coordinate of the start point
-- @param endX number The x coordinate of the end point
-- @param endY number The y coordinate of the end point
function Game:drawLineWithIntersections(startX, startY, endX, endY)
    endX, endY = self:adjustLineForNodeIntersections(startX, startY, endX, endY)
    endX, endY = self:adjustLineForConnectionIntersections(startX, startY, endX, endY)
    
    love.graphics.setColor(1, 0, 0)
    love.graphics.setLineWidth(4)
    love.graphics.line(startX, startY, endX, endY)
    love.graphics.setLineWidth(1)
end

return Game