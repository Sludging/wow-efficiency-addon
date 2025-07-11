-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Enchanting quest data
WowEfficiency.ProfessionQuests.Enchanting = {
    Darkmoon = { 29510 },
    Gathering = { 84290, 84291, 84292, 84293, 84294, 84295 },
    Trainer = { 84084, 84085, 84086 },
    Treasure = { 83258, 83259 },
    Treatise = { 83727 },
    Undermine = { 85736 },
    Uniques = { 81076, 81077, 81078, 82635, 83060, 83856, 83859, 83860, 83861, 83862, 83863, 83864, 83865 }
} 
