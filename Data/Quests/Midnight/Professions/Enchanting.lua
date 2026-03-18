-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Midnight = WowEfficiency.ProfessionQuests.Midnight or {}

-- Populate Enchanting quest data
WowEfficiency.ProfessionQuests.Midnight.Enchanting = {
    Gathering = { 95048, 95049, 95050, 95051, 95052, 95053 },
    Trainer = { 93698, 93699 },
    Treasure = { 93532, 93533 },
    Treatise = { 95129 },
    Uniques = { 89100, 89101, 89102, 89103, 89104, 89105, 89106, 89107, 92186, 92374 },
}
