-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Herbalism quest data
WowEfficiency.ProfessionQuests.Midnight.Herbalism = {
    Gathering = { 81425, 81426, 81427, 81428, 81429, 81430 },
    Trainer = { 93700, 93702, 93703, 93704 },
    Treatise = { 95130 },
    Uniques = { 89155, 89156, 89157, 89158, 89159, 89160, 89161, 89162, 92174, 93411 },
}
