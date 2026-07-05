-- UI.lua
-- UI logic and event handlers. References frames declared in SmartMail.xml.
--
-- Implements:
--   SmartMailUI_Init()              -- called by SmartMail_Init() after SavedVars ready
--   SmartMailUI_RefreshButtons()    -- grey out buttons based on selection / send state
--   SmartMail_UpdateProfileList()   -- redraws the 8 profile row buttons
--   SmartMail_SendAll()             -- sends every profile
--   SmartMail_SendSelected()        -- sends only the selected profile
--   SmartMail_DeleteProfile()       -- deletes selected profile (with confirm dialog)
--   SmartMail_OpenOptions()         -- TODO stub
--   SmartMailMinimap_OnLoad()       -- positions minimap button from saved angle
--   SmartMailMinimap_OnClick()      -- toggle / right-click behaviour
--   SmartMailMinimap_OnEnter()      -- tooltip
--   SmartMailMinimap_OnDragStop()   -- saves new minimap angle to SmartMailDB

-- ============================================================
-- Constants
-- ============================================================

local MINIMAP_RADIUS   = 80      -- pixels from minimap centre to button centre
local CAT_ROW_HEIGHT   = 20      -- height of each category checkbox row in editor

-- Colours for row selection highlight
local ROW_SEL_R, ROW_SEL_G, ROW_SEL_B, ROW_SEL_A = 1, 0.82, 0, 0.25

-- ============================================================
-- Module-level state
-- ============================================================

-- Scroll offset for the main profile list (set by FauxScrollFrame)
local profileListOffset = 0

-- Which profile index is currently selected in the list (nil = none)
-- Mirrors SmartMail.selectedIndex but kept local for clarity


-- ============================================================
-- SmartMailUI_Init()
-- Called by SmartMail_Init() once SavedVariables are ready.
-- ============================================================
function SmartMailUI_Init()
    -- Position the minimap button from saved angle
    SmartMailMinimap_SetAngle(SmartMailDB.minimapPos or 220)

    -- Replay persisted log entries into the log window
    if SmartMailLog_Replay then SmartMailLog_Replay() end

    -- Initial draw of the profile list
    SmartMail_UpdateProfileList()

    -- Set initial button states
    SmartMailUI_RefreshButtons()

    SmartMailMinimapButton:Show()
end


-- ============================================================
-- SmartMailUI_RefreshButtons()
-- Enables/disables buttons based on current state.
-- ============================================================
function SmartMailUI_RefreshButtons()
    local hasSelection = (SmartMail.selectedIndex ~= nil)
    local isSending    = SmartMail.isSending

    -- Send All: enabled when not sending and profiles exist
    local hasProfiles = SmartMailDB and
                        SmartMailDB.profiles and
                        table.getn(SmartMailDB.profiles) > 0

    if isSending then
        SmartMailBtnSendAll:Disable()
        SmartMailBtnSendSelected:Disable()
        SmartMailBtnDelete:Disable()
    else
        if hasProfiles then
            SmartMailBtnSendAll:Enable()
        else
            SmartMailBtnSendAll:Disable()
        end

        if hasSelection then
            SmartMailBtnSendSelected:Enable()
            SmartMailBtnDelete:Enable()
        else
            SmartMailBtnSendSelected:Disable()
            SmartMailBtnDelete:Disable()
        end
    end
end


-- ============================================================
-- SmartMail_UpdateProfileList()
-- Redraws the 8 visible row buttons based on scroll offset.
-- Called by FauxScrollFrame_OnVerticalScroll and directly.
-- ============================================================
function SmartMail_UpdateProfileList()
    local profiles = SmartMailDB and SmartMailDB.profiles or {}
    local total    = table.getn(profiles)

    -- Update scroll widget
    FauxScrollFrame_Update(
        SmartMailScrollFrame,
        total,
        SmartMail.NUM_ROWS,
        20,               -- row height in pixels
        nil, nil, nil, nil, nil, nil
    )
    profileListOffset = FauxScrollFrame_GetOffset(SmartMailScrollFrame)

    for i = 1, SmartMail.NUM_ROWS do
        local rowFrame = SmartMail.rowButtons[i]
        if not rowFrame then break end

        local profileIdx = i + profileListOffset
        local profile    = profiles[profileIdx]

        if profile then
            -- Name column
            local nameStr = profile.name or "(unnamed)"
            getglobal(rowFrame:GetName() .. "Name"):SetText(nameStr)

            -- Categories column (comma-joined, truncated)
            local cats = profile.categories or {}
            local catStr = table.concat(cats, ", ")
            if string.len(catStr) > 20 then
                catStr = string.sub(catStr, 1, 18) .. "…"
            end
            getglobal(rowFrame:GetName() .. "Categories"):SetText(catStr)

            -- Highlight if selected
            local hl = getglobal(rowFrame:GetName() .. "Highlight")
            if SmartMail.selectedIndex == profileIdx then
                hl:SetVertexColor(ROW_SEL_R, ROW_SEL_G, ROW_SEL_B, ROW_SEL_A)
                hl:Show()
            else
                hl:Hide()
            end

            -- Wire up click: selecting this row
            local capturedIdx = profileIdx
            rowFrame:SetScript("OnClick", function()
                SmartMail_SelectRow(capturedIdx)
            end)

            rowFrame:Show()
        else
            -- Empty row
            getglobal(rowFrame:GetName() .. "Name"):SetText("")
            getglobal(rowFrame:GetName() .. "Categories"):SetText("")
            getglobal(rowFrame:GetName() .. "Highlight"):Hide()
            rowFrame:SetScript("OnClick", nil)
            rowFrame:Show()  -- keep visible so the list doesn't collapse
        end
    end
end


-- ============================================================
-- SmartMail_SelectRow(profileIdx)
-- Highlights a row and stores the selection.
-- Calling again on the same row deselects it.
-- ============================================================
function SmartMail_SelectRow(profileIdx)
    if SmartMail.selectedIndex == profileIdx then
        SmartMail.selectedIndex = nil   -- toggle off
    else
        SmartMail.selectedIndex = profileIdx
    end
    SmartMail_UpdateProfileList()
    SmartMailUI_RefreshButtons()
end


-- ============================================================
-- Send handlers
-- ============================================================

function SmartMail_SendAll()
    if SmartMail.isSending then return end
    local profiles = SmartMailDB and SmartMailDB.profiles
    if not profiles or table.getn(profiles) == 0 then
        SmartMailLog_Add("No profiles defined.", "warn")
        return
    end
    SmartMailQueue_BuildAndStart(profiles)
end

function SmartMail_SendSelected()
    if SmartMail.isSending then return end
    local idx = SmartMail.selectedIndex
    if not idx then return end
    local profile = SmartMailDB.profiles[idx]
    if not profile then return end
    SmartMailQueue_BuildAndStart({ profile })
end


-- ============================================================
-- Profile editor: delete
-- ============================================================

function SmartMail_DeleteProfile()
    local idx = SmartMail.selectedIndex
    if not idx then return end
    local profile = SmartMailDB.profiles[idx]
    if not profile then return end

    -- Use Blizzard's StaticPopup for a simple yes/no
    StaticPopupDialogs["SMARTMAIL_CONFIRM_DELETE"] = {
        text          = "Delete profile |cffffff00" .. (profile.name or "?") .. "|r?",
        button1       = "Delete",
        button2       = "Cancel",
        OnAccept      = function()
            table.remove(SmartMailDB.profiles, idx)
            SmartMail.selectedIndex = nil
            SmartMail_UpdateProfileList()
            SmartMailUI_RefreshButtons()
            SmartMailLog_Add("Deleted profile '" .. (profile.name or "?") .. "'.", "info")
        end,
        timeout       = 0,
        whileDead     = false,
        hideOnEscape  = true,
    }
    StaticPopup_Show("SMARTMAIL_CONFIRM_DELETE")
end


-- ============================================================
-- SmartMail_OpenOptions()  – TODO stub
-- ============================================================

function SmartMail_OpenOptions()
    SmartMailLog_Add("Options panel is not yet implemented. Stay tuned!", "warn")
    SmartMailFrameStatusLabel:SetText("Options: coming soon.")
end


-- ============================================================
-- Minimap button helpers
-- ============================================================

-- Convert an angle (degrees) to an x,y offset from minimap centre
local function Minimap_AngleToXY(angle)
    local rad = math.rad(angle)
    return MINIMAP_RADIUS * math.cos(rad),
           MINIMAP_RADIUS * math.sin(rad)
end

-- Compute the angle from minimap centre to the current cursor position
local function Minimap_CursorAngle()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale  = UIParent:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    return math.deg(math.atan2(cy - my, cx - mx))
end

function SmartMailMinimap_SetAngle(angle)
    local x, y = Minimap_AngleToXY(angle)
    SmartMailMinimapButton:ClearAllPoints()
    SmartMailMinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    SmartMailDB.minimapPos = angle
end

function SmartMailMinimap_OnLoad(self)
    -- Will be positioned properly by SmartMailUI_Init()
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function SmartMailMinimap_OnClick(self, button)
    if button == "LeftButton" then
        if SmartMailFrame:IsShown() then
            SmartMailFrame:Hide()
        else
            SmartMailFrame:Show()
        end
    elseif button == "RightButton" then
        -- Right-click: toggle log window
        if SmartMailLogFrame:IsShown() then
            SmartMailLogFrame:Hide()
        else
            SmartMailLogFrame:Show()
        end
    end
end

function SmartMailMinimap_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff00ccffSmartMail|r")
    GameTooltip:AddLine("Left-click: toggle window", 1, 1, 1)
    GameTooltip:AddLine("Right-click: toggle log", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: reposition", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

function SmartMailMinimap_OnDragStop(self)
    self:StopMovingOrSizing()
    local angle = Minimap_CursorAngle()
    SmartMailMinimap_SetAngle(angle)
end
