-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Tailoring quest data
WowEfficiency.ProfessionQuests.Tailoring = {
    Artisan = { 84132 },
    Darkmoon = { 29520 },
    Treasure = { 83269, 83270 },
    Treatise = { 83735 },
    Undermine = { 85745 },
    Uniques = { 80871, 80872, 80873, 82634, 83061, 83922, 83923, 83924, 83925, 83926, 83927, 83928, 83929 }
} 
