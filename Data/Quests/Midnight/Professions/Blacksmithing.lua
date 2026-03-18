-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Blacksmithing quest data
WowEfficiency.ProfessionQuests.Midnight.Blacksmithing = {
    Artisan = { 93691 },
    Treasure = { 93530, 93531 },
    Treatise = { 95128 },
    Uniques = { 89177, 89178, 89179, 89180, 89181, 89182, 89183, 89184, 93795 },
}
