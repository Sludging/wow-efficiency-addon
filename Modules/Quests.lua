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
    -- TODO: Investigate if this works.
    C_Log.LogMessage("Quest tracking ended.")

    
end

-------------------------------------------------
--- Constants
-------------------------------------------------

Module.Constants = {
    TrackedQuestIDs = {
        -- Alchemy
        -- Artisan
        84133,
        -- Darkmoon
        29506,
        -- Treasure
        83253,
        83255,
        -- Treatise
        83725,
        -- Uniques
        81146,
        81147,
        81148,
        82633,
        83058,
        83840,
        83841,
        83842,
        83843,
        83844,
        83845,
        83846,
        83847,

        -- Blacksmithing
        -- Artisan
        84127,
        -- Darkmoon
        29508,
        -- Treasure
        83256,
        83257,
        -- Treatise
        83726,
        -- Uniques
        82631,
        83059,
        83848,
        83849,
        83850,
        83851,
        83852,
        83853,
        83854,
        83855,
        84226,
        84227,
        84228,

        -- Enchanting
        -- Darkmoon
        29510,
        -- Gathering
        84290,
        84291,
        84292,
        84293,
        84294,
        84295,
        -- Trainer
        84084,
        84085,
        84086,
        -- Treasure
        83258,
        83259,
        -- Treatise
        83727,
        -- Uniques
        81076,
        81077,
        81078,
        82635,
        83060,
        83856,
        83859,
        83860,
        83861,
        83862,
        83863,
        83864,
        83865,

        -- Engineering
        -- Artisan
        84128,
        -- Darkmoon
        29511,
        -- Treasure
        83260,
        83261,
        -- Treatise
        83728,
        -- Uniques
        82632,
        83063,
        83866,
        83867,
        83868,
        83869,
        83870,
        83871,
        83872,
        83873,
        84229,
        84230,
        84231,

        -- Herbalism
        -- Darkmoon
        29514,
        -- Gathering
        81416,
        81417,
        81418,
        81419,
        81420,
        81421,
        -- Trainer
        82916,
        82958,
        82962,
        82965,
        82970,
        -- Treatise
        83729,
        -- Uniques
        81422,
        81423,
        81424,
        82630,
        83066,
        83874,
        83875,
        83876,
        83877,
        83878,
        83879,
        83880,
        83881,

        -- Inscription
        -- Artisan
        84129,
        -- Darkmoon
        29515,
        -- Treasure
        83262,
        83264,
        -- Treatise
        83730,
        -- Uniques
        80749,
        80750,
        80751,
        82636,
        83064,
        83882,
        83883,
        83884,
        83885,
        83886,
        83887,
        83888,
        83889,

        -- Jewelcrafting
        -- Artisan
        84130,
        -- Darkmoon
        29516,
        -- Treasure
        83265,
        83266,
        -- Treatise
        83731,
        -- Uniques
        81259,
        81260,
        81261,
        82637,
        83065,
        83890,
        83891,
        83892,
        83893,
        83894,
        83895,
        83896,
        83897,

        -- Leatherworking
        -- Artisan
        84131,
        -- Darkmoon
        29517,
        -- Treasure
        83267,
        83268,
        -- Treatise
        83732,
        -- Uniques
        80978,
        80979,
        80980,
        82626,
        83068,
        83898,
        83899,
        83900,
        83901,
        83902,
        83903,
        83904,
        83905,

        -- Mining
        -- Darkmoon
        29518,
        -- Gathering
        83049,
        83050,
        83051,
        83052,
        83053,
        83054,
        -- Trainer
        83102,
        83103,
        83104,
        83105,
        83106,
        -- Treatise
        83733,
        -- Uniques
        81390,
        81391,
        81392,
        82614,
        83062,
        83906,
        83907,
        83908,
        83909,
        83910,
        83911,
        83912,
        83913,

        -- Skinning
        -- Darkmoon
        29519,
        -- Gathering
        81459,
        81460,
        81461,
        81462,
        81463,
        81464,
        -- Trainer
        82992,
        82993,
        83097,
        83098,
        83100,
        -- Treatise
        83734,
        -- Uniques
        82596,
        83067,
        83914,
        83915,
        83916,
        83917,
        83918,
        83919,
        83920,
        83921,
        84232,
        84233,
        84234,

        -- Tailoring
        -- Artisan
        84132,
        -- Darkmoon
        29520,
        -- Treasure
        83269,
        83270,
        -- Treatise
        83735,
        -- Uniques
        80871,
        80872,
        80873,
        82634,
        83061,
        83922,
        83923,
        83924,
        83925,
        83926,
        83927,
        83928,
        83929,
    }
}
