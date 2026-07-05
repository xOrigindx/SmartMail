-- Layout.lua
-- Visual drag-and-drop layout editor for the SmartMail main frame.
--
-- Usage (slash commands added to SmartMail.lua):
--   /sm layout          toggle layout mode on/off
--   /sm layout reset    clear all saved positions (reload UI to restore XML defaults)
--   /sm layout export   print XML-ready <Anchor> lines to chat
--
-- How it works:
--   Enter mode  → semi-transparent coloured overlays appear over every tracked element.
--   Drag overlay → the real frame follows it; offset relative to SmartMailFrame is saved.
--   Done button  → overlays removed; positions live in SmartMailDB.layout.
--   On next load → SmartMailLayout_Apply() re-anchors every element from the saved table.
--
-- Position math:
--   All positions are stored as TOPLEFT offsets relative to SmartMailFrame's TOPLEFT.
--   x = element:GetLeft() - SmartMailFrame:GetLeft()   (positive = rightward)
--   y = element:GetTop()  - SmartMailFrame:GetTop()    (negative = downward)
--   These values map 1-to-1 with WoW XML anchor x/y attributes.

SmartMailLayout = SmartMailLayout or {}

-- ============================================================
-- Elements tracked by the layout editor.
-- Must all be named global frames that are children of SmartMailFrame.
-- ============================================================

local ELEMENTS = {
    "SmartMailScrollFrame",
    "SmartMailBtnSendAll",
    "SmartMailBtnSendSelected",
    "SmartMailBtnNew",
    "SmartMailBtnEdit",
    "SmartMailBtnDelete",
    "SmartMailBtnOptions",
    "SmartMailBtnOpenLog",
    "SmartMailFrameStatusLabel",
    "SmartMailFrameProfilesLabel",
    "SmartMailDivider1",
    "SmartMailDivider2",
}

-- Distinct colours per element so overlapping handles are easy to tell apart
local COLOURS = {
    {1, 0.6, 0,    0.25},   -- orange
    {0, 0.8, 1,    0.25},   -- cyan
    {0, 1,   0.4,  0.25},   -- green
    {1, 0.2, 0.6,  0.25},   -- pink
    {0.8, 1, 0,    0.25},   -- yellow-green
    {0.6, 0, 1,    0.25},   -- purple
    {1,   1, 0,    0.25},   -- yellow
    {0,   1, 1,    0.25},   -- teal
    {1, 0.4, 0.4,  0.25},   -- red
    {0.4, 0.4, 1,  0.25},   -- blue
    {1, 0.8, 0.4,  0.25},   -- gold
    {0.4, 1, 0.8,  0.25},   -- mint
}

-- ============================================================
-- Module state
-- ============================================================

local active   = false
local overlays = {}
local toolbar  = nil


-- ============================================================
-- Position helpers
-- ============================================================

-- Returns TOPLEFT offset of `frame` relative to `parent` in UI units.
local function GetTopleftOffset(frame, parent)
    local x = (frame:GetLeft()  or 0) - (parent:GetLeft() or 0)
    local y = (frame:GetTop()   or 0) - (parent:GetTop()  or 0)
    return math.floor(x + 0.5), math.floor(y + 0.5)
end


-- ============================================================
-- Persist / Apply / Reset / Export
-- ============================================================

local function Layout_SavePos(frameName, x, y)
    if not SmartMailDB then return end
    if not SmartMailDB.layout then SmartMailDB.layout = {} end
    SmartMailDB.layout[frameName] = { x = x, y = y }
end

-- SmartMailLayout_Apply()
-- Called by SmartMailUI_Init() on every load.
-- Repositions all elements that have a saved layout entry.
function SmartMailLayout_Apply()
    local layout = SmartMailDB and SmartMailDB.layout
    if not layout then return end

    for frameName, pos in pairs(layout) do
        local frame = getglobal(frameName)
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", SmartMailFrame, "TOPLEFT", pos.x, pos.y)
        end
    end
end

-- SmartMailLayout_Reset()
-- Wipes all saved positions.  Requires /reload to restore XML defaults.
function SmartMailLayout_Reset()
    if SmartMailDB then SmartMailDB.layout = {} end
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ccffSmartMail|r: Layout positions cleared. " ..
        "Type |cffffff00/reload|r to restore XML defaults.",
        1, 1, 0.5
    )
end

-- SmartMailLayout_Export()
-- Prints each saved position as a formatted XML <Anchor> snippet to chat.
-- Copy-paste these into SmartMail.xml to hard-code the layout permanently.
function SmartMailLayout_Export()
    local layout = SmartMailDB and SmartMailDB.layout
    if not layout or not next(layout) then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccffSmartMail|r: No layout saved yet. Use |cffffff00/sm layout|r first.",
            1, 0.5, 0.5)
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ccffSmartMail Layout Export|r  (paste into SmartMail.xml):",
        1, 1, 1)

    for frameName, pos in pairs(layout) do
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffffff00<!-- " .. frameName .. " -->|r",
            0.9, 0.9, 0.4)
        DEFAULT_CHAT_FRAME:AddMessage(
            string.format(
                '|cff88ccff<Anchor point="TOPLEFT" relativePoint="TOPLEFT" x="%d" y="%d"/>|r',
                pos.x, pos.y),
            0.6, 0.9, 1)
    end

    DEFAULT_CHAT_FRAME:AddMessage(
        "── end of export ──",
        0.5, 0.5, 0.5)
end


-- ============================================================
-- Overlay factory
-- ============================================================

local function CreateOverlay(targetFrame, colourIndex)
    local name    = targetFrame:GetName()
    local col     = COLOURS[colourIndex] or COLOURS[1]
    local ovName  = "SmartMailLayoutOv_" .. name

    -- Hide a stale copy if one exists from a previous toggle
    -- (SetParent(nil) is invalid in 1.12.1 – just hide it; CreateFrame
    -- below will return the same global and reinitialise it)
    local existing = getglobal(ovName)
    if existing then existing:Hide() end

    local ov = CreateFrame("Frame", ovName, UIParent)
    ov:SetFrameStrata("TOOLTIP")
    ov:SetWidth(math.max(targetFrame:GetWidth(),  8))
    ov:SetHeight(math.max(targetFrame:GetHeight(), 8))
    ov:SetPoint("TOPLEFT", targetFrame, "TOPLEFT", 0, 0)
    ov:SetMovable(true)
    ov:EnableMouse(true)
    ov:RegisterForDrag("LeftButton")

    ov:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 8,
        insets   = {left = 2, right = 2, top = 2, bottom = 2},
    })
    ov:SetBackdropColor(col[1], col[2], col[3], col[4])
    ov:SetBackdropBorderColor(col[1], col[2], col[3], 1)

    -- Short label (strip the "SmartMail" prefix for readability)
    local short  = string.gsub(name, "SmartMail", "")
    local label  = ov:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetAllPoints()
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetText(short)

    ov.targetFrame = targetFrame

    -- Drag start
    ov:SetScript("OnDragStart", function()
        this:StartMoving()
    end)

    -- Drag stop: snap real frame to where the overlay landed, then save
    ov:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()

        local x, y    = GetTopleftOffset(this, SmartMailFrame)
        local target  = this.targetFrame

        target:ClearAllPoints()
        target:SetPoint("TOPLEFT", SmartMailFrame, "TOPLEFT", x, y)

        -- Re-sync the overlay to sit flush on top of the target
        this:ClearAllPoints()
        this:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)

        Layout_SavePos(target:GetName(), x, y)

        -- GameTooltip:IsOwned() does not exist in 1.12.1 – just hide it
        GameTooltip:Hide()
    end)

    -- Tooltip: show frame name + current offset on hover
    ov:SetScript("OnEnter", function()
        local x, y = GetTopleftOffset(this.targetFrame, SmartMailFrame)
        GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
        GameTooltip:AddLine("|cffffff00" .. this.targetFrame:GetName() .. "|r")
        GameTooltip:AddLine(string.format("x = %d   y = %d", x, y), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to reposition", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    ov:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return ov
end


-- ============================================================
-- Toolbar  (Done / Export / Reset)
-- ============================================================

local function Toolbar_Build()
    local bar = CreateFrame("Frame", "SmartMailLayoutToolbar", UIParent)
    bar:SetWidth(330)
    bar:SetHeight(40)
    bar:SetFrameStrata("TOOLTIP")
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() this:StartMoving() end)
    bar:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)

    bar:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true,
        tileSize = 32,
        edgeSize = 16,
        insets   = {left = 4, right = 4, top = 4, bottom = 4},
    })

    -- Title
    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", bar, "LEFT", 10, 0)
    title:SetText("|cffff9900Layout Mode|r")

    -- Done button
    -- Wrap all callbacks in lambdas so they resolve the global function
    -- at call-time, not at Toolbar_Build() definition-time.
    local btnDone = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    btnDone:SetWidth(70)
    btnDone:SetHeight(22)
    btnDone:SetPoint("RIGHT", bar, "RIGHT", -145, 0)
    btnDone:SetText("Done")
    btnDone:SetScript("OnClick", function() SmartMailLayout_Exit() end)

    -- Export button
    local btnExport = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    btnExport:SetWidth(70)
    btnExport:SetHeight(22)
    btnExport:SetPoint("LEFT", btnDone, "RIGHT", 4, 0)
    btnExport:SetText("Export")
    btnExport:SetScript("OnClick", function() SmartMailLayout_Export() end)

    -- Reset button
    local btnReset = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    btnReset:SetWidth(60)
    btnReset:SetHeight(22)
    btnReset:SetPoint("LEFT", btnExport, "RIGHT", 4, 0)
    btnReset:SetText("Reset")
    btnReset:SetScript("OnClick", function()
        SmartMailLayout_Reset()
        SmartMailLayout_Exit()
    end)

    return bar
end


-- ============================================================
-- Enter / Exit layout mode
-- ============================================================

function SmartMailLayout_Enter()
    if active then return end
    active = true

    -- Ensure main frame is visible so elements have screen positions
    SmartMailFrame:Show()

    -- Build overlays
    overlays = {}
    for i, elName in ipairs(ELEMENTS) do
        local frame = getglobal(elName)
        if frame then
            local ov = CreateOverlay(frame, i)
            table.insert(overlays, ov)
        end
    end

    -- Build (or show) toolbar above the main frame
    if not toolbar then toolbar = Toolbar_Build() end
    toolbar:ClearAllPoints()
    toolbar:SetPoint("BOTTOM", SmartMailFrame, "TOP", 0, 6)
    toolbar:Show()

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ccffSmartMail Layout Mode|r: " ..
        "Drag the coloured handles to reposition elements. " ..
        "Click |cffffff00Done|r to finish, |cffffff00Export|r for XML.",
        1, 1, 1)
end

function SmartMailLayout_Exit()
    if not active then return end
    active = false

    for _, ov in ipairs(overlays) do
        ov:Hide()
    end
    overlays = {}

    if toolbar then toolbar:Hide() end

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ccffSmartMail|r: Layout saved. " ..
        "Use |cffffff00/sm layout export|r to get XML anchors, " ..
        "or |cffffff00/sm layout reset|r to start over.",
        1, 1, 1)
end

function SmartMailLayout_Toggle()
    if active then
        SmartMailLayout_Exit()
    else
        SmartMailLayout_Enter()
    end
end
