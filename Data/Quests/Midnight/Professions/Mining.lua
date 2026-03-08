-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Mining quest data
WowEfficiency.ProfessionQuests.Midnight.Mining = {
    Artisan = { 93705, 93706, 93708, 93709 },
    Treatise = { 95135 },
    -- TODO: Unique treasure quest IDs (8 per profession, need in-game discovery)
}
