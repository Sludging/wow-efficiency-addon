-- Get the addon name passed by WoW when loading the file
local addonName, addonNamespace = select(1, ...), select(2, ...)

-- Get the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Fetch shared functionality
---@type WoWEfficiency_DB
local db = WoWEfficiency:GetModule('DB')
---@type WoWEfficiency_Professions
local ProfessionsModule = WoWEfficiency:GetModule('Professions', true)
---@type WoWEfficiency_Professions_Cooldowns
local CooldownsModule = WoWEfficiency:GetModule('Professions.Cooldowns', true)
---@type WoWEfficiency_Professions_Concentration
local ConcentrationModule = WoWEfficiency:GetModule('Professions.Concentration', true)
local BankModule = WoWEfficiency:GetModule('Bank', true)
local CurrenciesModule = WoWEfficiency:GetModule('Currencies', true)

-- Upvalue global API functions
local C_Timer_After = C_Timer.After
local C_CurrencyInfo_GetCurrencyInfo = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
local _UnitLevel = UnitLevel
local _GetServerTime = GetServerTime
local statusConfig = addonNamespace.Edition.status

-- Upvalue frame utilities from Utils/Frame.lua
-- Get Frame utilities from addon namespace (loaded by Utils/Frame.lua)
local _FrameUtils  = addonNamespace.Utils and addonNamespace.Utils.Frame
local MakeCard     = _FrameUtils.MakeCard
local CardRule     = _FrameUtils.CardRule
local CardHeader   = _FrameUtils.CardHeader
local CardRow      = _FrameUtils.CardRow
local NewLayout    = _FrameUtils.NewLayout
local WIN_W        = _FrameUtils.WIN_W
local WIN_H        = _FrameUtils.WIN_H
local TITLE_H      = _FrameUtils.TITLE_H
local CONTENT_W    = _FrameUtils.CONTENT_W
local CARD_PAD     = _FrameUtils.CARD_PAD
local ROW_STEP     = _FrameUtils.ROW_STEP
local SOLID_BD     = _FrameUtils.SOLID_BD
local STATUS_ICONS = _FrameUtils.STATUS_ICONS
local GOLD         = _FrameUtils.GOLD
local GRAY         = _FrameUtils.GRAY
local WHITE        = _FrameUtils.WHITE
local R            = _FrameUtils.R
-- Define the module
-- Creates a minimap-accessible status panel that shows profession and account data
-- collection status. Each card displays what data has been collected this session,
-- using a colour-coded status system (green/yellow/red).
---@class WoWEfficiency_UI: AceModule, AceEvent-3.0, AceBucket-3.0
---@field CreateWindow fun(self)
---@field ShowWindow fun(self)
---@field HideWindow fun(self)
---@field ToggleWindow fun(self)
---@field CreateContent fun(self)
---@field UpdateContent fun(self)
---@field RefreshWindow fun(self)
---@field OnPlayerEnteringWorld fun(self)
local Module = WoWEfficiency:NewModule('UI', "AceEvent-3.0", "AceBucket-3.0")

-- ==============================================================================
-- Module state
-- ==============================================================================

local sessionStartTime = 0
local mainFrame        = nil
local scrollFrame      = nil
local scrollChild      = nil -- persists for the session; content frames are created once in CreateContent
local scrollBar        = nil
-- Stores references to every dynamic element created in CreateContent.
-- UpdateContent calls SetText / SetTexture on these rather than recreating frames.
local contentRefs = {
    legendCard     = nil,
    legendH        = 0,
    profHeading    = nil, -- "Professions" section heading frame
    levelNotice    = nil, -- shown below the selected edition's status level
    noProfNotice   = nil, -- shown when player has no tracked professions
    profSlots      = {}, -- reusable profession cards, sized by the edition configuration
    accountHeading = nil, -- "Account Data" section heading frame
    currencies     = nil, -- card frame refs for currencies
    warbank        = nil, -- card frame refs for warbank gold
    statusNotice   = nil, -- shown when no status sections are available
}

-- ==============================================================================
-- Utility function
-- ==============================================================================

local function FormatGold(value)
    local gold = value / 100 / 100
    local calc = BreakUpLargeNumbers(gold)
    local gcoin = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "
    return (calc .. gcoin)
end

-- ==============================================================================
-- Status & formatting helpers
-- ==============================================================================

local function GetStatus(ts)
    if not ts or ts == 0 then return "red" end
    if ts > sessionStartTime then return "green" end
    return "yellow"
end

local function WorstStatus(a, b)
    if a == "red" or b == "red" then return "red" end
    if a == "yellow" or b == "yellow" then return "yellow" end
    return "green"
end

local function FormatRelative(ts)
    if not ts or ts == 0 then return nil end
    local elapsed = _GetServerTime() - ts
    if elapsed < 120 then
        return "just now"
    elseif elapsed < 3600 then
        return math.floor(elapsed / 60) .. " min ago"
    elseif elapsed < 86400 then
        local h = math.floor(elapsed / 3600)
        return h .. (h == 1 and " hour ago" or " hours ago")
    elseif elapsed < 604800 then
        local d = math.floor(elapsed / 86400)
        return d .. (d == 1 and " day ago" or " days ago")
    else
        return date("%Y-%m-%d", ts)
    end
end

-- ==============================================================================
-- Static card builder
-- ==============================================================================

-- Builds the legend card that explains the three collection statuses.
-- This card's content never changes.
local function BuildLegend(parent)
    local HEADER_H = 34
    local BODY_H   = 3 * 18 + 12
    local h        = HEADER_H + BODY_H

    local card = MakeCard(parent, h)
    CardRule(card, HEADER_H)

    local title = card:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(GameFontNormal)
    title:SetText(WHITE .. "Status Guide" .. R)
    title:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -10)

    local entries = {
        { icon = STATUS_ICONS.green,  text = "Collected this session" },
        { icon = STATUS_ICONS.yellow, text = "Collected previously — reopen after login to update" },
        { icon = STATUS_ICONS.red,    text = "Not collected — follow the hint under each item" },
    }
    local y = -(HEADER_H + 8)
    for _, e in ipairs(entries) do
        local line = card:CreateFontString(nil, "OVERLAY")
        line:SetFontObject(GameFontHighlightSmall)
        line:SetText(e.icon .. "  " .. GRAY .. e.text .. R)
        line:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, y)
        line:SetPoint("RIGHT",   card, "RIGHT",   -CARD_PAD, 0)
        y = y - 18
    end

    return card, h
end

-- ==============================================================================
-- Card slot builders
-- ==============================================================================

-- These functions create the frame structure for each card with placeholder
-- content and no initial position. UpdateContent positions and populates them
-- on every refresh without allocating new frames.

-- Creates a gold section heading frame with no initial position.
local function CreateHeadingFrame(parent, text)
    local f  = CreateFrame("Frame", nil, parent)
    local fs = f:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(GameFontNormal)
    fs:SetText(GOLD .. text .. R)
    fs:SetAllPoints()
    fs:SetJustifyH("LEFT")
    return f
end

-- Creates a small notice frame with left-aligned gray text and no initial position.
local function CreateNoticeFrame(parent, text)
    local f   = CreateFrame("Frame", nil, parent)
    local lbl = f:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(GameFontHighlightSmall)
    lbl:SetText(GRAY .. text .. R)
    lbl:SetAllPoints()
    lbl:SetJustifyH("LEFT")
    f:Hide()
    return f
end

-- Creates a profession card slot with a placeholder icon and empty row content.
-- The slot is hidden until UpdateContent assigns a profession and shows it.
-- Returns a table of references to every mutable element in the card.
local function CreateProfessionSlot(parent)
    local HEADER_H = 40
    local hasWindowData = CooldownsModule or ConcentrationModule
    local h        = HEADER_H + 8 + ROW_STEP + (hasWindowData and (6 + ROW_STEP) or 0) + 10

    local card = MakeCard(parent, h)
    -- Placeholder icon; UpdateContent replaces texture and label text when a
    -- profession is assigned to this slot for the first time
    local headerIcon, headerLabel = CardHeader(card, " ", "Interface\\Icons\\INV_Misc_QuestionMark")
    CardRule(card, HEADER_H)

    local y                           = -(HEADER_H + 8)
    local nextY, basicRow, basicDet   = CardRow(card, y, "Basic Stats", "red", "")
    local windowRow, windowDet
    if hasWindowData then
        nextY, windowRow, windowDet = CardRow(card, nextY - 6, "Window Data", "red", "")
    end

    card:Hide()
    return {
        card        = card,
        h           = h,
        skillLineID = nil, -- profession currently assigned to this slot
        headerIcon  = headerIcon,
        headerLabel = headerLabel,
        basicRow    = basicRow,
        basicDet    = basicDet,
        windowRow   = windowRow,
        windowDet   = windowDet,
    }
end

-- Creates the Warbank Gold card with placeholder row content.
local function BuildWarbankCardSlot(parent)
    local HEADER_H = 36
    local h        = HEADER_H + 8 + ROW_STEP + 10

    local card = MakeCard(parent, h)
    CardHeader(card, "Warbank Gold")
    CardRule(card, HEADER_H)

    local _, row, det = CardRow(card, -(HEADER_H + 8), "Balance", "red", "")

    card:Hide()
    return { card = card, h = h, row = row, det = det }
end

-- Creates the Currencies card with placeholder row content.
local function BuildCurrenciesCardSlot(parent)
    local HEADER_H = 36
    local h        = HEADER_H + 8 + ROW_STEP + 18 + 10  -- +18 for the two-line hint in the red state

    local card = MakeCard(parent, h)
    CardHeader(card, "Currencies")
    CardRule(card, HEADER_H)

    local _, row, det = CardRow(card, -(HEADER_H + 8), "Tracked Currencies", "red", "")

    card:Hide()
    return { card = card, h = h, row = row, det = det }
end

-- ==============================================================================
-- Row content calculations
-- ==============================================================================

-- These functions compute the status and detail text for each card row from
-- the current DB state, independently of the frames that display them.

-- Returns (status, detailText) for the "Basic Stats" row of a profession card.
local function CalcBasicStatsRow(skillLineID, charDB)
    local status  = GetStatus(charDB.lastUpdated["professions"])
    local expData = (charDB.professions[skillLineID] or {})[statusConfig.professionContentKey]

    if expData and expData.maxLevel and expData.maxLevel > 0 then
        local parts = {}
        table.insert(parts, WHITE .. expData.level .. "/" .. expData.maxLevel .. " skill" .. R)
        if expData.knowledgeLevel and expData.knowledgeLevel > 0 then
            table.insert(parts, expData.knowledgeLevel .. " KP spent")
        end
        if expData.knowledgeUnspent and expData.knowledgeUnspent > 0 then
            table.insert(parts, WHITE .. expData.knowledgeUnspent .. " unspent KP" .. R)
        end
        local ts = FormatRelative(charDB.lastUpdated["professions"])
        if ts then table.insert(parts, "updated " .. ts) end
        return status, table.concat(parts, GRAY .. " · " .. R)
    else
        return status, "Auto-collected on login. Relog if missing."
    end
end

-- Returns (status, detailText) for the "Window Data" row of a profession card.
local function CalcWindowDataRow(skillLineID, profName, charDB)
    local hasCooldowns     = CooldownsModule and CooldownsModule.Constants[skillLineID] ~= nil
    local hasConcentration = ConcentrationModule and ConcentrationModule.Constants[skillLineID] ~= nil
    local windowStatus = "green"
    local bestTs       = 0

    if hasCooldowns then
        local ts = charDB.lastUpdated["cooldown-" .. skillLineID]
        windowStatus = WorstStatus(windowStatus, GetStatus(ts))
        if (ts or 0) > bestTs then bestTs = ts or 0 end
    end
    if hasConcentration then
        local ts = charDB.lastUpdated["concentration-" .. skillLineID]
        windowStatus = WorstStatus(windowStatus, GetStatus(ts))
        if (ts or 0) > bestTs then bestTs = ts or 0 end
    end

    local expData = (charDB.professions[skillLineID] or {})[statusConfig.professionContentKey]
    local detail
    if windowStatus == "red" then
        local what = (hasCooldowns and hasConcentration) and "cooldowns and concentration"
                  or (hasCooldowns and "cooldowns" or "concentration")
        detail = "Open your " .. profName .. " window to collect " .. what .. "."
    else
        local parts = {}
        if expData then
            if hasConcentration and expData.concentration and expData.concentration.amount then
                table.insert(parts, WHITE .. "Concentration " .. BreakUpLargeNumbers(expData.concentration.amount)
                    .. "/" .. BreakUpLargeNumbers(expData.concentration.maxQuantity) .. R)
            end
            if hasCooldowns and expData.cooldowns then
                local n = 0
                for _ in pairs(expData.cooldowns) do n = n + 1 end
                if n > 0 then table.insert(parts, WHITE .. n .. R .. " cooldown(s) tracked") end
            end
        end
        local ts = FormatRelative(bestTs)
        if ts then table.insert(parts, "updated " .. ts) end
        detail = #parts > 0 and table.concat(parts, GRAY .. " · " .. R) or "Data collected."
    end

    return windowStatus, detail
end

-- Returns (status, detailText) for the Warbank Gold card.
local function CalcWarbankRow(globalDB)
    local status = GetStatus(globalDB.lastUpdated["warbankGold"])
    if status == "red" then
        return status, "Open your Warbank to collect gold data."
    end
    local parts = {}
    local goldStr = globalDB.warbankGold and FormatGold(globalDB.warbankGold) or nil
    if goldStr then table.insert(parts, goldStr) end
    local ts = FormatRelative(globalDB.lastUpdated["warbankGold"])
    if ts then table.insert(parts, "updated " .. ts) end
    return status, (#parts > 0 and table.concat(parts, GRAY .. " · " .. R) or "Data collected.")
end

-- Returns (status, detailText) for the Currencies card.
local function CalcCurrenciesRow(charDB)
    local status = GetStatus(charDB.lastUpdated["currencies"])
    local TIP = "\n\nTip: open the Currency tab and click Transfer on any tracked currency to populate all your characters at once."
    if status == "red" then
        return status, "Automatically collected on login. Relog if missing." .. TIP
    end
    local parts = {}
    for currencyID, data in pairs(charDB.currencies or {}) do
        local info = C_CurrencyInfo_GetCurrencyInfo(currencyID)
        local name = info and info.name or ("Currency " .. currencyID)
        table.insert(parts, WHITE .. name .. ": " .. BreakUpLargeNumbers(data.amount or 0) .. R)
    end
    local ts = FormatRelative(charDB.lastUpdated["currencies"])
    if ts then table.insert(parts, "updated " .. ts) end
    local detail = #parts > 0 and table.concat(parts, GRAY .. " · " .. R) or "No currencies collected."
    return status, detail .. TIP
end

-- ==============================================================================
-- Content population
-- ==============================================================================

--- Creates reusable profession cards and notices when profession tracking is enabled.
--- Stores frame references in contentRefs for later refreshes.
local function CreateProfessionSection(parent)
    if not ProfessionsModule then return end

    contentRefs.profHeading = CreateHeadingFrame(parent, "Professions")
    contentRefs.noProfNotice = CreateNoticeFrame(parent,
        "No tracked professions found for this character.")
    for i = 1, addonNamespace.Edition.professions.maxSlots do
        contentRefs.profSlots[i] = CreateProfessionSlot(parent)
    end
end

--- Creates the reusable currency card when currency tracking is enabled.
local function CreateCurrenciesSection(parent)
    if not CurrenciesModule then return end
    contentRefs.currencies = BuildCurrenciesCardSlot(parent)
end

--- Creates supported account cards and their shared heading.
--- Omits the heading when neither account card is available.
local function CreateAccountSection(parent)
    CreateCurrenciesSection(parent)
    if BankModule then
        contentRefs.warbank = BuildWarbankCardSlot(parent)
    end
    if contentRefs.currencies or contentRefs.warbank then
        contentRefs.accountHeading = CreateHeadingFrame(parent, "Account Data")
    end
end

-- Creates all content frames once when the window is first opened and stores
-- their references in contentRefs. UpdateContent only repositions and updates them.
function Module:CreateContent()
    CreateProfessionSection(scrollChild)
    CreateAccountSection(scrollChild)
    if not contentRefs.profHeading and not contentRefs.accountHeading then
        contentRefs.statusNotice = CreateNoticeFrame(scrollChild,
            "No status information is available to display.")
        return
    end

    contentRefs.legendCard, contentRefs.legendH = BuildLegend(scrollChild)
    if contentRefs.profHeading or contentRefs.currencies then
        local tracking = contentRefs.profHeading and contentRefs.currencies and "Profession and currency tracking"
            or (contentRefs.profHeading and "Profession tracking" or "Currency tracking")
        contentRefs.levelNotice = CreateNoticeFrame(scrollChild,
            tracking .. " requires level " .. statusConfig.minLevel .. ".")
    end
end

--- Returns the character's tracked professions, sorted by display name.
--- Each entry contains the skill-line ID, name, icon texture, and current skill ranks.
local function GetTrackedProfessions()
    local profs = ProfessionsModule:GetTrackedProfessions()
    table.sort(profs, function(a, b) return a.name < b.name end)
    return profs
end

--- Updates and places an existing profession card, or hides an unused slot.
--- Reuses the card's header and rows without creating frames.
local function UpdateProfessionSlot(slot, prof, charDB, layout)
    if not prof then
        slot.card:Hide()
        return
    end

    if slot.skillLineID ~= prof.id then
        slot.skillLineID = prof.id
        slot.headerIcon:SetTexture(prof.texture)
        slot.headerLabel:SetText(GOLD .. prof.name .. R)
    end
    local basicStatus, basicDetail = CalcBasicStatsRow(prof.id, charDB)
    slot.basicRow:SetText(STATUS_ICONS[basicStatus] .. "  " .. WHITE .. "Basic Stats" .. R)
    slot.basicDet:SetText(GRAY .. basicDetail .. R)
    if slot.windowRow then
        local windowStatus, windowDetail = CalcWindowDataRow(prof.id, prof.name, charDB)
        slot.windowRow:SetText(STATUS_ICONS[windowStatus] .. "  " .. WHITE .. "Window Data" .. R)
        slot.windowDet:SetText(GRAY .. windowDetail .. R)
    end
    slot.card:Show()
    layout:Place(slot.card, slot.h)
end

--- Updates profession cards or shows the applicable level or no-profession notice.
--- Does nothing when the profession section was not created.
local function UpdateProfessionSection(layout, charDB, playerLevel)
    if not contentRefs.profHeading then return end
    layout:Place(contentRefs.profHeading, 20, 14)
    if playerLevel < statusConfig.minLevel then
        contentRefs.levelNotice:Show()
        layout:Place(contentRefs.levelNotice, 20, 6)
        contentRefs.noProfNotice:Hide()
        for _, slot in ipairs(contentRefs.profSlots) do slot.card:Hide() end
        return
    end

    local profs = GetTrackedProfessions()
    if #profs == 0 then
        contentRefs.noProfNotice:Show()
        layout:Place(contentRefs.noProfNotice, 20, 6)
    else
        contentRefs.noProfNotice:Hide()
    end
    for i, slot in ipairs(contentRefs.profSlots) do
        UpdateProfessionSlot(slot, profs[i], charDB, layout)
    end
end

--- Updates the currency card and applies its configured display level.
--- Shows the level notice here only when no profession section can show it.
local function UpdateCurrenciesSection(layout, charDB, playerLevel)
    local currencies = contentRefs.currencies
    if not currencies then return end
    if playerLevel < statusConfig.minLevel then
        currencies.card:Hide()
        if not contentRefs.profHeading then
            contentRefs.levelNotice:Show()
            layout:Place(contentRefs.levelNotice, 20, 6)
        end
        return
    end

    local status, detail = CalcCurrenciesRow(charDB)
    currencies.row:SetText(STATUS_ICONS[status] .. "  " .. WHITE .. "Tracked Currencies" .. R)
    currencies.det:SetText(GRAY .. detail .. R)
    currencies.card:Show()
    layout:Place(currencies.card, currencies.h)
end

--- Updates and places the existing Warbank card without a character-level restriction.
local function UpdateBankSection(layout)
    local warbank = contentRefs.warbank
    if not warbank then return end
    local status, detail = CalcWarbankRow(db:GetDB().global)
    warbank.row:SetText(STATUS_ICONS[status] .. "  " .. WHITE .. "Balance" .. R)
    warbank.det:SetText(GRAY .. detail .. R)
    warbank.card:Show()
    layout:Place(warbank.card, warbank.h)
end

--- Places the account heading and updates its supported currency and Warbank cards.
local function UpdateAccountSection(layout, charDB, playerLevel)
    if not contentRefs.accountHeading then return end
    layout:Place(contentRefs.accountHeading, 20, 14)
    UpdateCurrenciesSection(layout, charDB, playerLevel)
    UpdateBankSection(layout)
end

-- Repositions all content frames and updates their text from the current DB state.
-- Called on every refresh; no frames are created during this call.
function Module:UpdateContent()
    local layout = NewLayout(scrollChild)
    if contentRefs.statusNotice then
        contentRefs.statusNotice:Show()
        layout:Place(contentRefs.statusNotice, 20, 10)
        return
    end

    local charDB = db:GetCharDB()
    local playerLevel = _UnitLevel("player")
    layout:Place(contentRefs.legendCard, contentRefs.legendH, 10)
    if contentRefs.levelNotice then contentRefs.levelNotice:Hide() end
    UpdateProfessionSection(layout, charDB, playerLevel)
    UpdateAccountSection(layout, charDB, playerLevel)
end

-- ==============================================================================
-- Window chrome
-- ==============================================================================

function Module:CreateWindow()
    -- Main frame
    mainFrame = CreateFrame("Frame", "WowEfficiencyFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(WIN_W, WIN_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetBackdrop(SOLID_BD)
    mainFrame:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
    mainFrame:SetBackdropBorderColor(0.45, 0.37, 0.0, 1)   -- dark gold border
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing)
    mainFrame:Hide()

    -- Darker title bar region
    local titleBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  1, -1)
    titleBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(TITLE_H - 1)
    titleBar:SetBackdrop(SOLID_BD)
    titleBar:SetBackdropColor(0.05, 0.05, 0.07, 1)
    titleBar:SetBackdropBorderColor(0, 0, 0, 0)  -- no visible border; blends into main

    -- Gold rule separating title bar from content
    local titleRule = mainFrame:CreateTexture(nil, "ARTWORK")
    titleRule:SetColorTexture(0.45, 0.37, 0.0, 0.9)
    titleRule:SetHeight(1)
    titleRule:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  1,  -TITLE_H)
    titleRule:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -1, -TITLE_H)

    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFontObject(GameFontNormalLarge)
    titleText:SetText(GOLD .. "WoW Efficiency" .. R .. "  —  Data Status")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 14, 0)
    titleText:SetJustifyH("LEFT")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 4, 4)
    closeBtn:SetScript("OnClick", function() Module:HideWindow() end)

    -- Scroll frame (sits below title bar)
    scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame)
    scrollFrame:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     10,  -(TITLE_H + 6))
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, 10)
    scrollFrame:EnableMouseWheel(true)

    -- Scroll bar
    scrollBar = CreateFrame("Slider", "WowEfficiencyScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT",    scrollFrame, "TOPRIGHT",    4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(30)
    scrollBar:SetValue(0)

    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    scrollFrame:SetScript("OnScrollRangeChanged", function(self, _, yRange)
        local maxVal = math.max(0, yRange or 0)
        scrollBar:SetMinMaxValues(0, maxVal)
        if scrollBar:GetValue() > maxVal then scrollBar:SetValue(maxVal) end
    end)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local min, max = scrollBar:GetMinMaxValues()
        local new = math.min(math.max(scrollBar:GetValue() - delta * 30, min), max)
        scrollBar:SetValue(new)
    end)
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(CONTENT_W, 10)
    scrollFrame:SetScrollChild(scrollChild)

    -- Create all content frames once. UpdateContent will position and populate
    -- them on every refresh without allocating new frames.
    self:CreateContent()
end

-- ==============================================================================
-- Lifecycle
-- ==============================================================================

function Module:OnInitialize()
    local LibDBIcon = LibStub("LibDBIcon-1.0")
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("WowEfficiency", {
        type = "launcher",
        text = "WoW Efficiency",
        icon = "Interface\\Icons\\INV_DataCrystal01",
        OnClick = function(_, button)
            if button == "LeftButton" then Module:ToggleWindow() end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("WoW Efficiency")
            tt:AddLine(GRAY .. "Left-click to toggle status panel" .. R)
        end,
    })

    LibDBIcon:Register("WowEfficiency", LDB, db:GetDB().profile.minimap)
end

function Module:OnEnable()
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnPlayerEnteringWorld')
    -- Refresh only for events used by registered status collectors.
    local events = {}
    if ProfessionsModule or CooldownsModule or ConcentrationModule then
        table.insert(events, "TRADE_SKILL_LIST_UPDATE")
    end
    if BankModule then
        table.insert(events, "BANKFRAME_CLOSED")
    end
    if CurrenciesModule then
        table.insert(events, "CURRENCY_DISPLAY_UPDATE")
        table.insert(events, "ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED")
    end
    if #events > 0 then
        self:RegisterBucketEvent(events, 0.2, "RefreshWindow")
    end
end

function Module:OnPlayerEnteringWorld()
    sessionStartTime = _GetServerTime()
    self:RefreshWindow()

    if not db:GetDB().profile.hasShownWelcome then
        db:GetDB().profile.hasShownWelcome = true
        -- Delay slightly so UI has finished initial rendering
        C_Timer_After(1, function() Module:ShowWindow() end)
    end
end

function Module:RefreshWindow()
    -- Only update if the window actually exists and is currently visible to the user
    if not mainFrame or not mainFrame:IsShown() then return end
    self:UpdateContent()
end

-- ==============================================================================
-- Window management
-- ==============================================================================

function Module:ToggleWindow()
    if not mainFrame then
        self:ShowWindow()
    elseif mainFrame:IsShown() then
        self:HideWindow()
    else
        self:ShowWindow()
    end
end

function Module:ShowWindow()
    if not mainFrame then self:CreateWindow() end
    self:UpdateContent()
    mainFrame:Show()
end

function Module:HideWindow()
    if mainFrame then mainFrame:Hide() end
end

-- ==============================================================================
-- TODO
-- ==============================================================================

-- Last updated (show time since? at the very least show user time instead of server time / iso)
