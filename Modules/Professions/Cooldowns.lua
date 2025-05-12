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
---@class WoWEfficiency_Professions_Cooldowns: AceModule, AceEvent-3.0, AceBucket-3.0
---@field UpdateCooldowns fun(self: WoWEfficiency_Professions_Cooldowns)
local Module = WoWEfficiency:NewModule('Professions.Cooldowns', "AceBucket-3.0")

-- Upvalue global functions
---@type SpellCooldownInfo
local CS_GetSpellCooldown = C_Spell.GetSpellCooldown
local C_TradeSkillUI_GetRecipeCooldown = C_TradeSkillUI.GetRecipeCooldown
local C_TradeSkillUI_IsRecipeProfessionLearned = C_TradeSkillUI.IsRecipeProfessionLearned
local C_TradeSkillUI_GetBaseProfessionInfo = C_TradeSkillUI.GetBaseProfessionInfo


function Module:OnEnable()
    self:RegisterEvent('TRADE_SKILL_LIST_UPDATE', "UpdateCooldowns")
end

local GetCooldownStruct = function(recipeID)
    return {
        recipeID = recipeID,
        isCooldownRecipe = false,
        currentCharges = 0,
        maxCharges = 0,
        startTime = 0,              -- seconds with ms precision, starttime for charge 1
        startTimeCurrentCharge = 0, -- seconds with ms precision, starttime for charge 1
        cooldownPerCharge = 0,      -- with cd reductions included
    }
end

local GetRecipeCooldowns = function(recipeID)
    -- Skip if the recipe is not learned
    local isLearned = C_TradeSkillUI_IsRecipeProfessionLearned(recipeID)
    if not isLearned then
        return
    end

    -- Get the cooldown info for the recipe
    local currentCooldown, isDayCooldown, currentCharges, maxCharges = C_TradeSkillUI_GetRecipeCooldown(recipeID)

    -- some new recipes in TWW are not marked as day cds even if they are... like inventing
    -- they only have a cd shown when on cd otherwise same info as regular recipes.. great
    local isCooldownRecipe = isDayCooldown or (maxCharges and maxCharges > 0) or (currentCharges and currentCharges > 0)
    if not isCooldownRecipe then
        return
    end

    -- TODO: I think we aren't dealing with daily cooldowns properly here.
    -- Need to investigate how to deal with them, look at CraftSim.

    Debug:DebugPrint("Updating cooldown for recipeID: " .. recipeID)

    local cooldownStruct = GetCooldownStruct(recipeID)
    cooldownStruct.currentCharges = currentCharges
    cooldownStruct.maxCharges = maxCharges

    -- daily cooldowns will be treated as cooldown recipes with 1 charge and a cooldown of 24h per charge
    if isDayCooldown or (cooldownStruct.maxCharges == 0 and currentCooldown > 0) then
        local spellCooldownInfo = CS_GetSpellCooldown(recipeID)
        cooldownStruct.cooldownPerCharge = spellCooldownInfo.duration
        cooldownStruct.maxCharges = 1
        cooldownStruct.currentCharges = 1
        -- TODO: Figure out why cooldownPerCharge is sometimes nil
        if spellCooldownInfo.startTime > 0 and cooldownStruct.cooldownPerCharge then
            cooldownStruct.currentCharges = 0
            local elapsedTimeSinceCooldownStart = (cooldownStruct.cooldownPerCharge - currentCooldown)
            cooldownStruct.startTimeCurrentCharge = GetServerTime() - elapsedTimeSinceCooldownStart
            cooldownStruct.startTime = cooldownStruct.startTimeCurrentCharge
        end
    else
        cooldownStruct.cooldownPerCharge = CS_GetSpellCooldown(recipeID).cooldownDuration
        -- TODO: Figure out why cooldownPerCharge is sometimes nil
        if cooldownStruct.currentCharges < cooldownStruct.maxCharges and cooldownStruct.cooldownPerCharge then
            local elapsedTimeSinceCooldownStart = (cooldownStruct.cooldownPerCharge - currentCooldown)
            cooldownStruct.startTimeCurrentCharge = GetServerTime() - elapsedTimeSinceCooldownStart
            cooldownStruct.startTime = math.max(
            cooldownStruct.startTimeCurrentCharge - (currentCharges) * cooldownStruct.cooldownPerCharge, 0)
        end
    end
    
    return cooldownStruct
end

function Module:UpdateCooldowns()
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
    local cooldowns = Module.Constants[skillLineID]
    -- If we don't have profession data, or there aren't any cooldowns for this profession, skip
    if not professionData or not cooldowns then
        return
    end

    Debug:DebugPrint("Updating cooldowns")

    for _, recipeID in pairs(cooldowns) do
        local recipeCooldowns = GetRecipeCooldowns(recipeID)
        -- Add the cooldown struct to the profession data
        if recipeCooldowns then
            professionData.cooldowns[recipeID] = recipeCooldowns
        end
    end

    professionsDB[skillLineID] = professionData

    db:UpdateCharDBKey("professions", professionsDB)
    db:TrackLastUpdated("cooldown-" .. skillLineID)

    Debug:DebugPrint("Cooldowns updated")
end

Module.Constants = {
    -- Alchemy
    [171] = {
        430345, -- twwAlchemyMeticulous
        430624, -- twwAlchemyGleamingGlory
        449938, -- Gleaming Chaos
        -- Transmutes
        430618, -- Mercurial Blessings
        449573, -- Mercurial Coalescence
        449571, -- Mercurial Herbs
        430619, -- Mercurial Storms
        430622, -- Ominous Call
        449574, -- Ominous Coalescence
        430623, -- Ominous Gloom
        449572, -- Ominous Herbs
        449575, -- Volatile Coalescence
        430621, -- Volatile Stone
        430620, -- Volatile Weaving
    },
    -- Blacksmithing
    [164] = {
        453727, -- Everburning
    },
    -- Engineering
    [202] = {
        447374, -- BoxOBooms
        447312, -- Invent
    },
    -- Jewelcrafting
    [755] = {
        435337, -- Amber Prism
        435338, -- Emerald Prism
        435369, -- Onyx Prism
        435339, -- Ruby Prism
        435370, -- Sapphire Prism
    },
    -- Tailoring
    [197] = {
        446928, -- Dawnweave
        446927, -- Duskweave
    }
}