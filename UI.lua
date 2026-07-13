-- ============================================================
-- UI.lua
-- All visible UI frame creation and layout logic.
-- Controller logic (SetScript handlers) remains in the
-- original files and references frames by global name.
-- ============================================================

-- Safe debug wrapper: SmartMail_Debug may not exist yet at load
-- time since SmartMail.lua loads after UI.lua.
local function UI_Debug(msg)
    if SmartMail_Debug then SmartMail_Debug(msg) end
end

-- Spawns a full dialog window (like the Log Window)
function SmartMail_CreateDialog(name, parent, titleText, width, height)
    local frame = CreateFrame("Frame", name, parent, "SmartMailDialogTemplate")
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end
    
    local title = getglobal(name .. "Title")
    if title and titleText then
        title:SetText(titleText)
    end
    
    UI_Debug("Created Dialog: " .. name)
    return frame
end

-- Spawns a single list row
function SmartMail_CreateListRow(name, parent, width, height)
    local row = CreateFrame("Button", name, parent, "SmartMailListRowTemplate")
    
    if width then row:SetWidth(width) end
    if height then row:SetHeight(height) end
    
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    row.text = getglobal(name .. "Text")
    row.selection = getglobal(name .. "Selection")
    
    row.SetSelected = function(self, isSelected)
        if isSelected then
            self.selection:Show()
        else
            self.selection:Hide()
        end
    end
    
    UI_Debug("Created List Row: " .. name)
    return row
end

-- ============================================================
-- Main Frame Width Toggle
-- ============================================================
SmartMailUI_SideTabs = {}

function SmartMail_ToggleMainFrameWidth(expand)
    if not SmartMailMainFrame then return end
    if expand then
        SmartMailMainFrame:SetWidth(384 + 664) -- 1048 total width to match both frames combined
        for _, tab in ipairs(SmartMailUI_SideTabs) do
            tab:Hide()
        end
        if SmartMailMainFrameMinimizeButton then SmartMailMainFrameMinimizeButton:Show() end
    else
        SmartMailMainFrame:SetWidth(384) -- Original width
        if SmartMailMainFrameMinimizeButton then SmartMailMainFrameMinimizeButton:Hide() end
        for _, tab in ipairs(SmartMailUI_SideTabs) do
            if tab:GetName() == "SmartMailCustomTab" then
                if not (SmartMailDB and SmartMailDB.disableCustom) then
                    tab:Show()
                end
            else
                tab:Show()
            end
        end
    end
end

-- ============================================================
-- Custom Tab Button (the vertical "Custom" tab on the right
-- edge of the Main Frame)
-- ============================================================
function SmartMailUI_CreateSideTab(tabName, text)
    if getglobal(tabName) then return getglobal(tabName) end -- Prevent duplicate creation

    local minTab = CreateFrame("Button", tabName, UIParent)
    minTab:SetWidth(32)
    minTab:SetHeight(120)
    
    local numTabs = table.getn(SmartMailUI_SideTabs)
    local yOffset = -20 - (numTabs * 120) -- Stack each new tab under the previous
    
    minTab:SetPoint("TOPLEFT", SmartMailMainFrame, "TOPRIGHT", -5, yOffset)
    minTab:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })

    local hl = minTab:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetBlendMode("ADD")
    hl:SetAllPoints(minTab)

    local minTabText = minTab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    local fontFile, _, flags = minTabText:GetFont()
    minTabText:SetFont(fontFile, 14, flags)
    minTabText:SetPoint("CENTER", minTab, "CENTER", 1, 0)
    
    local verticalText = ""
    for i = 1, string.len(text) do
        verticalText = verticalText .. string.sub(text, i, i)
        if i < string.len(text) then
            verticalText = verticalText .. "\n"
        end
    end
    minTabText:SetText(verticalText)

    minTab:Hide()
    UI_Debug("UI: Created Side Tab " .. tabName)
    
    table.insert(SmartMailUI_SideTabs, minTab)
    return minTab
end


-- ============================================================
-- Disables (or enables) a side tab and collapses its associated frame
-- ============================================================
function SmartMailUI_DisableSideBarTab(tabName, disable, associatedFrameName)
    local tab = getglobal(tabName)
    if not tab then return end
    
    if disable then
        tab:Hide()
        if associatedFrameName then
            local frame = getglobal(associatedFrameName)
            if frame and frame:IsVisible() then
                frame:Hide()
                if SmartMail_ToggleMainFrameWidth then SmartMail_ToggleMainFrameWidth(false) end
            end
        end
    else
        local frame = associatedFrameName and getglobal(associatedFrameName)
        if not (frame and frame:IsVisible()) then
            tab:Show()
        end
    end
end

-- ============================================================
-- Custom Send Frame — All visible layout
-- Returns a table of local frame references so Custom.lua
-- can attach its controller scripts.
-- ============================================================
function SmartMailUI_CreateCustomSendFrame()
    if SmartMailCustomSendFrame then return end -- Prevent duplicate creation

    UI_Debug("UI: Creating SmartMailCustomSendFrame layout...")

    -- Main Custom Send Frame
    local frame = CreateFrame("Frame", "SmartMailCustomSendFrame", SmartMailMainFrame)
    frame:SetWidth(664)
    frame:SetHeight(512)
    -- Anchor to TOPLEFT instead of TOPRIGHT so changing Main Frame width doesn't shift it
    frame:SetPoint("TOPLEFT", SmartMailMainFrame, "TOPLEFT", 379, 15)
    frame:Hide()

    -- Header decoration
    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(300)
    header:SetHeight(64)
    header:SetPoint("TOP", frame, "TOP", 0, 12)

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("SmartMail Custom Send")

    -- "Custom List" label
    local leftListTitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    leftListTitle:SetText("Custom List")

    -- Left list frame (item list with backdrop)
    local listFrame = CreateFrame("Frame", "SmartMailCustomSendFrameListFrame", frame)
    listFrame:SetWidth(344)
    listFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -89)
    listFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 50)
    leftListTitle:SetPoint("BOTTOMRIGHT", listFrame, "TOPRIGHT", -20, 5)
    listFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    listFrame:SetBackdropColor(0, 0, 0, 0.6)

    -- Scroll frame for item list
    local scrollFrame = CreateFrame("ScrollFrame", "SmartMailCustomSendFrameListFrameScrollFrame", listFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -28, 8)

    -- Scroll child for item list
    local scrollChild = CreateFrame("Frame", "SmartMailCustomSendFrameListFrameScrollFrameScrollChild", scrollFrame)
    scrollChild:SetWidth(250)
    scrollChild:SetHeight(260)
    scrollFrame:SetScrollChild(scrollChild)

    -- Money input
    local moneyInput = CreateFrame("Frame", "SmartMailCustomMoneyInput", frame, "MoneyInputFrameTemplate")
    moneyInput:SetPoint("BOTTOM", frame, "BOTTOM", 0, 22)
    MoneyInputFrame_SetCopper(moneyInput, 0)

    local gBox = getglobal("SmartMailCustomMoneyInputGold")
    local sBox = getglobal("SmartMailCustomMoneyInputSilver")
    local cBox = getglobal("SmartMailCustomMoneyInputCopper")

    -- Add Money button
    local addMoneyBtn = CreateFrame("Button", "SmartMailCustomAddMoneyBtn", frame, "UIPanelButtonTemplate")
    addMoneyBtn:SetWidth(40)
    addMoneyBtn:SetHeight(20)
    if cBox then
        addMoneyBtn:SetPoint("LEFT", cBox, "RIGHT", 10, 0)
    else
        addMoneyBtn:SetPoint("LEFT", moneyInput, "RIGHT", 10, 0)
    end
    addMoneyBtn:SetText("Add")

    -- Clear Money button
    local clearMoneyBtn = CreateFrame("Button", "SmartMailCustomClearMoneyBtn", frame, "UIPanelButtonTemplate")
    clearMoneyBtn:SetWidth(45)
    clearMoneyBtn:SetHeight(20)
    if gBox then
        clearMoneyBtn:SetPoint("RIGHT", gBox, "LEFT", -15, 0)
    else
        clearMoneyBtn:SetPoint("RIGHT", moneyInput, "LEFT", -15, 0)
    end
    clearMoneyBtn:SetText("Clear")

    -- Send button
    local sendBtn = CreateFrame("Button", "SmartMailCustomSendBtn", frame, "UIPanelButtonTemplate")
    sendBtn:SetWidth(100)
    sendBtn:SetHeight(24)
    sendBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 40, 20)
    sendBtn:SetText("Send")

    -- Cancel button
    local cancelBtn = CreateFrame("Button", "SmartMailCustomCancelBtn", frame, "UIPanelButtonTemplate")
    cancelBtn:SetWidth(100)
    cancelBtn:SetHeight(24)
    cancelBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 20)
    cancelBtn:SetText("Cancel")

    UI_Debug("UI: SmartMailCustomSendFrame layout complete.")
end

-- ============================================================
-- Amount Entry Dialog — popup for entering specific amounts
-- ============================================================
function SmartMailUI_CreateAmountFrame()
    if SmartMailCustomAmountFrame then return end -- Prevent duplicate creation

    UI_Debug("UI: Creating SmartMailCustomAmountFrame layout...")

    local amtFrame = CreateFrame("Frame", "SmartMailCustomAmountFrame", UIParent)
    amtFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    amtFrame:SetWidth(200)
    amtFrame:SetHeight(120)
    amtFrame:SetPoint("CENTER", UIParent, "CENTER")
    amtFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    amtFrame:SetBackdropColor(0, 0, 0, 1)
    amtFrame:Hide()

    -- Title
    local amtTitle = amtFrame:CreateFontString("SmartMailCustomAmountTitle", "ARTWORK", "GameFontNormal")
    amtTitle:SetPoint("TOP", amtFrame, "TOP", 0, -15)
    amtTitle:SetText("Enter Amount")

    -- Edit box
    local amtEdit = CreateFrame("EditBox", "SmartMailCustomAmountEditBox", amtFrame, "InputBoxTemplate")
    amtEdit:SetWidth(60)
    amtEdit:SetHeight(20)
    amtEdit:SetPoint("TOP", amtTitle, "BOTTOM", 0, -15)
    amtEdit:SetNumeric(true)
    amtEdit:SetAutoFocus(true)

    -- Max button
    local amtMaxBtn = CreateFrame("Button", "SmartMailCustomAmountMaxBtn", amtFrame, "UIPanelButtonTemplate")
    amtMaxBtn:SetWidth(50)
    amtMaxBtn:SetHeight(20)
    amtMaxBtn:SetPoint("LEFT", amtEdit, "RIGHT", 5, 0)
    amtMaxBtn:SetText("Max")

    -- Accept button
    local amtOkBtn = CreateFrame("Button", "SmartMailCustomAmountOkBtn", amtFrame, "UIPanelButtonTemplate")
    amtOkBtn:SetWidth(80)
    amtOkBtn:SetHeight(24)
    amtOkBtn:SetPoint("BOTTOMLEFT", amtFrame, "BOTTOMLEFT", 15, 15)
    amtOkBtn:SetText("Accept")

    -- Cancel button
    local amtCancelBtn = CreateFrame("Button", "SmartMailCustomAmountCancelBtn", amtFrame, "UIPanelButtonTemplate")
    amtCancelBtn:SetWidth(80)
    amtCancelBtn:SetHeight(24)
    amtCancelBtn:SetPoint("BOTTOMRIGHT", amtFrame, "BOTTOMRIGHT", -15, 15)
    amtCancelBtn:SetText("Cancel")

    -- Dragging support
    amtFrame:EnableMouse(true)
    amtFrame:SetMovable(true)
    amtFrame:RegisterForDrag("LeftButton")

    -- Register for ESC close
    tinsert(UISpecialFrames, "SmartMailCustomAmountFrame")

    UI_Debug("UI: SmartMailCustomAmountFrame layout complete.")
end

-- ============================================================
-- Side Panel — recipient list, cart, and buttons
-- ============================================================
function SmartMailUI_CreateSidePanel()
    if SmartMailCustomSidePanel then return end -- Prevent duplicate creation
    if not SmartMailCustomSendFrame then return end

    UI_Debug("UI: Creating SmartMailCustomSidePanel layout...")

    local frame = SmartMailCustomSendFrame

    -- Side Panel container
    local sidePanel = CreateFrame("Frame", "SmartMailCustomSidePanel", frame)
    sidePanel:SetWidth(280)
    sidePanel:SetHeight(512)
    sidePanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, 0)

    -- Add Recipient button
    local sideAddBtn = CreateFrame("Button", "SmartMailCustomSideAddBtn", sidePanel, "UIPanelButtonTemplate")
    sideAddBtn:SetWidth(56)
    sideAddBtn:SetHeight(24)
    sideAddBtn:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 54, -40)
    sideAddBtn:SetText("Add")

    -- History dropdown (hidden, used programmatically)
    local histDropdown = CreateFrame("Frame", "SmartMailRecipientHistoryDropdown", sidePanel, "UIDropDownMenuTemplate")
    histDropdown:Hide()

    -- History button
    local sideHistBtn = CreateFrame("Button", "SmartMailCustomHistBtn", sidePanel, "UIPanelButtonTemplate")
    sideHistBtn:SetWidth(56)
    sideHistBtn:SetHeight(24)
    sideHistBtn:SetPoint("LEFT", sideAddBtn, "RIGHT", 2, 0)
    sideHistBtn:SetText("Hist")

    -- Delete button
    local sideDelBtn = CreateFrame("Button", "SmartMailCustomSideDelBtn", sidePanel, "UIPanelButtonTemplate")
    sideDelBtn:SetWidth(56)
    sideDelBtn:SetHeight(24)
    sideDelBtn:SetPoint("LEFT", sideHistBtn, "RIGHT", 2, 0)
    sideDelBtn:SetText("Delete")

    -- Recipient list frame
    local sideListFrame = CreateFrame("Frame", "SmartMailCustomRecipientListFrame", sidePanel)
    sideListFrame:SetWidth(260)
    sideListFrame:SetHeight(120)
    sideListFrame:SetPoint("TOP", sidePanel, "TOP", 0, -89)

    -- "Saved Recipients List" label
    local sideListTitle = sidePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sideListTitle:SetPoint("BOTTOMRIGHT", sideListFrame, "TOPRIGHT", -20, 5)
    sideListTitle:SetText("Saved Recipients List")

    sideListFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    sideListFrame:SetBackdropColor(0, 0, 0, 1)

    -- Recipient scroll frame
    local sideScrollFrame = CreateFrame("ScrollFrame", "SmartMailCustomRecipientScrollFrame", sideListFrame, "UIPanelScrollFrameTemplate")
    sideScrollFrame:SetPoint("TOPLEFT", sideListFrame, "TOPLEFT", 8, -8)
    sideScrollFrame:SetPoint("BOTTOMRIGHT", sideListFrame, "BOTTOMRIGHT", -28, 8)

    -- Recipient scroll child
    local sideScrollChild = CreateFrame("Frame", "SmartMailCustomRecipientScrollChild", sideScrollFrame)
    sideScrollChild:SetWidth(230)
    sideScrollChild:SetHeight(120)
    sideScrollFrame:SetScrollChild(sideScrollChild)

    -- Cart list frame
    local customListFrame = CreateFrame("Frame", "SmartMailCustomListSideFrame", sidePanel)
    customListFrame:SetWidth(260)
    customListFrame:SetPoint("TOP", sideListFrame, "BOTTOM", 0, -29)
    customListFrame:SetPoint("BOTTOM", sidePanel, "BOTTOM", 0, 50)

    -- "Cart" label
    local customListTitle = sidePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    customListTitle:SetPoint("BOTTOMRIGHT", customListFrame, "TOPRIGHT", -20, 5)
    customListTitle:SetText("Cart")

    customListFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    customListFrame:SetBackdropColor(0, 0, 0, 1)

    -- Cart scroll frame
    local customListScrollFrame = CreateFrame("ScrollFrame", "SmartMailCustomListSideScrollFrame", customListFrame, "UIPanelScrollFrameTemplate")
    customListScrollFrame:SetPoint("TOPLEFT", customListFrame, "TOPLEFT", 8, -8)
    customListScrollFrame:SetPoint("BOTTOMRIGHT", customListFrame, "BOTTOMRIGHT", -28, 8)

    -- Cart scroll child
    local customListScrollChild = CreateFrame("Frame", "SmartMailCustomListSideScrollChild", customListScrollFrame)
    customListScrollChild:SetWidth(230)
    customListScrollChild:SetHeight(272)
    customListScrollFrame:SetScrollChild(customListScrollChild)

    UI_Debug("UI: SmartMailCustomSidePanel layout complete.")
end

-- ============================================================
-- Initialize all Custom UI (call order matters)
-- ============================================================
function SmartMailUI_InitCustomFrames()
    UI_Debug("UI: Initializing all Custom Send UI frames...")
    SmartMailUI_CreateCustomSendFrame()
    SmartMailUI_CreateAmountFrame()
    SmartMailUI_CreateSidePanel()
    UI_Debug("UI: All Custom Send UI frames initialized.")
end

-- ============================================================
-- Auto-initialize on load
-- ============================================================
SmartMailUI_CreateSideTab("SmartMailCustomTab", "Custom")
SmartMailUI_InitCustomFrames()
