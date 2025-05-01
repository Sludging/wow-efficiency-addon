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
---@class WoWEfficiency_Professions: AceModule, AceEvent-3.0
---@field UpdateProfessions fun(self: WoWEfficiency_Professions)
local Module = WoWEfficiency:NewModule('Professions')

function Module:OnInitialize()
    Debug:DebugPrint("Professions Module" .. " Initialized.")
end

function Module:OnEnable()
    Debug:DebugPrint("Professions Module" .. " Enabled.")

    -- Register events
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateProfessions")
    self:RegisterEvent("PLAYER_LOGOUT", "UpdateProfessions")
    self:RegisterEvent("PLAYER_LEAVING_WORLD", "UpdateProfessions")
end

local GetProfessionStruct = function(skillLineID, skillLevel, maxSkillLevel)
    return {
        enabled = true,
        skillLineID = skillLineID,
        level = skillLevel,
        maxLevel = maxSkillLevel,
        knowledgeLevel = 0,
        knowledgeMaxLevel = 0,
        knowledgeUnspent = 0,
        specializations = {}
    }
end

local GetSpecializationStruct = function(tabInfo, treeID, configID)
    return {
        tabInfo = tabInfo,
        state = C_ProfSpecs.GetStateForTab(treeID, configID),
        treeID = treeID,
        configID = configID,
        knowledgeLevel = 0,
        knowledgeMaxLevel = 0
    }
end

local ExtractProfessionData = function(professionIndex)
    -- Get baseline profession info
    local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLineID, skillModifier, specializationIndex, specializationOffset =
        GetProfessionInfo(professionIndex)

    -- Map to our base profession data
    local baseProfessionData = Module.Constants.Base[skillLineID]
    if not baseProfessionData then
        Debug:DebugPrint("!!! WARNING: Failed to find base profession data for skillLineID: " .. skillLineID)
        return
    end

    -- Initialize the profession struct
    local professionStruct = GetProfessionStruct(skillLineID, skillLevel, maxSkillLevel)

    -- Currency info for the skill line contains the current unspent knowledge points.
    local currencyInfo = C_ProfSpecs.GetCurrencyInfoForSkillLine(baseProfessionData.skillLineVariantID)
    if currencyInfo and currencyInfo.numAvailable then
        professionStruct.knowledgeUnspent = currencyInfo.numAvailable
    end

    -- Catch up currency info
    if baseProfessionData.catchUpCurrencyID then
        local catchUpCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(baseProfessionData.catchUpCurrencyID)
        if catchUpCurrencyInfo and catchUpCurrencyInfo.quantity then
            professionStruct.catchUpCurrencyInfo = catchUpCurrencyInfo
        end
    end

    -- Get the config ID for the skill line
    local configID = C_ProfSpecs.GetConfigIDForSkillLine(baseProfessionData.skillLineVariantID)
    if configID and configID > 0 then
        -- Get the config info for the skill line
        local configInfo = C_Traits.GetConfigInfo(configID)
        if configInfo then
            -- Iterate over the tree IDs (specialization trees)
            for _, treeID in pairs(configInfo.treeIDs) do
                -- Get the nodes for the tree
                local treeNodes = C_Traits.GetTreeNodes(treeID)
                if not treeNodes then
                    Debug:DebugPrint("!!! WARNING: Failed to get tree nodes for treeID: " .. treeID)
                    return
                end

                -- Get the tab info for the tree
                local tabInfo = C_ProfSpecs.GetTabInfo(treeID)
                -- Initialize the specialization struct
                local specializationStruct = GetSpecializationStruct(tabInfo, treeID, configID)

                for _, nodeID in pairs(treeNodes) do
                    -- Get the node info
                    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
                    if not nodeInfo then
                        Debug:DebugPrint("!!! WARNING: Failed to get node info for nodeID: " .. nodeID)
                        return
                    end

                    -- If the node has been purchased, add the knowledge level
                    if nodeInfo.ranksPurchased > 1 then
                        professionStruct.knowledgeLevel = professionStruct.knowledgeLevel + (nodeInfo.currentRank - 1)
                        if tabInfo and specializationStruct then
                            specializationStruct.knowledgeLevel = specializationStruct.knowledgeLevel +
                                (nodeInfo.currentRank - 1)
                        end
                    end

                    -- I might be able to just have this on the site, not sure I need it.
                    -- Update the max knowledge level
                    professionStruct.knowledgeMaxLevel = professionStruct.knowledgeMaxLevel + (nodeInfo.maxRanks - 1)
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

    return professionStruct
end

function Module:UpdateProfessions()
    -- TODO: Don't track characters under 70
    local prof1, prof2 = GetProfessions()

    Debug:DebugPrint("Before - Professions: " .. Table:ToString(db:GetCharDBKey("professions")))

    local professionsDB = db:GetCharDBKey("professions")
    for _, professionIndex in pairs({ prof1, prof2 }) do
        if professionIndex then
            local professionData = ExtractProfessionData(professionIndex)
            if professionData then
                professionsDB[professionData.skillLineID] = professionData
            else
                Debug:DebugPrint("!!! WARNING: Failed to extract profession data for profession index: " .. professionIndex)
            end
        end
    end

    Debug:DebugPrint("After - Professions: " .. Table:ToString(db:GetCharDBKey("professions")))

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
    }
}
