-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Herbalism quest data
WowEfficiency.ProfessionQuests.Herbalism = {
    Darkmoon = { 29514 },
    Gathering = { 81416, 81417, 81418, 81419, 81420, 81421 },
    Trainer = { 82916, 82958, 82962, 82965, 82970 },
    Treatise = { 83729 },
    Undermine = { 85738 },
    Uniques = { 81422, 81423, 81424, 82630, 83066, 83874, 83875, 83876, 83877, 83878, 83879, 83880, 83881 }
} 
