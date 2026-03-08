-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Skinning quest data
WowEfficiency.ProfessionQuests.Midnight.Skinning = {
    Artisan = { 93710, 93711, 93712, 93714 },
    Treatise = { 95136 },
    Uniques = { 89166, 89167, 89168, 89169, 89170, 89171, 89172, 89173, 92188, 92373 },
}
