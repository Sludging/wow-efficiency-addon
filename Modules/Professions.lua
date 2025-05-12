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

local GetProfessionStruct = function(skillLineID, skillLevel, maxSkillLevel)
    local baseline = {
        skillLineID = skillLineID,
        level = skillLevel,
        maxLevel = maxSkillLevel,
        knowledgeLevel = 0,
        knowledgeMaxLevel = 0,
        knowledgeUnspent = 0,
        specializations = {},
        cooldowns = {},
        concentration = nil,
    }

    -- Get the current profession data
    local current = db:GetCharDBKey("professions")[skillLineID]
    -- If we don't have current profession data, return the baseline
    if not current then
        return baseline
    end

    -- Copy over the current profession data
    for k, v in pairs(current) do
        baseline[k] = v
    end

    -- Return the baseline (this allows us to add keys that don't exist in the current data)
    return baseline
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

local ExtractProfessionData = function(professionIndex)
    -- Get baseline profession info
    local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLineID, skillModifier, specializationIndex, specializationOffset =
        _GetProfessionInfo(professionIndex)

    -- Map to our base profession data
    local baseProfessionData = Module.Constants.Base[skillLineID]
    if not baseProfessionData then
        Debug:DebugPrint("!!! WARNING: Failed to find base profession data for skillLineID: " .. skillLineID)
        return
    end

    -- Initialize the profession struct
    local professionStruct = GetProfessionStruct(skillLineID, skillLevel, maxSkillLevel)

    -- Currency info for the skill line contains the current unspent knowledge points.
    local currencyInfo = C_ProfSpecs_GetCurrencyInfoForSkillLine(baseProfessionData.skillLineVariantID)
    if currencyInfo and currencyInfo.numAvailable then
        professionStruct.knowledgeUnspent = currencyInfo.numAvailable
    end

    -- Catch up currency info
    if baseProfessionData.catchUpCurrencyID then
        local catchUpCurrencyInfo = C_CurrencyInfo_GetCurrencyInfo(baseProfessionData.catchUpCurrencyID)
        if catchUpCurrencyInfo and catchUpCurrencyInfo.quantity then
            professionStruct.catchUpCurrencyInfo = catchUpCurrencyInfo
        end
    end

    -- Knowledge level sum
    local knowledgeLevelSum = 0
    local knowledgeMaxLevelSum = 0

    -- Get the config ID for the skill line
    local configID = C_ProfSpecs_GetConfigIDForSkillLine(baseProfessionData.skillLineVariantID)
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
                    return
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
                        return
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
                professionStruct.specializations[treeID] = specializationStruct                
            end
        end
    end

    -- Set the knowledge level and max level
    professionStruct.knowledgeLevel = knowledgeLevelSum
    professionStruct.knowledgeMaxLevel = knowledgeMaxLevelSum

    return professionStruct
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
            local professionData = ExtractProfessionData(professionIndex)
            if professionData then
                professionsDB[professionData.skillLineID] = professionData
            else
                Debug:DebugPrint("!!! WARNING: Failed to extract profession data for profession index: " ..
                professionIndex)
            end
        end
    end

    db:UpdateCharDBKey("professions", professionsDB)

    Debug:DebugPrint("Professions updated")
end

-------------------------------------------------
--- Constants
-------------------------------------------------

Module.Constants = {
    -- [SkillLineID] -> Data
    Base = {
        [171] = {
            name = "Alchemy",
            skillLineID = 171,
            skillLineVariantID = 2871,
            catchUpCurrencyID = 3057,
        },
        [164] = {
            name = "Blacksmithing",
            skillLineID = 164,
            skillLineVariantID = 2872,
            catchUpCurrencyID = 3058,
        },
        [333] = {
            name = "Enchanting",
            skillLineID = 333,
            skillLineVariantID = 2874,
            catchUpCurrencyID = 3059,
        },
        [202] = {
            name = "Engineering",
            skillLineID = 202,
            skillLineVariantID = 2875,
            catchUpCurrencyID = 3060,
        },
        [182] = {
            name = "Herbalism",
            skillLineID = 182,
            skillLineVariantID = 2877,
            catchUpCurrencyID = 3061,
        },
        [773] = {
            name = "Inscription",
            skillLineID = 773,
            skillLineVariantID = 2878,
            catchUpCurrencyID = 3062,
        },
        [755] = {
            name = "Jewelcrafting",
            skillLineID = 755,
            skillLineVariantID = 2879,
            catchUpCurrencyID = 3063,
        },
        [165] = {
            name = "Leatherworking",
            skillLineID = 165,
            skillLineVariantID = 2880,
            catchUpCurrencyID = 3064,
        },
        [186] = {
            name = "Mining",
            skillLineID = 186,
            skillLineVariantID = 2881,
            catchUpCurrencyID = 3065,
        },
        [393] = {
            name = "Skinning",
            skillLineID = 393,
            skillLineVariantID = 2882,
            catchUpCurrencyID = 3066,
        },
        [197] = {
            name = "Tailoring",
            skillLineID = 197,
            skillLineVariantID = 2883,
            catchUpCurrencyID = 3067,
        }
    },
}