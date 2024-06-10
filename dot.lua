Dot = {}
Dot.__index = Dot

function Dot:new(connection, position, owner)
    local dot = setmetatable({}, Dot)
    dot.connection = connection
    dot.position = position or 0
    dot.moveSpeed = 50  -- Speed of the moving point in pixels per second
    dot.owner = owner
    dot.value = 1  -- All dots have a value of 1
    dot.arrived = false  -- To track if the dot has arrived
    return dot
end

function Dot:update(dt)
    if not self.arrived then
        self.position = self.position + self.moveSpeed * dt / self.connection.length
        if self.position >= 1 then
            self.position = 1
            self:handleArrival()
        end
    end
end

function Dot:handleArrival()
    if self.arrived then
        return  -- Ensure the dot only arrives once
    end

    self.arrived = true  -- Mark the dot as arrived
    local node2 = self.connection.node2
    node2:dotArrive(self.owner, self.value)
    self.connection:removeDot(self)
end

function Dot:draw()
    local startX, startY = self.connection.startX, self.connection.startY
    local endX, endY = self.connection.endX, self.connection.endY
    local dotX = startX + self.position * (endX - startX)
    local dotY = startY + self.position * (endY - startY)
    love.graphics.setColor(1, 1, 1)  -- White color for dots
    love.graphics.circle("fill", dotX, dotY, 5)

    -- Draw the value above the dot
    local font = love.graphics.getFont()
    local text = tostring(self.value)
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, dotX - textWidth / 2, dotY - textHeight - 5)
end

return Dot
