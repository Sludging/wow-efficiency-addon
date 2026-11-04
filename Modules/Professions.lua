-- Get the addon name passed by WoW when loading the file
local addonName, addonNamespace = select(1, ...), select(2, ...)

if not addonNamespace.Edition.collectors['Professions'] then
    return
end

-- Get the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Fetch shared functionality
---@type WoWEfficiency_Debug
local Debug = WoWEfficiency:GetModule('Debug')
---@type WoWEfficiency_DB
local db = WoWEfficiency:GetModule('DB')
---@type WoWEfficiency_Professions_Retail|nil
local Retail = WoWEfficiency:GetModule('Professions.Retail', true)
local professionConfig = addonNamespace.Edition.professions
local professionData = professionConfig.data

-- Define the module
---@class WoWEfficiency_Professions: AceModule, AceEvent-3.0, AceBucket-3.0
---@field UpdateProfessions fun(self: WoWEfficiency_Professions)
---@field OnEnable fun(self: WoWEfficiency_Professions)
---@field OnInitialize fun(self: WoWEfficiency_Professions)
---@field GetTrackedProfessions fun(self: WoWEfficiency_Professions): table
local Module = WoWEfficiency:NewModule('Professions', "AceBucket-3.0")

-- Upvalue global functions
local _GetProfessions = GetProfessions
local _GetProfessionInfo = GetProfessionInfo
local _UnitLevel = UnitLevel

function Module:OnInitialize()
    Debug:DebugPrint("Professions Module" .. " Initialized.")
end

function Module:OnEnable()
    Debug:DebugPrint("Professions Module" .. " Enabled.")

    -- Trigger update profession as soon as possible to make it available for the other functions
    self:RegisterEvent('PLAYER_ENTERING_WORLD', "UpdateProfessions")
    -- Register bucket events for profession updates
    local events = {
        'SKILL_LINES_CHANGED',
        'TRADE_SKILL_LIST_UPDATE',
    }
    if Retail then
        events[#events + 1] = 'CURRENCY_DISPLAY_UPDATE'
    end
    self:RegisterBucketEvent(
    ---@diagnostic disable-next-line: param-type-mismatch
        events,
        3,
        "UpdateProfessions"
    )
end

-- Return supported current professions, retaining secondary slots only when configured.
function Module:GetTrackedProfessions()
    local professions = {}
    for slot, professionIndex in pairs({ _GetProfessions() }) do
        if professionConfig.includeSecondary or slot <= 2 then
            local name, texture, level, maxLevel, _, _, skillLineID = _GetProfessionInfo(professionIndex)
            if skillLineID and professionData[skillLineID] then
                professions[#professions + 1] = {
                    id = skillLineID,
                    name = name,
                    texture = texture,
                    level = level,
                    maxLevel = maxLevel,
                }
            end
        end
    end
    return professions
end

-- Store reported base ranks and let the optional Retail module enrich expansion data.
function Module:UpdateProfessions()
    if not db:IsCharDBReady() then
        return
    end

    local playerLevel = _UnitLevel("player")
    if playerLevel < professionConfig.minLevel then
        return
    end

    local professionsDB = db:GetCharDBKey("professions")
    for _, profession in ipairs(self:GetTrackedProfessions()) do
        local skillLineID = profession.id
        local profStruct = professionsDB[skillLineID] or { skillLineID = skillLineID }
        profStruct.skillLineID = skillLineID

        -- A temporary 0/0 report must not erase a previously collected base rank.
        if profession.level and profession.maxLevel and profession.maxLevel > 0 then
            profStruct.base = {
                level = profession.level,
                maxLevel = profession.maxLevel,
                professionName = profession.name,
            }
        end
        if Retail then
            Retail:UpdateProfession(profStruct, skillLineID, playerLevel)
        end

        professionsDB[skillLineID] = profStruct
    end

    db:UpdateCharDBKey("professions", professionsDB)

    Debug:DebugPrint("Professions updated")
end

