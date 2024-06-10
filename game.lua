local Node = require("node")
local Connection = require("connection")

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
            connection:update(dt)
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

function Game:getPointOnCircle(x, y, radius, angle)
    return x + radius * math.cos(angle), y + radius * math.sin(angle)
end

function Game:drawDrawingLine()
    if self.isDrawingLine and self.selectedNode then
        local angle = math.atan2(self.lineEnd.y - self.selectedNode.y, self.lineEnd.x - self.selectedNode.x)
        local startX, startY = self:getPointOnCircle(self.selectedNode.x, self.selectedNode.y, self.selectedNode.radius, angle)
        love.graphics.setColor(1, 0, 0)
        love.graphics.setLineWidth(4)
        love.graphics.line(startX, startY, self.lineEnd.x, self.lineEnd.y)
        love.graphics.setLineWidth(1)
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
    if self.selectedNode and self.selectedNode:isInside(x, y) then
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

function Game:handleLineRelease(x, y)
    self.isDrawingLine = false
    local joinedNode = self:getNodeAt(x, y)

    if joinedNode and joinedNode ~= self.selectedNode then
        if not self:connectionExists(self.selectedNode, joinedNode) then
            local newConnection = Connection:new(self.selectedNode, joinedNode)
            self.selectedNode:addConnection(newConnection)
            joinedNode:addConnection(newConnection)
        end
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

function Game:connectionExists(node1, node2)
    for _, connection in ipairs(node1.connections) do
        if (connection.node1 == node1 and connection.node2 == node2) or
           (connection.node1 == node2 and connection.node2 == node1) then
            return true
        end
    end
    return false
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

return Game
