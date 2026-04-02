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
---@class WoWEfficiency_Currencies: AceModule, AceEvent-3.0
---@field UpdateCurrencies fun(self: WoWEfficiency_Currencies)
local Module = WoWEfficiency:NewModule('Currencies', "AceEvent-3.0")

-- Upvalue global functions
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local C_CurrencyInfo_FetchCurrencyDataFromAccountCharacters = C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters

-- Tracked currency IDs. Add new currencies here as needed.
-- Format: [currencyID] = true
Module.TrackedCurrencies = {
    [3316] = true, -- Voidlight Marl
}

function Module:OnEnable()
    Debug:DebugPrint("Currencies Module Enabled.")

    self:RegisterEvent('PLAYER_ENTERING_WORLD', "UpdateCurrencies")
    self:RegisterEvent('CURRENCY_DISPLAY_UPDATE', "UpdateCurrencies")
    self:RegisterEvent('ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED', "UpdateAccountCurrencies")
end

-- Update currencies for the current character
function Module:UpdateCurrencies()
    if not db:IsCharDBReady() then return end

    local currenciesDB = db:GetCharDBKey("currencies")

    for currencyID in pairs(Module.TrackedCurrencies) do
        local info = C_CurrencyInfo_GetCurrencyInfo(currencyID)
        if info then
            currenciesDB[currencyID] = {
                currencyID = currencyID,
                amount = info.quantity,
                maxQuantity = info.maxQuantity,
            }
        end
    end

    db:UpdateCharDBKey("currencies", currenciesDB)

    Debug:DebugPrint("Currencies updated")
end

-- Update account currencies for all characters
function Module:UpdateAccountCurrencies()
    local currenciesDB = db:GetDB().global.currencies

    for currencyID in pairs(Module.TrackedCurrencies) do
        -- Fetch account currencies
        local accountCurrencies = C_CurrencyInfo_FetchCurrencyDataFromAccountCharacters(currencyID)
        if accountCurrencies then
            -- Ensure specific currency sub-table exists
            if not currenciesDB[currencyID] then
                currenciesDB[currencyID] = {}
            end

            -- For each character
            for _, currencyData in pairs(accountCurrencies) do
                currenciesDB[currencyID][currencyData.fullCharacterName] = {
                    currencyID = currencyID,
                    amount = currencyData.quantity,
                    maxQuantity = 0, -- Not available for account currencies
                }
            end
        end
    end

    db:GetDB().global.currencies = currenciesDB
    db:TrackGlobalLastUpdated("currencies")

    Debug:DebugPrint("Account currencies updated")
end
