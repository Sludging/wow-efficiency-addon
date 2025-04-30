---@meta -- Indicate this file is for metadata/types only

---@class WoWEfficiency_Addon: AceAddon, AceConsole-3.0, AceEvent-3.0
---@field Debug WoWEfficiency_Debug @Debug instance
---@field OnInitialize fun(self: WoWEfficiency_Addon)
---@field OnEnable fun(self: WoWEfficiency_Addon)
---@field ChatCommand fun(self: WoWEfficiency_Addon, input: string)
local WoWEfficiency_Addon = {} -- Dummy table often helps tools
