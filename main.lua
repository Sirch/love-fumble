local Node = require("node")
local Connection = require("connection")

local nodes = {}
local selectedNode
local isDrawingLine = false
local isRetractingLine = false
local lineEnd = {x = 0, y = 0}
local retractStart = {x = 0, y = 0}
local retractEnd = {x = 0, y = 0}
local retractSpeed = 600  -- pixels per second, increased for faster retraction

function love.load()
    -- Set the random seed for reproducibility
    math.randomseed(os.time())

    -- Screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Number of nodes
    local numNodes = 4
    local radius = 20
    local minDistance = 2 * radius * 2  -- Minimum distance is 2 diameters

    -- Initialize nodes
    for i = 1, numNodes do
        local x, y
        local validPosition = false

        while not validPosition do
            -- Generate random position
            x = math.random(radius, screenWidth - radius)
            y = math.random(radius, screenHeight - radius)

            -- Check distance to all existing nodes
            validPosition = true
            for _, node in ipairs(nodes) do
                local dx = x - node.x
                local dy = y - node.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance < minDistance then
                    validPosition = false
                    break
                end
            end
        end

        table.insert(nodes, Node:new(x, y, radius))
    end

    -- Set the first node as selected
    selectedNode = nodes[1]
    selectedNode.selected = true
end

function love.update(dt)
    -- Update the counter for the selected node
    if selectedNode then
        selectedNode:update(dt)
    end

    -- Update all connections
    for _, node in ipairs(nodes) do
        for _, connection in ipairs(node.connections) do
            connection:update(dt)
        end
    end

    -- Animate the retraction of the line
    if isRetractingLine then
        local dx = retractEnd.x - retractStart.x
        local dy = retractEnd.y - retractStart.y
        local distance = math.sqrt(dx * dx + dy * dy)
        local moveDistance = retractSpeed * dt

        if moveDistance >= distance then
            -- Finish retraction
            isRetractingLine = false
        else
            -- Continue retraction
            local angle = math.atan2(dy, dx)
            retractStart.x = retractStart.x + moveDistance * math.cos(angle)
            retractStart.y = retractStart.y + moveDistance * math.sin(angle)
        end
    end
end

function love.draw()
    -- Draw all the nodes and their connections
    for _, node in ipairs(nodes) do
        node:drawConnections()
    end

    for _, node in ipairs(nodes) do
        node:draw()
    end

    -- Draw the line if it is being drawn
    if isDrawingLine then
        local angle = math.atan2(lineEnd.y - selectedNode.y, lineEnd.x - selectedNode.x)
        local startX = selectedNode.x + selectedNode.radius * math.cos(angle)
        local startY = selectedNode.y + selectedNode.radius * math.sin(angle)

        love.graphics.setColor(1, 0, 0)  -- Red color for the line
        love.graphics.setLineWidth(4)  -- Line thickness doubled
        love.graphics.line(startX, startY, lineEnd.x, lineEnd.y)
        love.graphics.setLineWidth(1)  -- Reset line width to default
    end

    -- Draw the retracting line
    if isRetractingLine then
        local angle = math.atan2(retractEnd.y - selectedNode.y, retractEnd.x - selectedNode.x)
        local startX = selectedNode.x + selectedNode.radius * math.cos(angle)
        local startY = selectedNode.y + selectedNode.radius * math.sin(angle)
        
        love.graphics.setColor(1, 0, 0)  -- Red color for the line
        love.graphics.setLineWidth(4)  -- Line thickness doubled
        love.graphics.line(retractStart.x, retractStart.y, startX, startY)
        love.graphics.setLineWidth(1)  -- Reset line width to default
    end

    -- Reset color to white for other drawing
    love.graphics.setColor(1, 1, 1)
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 and selectedNode then -- Left mouse button
        if selectedNode:isInside(x, y) then
            isDrawingLine = true
            lineEnd.x = x
            lineEnd.y = y
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if isDrawingLine then
        lineEnd.x = x
        lineEnd.y = y
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 and isDrawingLine then -- Left mouse button
        isDrawingLine = false
        local joinedNode = nil

        -- Check if the mouse was released inside another node
        for _, node in ipairs(nodes) do
            if node ~= selectedNode and node:isInside(x, y) then
                joinedNode = node
                break
            end
        end

        if joinedNode then
            -- Check if a connection already exists between selectedNode and joinedNode
            local connectionExists = false
            for _, connection in ipairs(selectedNode.connections) do
                if (connection.node1 == selectedNode and connection.node2 == joinedNode) or
                   (connection.node1 == joinedNode and connection.node2 == selectedNode) then
                    connectionExists = true
                    break
                end
            end

            if not connectionExists then
                -- Create a new connection
                local newConnection = Connection:new(selectedNode, joinedNode)
                selectedNode:addConnection(newConnection)
                joinedNode:addConnection(newConnection)
            end
        else
            -- Start retracting the line
            isRetractingLine = true
            retractStart.x = lineEnd.x
            retractStart.y = lineEnd.y
            retractEnd.x = selectedNode.x
            retractEnd.y = selectedNode.y
        end
    end
end
