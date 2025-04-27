---@meta -- Indicate this file is for metadata/types only

---@class WoWEfficiency_Addon: AceAddon-3.0, AceConsole-3.0, AceEvent-3.0
---@field db AceDBObject-3.0 @Database instance
---@field Constants table @Stores addon constants, populated by Constants.lua
---@field OnInitialize fun(self: WoWEfficiency_Addon)
---@field OnEnable fun(self: WoWEfficiency_Addon)
---@field OnDatabaseShutdown fun(self: WoWEfficiency_Addon)
---@field UpdateAllTrackedQuests fun(self: WoWEfficiency_Addon)
local WoWEfficiency_Addon = {} -- Dummy table often helps tools
