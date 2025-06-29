-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Engineering quest data
WowEfficiency.ProfessionQuests.Engineering = {
    Artisan = { 84128 },
    Darkmoon = { 29511 },
    Treasure = { 83260, 83261 },
    Treatise = { 83728 },
    Undermine = { 85737 },
    Uniques = { 82632, 83063, 83866, 83867, 83868, 83869, 83870, 83871, 83872, 83873, 84229, 84230, 84231 }
} 
