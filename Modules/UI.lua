-- Get the addon name passed by WoW when loading the file
local addonName = select(1, ...)

-- Get the main addon object
---@type WoWEfficiency_Addon
local WoWEfficiency = LibStub('AceAddon-3.0'):GetAddon(addonName)

-- Define the module
---@class WoWEfficiency_UI: AceModule, AceEvent-3.0
local Module = WoWEfficiency:NewModule('UI', "AceEvent-3.0")

-- ==============================================================================
-- Module state
-- ==============================================================================

local sessionStartTime = 0
local mainFrame   = nil  -- created once, persists for the session
local scrollFrame = nil
local scrollBar   = nil
local scrollChild = nil  -- recreated on each content rebuild
local LibDBIcon
local db

-- ==============================================================================
-- Layout constants
-- ==============================================================================

local MIDNIGHT_MIN_LEVEL = 78

local WIN_W     = 480
local WIN_H     = 560
local TITLE_H   = 44
-- scrollFrame: left margin 10, right margin 30 (scroll bar takes ~20)
local CONTENT_W = WIN_W - 10 - 30  -- 440

local CARD_PAD  = 12   -- horizontal inset inside cards
local CARD_GAP  = 8    -- vertical gap between cards

-- Backdrop reused for all styled frames (solid fill + 1px solid border)
local SOLID_BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

local STATUS_ICONS = {
    green  = "|TInterface\\RaidFrame\\ReadyCheck-Ready:13:13|t",
    yellow = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:13:13|t",
    red    = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:13:13|t",
}

local GOLD  = "|cFFFFD700"
local GRAY  = "|cFF888888"
local WHITE = "|cFFFFFFFF"
local R     = "|r"

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

local function FormatNumber(n)
    local s = tostring(math.floor(n))
    return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function FormatGold(copper)
    if not copper or copper == 0 then return nil end
    local gold   = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop    = copper % 100
    if gold > 0 then
        return string.format("|cFFFFD700%sg|r |cFFC0C0C0%ds|r |cFFCD7F32%dc|r", FormatNumber(gold), silver, cop)
    elseif silver > 0 then
        return string.format("|cFFC0C0C0%ds|r |cFFCD7F32%dc|r", silver, cop)
    else
        return string.format("|cFFCD7F32%dc|r", cop)
    end
end

local function FormatISO(isoStr)
    if not isoStr then return nil end
    return isoStr:gsub("T", " "):gsub("Z", "")
end

-- ==============================================================================
-- Primitive card builders
-- ==============================================================================

-- Creates a dark styled card of fixed dimensions
local function MakeCard(parent, h)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(CONTENT_W, h)
    f:SetBackdrop(SOLID_BD)
    f:SetBackdropColor(0.12, 0.12, 0.15, 0.95)
    f:SetBackdropBorderColor(0.22, 0.22, 0.28, 1)
    return f
end

-- Thin horizontal rule inside a card, drawn at yFromTop pixels below card top
local function CardRule(card, yFromTop)
    local sep = card:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.28, 0.28, 0.35, 1)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  card, "TOPLEFT",  CARD_PAD, -yFromTop)
    sep:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -yFromTop)
end

-- Gold title header with optional 22×22 icon, returns header bottom y (negative)
local function CardHeader(card, title, iconTex)
    if iconTex then
        local icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -9)
        icon:SetTexture(iconTex)

        local lbl = card:CreateFontString(nil, "OVERLAY")
        lbl:SetFontObject(GameFontNormal)
        lbl:SetText(GOLD .. title .. R)
        lbl:SetPoint("LEFT",  icon, "RIGHT", 6, 0)
        lbl:SetPoint("RIGHT", card, "RIGHT", -CARD_PAD, 0)
        lbl:SetJustifyH("LEFT")
    else
        local lbl = card:CreateFontString(nil, "OVERLAY")
        lbl:SetFontObject(GameFontNormal)
        lbl:SetText(GOLD .. title .. R)
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -10)
        lbl:SetPoint("RIGHT",   card, "RIGHT",   -CARD_PAD, 0)
        lbl:SetJustifyH("LEFT")
    end
end

-- Two-line sub-row: icon + white label, then gray detail text.
-- yOff is the y position relative to the card top (negative).
-- Returns the next yOff (accounts for both lines + a small gap).
local ROW_STEP = 50  -- vertical space each sub-row consumes

local function CardRow(card, yOff, label, status, detail)
    local row = card:CreateFontString(nil, "OVERLAY")
    row:SetFontObject(GameFontHighlight)
    row:SetText(STATUS_ICONS[status] .. "  " .. WHITE .. label .. R)
    row:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, yOff)
    row:SetPoint("RIGHT",   card, "RIGHT",   -CARD_PAD, 0)
    row:SetJustifyH("LEFT")

    local det = card:CreateFontString(nil, "OVERLAY")
    det:SetFontObject(GameFontHighlightSmall)
    det:SetText(GRAY .. detail .. R)
    det:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD + 18, yOff - 18)
    det:SetPoint("RIGHT",   card, "RIGHT",   -CARD_PAD, 0)
    det:SetJustifyH("LEFT")
    det:SetWordWrap(true)

    return yOff - ROW_STEP
end

-- ==============================================================================
-- Stacking layout helper
-- ==============================================================================

-- Tracks vertical offset within a scroll child and sizes it automatically.
local function NewLayout(parent)
    local self = { parent = parent, y = 0 }

    function self:Place(frame, h, gap)
        gap = gap or CARD_GAP
        self.y = self.y - gap
        frame:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
        frame:SetWidth(CONTENT_W)
        frame:SetHeight(h)
        self.y = self.y - h
        self.parent:SetHeight(math.abs(self.y) + CARD_GAP)
    end

    function self:Heading(text, gap)
        local f  = CreateFrame("Frame", nil, self.parent)
        local fs = f:CreateFontString(nil, "OVERLAY")
        fs:SetFontObject(GameFontNormal)
        fs:SetText(GOLD .. text .. R)
        fs:SetAllPoints()
        fs:SetJustifyH("LEFT")
        self:Place(f, 20, gap or 14)
    end

    return self
end

-- ==============================================================================
-- Card builders — one per data category
-- ==============================================================================

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

local function BuildProfCard(parent, skillLineID, profTexture, profName, charDB)
    local Cooldowns     = WoWEfficiency:GetModule('Professions.Cooldowns')
    local Concentration = WoWEfficiency:GetModule('Professions.Concentration')

    local HEADER_H = 40
    local h        = HEADER_H + 8 + ROW_STEP + 6 + ROW_STEP + 10

    local card = MakeCard(parent, h)
    CardHeader(card, profName, profTexture)
    CardRule(card, HEADER_H)

    -- Sub-row 1: Basic Stats (auto-collected on login)
    local basicStatus = GetStatus(charDB.lastUpdated["professions"])
    local basicDetail
    local expData = (charDB.professions[skillLineID] or {}).Midnight

    if expData and expData.level and expData.level > 0 then
        local parts = {}
        table.insert(parts, WHITE .. expData.level .. "/" .. expData.maxLevel .. " skill" .. R)
        if expData.knowledgeLevel and expData.knowledgeLevel > 0 then
            table.insert(parts, expData.knowledgeLevel .. " KP spent")
        end
        if expData.knowledgeUnspent and expData.knowledgeUnspent > 0 then
            table.insert(parts, WHITE .. expData.knowledgeUnspent .. " unspent KP" .. R)
        end
        local ts = FormatISO(charDB.lastUpdatedISO["professions"])
        if ts then table.insert(parts, "updated " .. ts) end
        basicDetail = table.concat(parts, GRAY .. " · " .. R)
    else
        basicDetail = "Auto-collected on login. Relog if missing."
    end

    local y = -(HEADER_H + 8)
    y = CardRow(card, y, "Basic Stats", basicStatus, basicDetail)
    y = y - 6

    -- Sub-row 2: Window Data (requires opening the profession window)
    local hasCooldowns     = Cooldowns.Constants[skillLineID] ~= nil
    local hasConcentration = Concentration.Constants[skillLineID] ~= nil

    local windowStatus = "green"
    local bestTs, bestISO = 0, nil

    if hasCooldowns then
        local ts = charDB.lastUpdated["cooldown-" .. skillLineID]
        windowStatus = WorstStatus(windowStatus, GetStatus(ts))
        if (ts or 0) > bestTs then bestTs = ts or 0; bestISO = charDB.lastUpdatedISO["cooldown-" .. skillLineID] end
    end
    if hasConcentration then
        local ts = charDB.lastUpdated["concentration-" .. skillLineID]
        windowStatus = WorstStatus(windowStatus, GetStatus(ts))
        if (ts or 0) > bestTs then bestTs = ts or 0; bestISO = charDB.lastUpdatedISO["concentration-" .. skillLineID] end
    end

    local windowDetail
    if windowStatus == "red" then
        local what = (hasCooldowns and hasConcentration) and "cooldowns and concentration"
                  or (hasCooldowns and "cooldowns" or "concentration")
        windowDetail = "Open your " .. profName .. " window to collect " .. what .. "."
    else
        local parts = {}
        if expData then
            if hasConcentration and expData.concentration and expData.concentration.amount then
                table.insert(parts, WHITE .. "Concentration " .. expData.concentration.amount
                    .. "/" .. expData.concentration.maxQuantity .. R)
            end
            if hasCooldowns and expData.cooldowns then
                local n = 0
                for _ in pairs(expData.cooldowns) do n = n + 1 end
                if n > 0 then table.insert(parts, WHITE .. n .. R .. " cooldown(s) tracked") end
            end
        end
        if bestISO then table.insert(parts, "updated " .. FormatISO(bestISO)) end
        windowDetail = #parts > 0 and table.concat(parts, GRAY .. " · " .. R) or "Data collected."
    end

    CardRow(card, y, "Window Data", windowStatus, windowDetail)

    return card, h
end

local function BuildWarbankCard(parent, globalDB)
    local HEADER_H = 36
    local h        = HEADER_H + 8 + ROW_STEP + 10

    local card = MakeCard(parent, h)
    CardHeader(card, "Warbank Gold")
    CardRule(card, HEADER_H)

    local status = GetStatus(globalDB.lastUpdated["warbankGold"])
    local detail
    if status == "red" then
        detail = "Open your Warbank to collect gold data."
    else
        local parts = {}
        local goldStr = FormatGold(globalDB.warbankGold)
        if goldStr then table.insert(parts, goldStr) end
        local ts = FormatISO(globalDB.lastUpdatedISO["warbankGold"])
        if ts then table.insert(parts, "updated " .. ts) end
        detail = #parts > 0 and table.concat(parts, GRAY .. " · " .. R) or "Data collected."
    end

    CardRow(card, -(HEADER_H + 8), "Balance", status, detail)
    return card, h
end

local function BuildCurrenciesCard(parent, charDB)
    local HEADER_H = 36
    local h        = HEADER_H + 8 + ROW_STEP + 10

    local card = MakeCard(parent, h)
    CardHeader(card, "Currencies")
    CardRule(card, HEADER_H)

    local status = GetStatus(charDB.lastUpdated["currencies"])
    local detail
    if status == "red" then
        detail = "Automatically collected on login. Relog if missing."
    else
        local parts = {}
        for currencyID, data in pairs(charDB.currencies or {}) do
            local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
            local name = info and info.name or ("Currency " .. currencyID)
            table.insert(parts, WHITE .. name .. ": " .. (data.amount or 0) .. R)
        end
        local ts = FormatISO(charDB.lastUpdatedISO["currencies"])
        if ts then table.insert(parts, "updated " .. ts) end
        detail = #parts > 0 and table.concat(parts, GRAY .. " · " .. R) or "No currencies collected."
    end

    CardRow(card, -(HEADER_H + 8), "Tracked Currencies", status, detail)
    return card, h
end

-- ==============================================================================
-- Content population
-- ==============================================================================

function Module:PopulateContent()
    local Professions = WoWEfficiency:GetModule('Professions')
    local charDB      = db:GetDB().char
    local globalDB    = db:GetDB().global
    local layout      = NewLayout(scrollChild)

    -- Status guide legend
    local legendCard, legendH = BuildLegend(scrollChild)
    layout:Place(legendCard, legendH, 10)

    -- ---- Professions --------------------------------------------------------
    layout:Heading("Professions")

    local playerLevel = UnitLevel("player")
    if playerLevel < MIDNIGHT_MIN_LEVEL then
        local notice = CreateFrame("Frame", nil, scrollChild)
        local lbl = notice:CreateFontString(nil, "OVERLAY")
        lbl:SetFontObject(GameFontHighlightSmall)
        lbl:SetText(GRAY .. "Profession and currency tracking requires level "
            .. MIDNIGHT_MIN_LEVEL .. " (Midnight content)." .. R)
        lbl:SetAllPoints()
        lbl:SetJustifyH("LEFT")
        layout:Place(notice, 20, 6)
    else
        local prof1, prof2 = GetProfessions()
        local profs = {}
        for _, idx in pairs({ prof1, prof2 }) do
            if idx then
                local profName, profTex, _, _, _, _, skillLineID = GetProfessionInfo(idx)
                if skillLineID and Professions.Constants[skillLineID] then
                    table.insert(profs, { id = skillLineID, name = profName, texture = profTex })
                end
            end
        end
        table.sort(profs, function(a, b) return a.name < b.name end)

        if #profs == 0 then
            local notice = CreateFrame("Frame", nil, scrollChild)
            local lbl = notice:CreateFontString(nil, "OVERLAY")
            lbl:SetFontObject(GameFontHighlightSmall)
            lbl:SetText(GRAY .. "No tracked professions found for this character." .. R)
            lbl:SetAllPoints()
            lbl:SetJustifyH("LEFT")
            layout:Place(notice, 20, 6)
        else
            for _, prof in ipairs(profs) do
                local card, h = BuildProfCard(scrollChild, prof.id, prof.texture, prof.name, charDB)
                layout:Place(card, h)
            end
        end

        -- Currencies (only relevant at Midnight level)
        layout:Heading("Account Data")
        local currCard, currH = BuildCurrenciesCard(scrollChild, charDB)
        layout:Place(currCard, currH)
    end

    -- ---- Account Data -------------------------------------------------------
    -- Warbank is account-wide, always shown regardless of level
    if playerLevel < MIDNIGHT_MIN_LEVEL then
        layout:Heading("Account Data")
    end
    local bankCard, bankH = BuildWarbankCard(scrollChild, globalDB)
    layout:Place(bankCard, bankH)
end

-- ==============================================================================
-- Window chrome (created once per session)
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

    -- Title text — created on titleBar so it renders above titleBar's own backdrop
    local titleText = titleBar:CreateFontString(nil, "OVERLAY")
    titleText:SetFontObject(GameFontNormalLarge)
    titleText:SetText(GOLD .. "WoW Efficiency" .. R .. "  —  Data Status")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 14, 0)
    titleText:SetJustifyH("LEFT")

    -- Standard WoW close button (no extra rectangle, no status bar)
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 4, 4)
    closeBtn:SetScript("OnClick", function() Module:HideWindow() end)

    -- Scroll frame (sits below title bar)
    scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame)
    scrollFrame:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     10,  -(TITLE_H + 6))
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, 10)
    scrollFrame:EnableMouseWheel(true)

    -- WoW-native scroll bar
    scrollBar = CreateFrame("Slider", "WowEfficiencyScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT",    scrollFrame, "TOPRIGHT",    4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(30)
    scrollBar:SetValue(0)

    -- Scroll bar drives the scroll position; scroll frame reports range changes
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
end

-- ==============================================================================
-- Content rebuild
-- ==============================================================================

function Module:RebuildContent()
    -- Discard previous scroll child (its child frames go with it)
    if scrollChild then scrollChild:Hide() end

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(CONTENT_W, 600)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame:SetVerticalScroll(0)
    scrollBar:SetValue(0)

    self:PopulateContent()
end

-- ==============================================================================
-- Lifecycle
-- ==============================================================================

function Module:OnInitialize()
    db = WoWEfficiency:GetModule('DB')
    LibDBIcon = LibStub("LibDBIcon-1.0")

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
    sessionStartTime = GetServerTime()
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnPlayerEnteringWorld')
    -- Refresh open window whenever data modules write new data.
    -- UI.lua loads after Cooldowns, Concentration, and Bank, so their handlers
    -- run first — data is written before RefreshWindow executes.
    self:RegisterEvent('TRADE_SKILL_LIST_UPDATE', 'RefreshWindow')
    self:RegisterEvent('BANKFRAME_CLOSED',        'RefreshWindow')
    self:RegisterEvent('CURRENCY_DISPLAY_UPDATE', 'RefreshWindow')
end

function Module:OnPlayerEnteringWorld()
    sessionStartTime = GetServerTime()
    self:RefreshWindow()

    if not db:GetDB().profile.hasShownWelcome then
        db:GetDB().profile.hasShownWelcome = true
        C_Timer.After(1, function() Module:ShowWindow() end)
    end
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
    self:RebuildContent()
    mainFrame:Show()
end

function Module:HideWindow()
    if mainFrame then mainFrame:Hide() end
end

function Module:RefreshWindow()
    if not mainFrame or not mainFrame:IsShown() then return end
    self:RebuildContent()
end
