-- Profession quest data loader
-- This file loads all profession quest data files and returns them as a structured table

local professions = {
    "Alchemy",
    "Blacksmithing", 
    "Enchanting",
    "Engineering",
    "Herbalism",
    "Inscription",
    "Jewelcrafting",
    "Leatherworking",
    "Mining",
    "Skinning",
    "Tailoring"
}

local professionQuests = {}

-- Load each profession's quest data
for _, profession in ipairs(professions) do
    local success, questData = pcall(function()
        return dofile("Data/Quests/Professions/" .. profession .. ".lua")
    end)
    
    if success and questData then
        professionQuests[profession] = questData
    else
        print("Warning: Failed to load quest data for profession: " .. profession)
    end
end

return professionQuests 
