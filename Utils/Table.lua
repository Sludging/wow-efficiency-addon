Table = {}

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