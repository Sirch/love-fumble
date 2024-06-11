local utils = {}

local function partialTablesEqual(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then
            return false
        end
    end
    return true
end

--- This function checks for a matching partialTablesEqual.
-- @param a tbl The table to chec.
-- @param b obj The object to search.
-- @return true if obj in tbl.
local function containsMatchingObject(tbl, obj)
    for _, item in ipairs(tbl) do
        if partialTablesEqual(obj, item) then
            return true
        end
    end
    return false
end

return utils