-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Skinning quest data
WowEfficiency.ProfessionQuests.Skinning = {
    Darkmoon = { 29519 },
    Gathering = { 81459, 81460, 81461, 81462, 81463, 81464 },
    Trainer = { 82992, 82993, 83097, 83098, 83100 },
    Treatise = { 83734 },
    Undermine = { 85744 },
    Uniques = { 82596, 83067, 83914, 83915, 83916, 83917, 83918, 83919, 83920, 83921, 84232, 84233, 84234 }
} 
