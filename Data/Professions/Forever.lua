-- Get the addon namespace
local _, addonNamespace = ...

-- Initialize the ProfessionData table if it doesn't exist
addonNamespace.ProfessionData = addonNamespace.ProfessionData or {}

-- Populate Forever profession data
addonNamespace.ProfessionData.forever = {
    [171] = { name = "Alchemy" },
    [164] = { name = "Blacksmithing" },
    [185] = { name = "Cooking" },
    [333] = { name = "Enchanting" },
    [202] = { name = "Engineering" },
    [129] = { name = "First Aid" },
    [356] = { name = "Fishing" },
    [182] = { name = "Herbalism" },
    [165] = { name = "Leatherworking" },
    [186] = { name = "Mining" },
    [393] = { name = "Skinning" },
    [197] = { name = "Tailoring" },
}
