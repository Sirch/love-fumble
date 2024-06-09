local Node = require("node")
local Connection = require("connection")

local nodes = {}
local selectedNode
local isDrawingLine = false
local isRetractingLine = false
local lineEnd = {x = 0, y = 0}
local retractStart = {x = 0, y = 0}
local retractEnd = {x = 0, y = 0}
local retractSpeed = 600  -- Pixels per second, increased for faster retraction

-- Function declarations
local initializeNodes
local getRandomPosition
local isValidPosition
local selectFirstNode
local updateSelectedNode
local updateConnections
local updateLineRetraction
local drawConnections
local drawNodes
local drawDrawingLine
local drawRetractingLine
local handleLeftClick
local handleRightClick
local handleLineRelease
local getNodeAt
local connectionExists
local startLineRetraction

function love.load()
    math.randomseed(os.time())
    initializeNodes(4, 20)
    selectFirstNode()
end

initializeNodes = function(numNodes, radius)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local minDistance = 2 * radius * 2

    for i = 1, numNodes do
        local x, y = getRandomPosition(radius, screenWidth, screenHeight, minDistance)
        table.insert(nodes, Node:new(x, y, radius))
    end
end

getRandomPosition = function(radius, screenWidth, screenHeight, minDistance)
    while true do
        local x = math.random(radius, screenWidth - radius)
        local y = math.random(radius, screenHeight - radius)
        if isValidPosition(x, y, radius, minDistance) then
            return x, y
        end
    end
end

isValidPosition = function(x, y, radius, minDistance)
    for _, node in ipairs(nodes) do
        local dx = x - node.x
        local dy = y - node.y
        if math.sqrt(dx * dx + dy * dy) < minDistance then
            return false
        end
    end
    return true
end

selectFirstNode = function()
    selectedNode = nodes[1]
    selectedNode.selected = true
end

function love.update(dt)
    updateSelectedNode(dt)
    updateConnections(dt)
    updateLineRetraction(dt)
end

updateSelectedNode = function(dt)
    if selectedNode then
        selectedNode:update(dt)
    end
end

updateConnections = function(dt)
    for _, node in ipairs(nodes) do
        for _, connection in ipairs(node.connections) do
            connection:update(dt)
        end
    end
end

updateLineRetraction = function(dt)
    if isRetractingLine then
        local dx = retractEnd.x - retractStart.x
        local dy = retractEnd.y - retractStart.y
        local distance = math.sqrt(dx * dx + dy * dy)
        local moveDistance = retractSpeed * dt

        if moveDistance >= distance then
            isRetractingLine = false
        else
            local angle = math.atan2(dy, dx)
            retractStart.x = retractStart.x + moveDistance * math.cos(angle)
            retractStart.y = retractStart.y + moveDistance * math.sin(angle)
        end
    end
end

function love.draw()
    drawConnections()
    drawNodes()
    drawDrawingLine()
    drawRetractingLine()
end

drawConnections = function()
    for _, node in ipairs(nodes) do
        node:drawConnections()
    end
end

drawNodes = function()
    for _, node in ipairs(nodes) do
        node:draw()
    end
end

drawDrawingLine = function()
    if isDrawingLine then
        local angle = math.atan2(lineEnd.y - selectedNode.y, lineEnd.x - selectedNode.x)
        local startX = selectedNode.x + selectedNode.radius * math.cos(angle)
        local startY = selectedNode.y + selectedNode.radius * math.sin(angle)
        love.graphics.setColor(1, 0, 0)
        love.graphics.setLineWidth(4)
        love.graphics.line(startX, startY, lineEnd.x, lineEnd.y)
        love.graphics.setLineWidth(1)
    end
end

drawRetractingLine = function()
    if isRetractingLine then
        local angle = math.atan2(retractEnd.y - selectedNode.y, retractEnd.x - selectedNode.x)
        local startX = selectedNode.x + selectedNode.radius * math.cos(angle)
        local startY = selectedNode.y + selectedNode.radius * math.sin(angle)
        love.graphics.setColor(1, 0, 0)
        love.graphics.setLineWidth(4)
        love.graphics.line(retractStart.x, retractStart.y, startX, startY)
        love.graphics.setLineWidth(1)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        handleLeftClick(x, y)
    elseif button == 2 then  -- Right mouse button
        handleRightClick(x, y)
    end
end

handleLeftClick = function(x, y)
    if selectedNode and selectedNode:isInside(x, y) then
        isDrawingLine = true
        lineEnd.x = x
        lineEnd.y = y
    end
end

handleRightClick = function(x, y)
    for _, node in ipairs(nodes) do
        for i = #node.connections, 1, -1 do
            local connection = node.connections[i]
            if connection:isClicked(x, y) then
                table.remove(node.connections, i)
                break
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if isDrawingLine then
        lineEnd.x = x
        lineEnd.y = y
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then  -- Left mouse button
        if isDrawingLine then
            handleLineRelease(x, y)
        end
    end
end

handleLineRelease = function(x, y)
    isDrawingLine = false
    local joinedNode = getNodeAt(x, y)

    if joinedNode and joinedNode ~= selectedNode then
        if not connectionExists(selectedNode, joinedNode) then
            local newConnection = Connection:new(selectedNode, joinedNode)
            selectedNode:addConnection(newConnection)
            joinedNode:addConnection(newConnection)
        end
    else
        startLineRetraction(x, y)
    end
end

getNodeAt = function(x, y)
    for _, node in ipairs(nodes) do
        if node:isInside(x, y) then
            return node
        end
    end
    return nil
end

connectionExists = function(node1, node2)
    for _, connection in ipairs(node1.connections) do
        if (connection.node1 == node1 and connection.node2 == node2) or
           (connection.node1 == node2 and connection.node2 == node1) then
            return true
        end
    end
    return false
end

startLineRetraction = function(x, y)
    isRetractingLine = true
    retractStart.x = x
    retractStart.y = y
    retractEnd.x = selectedNode.x
    retractEnd.y = selectedNode.y
end
