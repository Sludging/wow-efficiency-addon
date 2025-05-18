-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the main addon object
---@type WoWEfficiency_Addon
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
---@field WipeDB fun(self: WoWEfficiency_DB): nil
local Module = WoWEfficiency:NewModule('DB')

-- Define the default structure for our character-specific database
local dbDefaults = {
    char = { -- Define profile structure under 'char' for character-specific data
        completedQuests = {}, -- Stores { [questID] = true } for completed quests
        professions = {}, -- Stores { [professionID] = <professionData> } for professions.
        lastUpdated = {}, -- Stores { [category] = timestamp } for last updated time for each category
        lastUpdatedISO = {}, -- Stores { [category] = ISO 8601 timestamp } for last updated time for each category
        logs = {}, -- Stores { [timestamp] = msg } for logs.
        nextWeeklyReset = 0, -- Stores the server time for this character's next weekly reset processing
        -- Add other character-specific settings here later
    },
    profile = { -- Settings shared across characters using this profile
        debugMode = false,
    },
    global = { 
        weeklyResetTime = 0, -- Updated once per week.
    }
}

function Module:OnInitialize()
    -- Initialize database
    self.db = LibStub("AceDB-3.0"):New("WowEfficiencyDB", dbDefaults, true) -- 'true' for character-specific DB

    -- Handle weekly reset
    self:HandleWeeklyReset()
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
    local iso_format = date("!%Y-%m-%dT%H:%M:%SZ")
    self.db.char.logs[iso_format] = category .. ": " .. msg
end

function Module:TrackLastUpdated(category)
    self.db.char.lastUpdated[category] = GetServerTime()
    self.db.char.lastUpdatedISO[category] = date("!%Y-%m-%dT%H:%M:%SZ")
end

function Module:HandleWeeklyReset()
    local currentTime = GetServerTime()
    local nextWeeklyReset = GetServerTime() + C_DateAndTime.GetSecondsUntilWeeklyReset()

    -- Ensure nextWeeklyResetProcessTime is properly initialized (should be 0 from dbDefaults on first run for a char)
    if type(self.db.char.nextWeeklyReset) ~= "number" then
        self.db.char.nextWeeklyReset = 0
    end

    if currentTime >= self.db.char.nextWeeklyReset then
        -- It's time to process the weekly reset for this character.
        self:UpdateCharDBKey("completedQuests", {})
        -- Add other character-specific weekly resets here if needed in the future.

        -- Track the next reset for this character.
        self.db.char.nextWeeklyReset = nextWeeklyReset
        
        WoWEfficiency:Print("|cFFFF0000Weekly reset processed for this character.|r")
    end

    -- Update the global weekly reset time.
    if type(self.db.global.weeklyResetTime) ~= "number" then
        self.db.global.weeklyResetTime = 0
    end

    if currentTime >= self.db.global.weeklyResetTime then
        -- Track the next reset for the global weekly reset time.
        self.db.global.weeklyResetTime = nextWeeklyReset
    end
end

function Module:WipeDB()
    if self.db then
        self.db:ResetDB()
        self:HandleWeeklyReset() -- Re-initialize weekly reset timer
        WoWEfficiency:Print("|cFFFF0000Database wiped and reset to defaults.|r")
    else
        WoWEfficiency:Print("|cFFFF0000Error:|r Database not initialized, cannot wipe.")
    end
end