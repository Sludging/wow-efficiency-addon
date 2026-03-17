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
---@class WoWEfficiency_Professions: AceModule, AceEvent-3.0, AceBucket-3.0
---@field UpdateProfessions fun(self: WoWEfficiency_Professions)
---@field OnEnable fun(self: WoWEfficiency_Professions)
---@field OnInitialize fun(self: WoWEfficiency_Professions)
---@field Constants table
local Module = WoWEfficiency:NewModule('Professions', "AceBucket-3.0")

-- Upvalue global functions
local _GetProfessions = GetProfessions
local _GetProfessionInfo = GetProfessionInfo
local C_ProfSpecs_GetCurrencyInfoForSkillLine = C_ProfSpecs.GetCurrencyInfoForSkillLine
local C_ProfSpecs_GetConfigIDForSkillLine = C_ProfSpecs.GetConfigIDForSkillLine
local C_Traits_GetConfigInfo = C_Traits.GetConfigInfo
local C_Traits_GetTreeNodes = C_Traits.GetTreeNodes
local C_Traits_GetNodeInfo = C_Traits.GetNodeInfo
local C_ProfSpecs_GetStateForTab = C_ProfSpecs.GetStateForTab
local C_ProfSpecs_GetTabInfo = C_ProfSpecs.GetTabInfo
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local C_TradeSkillUI_GetProfessionInfoBySkillLineID = C_TradeSkillUI.GetProfessionInfoBySkillLineID

function Module:OnInitialize()
    Debug:DebugPrint("Professions Module" .. " Initialized.")
end

function Module:OnEnable()
    Debug:DebugPrint("Professions Module" .. " Enabled.")

    -- Trigger update profession as soon as possible to make it available for the other functions
    self:RegisterEvent('PLAYER_ENTERING_WORLD', "UpdateProfessions")
    -- Register bucket events for profession updates
    self:RegisterBucketEvent(
    ---@diagnostic disable-next-line: param-type-mismatch
        {
            'SKILL_LINES_CHANGED',
            'TRADE_SKILL_LIST_UPDATE',
        },
        3,
        "UpdateProfessions"
    )
end

local GetExpansionProfStruct = function()
    return {
        level = 0,
        maxLevel = 0,
        knowledgeLevel = 0,
        knowledgeMaxLevel = 0,
        knowledgeUnspent = 0,
        specializations = {},
        cooldowns = {},
        concentration = nil,
    }
end

local GetSpecializationStruct = function(tabInfo, treeID, configID)
    return {
        tabInfo = tabInfo,
        state = C_ProfSpecs_GetStateForTab(treeID, configID),
        treeID = treeID,
        configID = configID,
        knowledgeLevel = 0,
        knowledgeMaxLevel = 0
    }
end

local ExtractExpansionData = function(variantConstants, existingData)
    local expansionStruct = existingData or GetExpansionProfStruct()

    -- Get per-expansion level data via the variant-specific API
    -- C_TradeSkillUI.GetProfessionInfoBySkillLineID may return 0 when the profession window
    -- hasn't been opened yet. Only overwrite stored data when we get a real value.
    local variantInfo = C_TradeSkillUI_GetProfessionInfoBySkillLineID(variantConstants.skillLineVariantID)
    if variantInfo and variantInfo.maxSkillLevel and variantInfo.maxSkillLevel > 0 then
        expansionStruct.level = variantInfo.skillLevel
        expansionStruct.maxLevel = variantInfo.maxSkillLevel
        expansionStruct.professionName = variantInfo.professionName
    end

    -- Currency info for the skill line contains the current unspent knowledge points.
    local currencyInfo = C_ProfSpecs_GetCurrencyInfoForSkillLine(variantConstants.skillLineVariantID)
    if currencyInfo and currencyInfo.numAvailable then
        expansionStruct.knowledgeUnspent = currencyInfo.numAvailable
    end

    -- Catch up currency info
    if variantConstants.catchUpCurrencyID then
        local catchUpCurrencyInfo = C_CurrencyInfo_GetCurrencyInfo(variantConstants.catchUpCurrencyID)
        if catchUpCurrencyInfo and catchUpCurrencyInfo.quantity then
            expansionStruct.catchUpCurrencyInfo = catchUpCurrencyInfo
        end
    end

    -- Knowledge level sum
    local knowledgeLevelSum = 0
    local knowledgeMaxLevelSum = 0

    -- Get the config ID for the skill line
    local configID = C_ProfSpecs_GetConfigIDForSkillLine(variantConstants.skillLineVariantID)
    if configID and configID > 0 then
        -- Get the config info for the skill line
        local configInfo = C_Traits_GetConfigInfo(configID)
        if configInfo then
            -- Iterate over the tree IDs (specialization trees)
            for _, treeID in pairs(configInfo.treeIDs) do
                -- Get the nodes for the tree
                local treeNodes = C_Traits_GetTreeNodes(treeID)
                if not treeNodes then
                    Debug:DebugPrint("!!! WARNING: Failed to get tree nodes for treeID: " .. treeID)
                    return expansionStruct
                end

                -- Get the tab info for the tree
                local tabInfo = C_ProfSpecs_GetTabInfo(treeID)
                -- Initialize the specialization struct
                local specializationStruct = GetSpecializationStruct(tabInfo, treeID, configID)

                for _, nodeID in pairs(treeNodes) do
                    -- Get the node info
                    local nodeInfo = C_Traits_GetNodeInfo(configID, nodeID)
                    if not nodeInfo then
                        Debug:DebugPrint("!!! WARNING: Failed to get node info for nodeID: " .. nodeID)
                        return expansionStruct
                    end

                    -- If the node has been purchased, add the knowledge level
                    if nodeInfo.ranksPurchased > 1 then
                        knowledgeLevelSum = knowledgeLevelSum + (nodeInfo.currentRank - 1)
                        if tabInfo and specializationStruct then
                            specializationStruct.knowledgeLevel = specializationStruct.knowledgeLevel +
                                (nodeInfo.currentRank - 1)
                        end
                    end

                    -- I might be able to just have this on the site, not sure I need it.
                    -- Update the max knowledge level
                    knowledgeMaxLevelSum = knowledgeMaxLevelSum + (nodeInfo.maxRanks - 1)
                    if tabInfo and specializationStruct then
                        specializationStruct.knowledgeMaxLevel = specializationStruct.knowledgeMaxLevel +
                            (nodeInfo.maxRanks - 1)
                    end
                end

                -- Should we use the treeID or something from the tabInfo?
                expansionStruct.specializations[treeID] = specializationStruct
            end
        end
    end

    -- Set the knowledge level and max level
    expansionStruct.knowledgeLevel = knowledgeLevelSum
    expansionStruct.knowledgeMaxLevel = knowledgeMaxLevelSum

    return expansionStruct
end

function Module:UpdateProfessions()
    local playerLevel = UnitLevel("player")
    if playerLevel < 70 then
        return
    end

    local prof1, prof2 = _GetProfessions()

    local professionsDB = db:GetCharDBKey("professions")
    for _, professionIndex in pairs({ prof1, prof2 }) do
        if professionIndex then
            local _, _, _, _, _, _, skillLineID = _GetProfessionInfo(professionIndex)

            local profConstants = Module.Constants[skillLineID]
            if not profConstants then
                return
            end

            local profStruct = professionsDB[skillLineID] or { skillLineID = skillLineID }
            profStruct.skillLineID = skillLineID

            for key, value in pairs(profConstants) do
                if type(value) == "table" and playerLevel >= value.minLevel then
                    profStruct[key] = ExtractExpansionData(value, profStruct[key])
                end
            end

            professionsDB[skillLineID] = profStruct
        end
    end

    db:UpdateCharDBKey("professions", professionsDB)

    Debug:DebugPrint("Professions updated")
end

-------------------------------------------------
--- Constants
-------------------------------------------------

Module.Constants = {
    [171] = {
        name = "Alchemy",
        skillLineID = 171,
        TWW = { minLevel = 70, skillLineVariantID = 2871, catchUpCurrencyID = 3057 },
        Midnight = { minLevel = 80, skillLineVariantID = 2906, catchUpCurrencyID = 3189 },
    },
    [164] = {
        name = "Blacksmithing",
        skillLineID = 164,
        TWW = { minLevel = 70, skillLineVariantID = 2872, catchUpCurrencyID = 3058 },
        Midnight = { minLevel = 80, skillLineVariantID = 2907, catchUpCurrencyID = 3199 },
    },
    [333] = {
        name = "Enchanting",
        skillLineID = 333,
        TWW = { minLevel = 70, skillLineVariantID = 2874, catchUpCurrencyID = 3059 },
        Midnight = { minLevel = 80, skillLineVariantID = 2909, catchUpCurrencyID = 3198 },
    },
    [202] = {
        name = "Engineering",
        skillLineID = 202,
        TWW = { minLevel = 70, skillLineVariantID = 2875, catchUpCurrencyID = 3060 },
        Midnight = { minLevel = 80, skillLineVariantID = 2910, catchUpCurrencyID = 3197 },
    },
    [182] = {
        name = "Herbalism",
        skillLineID = 182,
        TWW = { minLevel = 70, skillLineVariantID = 2877, catchUpCurrencyID = 3061 },
        Midnight = { minLevel = 80, skillLineVariantID = 2912, catchUpCurrencyID = 3196 },
    },
    [773] = {
        name = "Inscription",
        skillLineID = 773,
        TWW = { minLevel = 70, skillLineVariantID = 2878, catchUpCurrencyID = 3062 },
        Midnight = { minLevel = 80, skillLineVariantID = 2913, catchUpCurrencyID = 3195 },
    },
    [755] = {
        name = "Jewelcrafting",
        skillLineID = 755,
        TWW = { minLevel = 70, skillLineVariantID = 2879, catchUpCurrencyID = 3063 },
        Midnight = { minLevel = 80, skillLineVariantID = 2914, catchUpCurrencyID = 3194 },
    },
    [165] = {
        name = "Leatherworking",
        skillLineID = 165,
        TWW = { minLevel = 70, skillLineVariantID = 2880, catchUpCurrencyID = 3064 },
        Midnight = { minLevel = 80, skillLineVariantID = 2915, catchUpCurrencyID = 3193 },
    },
    [186] = {
        name = "Mining",
        skillLineID = 186,
        TWW = { minLevel = 70, skillLineVariantID = 2881, catchUpCurrencyID = 3065 },
        Midnight = { minLevel = 80, skillLineVariantID = 2916, catchUpCurrencyID = 3192 },
    },
    [393] = {
        name = "Skinning",
        skillLineID = 393,
        TWW = { minLevel = 70, skillLineVariantID = 2882, catchUpCurrencyID = 3066 },
        Midnight = { minLevel = 80, skillLineVariantID = 2917, catchUpCurrencyID = 3191 },
    },
    [197] = {
        name = "Tailoring",
        skillLineID = 197,
        TWW = { minLevel = 70, skillLineVariantID = 2883, catchUpCurrencyID = 3067 },
        Midnight = { minLevel = 80, skillLineVariantID = 2918, catchUpCurrencyID = 3190 },
    },
}
