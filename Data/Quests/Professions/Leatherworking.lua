-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Leatherworking quest data
WowEfficiency.ProfessionQuests.Leatherworking = {
    Artisan = { 84131 },
    Darkmoon = { 29517 },
    Treasure = { 83267, 83268 },
    Treatise = { 83732 },
    Undermine = { 85741 },
    Uniques = { 80978, 80979, 80980, 82626, 83068, 83898, 83899, 83900, 83901, 83902, 83903, 83904, 83905 }
} 
