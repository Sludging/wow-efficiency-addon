-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Alchemy quest data
WowEfficiency.ProfessionQuests.Alchemy = {
    Artisan = { 84133 },
    Darkmoon = { 29506 },
    Treasure = { 83253, 83255 },
    Treatise = { 83725 },
    Undermine = { 85734 },
    Uniques = { 81146, 81147, 81148, 82633, 83058, 83840, 83841, 83842, 83843, 83844, 83845, 83846, 83847 }
} 
