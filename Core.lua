-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the AceAddon library and create the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

-- ==============================================================================
-- Database Setup
-- ==============================================================================

-- Define the default structure for our character-specific database
local dbDefaults = {
    char = { -- Define profile structure under 'char' for character-specific data
        completedQuests = {}, -- Stores { [questID] = true } for completed quests
        -- Add other character-specific settings here later
    }
    -- profile = { ... } -- could be used for settings shared across characters on the account
    -- global = { ... } -- could be used for settings shared across all accounts/servers
}

function WoWEfficiency:OnInitialize()
    -- This function runs once when the addon is first loaded
    self.db = LibStub("AceDB-3.0"):New("WoWEfficiencyDB", dbDefaults, true) -- 'true' for character-specific DB
    self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown") -- Register the shutdown callback
    -- self:Print(addonName .. " Initialized. DB is ready.")
end

-- ==============================================================================
-- Core Logic
-- ==============================================================================

-- Checks all quests in the trackedQuestIDs list and updates the database
function WoWEfficiency:UpdateAllTrackedQuests()
    self:Print("Running UpdateAllTrackedQuests...")
    local completedQuestsDB = self.db.char.completedQuests
    local changed = false

    -- Access the quest list from the Constants table attached to the addon object
    for _, questID in ipairs(WoWEfficiency.Constants.TrackedQuestIDs) do
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)

        if isCompleted then
            -- Quest is completed, ensure it's marked in the DB
            if not completedQuestsDB[questID] then
                completedQuestsDB[questID] = true
                changed = true
                -- self:Print("Quest " .. questID .. " marked as complete.")
            end
        else
            -- Quest is not completed, ensure it's *not* marked in the DB (optional cleanup)
            if completedQuestsDB[questID] then
                completedQuestsDB[questID] = nil -- Use nil to remove the key
                changed = true
                -- self:Print("Quest " .. questID .. " unmarked (no longer complete?).")
            end
        end
    end

    if changed then
        self:Print("Quest database updated.")
    else
        self:Print("No quest changes detected.")
    end
end

-- ==============================================================================
-- Event Handlers / AceAddon Functions
-- ==============================================================================

---@diagnostic disable-next-line: duplicate-set-field
function WoWEfficiency:OnEnable()
    -- This function runs every time the addon is enabled (e.g., after login, /reload)
    self:Print(addonName .. " Enabled.")
    self:UpdateAllTrackedQuests() -- Run the check on login/enable
end

---@diagnostic disable-next-line: duplicate-set-field
function WoWEfficiency:OnDatabaseShutdown()
    -- Fires when logging out, just before the database is about to be cleaned of all AceDB metadata.
    self:Print(addonName .. " Shutting Down. Running final quest check.")
    self:UpdateAllTrackedQuests() -- Run the check on clean logout/reload
end

-- We will add quest checking logic and event registration later...
