-- Get the addon name passed by WoW when loading the file
local addonName, addonNamespace = select(1, ...), select(2, ...)

if not addonNamespace.Edition.collectors['Professions.Retail'] then
    return
end

-- Get the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Fetch shared functionality
---@type WoWEfficiency_Debug
local Debug = WoWEfficiency:GetModule('Debug')
local professionData = addonNamespace.Edition.professions.data

-- Define the Retail-only profession details module.
---@class WoWEfficiency_Professions_Retail: AceModule
local Module = WoWEfficiency:NewModule('Professions.Retail')

-- Upvalue Retail-only APIs after the edition guard.
local C_ProfSpecs_GetCurrencyInfoForSkillLine = C_ProfSpecs.GetCurrencyInfoForSkillLine
local C_ProfSpecs_GetConfigIDForSkillLine = C_ProfSpecs.GetConfigIDForSkillLine
local C_Traits_GetConfigInfo = C_Traits.GetConfigInfo
local C_Traits_GetTreeNodes = C_Traits.GetTreeNodes
local C_Traits_GetNodeInfo = C_Traits.GetNodeInfo
local C_ProfSpecs_GetStateForTab = C_ProfSpecs.GetStateForTab
local C_ProfSpecs_GetTabInfo = C_ProfSpecs.GetTabInfo
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local C_TradeSkillUI_GetProfessionInfoBySkillLineID = C_TradeSkillUI.GetProfessionInfoBySkillLineID

-- Create the stored defaults for one expansion's profession details.
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

-- Create specialization totals and retain the tab's current state.
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

-- Refresh one expansion while retaining previously reported skill ranks.
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

    -- Moxie currency info
    if variantConstants.moxieCurrencyID then
        local moxieInfo = C_CurrencyInfo_GetCurrencyInfo(variantConstants.moxieCurrencyID)
        if moxieInfo and moxieInfo.quantity then
            expansionStruct.moxie = {
                currencyID = variantConstants.moxieCurrencyID,
                amount = moxieInfo.quantity,
                maxQuantity = moxieInfo.maxQuantity,
            }
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

-- Fill eligible expansion data without changing the shared base profession data.
function Module:UpdateProfession(profStruct, skillLineID, playerLevel)
    local profession = professionData[skillLineID]
    if not profession then
        return
    end

    for expansion, expansionData in pairs(profession.expansions) do
        if playerLevel >= expansionData.minLevel then
            profStruct[expansion] = ExtractExpansionData(expansionData, profStruct[expansion])
        end
    end
end
