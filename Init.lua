-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the AceAddon library and create the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

-- ==============================================================================
-- Module Setup
-- ==============================================================================

WoWEfficiency:SetDefaultModuleLibraries("AceEvent-3.0")
