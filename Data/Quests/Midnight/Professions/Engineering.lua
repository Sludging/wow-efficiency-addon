-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Engineering quest data
WowEfficiency.ProfessionQuests.Midnight.Engineering = {
    Artisan = { 93692 },
    Treasure = { 93534, 93535 },
    Treatise = { 95138 },
    -- TODO: Unique treasure quest IDs (8 per profession, need in-game discovery)
}
