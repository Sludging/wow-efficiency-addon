-- Inspect WowEfficiency SavedVariables
-- Usage: lua Scripts/inspect-saved-vars.lua [path-to-SavedVariables]

local path = arg[1] or "/mnt/d/Program Files/World of Warcraft/_retail_/WTF/Account/113729#1/SavedVariables/WowEfficiency.lua"

-- Load the SavedVariables file - it defines WowEfficiencyDB as a global
dofile(path)

if not WowEfficiencyDB or not WowEfficiencyDB.char then
    print("ERROR: No character data found in " .. path)
    os.exit(1)
end

-- Collect characters with their most recent timestamp
local characters = {}
for name, data in pairs(WowEfficiencyDB.char) do
    local latest = 0
    local latestKey = ""
    if data.lastUpdated then
        for key, ts in pairs(data.lastUpdated) do
            if type(ts) == "number" and ts > latest then
                latest = ts
                latestKey = key
            end
        end
    end
    table.insert(characters, { name = name, data = data, latest = latest, latestKey = latestKey })
end

-- Sort by most recent first
table.sort(characters, function(a, b) return a.latest > b.latest end)

-- Helper: format a unix timestamp as a readable date
local function fmtTime(ts)
    if ts == 0 then return "never" end
    return os.date("%Y-%m-%d %H:%M:%S", ts)
end

-- Show top N most recently updated characters
local count = tonumber(arg[2]) or 5
print(string.format("=== %d Most Recently Updated Characters ===\n", count))

for i = 1, math.min(count, #characters) do
    local c = characters[i]
    print(string.format("--- %s ---", c.name))
    print(string.format("  Last updated: %s (%s)", fmtTime(c.latest), c.latestKey))

    -- Show lastUpdated breakdown
    if c.data.lastUpdated then
        print("  Timestamps:")
        for key, ts in pairs(c.data.lastUpdated) do
            if type(ts) == "number" then
                print(string.format("    %-30s %s", key, fmtTime(ts)))
            elseif type(ts) == "string" then
                print(string.format("    %-30s %s", key, ts))
            end
        end
    end

    -- Show professions summary
    if c.data.professions then
        print("  Professions:")
        for skillId, prof in pairs(c.data.professions) do
            if type(prof) == "table" then
                local name = prof.name or ("skillLine " .. tostring(skillId))
                print(string.format("    [%d] %s - Level %s/%s, Knowledge %s/%s",
                    skillId,
                    name,
                    tostring(prof.level or "?"), tostring(prof.maxLevel or "?"),
                    tostring(prof.knowledgeLevel or "?"), tostring(prof.knowledgeMaxLevel or "?")))
            end
        end
    end

    -- Show completed quests count
    if c.data.completedQuests then
        local qcount = 0
        for _ in pairs(c.data.completedQuests) do qcount = qcount + 1 end
        print(string.format("  Completed quests tracked: %d", qcount))
    end

    -- Show weekly reset
    if c.data.nextWeeklyReset then
        print(string.format("  Next weekly reset: %s", fmtTime(c.data.nextWeeklyReset)))
    end

    print()
end
