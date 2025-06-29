-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Mining quest data
WowEfficiency.ProfessionQuests.Mining = {
    Darkmoon = { 29518 },
    Gathering = { 83049, 83050, 83051, 83052, 83053, 83054 },
    Trainer = { 83102, 83103, 83104, 83105, 83106 },
    Treatise = { 83733 },
    Undermine = { 85742 },
    Uniques = { 81390, 81391, 81392, 82614, 83062, 83906, 83907, 83908, 83909, 83910, 83911, 83912, 83913 }
} 
