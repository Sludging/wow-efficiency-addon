-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Fetch shared functionality
---@type WoWEfficiency_DB
local db = WoWEfficiency:GetModule('DB')

-- Define the module
---@class WoWEfficiency_Debug: AceModule, AceEvent-3.0
---@field DebugPrint fun(self: WoWEfficiency_Debug, ...)
local Module = WoWEfficiency:NewModule('Debug')

-- Learn how to do this better.
function Module:DebugPrint(...)
    -- Use the WoWEfficiency object captured from the outer scope
    if db.db and db.db.profile and db.db.profile.debugMode then
        WoWEfficiency:Print("|cFF00FF00DEBUG:|r", ...)
    end
end