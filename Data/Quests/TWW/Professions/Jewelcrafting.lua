-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}
WowEfficiency.ProfessionQuests.TWW = WowEfficiency.ProfessionQuests.TWW or {}

-- Populate Jewelcrafting quest data
WowEfficiency.ProfessionQuests.TWW.Jewelcrafting = {
    Artisan = { 84130 },
    Treasure = { 83265, 83266 },
    Treatise = { 83731 },
    Undermine = { 85740 },
    Uniques = { 81259, 81260, 81261, 82637, 83065, 83890, 83891, 83892, 83893, 83894, 83895, 83896, 83897 }
}
