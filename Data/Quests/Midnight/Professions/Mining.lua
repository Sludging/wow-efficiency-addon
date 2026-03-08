-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Mining quest data
WowEfficiency.ProfessionQuests.Midnight.Mining = {
    Artisan = { 93705, 93706, 93708, 93709 },
    Treatise = { 95135 },
    Uniques = { 89144, 89145, 89146, 89147, 89148, 89149, 89150, 89151, 92187, 92372 },
}
