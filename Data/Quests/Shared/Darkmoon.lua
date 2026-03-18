-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.Shared = WowEfficiency.ProfessionQuests.Shared or {}

-- Darkmoon Faire profession quests (shared across all expansions)
WowEfficiency.ProfessionQuests.Shared.Darkmoon = {
    Alchemy = { 29506 },
    Blacksmithing = { 29508 },
    Enchanting = { 29510 },
    Engineering = { 29511 },
    Herbalism = { 29514 },
    Inscription = { 29515 },
    Jewelcrafting = { 29516 },
    Leatherworking = { 29517 },
    Mining = { 29518 },
    Skinning = { 29519 },
    Tailoring = { 29520 },
}
