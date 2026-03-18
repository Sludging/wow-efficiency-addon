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
---@class WoWEfficiency_Professions_Concentration: AceModule, AceEvent-3.0, AceBucket-3.0
---@field UpdateConcentration fun(self: WoWEfficiency_Professions_Concentration)
local Module = WoWEfficiency:NewModule('Professions.Concentration', "AceBucket-3.0")

-- Upvalue global functions
local C_TradeSkillUI_GetBaseProfessionInfo = C_TradeSkillUI.GetBaseProfessionInfo


function Module:OnEnable()
    self:RegisterEvent('TRADE_SKILL_LIST_UPDATE', "UpdateConcentration")
end

local GetConcentrationStruct = function(currencyID)
    return {
        currencyID = currencyID,
        lastUpdated = 0, -- seconds with ms precision, ( GetServerTime )
        amount = 0,
        rechargingDurationMS = 0,
        maxQuantity = 0,
    }
end

function Module:UpdateConcentration()
    local playerLevel = UnitLevel("player")
    if playerLevel < 70 then
        return
    end

    -- Get profession info (this gets the currently open window)
    local profInfo = C_TradeSkillUI_GetBaseProfessionInfo()
    -- If the profession is not a primary profession, skip
    if not profInfo or profInfo.isPrimaryProfession == false then
        return
    end

    -- I assume UpdateProfessions ran before this.
    -- Will revisit this assumption if needed.
    local professionsDB = db:GetCharDBKey("professions")

    -- In this case skill line id == profession id
    local skillLineID = profInfo.professionID

    local professionData = professionsDB[skillLineID]

    -- Get concentration info for each expansion's variant
    local expansionConstants = Module.Constants[skillLineID]
    if not expansionConstants then
        return
    end

    for expansionName, skillVariantID in pairs(expansionConstants) do
        if type(skillVariantID) == "number" and professionData[expansionName] then
            local currencyID = C_TradeSkillUI.GetConcentrationCurrencyID(skillVariantID)
            if currencyID and currencyID > 0 then
                local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)
                if currencyInfo then
                    local concentrationStruct = GetConcentrationStruct(currencyID)
                    concentrationStruct.amount = currencyInfo.quantity
                    concentrationStruct.maxQuantity = currencyInfo.maxQuantity
                    concentrationStruct.rechargingDurationMS = currencyInfo.rechargingCycleDurationMS
                    professionData[expansionName].concentration = concentrationStruct
                end
            end
        end
    end

    professionsDB[skillLineID] = professionData

    db:UpdateCharDBKey("professions", professionsDB)
    db:TrackLastUpdated("concentration-" .. skillLineID)

    Debug:DebugPrint("Concentration updated")
end

Module.Constants = {
    -- [SkillLineID] -> { expansion = skillLineVariantID }
    [171] = { TWW = 2871, Midnight = 2906 },
    [164] = { TWW = 2872, Midnight = 2907 },
    [333] = { TWW = 2874, Midnight = 2909 },
    [202] = { TWW = 2875, Midnight = 2910 },
    [182] = { TWW = 2877 },
    [773] = { TWW = 2878, Midnight = 2913 },
    [755] = { TWW = 2879, Midnight = 2914 },
    [165] = { TWW = 2880, Midnight = 2915 },
    [186] = { TWW = 2881 },
    [393] = { TWW = 2882 },
    [197] = { TWW = 2883, Midnight = 2918 },
}