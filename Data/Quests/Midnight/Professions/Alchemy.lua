-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Alchemy quest data
WowEfficiency.ProfessionQuests.Midnight.Alchemy = {
    Artisan = { 93690 },
    Treasure = { 93528, 93529 },
    Treatise = { 95127 },
    Uniques = { 89111, 89112, 89113, 89114, 89115, 89116, 89117, 89118, 93794 },
}
