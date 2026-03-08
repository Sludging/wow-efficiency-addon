-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Enchanting quest data
WowEfficiency.ProfessionQuests.Midnight.Enchanting = {
    Artisan = { 93698, 93699 },
    Treasure = { 93532, 93533 },
    Treatise = { 95129 },
    -- TODO: Unique treasure quest IDs (8 per profession, need in-game discovery)
}
