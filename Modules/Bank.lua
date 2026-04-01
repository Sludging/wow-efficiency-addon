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

-- Define the module
---@class WoWEfficiency_Bank: AceModule, AceEvent-3.0
---@field UpdateWarbankGold fun(self: WoWEfficiency_Bank)
local Module = WoWEfficiency:NewModule('Bank', "AceEvent-3.0")

-- Upvalue global functions
local C_Bank_FetchDepositedMoney = C_Bank.FetchDepositedMoney
local Enum_BankType_Account = Enum.BankType.Account

function Module:OnEnable()
    Debug:DebugPrint("Bank Module Enabled.")

    -- TODO: Verify these event names in-game. They may differ from the expected names.
    self:RegisterEvent('BANKFRAME_OPENED', "UpdateWarbankGold")
    self:RegisterEvent('BANKFRAME_CLOSED', "UpdateWarbankGold")
end

function Module:UpdateWarbankGold()
    local gold = C_Bank_FetchDepositedMoney(Enum_BankType_Account)
    if gold == nil then
        Debug:DebugPrint("Bank: FetchDepositedMoney returned nil, skipping update")
        return
    end

    db:GetDB().global.warbankGold = gold

    Debug:DebugPrint("Warbank gold updated: " .. gold)
end
