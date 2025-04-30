-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the main addon object
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Define the module
---@class WoWEfficiency_DB: AceModule, AceEvent-3.0
---@field db AceDBObject-3.0 @Database instance
local Module = WoWEfficiency:NewModule('DB')

-- Define the default structure for our character-specific database
local dbDefaults = {
    char = { -- Define profile structure under 'char' for character-specific data
        completedQuests = {}, -- Stores { [questID] = true } for completed quests
        -- Add other character-specific settings here later
    },
    profile = { -- Settings shared across characters using this profile
        debugMode = false,
    }
    -- global = { ... } -- could be used for settings shared across all accounts/servers
}

function Module:OnInitialize()
    -- Initialize database
    self.db = LibStub("AceDB-3.0"):New("WowEfficiencyDB", dbDefaults, true) -- 'true' for character-specific DB
end

