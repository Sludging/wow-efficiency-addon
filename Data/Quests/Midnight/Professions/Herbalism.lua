-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Herbalism quest data
WowEfficiency.ProfessionQuests.Midnight.Herbalism = {
    Artisan = { 93700, 93702, 93703, 93704 },
    Treatise = { 95130 },
    -- TODO: Unique treasure quest IDs (8 per profession, need in-game discovery)
}
