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
    Uniques = { 89078, 89079, 89080, 89081, 89082, 89083, 89084, 89085, 93201 },
}
