-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Fetch shared functionality
---@type WoWEfficiency_Debug
local Debug = WoWEfficiency:GetModule('Debug')
---@type WoWEfficiency_DB
local db = WoWEfficiency:GetModule('DB')

-- Upvalue global functions
local CQL_IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted

-- Define the module
---@class WoWEfficiency_Quests: AceModule, AceEvent-3.0, AceBucket-3.0
---@field UpdateAllTrackedQuests fun(self: WoWEfficiency_Quests)
---@field TrackedQuestIDs table @List of quest IDs to track
local Module = WoWEfficiency:NewModule('Quests', "AceBucket-3.0")

function Module:OnInitialize()
    Debug:DebugPrint("Quest Module" .. " Initialized.")
end

function Module:OnEnable()
    Debug:DebugPrint("Quest Module" .. " Enabled.")

    -- Register events
    self:RegisterBucketEvent(
        ---@diagnostic disable-next-line: param-type-mismatch 
        {
            "PLAYER_ENTERING_WORLD",
            --'QUEST_LOG_UPDATE', -- spammy quest log updates
            'QUEST_COMPLETE',
            'QUEST_FINISHED',
            'QUEST_TURNED_IN',
            'ITEM_PUSH',        -- tracking quests
            'LOOT_CLOSED',      -- tracking quests
            'SHOW_LOOT_TOAST',  -- tracking quests
        },
        3,
        "UpdateAllTrackedQuests"
    )

end

-- Checks all quests in the trackedQuestIDs list and updates the database
function Module:UpdateAllTrackedQuests()
    local playerLevel = UnitLevel("player")
    if playerLevel < 70 then
        return
    end
    -- TODO: Don't track characters that don't have the required professions?

    Debug:DebugPrint("Updating all tracked quests.")
    -- Ensure Constants and the quest list exist before proceeding
    if not self.Constants or not self.Constants.TrackedQuestIDs then
        Debug:DebugPrint("!!! ERROR: UpdateAllTrackedQuests cannot run because Constants are not loaded.")
        return -- Exit the function early
    end
    -- Ensure DB character profile is loaded
    if not db:IsCharDBReady() then
        -- This might happen if the check runs too early.
        Debug:DebugPrint("!!! WARNING: UpdateAllTrackedQuests cannot run because self.db.char is not ready.")
        return -- Exit the function early
    end

    local completedQuestsDB = db:GetCharDBKey("completedQuests")

    -- Access the quest list from self.Constants
    for _, questID in ipairs(self.Constants.TrackedQuestIDs) do
        -- Ensure questID is valid before checking
        if type(questID) == "number" and questID > 0 then
            -- TODO: Investigate but I think this comes back as false during logout.
            local isCompleted = CQL_IsQuestFlaggedCompleted(questID)

            if isCompleted then
                if not completedQuestsDB[questID] then
                    completedQuestsDB[questID] = true
                    Debug:DebugPrint("Quest " .. questID .. " marked as complete.")
                end
            end
        else
            Debug:DebugPrint("!!! WARNING: Invalid quest ID found in TrackedQuestIDs list: " .. tostring(questID))
        end
    end
    
    db:UpdateCharDBKey("completedQuests", completedQuestsDB)

    Debug:DebugPrint("Quest tracking ended.")
end

-------------------------------------------------
--- Constants
-------------------------------------------------

-- Helper function to flatten a structured quest table into a single array
local function FlattenQuestTable(questStructure)
    local flattened = {}
    
    for groupName, categories in pairs(questStructure) do
        for categoryName, questIDs in pairs(categories) do
            for _, questID in ipairs(questIDs) do
                table.insert(flattened, questID)
            end
        end
    end
    
    return flattened
end

-- Helper function to load quest data from external files
local function LoadQuestData()
    local questData = {}
    
    -- Load profession quest data
    local success, professionQuests = pcall(function()
        return dofile("Data/Quests/Professions/_loader.lua")
    end)
    
    if success and professionQuests then
        questData.Professions = professionQuests
    else
        Debug:DebugPrint("!!! ERROR: Failed to load profession quest data. Using empty table.")
        questData.Professions = {}
    end
    
    -- Future: Load other quest types here
    -- Example:
    -- local success, eventQuests = pcall(function()
    --     return dofile("Data/Quests/Events/_loader.lua")  
    -- end)
    -- if success and eventQuests then
    --     questData.Events = eventQuests
    -- end
    
    return questData
end

-- Load structured quest data from external files
-- Structure: GroupName = { SubGroupName = { CategoryName = { questID1, questID2, ... } } }
local StructuredQuests = LoadQuestData()

Module.Constants = {
    -- Flatten the structured quest data into the required format
    TrackedQuestIDs = FlattenQuestTable(StructuredQuests),
    
    -- Expose the structured data for easier access if needed
    StructuredQuests = StructuredQuests
}
