-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize utility namespace
WowEfficiency.Utils = WowEfficiency.Utils or {}

-- Create local reference for cleaner code
local Table = {}

function Table:Length(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

function Table:ToString(t)
    local result = ""
    for k, v in pairs(t) do
        local valueStr = ""
        if type(v) == "table" then
            valueStr = "table"
        elseif type(v) == "function" then
            valueStr = "function"
        elseif type(v) == "boolean" then
            valueStr = v and "true" or "false"
        elseif v == nil then
            valueStr = "nil"
        else
            valueStr = tostring(v)
        end
        result = result .. k .. ": " .. valueStr .. "\n"
    end
    return result
end

-- Recursively flatten a nested table structure
function Table:Flatten(item, result)
    local result = result or {}  -- create empty table, if none given during initialization
    if type(item) == 'table' then
        for k, v in pairs(item) do
            self:Flatten(v, result)
        end
    else
        table.insert(result, item)
    end
    return result
end

-- Flatten a nested table structure, but only include valid quest IDs (positive numbers)
function Table:FlattenQuestIDs(item, result)
    local result = result or {}  -- create empty table, if none given during initialization
    if type(item) == 'table' then
        for k, v in pairs(item) do
            self:FlattenQuestIDs(v, result)
        end
    elseif type(item) == 'number' and item > 0 then
        -- Only include positive numbers (valid quest IDs)
        table.insert(result, item)
    end
    return result
end

-- Assign to addon namespace (avoids global pollution)
WowEfficiency.Utils.Table = Table
