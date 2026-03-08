-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Leatherworking quest data
WowEfficiency.ProfessionQuests.Midnight.Leatherworking = {
    Artisan = { 93695 },
    Treasure = { 93540, 93541 },
    Treatise = { 95134 },
    -- TODO: Unique treasure quest IDs (8 per profession, need in-game discovery)
}
