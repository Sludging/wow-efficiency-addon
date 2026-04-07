-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize utility namespace
WowEfficiency.Utils = WowEfficiency.Utils or {}

-- ==============================================================================
-- Layout constants
-- ==============================================================================

-- Window dimensions
local WIN_W   = 480
local WIN_H   = 560
local TITLE_H = 44  -- height of the title bar region

-- Content area is the window width minus the left padding (10) and scrollbar gutter (30)
local CONTENT_W = WIN_W - 10 - 30

-- Spacing within and between cards
local CARD_PAD = 12  -- horizontal padding inside cards
local CARD_GAP = 8   -- vertical gap between cards
local ROW_STEP = 50  -- vertical spacing between card sub-rows

-- Shared backdrop definition used by the main window and all card frames
local SOLID_BD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- Inline texture strings for the three collection states
local STATUS_ICONS = {
    green  = "|TInterface\\RaidFrame\\ReadyCheck-Ready:13:13|t",
    yellow = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:13:13|t",
    red    = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:13:13|t",
}

-- Colour-code prefix/suffix shortcuts
local GOLD  = "|cFFFFD700"
local GRAY  = "|cFF888888"
local WHITE = "|cFFFFFFFF"
local R     = "|r"

-- ==============================================================================
-- Primitive card builders
-- ==============================================================================

-- Creates a dark styled card of fixed width and the given height.
local function MakeCard(parent, h)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(CONTENT_W, h)
    f:SetBackdrop(SOLID_BD)
    f:SetBackdropColor(0.12, 0.12, 0.15, 0.95)
    f:SetBackdropBorderColor(0.22, 0.22, 0.28, 1)
    return f
end

-- Thin horizontal rule drawn at yFromTop pixels below the card's top edge.
local function CardRule(card, yFromTop)
    local sep = card:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.28, 0.28, 0.35, 1)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  card, "TOPLEFT",  CARD_PAD, -yFromTop)
    sep:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CARD_PAD, -yFromTop)
end

-- Gold title header with an optional 22x22 icon.
-- Returns the icon Texture (or nil when no iconTex is given) and the label
-- FontString so callers can update the label and icon later.
local function CardHeader(card, title, iconTex)
    local lbl = card:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(GameFontNormal)
    lbl:SetText(GOLD .. title .. R)
    lbl:SetJustifyH("LEFT")
    local icon
    if iconTex then
        icon = card:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -9)
        icon:SetTexture(iconTex)
        lbl:SetPoint("LEFT",  icon, "RIGHT", 6, 0)
        lbl:SetPoint("RIGHT", card, "RIGHT", -CARD_PAD, 0)
    else
        lbl:SetPoint("TOPLEFT", card, "TOPLEFT", CARD_PAD, -10)
        lbl:SetPoint("RIGHT", card, "RIGHT", -CARD_PAD, 0)
    end
    return icon, lbl
end

-- A labelled sub-row with a status icon and a small detail line below it.
-- Returns the next y offset (for chaining into the next row), the row FontString
-- (label + status icon), and the detail FontString so callers can SetText on them.
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

    return yOff - ROW_STEP, row, det
end

-- ==============================================================================
-- Stacking layout helper
-- ==============================================================================

-- Tracks vertical offset within a parent frame and resizes it automatically.
-- Call Place() for each visible element in top-to-bottom order.
local function NewLayout(parent)
    local self = { parent = parent, y = 0 }

    -- Positions frame at the current offset and advances the cursor.
    -- Also resizes the parent (scroll child) to encompass all placed content.
    function self:Place(frame, h, gap)
        gap = gap or CARD_GAP
        self.y = self.y - gap
        frame:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, self.y)
        frame:SetWidth(CONTENT_W)
        frame:SetHeight(h)
        self.y = self.y - h
        self.parent:SetHeight(math.abs(self.y) + CARD_GAP)
    end

    -- Creates and positions a gold section heading label.
    -- Returns the heading Frame so the caller can store and re-place it in
    -- subsequent layout passes without re-creating it.
    function self:Heading(text, gap)
        local f  = CreateFrame("Frame", nil, self.parent)
        local fs = f:CreateFontString(nil, "OVERLAY")
        fs:SetFontObject(GameFontNormal)
        fs:SetText(GOLD .. text .. R)
        fs:SetAllPoints()
        fs:SetJustifyH("LEFT")
        self:Place(f, 20, gap or 14)
        return f
    end

    return self
end

-- ==============================================================================
-- Namespace export
-- ==============================================================================

WowEfficiency.Utils.Frame = {
    -- Primitive builders
    MakeCard     = MakeCard,
    CardRule     = CardRule,
    CardHeader   = CardHeader,
    CardRow      = CardRow,
    NewLayout    = NewLayout,
    -- Layout constants
    WIN_W        = WIN_W,
    WIN_H        = WIN_H,
    TITLE_H      = TITLE_H,
    CONTENT_W    = CONTENT_W,
    CARD_PAD     = CARD_PAD,
    CARD_GAP     = CARD_GAP,
    ROW_STEP     = ROW_STEP,
    SOLID_BD     = SOLID_BD,
    STATUS_ICONS = STATUS_ICONS,
    -- Colour helpers
    GOLD         = GOLD,
    GRAY         = GRAY,
    WHITE        = WHITE,
    R            = R,
}
