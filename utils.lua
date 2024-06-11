-- utils.lua

local Utils = {}

function Utils.lineIntersectsCircle(x1, y1, x2, y2, cx, cy, cr)
    local dx = x2 - x1
    local dy = y2 - y1

    local fx = x1 - cx
    local fy = y1 - cy

    local a = dx * dx + dy * dy
    local b = 2 * (fx * dx + fy * dy)
    local c = (fx * fx + fy * fy) - (cr * cr)

    local discriminant = b * b - 4 * a * c

    if discriminant >= 0 then
        discriminant = math.sqrt(discriminant)

        local t1 = (-b - discriminant) / (2 * a)
        local t2 = (-b + discriminant) / (2 * a)

        if (t1 >= 0 and t1 <= 1) or (t2 >= 0 and t2 <= 1) then
            return true
        end
    end

    return false
end

function Utils.doesLineIntersectAnyNode(game, sourceNode, destinationNode)
    for _, node in ipairs(game.nodes) do
        if node ~= sourceNode and node ~= destinationNode and
           Utils.lineIntersectsCircle(sourceNode.x, sourceNode.y, destinationNode.x, destinationNode.y, node.x, node.y, node.radius) then
            return true
        end
    end
    return false
end

return Utils
