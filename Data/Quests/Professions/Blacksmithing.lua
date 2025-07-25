-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Blacksmithing quest data
WowEfficiency.ProfessionQuests.Blacksmithing = {
    Artisan = { 84127 },
    Darkmoon = { 29508 },
    Treasure = { 83256, 83257 },
    Treatise = { 83726 },
    Undermine = { 85735 },
    Uniques = { 82631, 83059, 83848, 83849, 83850, 83851, 83852, 83853, 83854, 83855, 84226, 84227, 84228 }
} 
