-- Get the addon name passed by WoW when loading the file
local addonName, addonNamespace = ...

if not addonNamespace.Edition.collectors['Profile'] then
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

-- Define the module
---@class WoWEfficiency_Profile: AceModule, AceEvent-3.0
---@field UpdateProfile fun(self: WoWEfficiency_Profile)
---@field UpdateIdentity fun(self: WoWEfficiency_Profile, event?: string, unit?: string)
---@field UpdateLevel fun(self: WoWEfficiency_Profile, event?: string, newLevel?: number)
---@field UpdateSpecialization fun(self: WoWEfficiency_Profile, event?: string, unit?: string|number)
---@field UpdateGuild fun(self: WoWEfficiency_Profile, event?: string, unit?: string|boolean)
---@field UpdateItemLevel fun(self: WoWEfficiency_Profile)
---@field UpdateMoney fun(self: WoWEfficiency_Profile)
---@field UpdateExperience fun(self: WoWEfficiency_Profile, event?: string, unit?: string)
---@field UpdateAchievementPoints fun(self: WoWEfficiency_Profile)
local Module = WoWEfficiency:NewModule('Profile', 'AceEvent-3.0')

-- Upvalue global functions
local RegionalUniqueNamesEnabled = RegionalUniqueNamesEnabled
local UnitNameUnmodified = UnitNameUnmodified
local GetRealmName = GetRealmName
local UnitClass = UnitClass
local UnitRace = UnitRace
local UnitFactionGroup = UnitFactionGroup
local UnitSex = UnitSex
local UnitLevel = UnitLevel
local C_SpecializationInfo_GetSpecialization = C_SpecializationInfo.GetSpecialization
local C_SpecializationInfo_GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local IsInGuild = IsInGuild
local GetGuildInfo = GetGuildInfo
local GetAverageItemLevel = GetAverageItemLevel
local GetMoney = GetMoney
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local GetTotalAchievementPoints = GetTotalAchievementPoints
local GetServerTime = GetServerTime
local math_max = math.max

---Replace a successfully read section and record its freshness; nil leaves the previous snapshot unchanged.
---@param section string
---@param value table|number|boolean|nil False records a known-empty section.
local function SetProfileSection(section, value)
    if value == nil then return end

    local profile = db:GetCharDBKey('profile') or {}
    local now = GetServerTime()
    profile[section] = value
    profile.updatedAt = profile.updatedAt or {}
    profile.updatedAt[section] = now
    profile.capturedAt = math_max(profile.capturedAt or 0, now)
    db:UpdateCharDBKey('profile', profile)
end

---Register shared character-profile events.
function Module:OnEnable()
    Debug:DebugPrint("Profile Module Enabled.")

    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateProfile')
    self:RegisterEvent('UNIT_NAME_UPDATE', 'UpdateIdentity')
    self:RegisterEvent('PLAYER_LEVEL_UP', 'UpdateLevel')
    self:RegisterEvent('PLAYER_TALENT_UPDATE', 'UpdateSpecialization')
    self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'UpdateSpecialization')
    self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', 'UpdateSpecialization')
    self:RegisterEvent('PLAYER_GUILD_UPDATE', 'UpdateGuild')
    self:RegisterEvent('GUILD_ROSTER_UPDATE', 'UpdateGuild')
    self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateItemLevel')
    self:RegisterEvent('PLAYER_AVG_ITEM_LEVEL_UPDATE', 'UpdateItemLevel')
    self:RegisterEvent('PLAYER_MONEY', 'UpdateMoney')
    self:RegisterEvent('PLAYER_XP_UPDATE', 'UpdateExperience')
    self:RegisterEvent('ACHIEVEMENT_EARNED', 'UpdateAchievementPoints')
end

---Refresh every profile section without changing other character data.
function Module:UpdateProfile()
    self:UpdateIdentity()
    self:UpdateLevel()
    self:UpdateSpecialization()
    self:UpdateGuild()
    self:UpdateItemLevel()
    self:UpdateMoney()
    self:UpdateExperience()
    self:UpdateAchievementPoints()
end

---Capture names and both localized and stable character metadata.
---@param event? string
---@param unit? string Unit supplied by UNIT_NAME_UPDATE.
function Module:UpdateIdentity(event, unit)
    if unit and unit ~= 'player' then return end
    if not db:IsCharDBReady() then return end

    local name, surname = UnitNameUnmodified('player')
    local className, class, classID = UnitClass('player')
    local raceName, race, raceID = UnitRace('player')
    local faction, factionName = UnitFactionGroup('player')
    local identity = {
        name = name,
        fullName = name,
        className = className,
        class = class,
        classID = classID,
        raceName = raceName,
        race = race,
        raceID = raceID,
        factionName = factionName,
        faction = faction,
        gender = UnitSex('player'),
    }

    if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
        -- Regional naming uses a surname, not an actual realm name.
        if surname and surname ~= '' then
            identity.surname = surname
            identity.fullName = name .. ' ' .. surname
        end
    else
        identity.realm = GetRealmName()
    end

    SetProfileSection('identity', identity)
end

---Use the level-up payload because UnitLevel can still report the previous level.
---@param event? string
---@param newLevel? number Level supplied by PLAYER_LEVEL_UP.
function Module:UpdateLevel(event, newLevel)
    if not db:IsCharDBReady() then return end
    SetProfileSection('level', newLevel or UnitLevel('player'))
end

---Capture the selected specialization, or false when none is selected.
---@param event? string
---@param unit? string|number Unit for PLAYER_SPECIALIZATION_CHANGED; talent-group events pass a group index.
function Module:UpdateSpecialization(event, unit)
    if event == 'PLAYER_SPECIALIZATION_CHANGED' and unit ~= 'player' then return end
    if not db:IsCharDBReady() then return end

    local index = C_SpecializationInfo_GetSpecialization()
    if not index or index == 0 then
        SetProfileSection('specialization', false)
        return
    end

    local id, name, _, _, role = C_SpecializationInfo_GetSpecializationInfo(index)
    if id == 0 then
        SetProfileSection('specialization', false)
    elseif id then
        SetProfileSection('specialization', { id = id, name = name, role = role })
    end
end

---Clear a departed guild, but preserve the snapshot while a known member's guild info is unavailable.
---@param event? string
---@param unit? string|boolean Unit for PLAYER_GUILD_UPDATE; roster events pass an update flag.
function Module:UpdateGuild(event, unit)
    if event == 'PLAYER_GUILD_UPDATE' and unit ~= 'player' then return end
    if not db:IsCharDBReady() then return end

    if not IsInGuild() then
        SetProfileSection('guild', false)
        return
    end

    local name, rank, rankIndex, realm = GetGuildInfo('player')
    if not name then return end
    SetProfileSection('guild', { name = name, rank = rank, rankIndex = rankIndex, realm = realm })
end

---Capture average and equipped item levels when both are available.
function Module:UpdateItemLevel()
    if not db:IsCharDBReady() then return end

    local average, equipped = GetAverageItemLevel()
    if average == nil or equipped == nil then return end
    SetProfileSection('itemLevel', { average = average, equipped = equipped })
end

---Capture carried money in copper, including zero.
function Module:UpdateMoney()
    if not db:IsCharDBReady() then return end
    SetProfileSection('money', GetMoney())
end

---Capture current experience and the next-level requirement, including zero at the level cap.
---@param event? string
---@param unit? string Unit supplied by PLAYER_XP_UPDATE.
function Module:UpdateExperience(event, unit)
    if unit and unit ~= 'player' then return end
    if not db:IsCharDBReady() then return end
    SetProfileSection('experience', { current = UnitXP('player'), max = UnitXPMax('player') })
end

---Capture the character's total achievement points.
function Module:UpdateAchievementPoints()
    if not db:IsCharDBReady() then return end
    SetProfileSection('achievementPoints', GetTotalAchievementPoints())
end
