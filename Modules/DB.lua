-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the main addon object
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Define the module
---@class WoWEfficiency_DB: AceModule, AceEvent-3.0
---@field db AceDBObject-3.0 @Database instance
---@field IsCharDBReady fun(self: WoWEfficiency_DB): boolean
---@field GetDB fun(self: WoWEfficiency_DB): AceDBObject-3.0
---@field GetCharDB fun(self: WoWEfficiency_DB): table
---@field UpdateCharDB fun(self: WoWEfficiency_DB, key: string, value: any): nil
---@field GetCharDBKey fun(self: WoWEfficiency_DB, key: string): any
---@field UpdateCharDBKey fun(self: WoWEfficiency_DB, key: string, value: any): nil
---@field GetProfileDBKey fun(self: WoWEfficiency_DB, key: string): any
---@field UpdateProfileDBKey fun(self: WoWEfficiency_DB, key: string, value: any): nil
local Module = WoWEfficiency:NewModule('DB')

-- Define the default structure for our character-specific database
local dbDefaults = {
    char = { -- Define profile structure under 'char' for character-specific data
        completedQuests = {}, -- Stores { [questID] = true } for completed quests
        professions = {}, -- Stores { [professionID] = <professionData> } for professions.
        lastUpdated = {}, -- Stores { [category] = timestamp } for last updated time for each category
        lastUpdatedISO = {}, -- Stores { [category] = ISO 8601 timestamp } for last updated time for each category
        logs = {}, -- Stores { [timestamp] = msg } for logs.
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

function Module:IsCharDBReady()
    return self.db ~= nil and self.db.char ~= nil
end

function Module:IsProfileDBReady()
    return self.db ~= nil and self.db.profile ~= nil
end

function Module:GetDB()
    return self.db
end

function Module:GetCharDB()
    return self.db.char
end

function Module:GetCharDBKey(key)
    return self.db.char[key]
end

function Module:UpdateCharDBKey(key, value)
    self.db.char[key] = value
    self:TrackLastUpdated(key)
end

function Module:GetProfileDBKey(key)
    return self.db.profile[key]
end

function Module:UpdateProfileDBKey(key, value)
    self.db.profile[key] = value
end

function Module:WriteLogToDB(category, msg)
    local iso_format = date("!%Y-%m-%dT%H:%M:%S")
    self.db.char.logs[iso_format] = category .. ": " .. msg
end

function Module:TrackLastUpdated(category)
    self.db.char.lastUpdated[category] = time()
    self.db.char.lastUpdatedISO[category] = date("!%Y-%m-%dT%H:%M:%S")
end
