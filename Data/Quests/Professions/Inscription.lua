-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Inscription quest data
WowEfficiency.ProfessionQuests.Inscription = {
    Artisan = { 84129 },
    Darkmoon = { 29515 },
    Treasure = { 83262, 83264 },
    Treatise = { 83730 },
    Undermine = { 85739 },
    Uniques = { 80749, 80750, 80751, 82636, 83064, 83882, 83883, 83884, 83885, 83886, 83887, 83888, 83889 }
} 
