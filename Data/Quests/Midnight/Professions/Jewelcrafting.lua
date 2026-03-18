-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Jewelcrafting quest data
WowEfficiency.ProfessionQuests.Midnight.Jewelcrafting = {
    Artisan = { 93694 },
    Treasure = { 93539, 93538 },
    Treatise = { 95133 },
    Uniques = { 89122, 89123, 89124, 89125, 89126, 89127, 89128, 89129, 93222 },
}
