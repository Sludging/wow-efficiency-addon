-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Inscription quest data
WowEfficiency.ProfessionQuests.Midnight.Inscription = {
    Artisan = { 93693 },
    Treasure = { 93536, 93537 },
    Treatise = { 95131 },
    -- TODO: Unique treasure quest IDs (8 per profession, need in-game discovery)
}
