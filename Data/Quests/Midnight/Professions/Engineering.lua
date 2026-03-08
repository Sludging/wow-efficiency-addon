-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Engineering quest data
WowEfficiency.ProfessionQuests.Midnight.Engineering = {
    Artisan = { 93692 },
    Treasure = { 93534, 93535 },
    Treatise = { 95138 },
    Uniques = { 89133, 89134, 89135, 89136, 89137, 89138, 89139, 89140, 93796 },
}
