-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Tailoring quest data
WowEfficiency.ProfessionQuests.Midnight.Tailoring = {
    Artisan = { 93696 },
    Treasure = { 93542, 93543 },
    Treatise = { 95137 },
    -- TODO: Unique treasure quest IDs (8 per profession, need in-game discovery)
}
