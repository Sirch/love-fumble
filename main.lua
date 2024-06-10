local Game = require("game")

local game

function love.load()
    math.randomseed(os.time())
    game = Game:new()
    game:initializeNodes(4, 20)
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.mousepressed(x, y, button)
    game:handleMousePressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    game:handleMouseMoved(x, y)
end

function love.mousereleased(x, y, button)
    game:handleMouseReleased(x, y, button)
end
