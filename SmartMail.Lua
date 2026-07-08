SmartMail = {
    isBusy      = false,
    lookup      = {},
    db          = nil,
    log         = nil,
    debug       = true,
}
local orig_errorhandler = geterrorhandler()
seterrorhandler(function(msg)
    if msg and string.find(tostring(msg), "SmartMail") then
        if SmartMail_Debug then
            SmartMail_Debug("|cffff0000[LUA ERROR]|r " .. tostring(msg))
        end
    end
    if orig_errorhandler then
        orig_errorhandler(msg)
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "SmartMail" then
        if not SmartMailDB then SmartMailDB = { profiles = {} } end
        if not SmartMailDB.profiles then SmartMailDB.profiles = {} end
        if not SmartMailDebugLog then SmartMailDebugLog = {} end
        if not SmartMailDebugLog.debugLog then SmartMailDebugLog.debugLog = {} end
        
        -- Backups
        if not SmartMailDB_PerChar then SmartMailDB_PerChar = { profiles = {} } end
        if not SmartMailDB_PerChar.profiles then SmartMailDB_PerChar.profiles = {} end
        if not SmartMailDebugLog_PerChar then SmartMailDebugLog_PerChar = {} end
        if not SmartMailDebugLog_PerChar.debugLog then SmartMailDebugLog_PerChar.debugLog = {} end
    elseif event == "MAIL_SHOW" or event == "MAIL_CLOSED" then
        if event == "MAIL_SHOW" then
            if SmartMailMainFrame then SmartMailMainFrame:Show() end
        end
        if SmartMail_UpdateActionButtons then SmartMail_UpdateActionButtons() end
        if event == "MAIL_CLOSED" and SmartMailMainFrame and SmartMailMainFrame:IsVisible() then
            SmartMailMainFrame:Hide()
        end
    end
end)

function SmartMail_CreateListRow(name, parent, width, height)
    local row = CreateFrame("Button", name, parent, "SmartMailListRowTemplate")
    
    if width then row:SetWidth(width) end
    if height then row:SetHeight(height) end
    
    row.text = getglobal(name .. "Text")
    row.selection = getglobal(name .. "Selection")
    
    row.SetSelected = function(self, isSelected)
        if isSelected then
            self.selection:Show()
        else
            self.selection:Hide()
        end
    end
    
    return row
end

function SmartMail_Debug(msg, category)
    if SmartMail.debug then
        local msgStr = tostring(msg)
        if not category then
            local lowerMsg = string.lower(msgStr)
            if string.find(lowerMsg, "soulbound") then
                category = "Soulbound"
            elseif string.find(lowerMsg, "sendall") or string.find(lowerMsg, "send all") or string.find(lowerMsg, "confirm") or string.find(lowerMsg, "custom") or string.find(lowerMsg, "engine:") or string.find(lowerMsg, "smartmailengine") or string.find(lowerMsg, "mail_") or string.find(lowerMsg, "starting send") or string.find(lowerMsg, "routing") then
                category = "Send"
            elseif string.find(lowerMsg, "scan") or string.find(lowerMsg, "bridge:") or string.find(lowerMsg, "queue") or string.find(lowerMsg, "getpt") then
                category = "ScanInventory"
            elseif string.find(lowerMsg, "inbox") or string.find(lowerMsg, "openall") or string.find(lowerMsg, "open all") then
                category = "OpenAll"
            else
                category = "General"
            end
        end

        local formattedMsg = "|cff00ffff[SmartMail]|r " .. msgStr
        DEFAULT_CHAT_FRAME:AddMessage(formattedMsg)
        
        local ms = string.format(".%03d", math.mod(GetTime() * 1000, 1000))
        local timeStr = date("[%H:%M:%S") .. ms .. "] "
        local logMsg = timeStr .. msgStr
        
        if SmartMail and SmartMail.isStressTest then
            if not SmartMailStressLog then SmartMailStressLog = {} end
            local charName = UnitName("player") or "Unknown"
            table.insert(SmartMailStressLog, timeStr .. "[" .. charName .. "] [" .. category .. "] " .. msgStr)
        else
            -- Backup & Categories
            if not SmartMailDebugLog_PerChar then SmartMailDebugLog_PerChar = {} end
            if not SmartMailDebugLog_PerChar.debugLog then SmartMailDebugLog_PerChar.debugLog = {} end
            table.insert(SmartMailDebugLog_PerChar.debugLog, 1, "["..category.."] " .. logMsg)
            
            if not SmartMailDebugLog_PerChar[category] then SmartMailDebugLog_PerChar[category] = {} end
            table.insert(SmartMailDebugLog_PerChar[category], 1, logMsg)
        end
        
        -- Trim logs to prevent massive file sizes (max 5000)
        if table.getn(SmartMailDebugLog_PerChar.debugLog) > 5000 then
            table.remove(SmartMailDebugLog_PerChar.debugLog)
        end

        if table.getn(SmartMailDebugLog_PerChar[category]) > 1000 then
            table.remove(SmartMailDebugLog_PerChar[category])
        end
        
        -- Update UI Debug Window
        if SmartMailDebugFrame and SmartMailDebugFrame:IsVisible() then
            if SmartMail_UpdateDebugList then
                SmartMail_UpdateDebugList()
            end
        end
    end
end

SmartMail.debugCategories = { "debugLog", "Send", "ScanInventory", "OpenAll", "Soulbound", "General" }
SmartMail.currentDebugCategoryIndex = 1

function SmartMailDebugCategoryDropDown_Initialize()
    local info = {}
    for i, cat in ipairs(SmartMail.debugCategories) do
        local dispName = cat
        if cat == "debugLog" then dispName = "ALL" end
        info.text = dispName
        info.value = i
        info.func = SmartMailDebugCategoryDropDown_OnClick
        info.checked = (SmartMail.currentDebugCategoryIndex == i)
        UIDropDownMenu_AddButton(info)
    end
end

function SmartMailDebugCategoryDropDown_OnClick()
    SmartMail.currentDebugCategoryIndex = this.value
    UIDropDownMenu_SetSelectedValue(SmartMailDebugCategoryDropDown, this.value)
    UIDropDownMenu_SetText(this:GetText(), SmartMailDebugCategoryDropDown)
    
    SmartMail.debugSelection = {}
    SmartMail.lastDebugClick = nil
    
    local scrollFrame = SmartMailDebugFrameContentFrameScrollFrame
    if scrollFrame then
        FauxScrollFrame_SetOffset(scrollFrame, 0)
        scrollFrame:SetVerticalScroll(0)
    end
    
    SmartMail_UpdateDebugList()
end

function SmartMail_OpenCopyFrame()
    local cat = "debugLog"
    if SmartMail.currentDebugCategoryIndex and SmartMail.debugCategories then
        cat = SmartMail.debugCategories[SmartMail.currentDebugCategoryIndex] or "debugLog"
    end
    
    local fullText = ""
    local hasSelection = false
    
    if not SmartMail then SmartMail = {} end
    if not SmartMail.debugSelection then SmartMail.debugSelection = {} end
    
    for _, selected in pairs(SmartMail.debugSelection) do
        if selected then hasSelection = true break end
    end
    
    local logTable = (SmartMailDebugLog_PerChar and SmartMailDebugLog_PerChar[cat]) or {}
    
    if SmartMailCopyFrameText then
        SmartMailCopyFrameText:SetMaxLetters(0)
        SmartMailCopyFrameText:SetText("")
    end
    
    SmartMail.copyQueue = {}
    for i = table.getn(logTable), 1, -1 do
        if not hasSelection or SmartMail.debugSelection[i] then
            table.insert(SmartMail.copyQueue, logTable[i])
        end
    end
    
    SmartMailCopyFrame:Show()
end

function SmartMailCopyFrame_OnUpdate()
    if SmartMail.copyQueue and table.getn(SmartMail.copyQueue) > 0 then
        for i = 1, 5 do
            if table.getn(SmartMail.copyQueue) > 0 then
                local line = table.remove(SmartMail.copyQueue, 1)
                if SmartMailCopyFrameText then
                    SmartMailCopyFrameText:Insert(line .. "\n")
                end
            else
                break
            end
        end
        -- Do not auto-highlight, so the user doesn't accidentally overwrite it
        if table.getn(SmartMail.copyQueue) == 0 and SmartMailCopyFrameText then
            -- Done streaming
        end
    end
end

SmartMail.debugSelection = {}
SmartMail.lastDebugClick = nil

function SmartMail_UpdateDebugList()
    local cat = "debugLog"
    if SmartMail.currentDebugCategoryIndex and SmartMail.debugCategories then
        cat = SmartMail.debugCategories[SmartMail.currentDebugCategoryIndex] or "debugLog"
    end
    local numItems = 0
    if SmartMailDebugLog_PerChar and SmartMailDebugLog_PerChar[cat] then
        numItems = table.getn(SmartMailDebugLog_PerChar[cat])
    end
    local scrollFrame = SmartMailDebugFrameContentFrameScrollFrame
    if not scrollFrame then return end
    
    FauxScrollFrame_Update(scrollFrame, numItems, 14, 16)
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    
    if not scrollFrame.buttons then scrollFrame.buttons = {} end
    
    for i = 1, 14 do
        local index = offset + i
        local btn = scrollFrame.buttons[i]
        
        if not btn then
            btn = SmartMail_CreateListRow("SmartMailDebugRow" .. i, SmartMailDebugFrameContentFrame, 400, 16)
            
            if i == 1 then
                btn:SetPoint("TOPLEFT", SmartMailDebugFrameContentFrame, "TOPLEFT", 4, -4)
            else
                btn:SetPoint("TOPLEFT", scrollFrame.buttons[i-1], "BOTTOMLEFT", 0, 0)
            end
            
            btn.text:SetFontObject("GameFontHighlightSmall")
            btn.text:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
            
            btn:SetScript("OnClick", function()
                local clickedIdx = this.logIndex
                if not clickedIdx then return end
                
                if IsShiftKeyDown() and SmartMail.lastDebugClick then
                    local startIdx = math.min(SmartMail.lastDebugClick, clickedIdx)
                    local endIdx = math.max(SmartMail.lastDebugClick, clickedIdx)
                    for j = startIdx, endIdx do
                        SmartMail.debugSelection[j] = true
                    end
                else
                    if SmartMail.debugSelection[clickedIdx] then
                        SmartMail.debugSelection[clickedIdx] = nil
                    else
                        SmartMail.debugSelection[clickedIdx] = true
                    end
                    SmartMail.lastDebugClick = clickedIdx
                end
                SmartMail_UpdateDebugList()
            end)
            
            table.insert(scrollFrame.buttons, btn)
        end
        
        btn.logIndex = index
        
        if index <= numItems then
            local cat = "debugLog"
            if SmartMail.currentDebugCategoryIndex and SmartMail.debugCategories then
                cat = SmartMail.debugCategories[SmartMail.currentDebugCategoryIndex] or "debugLog"
            end
            local textStr = SmartMailDebugLog_PerChar[cat][index]
            if textStr then
                btn.text:SetText(tostring(index) .. ". " .. textStr)
                if SmartMail.debugSelection[index] then
                    btn:SetSelected(true)
                else
                    btn:SetSelected(false)
                end
            else
                btn:SetSelected(false)
            end
            btn:Show()
        else
            btn:Hide()
        end
    end
end

-- Slash Command Logic
SLASH_SMARTMAIL1 = "/smartmail"
SLASH_SMARTMAIL2 = "/sm"
SlashCmdList["SMARTMAIL"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "clear" then
        if SmartMailDebugLog then SmartMailDebugLog.debugLog = {} end
        if SmartMailDebugLog_PerChar then SmartMailDebugLog_PerChar.debugLog = {} end
        if SmartMail then SmartMail.debugSelection = {} SmartMail.lastDebugClick = nil end
        if SmartMailDebugFrame and SmartMailDebugFrame:IsVisible() then
            SmartMail_UpdateDebugList()
        end
        DEFAULT_CHAT_FRAME:AddMessage("SmartMail: Debug logs cleared.")
    elseif msg == "scan" then
        SmartMail_ScanInventory()
    elseif msg == "pttest" then
        DEFAULT_CHAT_FRAME:AddMessage("PT Test:")
        DEFAULT_CHAT_FRAME:AddMessage("PeriodicTableEmbed: " .. type(PeriodicTableEmbed))
        if PeriodicTableEmbed and type(PeriodicTableEmbed.GetInstance) == "function" then
            local inst = PeriodicTableEmbed:GetInstance("1") or PeriodicTableEmbed:GetInstance()
            DEFAULT_CHAT_FRAME:AddMessage("  GetInstance(): " .. type(inst))
            if type(inst) == "table" then
                DEFAULT_CHAT_FRAME:AddMessage("  GetSetTable: " .. type(inst.GetSetTable))
                DEFAULT_CHAT_FRAME:AddMessage("  IterateSet: " .. type(inst.IterateSet))
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("PeriodicTable: " .. type(PeriodicTable))
        if type(PeriodicTable) == "table" then
            DEFAULT_CHAT_FRAME:AddMessage("  GetSetTable: " .. type(PeriodicTable.GetSetTable))
            DEFAULT_CHAT_FRAME:AddMessage("  IterateSet: " .. type(PeriodicTable.IterateSet))
        end
    elseif msg == "debug on" then
        SmartMail.debug = true
        DEFAULT_CHAT_FRAME:AddMessage("SmartMail Debug: ON")
    elseif msg == "debug off" then
        SmartMail.debug = false
        DEFAULT_CHAT_FRAME:AddMessage("SmartMail Debug: OFF")
    elseif msg == "debug" then
        if SmartMailDebugFrame:IsVisible() then
            SmartMailDebugFrame:Hide()
        else
            SmartMailDebugFrame:Show()
        end
    else
        if SmartMailMainFrame:IsVisible() then
            SmartMailMainFrame:Hide()
        else
            SmartMailMainFrame:Show()
        end
    end
end

function SmartMail_ScanInventory()
    SmartMail_Debug("SmartMail_ScanInventory called...")
    if not SmartMailDebugLog then SmartMailDebugLog = { sessions = {} } end
    if not SmartMailDebugLog.debugScan then SmartMailDebugLog.debugScan = {} end
    
    local success, map = pcall(function() return Bridge:GetAllCategoryItems() end)
    if not success then
        SmartMail_Debug("Error in Bridge:GetAllCategoryItems(): " .. tostring(map))
        return
    end
    
    local scanResults = {}
    
    local found = 0
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, itemIDStr = string.find(link, "item:(%d+)")
                if itemIDStr then
                    local itemID = tonumber(itemIDStr)
                    local itemName = GetItemInfo(itemID) or ("Item " .. itemID)
                    local category = map[itemID]
                    
                    if category then
                        table.insert(scanResults, {
                            name = itemName,
                            id = itemID,
                            category = category,
                            bag = bag,
                            slot = slot
                        })
                        found = found + 1
                        SmartMail_Debug("Found " .. itemName .. " (" .. category .. ")")
                    end
                end
            end
        end
    end
    
    SmartMailDebugLog.debugScan[GetTime()] = scanResults
    SmartMail_Debug("Scan complete. Found " .. found .. " categorised items.")
end


-- Register frames to be closed with the ESC key
tinsert(UISpecialFrames, "SmartMailMainFrame")

-- MainFrame ESC interceptor setup
SmartMail.openChildFrames = {}

local originalMainFrameHide = SmartMailMainFrame.Hide
SmartMailMainFrame.Hide = function(self)
    SmartMail_Debug("SmartMailMainFrame:Hide() called.")
    
    if SmartMail.forceCloseAll then
        SmartMail.forceCloseAll = false
        SmartMail_Debug("Force closing all child frames...")
        for i = 1, table.getn(SmartMail.openChildFrames) do
            local child = SmartMail.openChildFrames[i]
            if child and child:IsVisible() then
                -- Unhook briefly or just call hide, since hide might pop from stack, we iterate carefully or clear stack
                -- Actually the OnHide of children will pop them, but let's just clear it.
                child:Hide()
            end
        end
        SmartMail.openChildFrames = {}
        
        SmartMail_Debug("MainFrame closing: Unselected current profile.")
        SmartMail.selectedProfile = nil
        SmartMail_UpdateProfileList()
        originalMainFrameHide(self)
        return
    end
    
    -- Pop frames from the stack until we find one that is visible
    while table.getn(SmartMail.openChildFrames) > 0 do
        local topFrame = SmartMail.openChildFrames[table.getn(SmartMail.openChildFrames)]
        
        -- Remove it from stack since we are processing it (or discarding it)
        tremove(SmartMail.openChildFrames, table.getn(SmartMail.openChildFrames))
        
        if topFrame and topFrame:IsVisible() then
            SmartMail_Debug("Intercepted: Hiding most recent child frame (" .. topFrame:GetName() .. ") instead.")
            topFrame:Hide()
            return
        end
    end
    
    SmartMail_Debug("No children open. Closing MainFrame normally.")
    if SmartMail.selectedProfile then
        SmartMail.selectedProfile = nil
        SmartMail_UpdateProfileList()
        SmartMail_Debug("MainFrame closing: Unselected current profile.")
    end
    originalMainFrameHide(self)
end

-- Populate Debug Window from saved variables when opened
SmartMailDebugFrame:SetScript("OnShow", function()
    SmartMail_Debug("SmartMailDebugFrame shown (Lua SetScript)")
    SmartMail_UpdateDebugList()
end)

SmartMailLogFrame:SetScript("OnShow", function()
    SmartMail_Debug("SmartMailLogFrame shown (Lua SetScript)")
    if SmartMail_UpdateLogFrame then
        SmartMail_UpdateLogFrame()
    end
end)

-- Profile Editor Logic
local createdCheckboxes = false
function SmartMail_InitializeProfileCheckboxes()
    SmartMail_Debug("SmartMail_InitializeProfileCheckboxes called...")
    if createdCheckboxes then return end
    SmartMail_Debug("Initializing Category Checkboxes...")
    
    local parent = SmartMailProfileEditorFrameCheckboxContainer
    local categories = Bridge:GetCategoryNames()
    SmartMail.categoryButtons = {}
    
    -- Create Active Frame Backdrop
    local activeBG = CreateFrame("Frame", nil, parent)
    activeBG:SetBackdrop({
        bgFile = "Interface\Tooltips\UI-Tooltip-Background",
        edgeFile = "Interface\Tooltips\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    activeBG:SetBackdropColor(0, 0, 0, 0.6)
    activeBG:SetBackdropBorderColor(0, 1, 0, 0.8)
    SmartMail.activeBG = activeBG
    
    local activeHeader = activeBG:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    activeHeader:SetText("Active Categories (Click to Remove)")
    activeHeader:SetTextColor(0, 1, 0)
    activeHeader:SetPoint("TOPLEFT", activeBG, "TOPLEFT", 10, -10)
    SmartMail.activeHeader = activeHeader
    
    -- Create Available Frame Backdrop
    local availableBG = CreateFrame("Frame", nil, parent)
    availableBG:SetBackdrop({
        bgFile = "Interface\Tooltips\UI-Tooltip-Background",
        edgeFile = "Interface\Tooltips\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    availableBG:SetBackdropColor(0, 0, 0, 0.6)
    availableBG:SetBackdropBorderColor(1, 1, 0, 0.8)
    SmartMail.availableBG = availableBG
    
    local availableHeader = availableBG:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    availableHeader:SetText("Available Categories (Click to Add)")
    availableHeader:SetTextColor(1, 1, 0)
    availableHeader:SetPoint("TOPLEFT", availableBG, "TOPLEFT", 10, -10)
    SmartMail.availableHeader = availableHeader
    
    for i, catName in ipairs(categories) do
        local btn = CreateFrame("Button", "SmartMailCategoryBtn" .. i, parent)
        btn:SetWidth(115)
        btn:SetHeight(16)
        
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(btn)
        highlight:SetTexture("Interface\QuestFrame\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", btn, "LEFT", 10, 0)
        text:SetText(catName)
        
        btn.categoryName = catName
        btn:SetScript("OnClick", function()
            local profileData = SmartMail.editingProfileData
            if not profileData then return end
            if profileData[this.categoryName] then
                profileData[this.categoryName] = nil
            else
                profileData[this.categoryName] = true
            end
            SmartMail_UpdateCategoryLists()
        end)
        
        table.insert(SmartMail.categoryButtons, btn)
    end
    
    createdCheckboxes = true
end

function SmartMail_UpdateCategoryLists()
    local profileData = SmartMail.editingProfileData or {}
    local activeList = {}
    local availableList = {}
    
    for _, btn in ipairs(SmartMail.categoryButtons) do
        if profileData[btn.categoryName] then
            table.insert(activeList, btn)
        else
            table.insert(availableList, btn)
        end
        btn:Hide()
        btn:SetParent(SmartMailProfileEditorFrameCheckboxContainer) -- default
    end
    
    table.sort(activeList, function(a, b) return a.categoryName < b.categoryName end)
    table.sort(availableList, function(a, b) return a.categoryName < b.categoryName end)
    
    local activeRows = math.ceil(table.getn(activeList) / 2)
    if activeRows == 0 then activeRows = 1 end
    local activeHeight = 30 + (activeRows * 16) + 10
    
    SmartMail.activeBG:ClearAllPoints()
    SmartMail.activeBG:SetPoint("TOPLEFT", SmartMailProfileEditorFrameCheckboxContainer, "TOPLEFT", 0, 0)
    SmartMail.activeBG:SetWidth(260)
    SmartMail.activeBG:SetHeight(activeHeight)
    
    for i, btn in ipairs(activeList) do
        local col = math.mod(i - 1, 2)
        local row = math.floor((i - 1) / 2)
        btn:SetParent(SmartMail.activeBG)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", SmartMail.activeBG, "TOPLEFT", 10 + (col * 125), -30 - (row * 16))
        btn:Show()
    end
    
    local availableRows = math.ceil(table.getn(availableList) / 2)
    if availableRows == 0 then availableRows = 1 end
    local availableHeight = 30 + (availableRows * 16) + 10
    
    SmartMail.availableBG:ClearAllPoints()
    SmartMail.availableBG:SetPoint("TOPLEFT", SmartMail.activeBG, "BOTTOMLEFT", 0, -10)
    SmartMail.availableBG:SetWidth(260)
    SmartMail.availableBG:SetHeight(availableHeight)
    
    for i, btn in ipairs(availableList) do
        local col = math.mod(i - 1, 2)
        local row = math.floor((i - 1) / 2)
        btn:SetParent(SmartMail.availableBG)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", SmartMail.availableBG, "TOPLEFT", 10 + (col * 125), -30 - (row * 16))
        btn:Show()
    end
end

function SmartMail_OpenProfileEditor(characterName)
    SmartMail_Debug("SmartMail_OpenProfileEditor called...")
    if SmartMailConfirmFrame and SmartMailConfirmFrame:IsVisible() then SmartMailConfirmFrame:Hide() end
    if SmartMailCustomSendFrame and SmartMailCustomSendFrame:IsVisible() then SmartMailCustomSendFrame:Hide() end
    SmartMail_Debug("Opening Profile Editor for: " .. tostring(characterName or "NEW"))
    
    SmartMail_InitializeProfileCheckboxes()
    SmartMail.editingProfileName = characterName
    SmartMailProfileEditorFrameNameEditBox:SetText(characterName or "")
    
    if not SmartMailDB_PerChar then SmartMailDB_PerChar = { profiles = {} } end
    if not SmartMailDB_PerChar.profiles then SmartMailDB_PerChar.profiles = {} end
    local existingProfile = SmartMailDB_PerChar.profiles[characterName]
    
    SmartMail.editingProfileData = {}
    if existingProfile then
        for k, v in pairs(existingProfile) do
            SmartMail.editingProfileData[k] = v
        end
    end
    
    SmartMail_UpdateCategoryLists()
    SmartMailProfileEditorFrame:Show()
end

function SmartMail_SaveProfile()
    SmartMail_Debug("SmartMail_SaveProfile called...")
    local charName = SmartMailProfileEditorFrameNameEditBox:GetText()
    SmartMail_Debug("Attempting to save profile for: " .. tostring(charName))
    
    if not charName or charName == "" then
        SmartMail_Debug("Save aborted: Character name is empty.")
        return
    end
    
    if not SmartMailDB_PerChar then SmartMailDB_PerChar = { profiles = {} } end
    if not SmartMailDB_PerChar.profiles then SmartMailDB_PerChar.profiles = {} end
    
    -- If profile is new, ask for verification!
    if not SmartMailDB_PerChar.profiles[charName] then
        StaticPopupDialogs["SMARTMAIL_VERIFY_RECIPIENT"] = {
            text = "Are you absolutely sure '" .. charName .. "' is spelled correctly?\n\nMail sent to the wrong person cannot be recovered!",
            button1 = "Yes, Save Profile",
            button2 = "No, Cancel",
            OnAccept = function()
                SmartMail_CommitSaveProfile(charName)
            end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1
        }
        StaticPopup_Show("SMARTMAIL_VERIFY_RECIPIENT")
    else
        -- Already verified/exists
        SmartMail_CommitSaveProfile(charName)
    end
end

function SmartMail_CommitSaveProfile(charName)
    SmartMail_Debug("SmartMail_CommitSaveProfile called...")
    if not SmartMailDB then SmartMailDB = { profiles = {} } end
    if not SmartMailDB.profiles then SmartMailDB.profiles = {} end
    
    local selectedCategories = {}
    local count = 0
    if SmartMail.editingProfileData then
        for k, v in pairs(SmartMail.editingProfileData) do
            if v then
                selectedCategories[k] = true
                count = count + 1
            end
        end
    end
    
    if SmartMail.editingProfileName and SmartMail.editingProfileName ~= charName then
        SmartMail_Debug("Profile renamed from '" .. SmartMail.editingProfileName .. "' to '" .. charName .. "'. Deleting old profile.")
        SmartMailDB.profiles[SmartMail.editingProfileName] = nil
        SmartMailDB_PerChar.profiles[SmartMail.editingProfileName] = nil
        
        if SmartMail.selectedProfile == SmartMail.editingProfileName then
            SmartMail.selectedProfile = charName
        end
    end
    
    SmartMailDB.profiles[charName] = selectedCategories
    SmartMailDB_PerChar.profiles[charName] = selectedCategories
    SmartMail.editingProfileName = nil
    
    SmartMail_Debug("Successfully saved profile '" .. charName .. "' with " .. count .. " categories checked.")
    
    SmartMailProfileEditorFrame:Hide()
    SmartMail.selectedProfile = charName
    SmartMail_UpdateProfileList()
end

function SmartMail_DeleteProfile(charName)
    SmartMail_Debug("SmartMail_DeleteProfile called...")
    if not charName then return end
    
    if SmartMailConfirmFrame and SmartMailConfirmFrame:IsVisible() then SmartMailConfirmFrame:Hide() end
    if SmartMailCustomSendFrame and SmartMailCustomSendFrame:IsVisible() then SmartMailCustomSendFrame:Hide() end
    
    StaticPopupDialogs["SMARTMAIL_DELETE_PROFILE"] = {
        text = "Are you sure you want to completely delete the profile for '" .. charName .. "'?",
        button1 = "Yes, Delete",
        button2 = "No, Cancel",
        OnAccept = function()
            if SmartMailDB.profiles[charName] then SmartMailDB.profiles[charName] = nil end
            if SmartMailDB_PerChar.profiles[charName] then SmartMailDB_PerChar.profiles[charName] = nil end
            
            if SmartMail.selectedProfile == charName then
                SmartMail.selectedProfile = nil
            end
            
            SmartMail_Debug("Profile '" .. charName .. "' has been deleted.")
            SmartMail_UpdateProfileList()
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    }
    StaticPopup_Show("SMARTMAIL_DELETE_PROFILE")
end

function SmartMail_UpdateActionButtons()
    SmartMail_Debug("SmartMail_UpdateActionButtons called...")
    local isPopupOpen = false
    if SmartMailProfileEditorFrame and SmartMailProfileEditorFrame:IsVisible() then isPopupOpen = true end
    
    local isMailOpen = MailFrame and MailFrame:IsVisible()
    
    if isPopupOpen then
        if SmartMailMainFrameOpenSelectedButton then SmartMailMainFrameOpenSelectedButton:Disable() end
        if SmartMailMainFrameSendAllButton then SmartMailMainFrameSendAllButton:Disable() end
        if SmartMailMainFrameSendAllFullButton then SmartMailMainFrameSendAllFullButton:Disable() end
        if SmartMailMainFrameAddButton then SmartMailMainFrameAddButton:Disable() end
        if SmartMailMainFrameEditButton then SmartMailMainFrameEditButton:Disable() end
        if SmartMailMainFrameDeleteButton then SmartMailMainFrameDeleteButton:Disable() end
    else
        if SmartMailMainFrameAddButton then SmartMailMainFrameAddButton:Enable() end
        
        if isMailOpen then
            if SmartMailMainFrameSendAllButton then SmartMailMainFrameSendAllButton:Enable() end
            if SmartMailMainFrameSendAllFullButton then SmartMailMainFrameSendAllFullButton:Enable() end
        else
            if SmartMailMainFrameSendAllButton then SmartMailMainFrameSendAllButton:Disable() end
            if SmartMailMainFrameSendAllFullButton then SmartMailMainFrameSendAllFullButton:Disable() end
        end
        
        if SmartMail.selectedProfile then
            if SmartMailMainFrameOpenSelectedButton then SmartMailMainFrameOpenSelectedButton:Enable() end
            if SmartMailMainFrameEditButton then SmartMailMainFrameEditButton:Enable() end
            if SmartMailMainFrameDeleteButton then SmartMailMainFrameDeleteButton:Enable() end
        else
            if SmartMailMainFrameOpenSelectedButton then SmartMailMainFrameOpenSelectedButton:Disable() end
            if SmartMailMainFrameEditButton then SmartMailMainFrameEditButton:Disable() end
            if SmartMailMainFrameDeleteButton then SmartMailMainFrameDeleteButton:Disable() end
        end
    end
    
    if SmartMailConfirmFrameSendButton then
        if isMailOpen then
            SmartMailConfirmFrameSendButton:Enable()
        else
            SmartMailConfirmFrameSendButton:Disable()
        end
    end
end

function SmartMail_UpdateProfileList()
    SmartMail_Debug("SmartMail_UpdateProfileList called...")
    if not SmartMailDB_PerChar or not SmartMailDB_PerChar.profiles then return end
    
    local scrollChild = SmartMailMainFrameListFrameScrollFrameScrollChild
    if not scrollChild then 
        SmartMail_Debug("UpdateProfileList failed: scrollChild is nil!")
        return 
    end
    
    if not SmartMail.selectedProfile then
        SmartMail.selectedProfile = nil
    end
    
    if not scrollChild.profileLines then
        scrollChild.profileLines = {}
    end
    
    -- Hide existing
    for _, line in ipairs(scrollChild.profileLines) do
        line:Hide()
    end
    
    local yOffset = -5
    local index = 1
    
    for charName, categories in pairs(SmartMailDB_PerChar.profiles) do
        local line = scrollChild.profileLines[index]
        if not line then
            line = SmartMail_CreateListRow("SmartMailProfileRow" .. index, scrollChild, 270, 20)
            line.text:SetFontObject("GameFontNormal")
            line.text:SetPoint("LEFT", line, "LEFT", 10, 0)
            
            line:SetScript("OnClick", function()
                SmartMail_Debug("Profile list line clicked (Lua SetScript)")
                if SmartMailProfileEditorFrame and SmartMailProfileEditorFrame:IsVisible() then
                    SmartMail_Debug("Blocked profile selection: Editor Window is open.")
                    return
                end
                
                if SmartMail.selectedProfile == this.charName then
                    SmartMail.selectedProfile = nil
                    SmartMail_Debug("Deselected profile: " .. tostring(this.charName))
                    if SmartMailConfirmFrame and SmartMailConfirmFrame:IsVisible() then
                        SmartMailConfirmFrame:Hide()
                    end
                else
                    SmartMail.selectedProfile = this.charName
                    SmartMail_Debug("Selected profile: " .. tostring(this.charName))
                    if SmartMailConfirmFrame and not SmartMailConfirmFrame:IsVisible() then
                        SmartMailConfirmFrame:Show()
                    else
                        SmartMail_UpdateConfirmList()
                    end
                end
                
                SmartMail_UpdateProfileList()
            end)
            
            table.insert(scrollChild.profileLines, line)
        end
        
        line.charName = charName
        
        local activeCats = {}
        for k, v in pairs(categories) do 
            if v and k ~= "itemSettings" then 
                table.insert(activeCats, k)
            end 
        end
        
        local numCats = table.getn(activeCats)
        if numCats > 0 then
            local catWord = numCats == 1 and "category" or "categories"
            line.text:SetText(charName .. " (" .. numCats .. " " .. catWord .. ": " .. table.concat(activeCats, ", ") .. ")")
        else
            line.text:SetText(charName)
        end
        
        if SmartMail.selectedProfile == charName then
            line.text:SetTextColor(1, 1, 1) -- White (Selected)
            line:SetSelected(true)
        else
            line.text:SetTextColor(1, 0.82, 0) -- Gold (Normal)
            line:SetSelected(false)
        end
        
        line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        line:Show()
        
        yOffset = yOffset - 20
        index = index + 1
    end
    
    SmartMail_UpdateActionButtons()
end

SmartMailMainFrame:SetScript("OnShow", function()
    SmartMail_Debug("SmartMailMainFrame shown (Lua SetScript)")
    SmartMail_UpdateProfileList()
end)

-- Wire up Add Button on Main UI
SmartMailMainFrameAddButton:SetScript("OnClick", function()
    SmartMail_Debug("SmartMailMainFrameAddButton clicked (Lua SetScript)")
    SmartMail_Debug("Add Button clicked")
    SmartMail_OpenProfileEditor(nil)
end)



function SmartMail_LoadGlobalProfiles()
    SmartMail_Debug("SmartMail_LoadGlobalProfiles called...")
    if not SmartMailDB or not SmartMailDB.profiles then
        SmartMail_Debug("No global profiles to load.")
        return
    end
    if not SmartMailDB_PerChar then SmartMailDB_PerChar = { profiles = {} } end
    if not SmartMailDB_PerChar.profiles then SmartMailDB_PerChar.profiles = {} end
    
    local count = 0
    for charName, categories in pairs(SmartMailDB.profiles) do
        local catCopy = {}
        for k, v in pairs(categories) do
            catCopy[k] = v
        end
        SmartMailDB_PerChar.profiles[charName] = catCopy
        count = count + 1
    end
    
    SmartMail_Debug("Loaded " .. count .. " global profiles into this character.")
    SmartMail_UpdateProfileList()
end

SmartMailOptionsFrameLoadGlobalButton:SetScript("OnClick", function()
    SmartMail_Debug("SmartMailOptionsFrameLoadGlobalButton clicked (Lua SetScript)")
    SmartMail_LoadGlobalProfiles()
end)

function SmartMail_ResetConfirmItems()
    SmartMail_Debug("SmartMail_ResetConfirmItems called...")
    if not SmartMail.confirmQueue then return end
    
    local charName = UIDropDownMenu_GetText(SmartMailMainFrameProfileDropdown)
    if not charName or charName == "" or not SmartMailDB_PerChar.profiles[charName] then return end
    local profile = SmartMailDB_PerChar.profiles[charName]
    
    if profile.itemSettings then
        for _, itemData in ipairs(SmartMail.confirmQueue) do
            local itemID = itemData.itemID
            if profile.itemSettings[itemID] then
                profile.itemSettings[itemID] = nil
            end
        end
    end
    
    SmartMail.confirmQueue = SmartMailQueue:BuildQueueForProfile(charName)
    SmartMail_UpdateConfirmList()
end

function SmartMail_SaveItemSetting(profileName, itemID, key, value)
    SmartMail_Debug("SmartMail_SaveItemSetting called...")
    if not SmartMailDB_PerChar then return end
    if not SmartMailDB_PerChar.profiles[profileName] then return end
    
    if not SmartMailDB_PerChar.profiles[profileName].itemSettings then
        SmartMailDB_PerChar.profiles[profileName].itemSettings = {}
    end
    if not SmartMailDB_PerChar.profiles[profileName].itemSettings[itemID] then
        SmartMailDB_PerChar.profiles[profileName].itemSettings[itemID] = {}
    end
    
    SmartMailDB_PerChar.profiles[profileName].itemSettings[itemID][key] = value
    SmartMail_Debug("ConfirmList: Saved item setting (" .. tostring(itemID) .. ") key '" .. tostring(key) .. "' = " .. tostring(value))
end

function SmartMail_UpdateConfirmList()
    local charName = SmartMail.selectedProfile
    if not charName then return end
    
    if SmartMailConfirmFrameTitle then
        SmartMailConfirmFrameTitle:SetText(charName)
    end
    
    SmartMail.confirmQueue = SmartMailQueue:BuildQueueForProfile(charName)
    SmartMail_Debug("Confirm Queue built with " .. table.getn(SmartMail.confirmQueue) .. " items.")
    
    local scrollChild = SmartMailConfirmFrameListFrameScrollFrameScrollChild
    if not scrollChild.items then scrollChild.items = {} end
    
    -- Hide all existing
    for _, btn in ipairs(scrollChild.items) do
        btn:Hide()
    end
    
    local yOffset = -5
    for i, itemData in ipairs(SmartMail.confirmQueue) do
        local btn = scrollChild.items[i]
        if not btn then
            btn = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
            btn:SetWidth(24)
            btn:SetHeight(24)
            
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetWidth(20)
            icon:SetHeight(20)
            icon:SetPoint("LEFT", btn, "RIGHT", 5, 0)
            btn.icon = icon
            
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            text:SetJustifyH("LEFT")
            text:SetWidth(160)
            text:SetHeight(20)
            btn.text = text
            
            local minusBtn = CreateFrame("Button", nil, btn)
            minusBtn:SetWidth(16)
            minusBtn:SetHeight(16)
            minusBtn:SetPoint("LEFT", btn, "LEFT", 231, 0)
            minusBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
            minusBtn:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
            minusBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
            minusBtn:SetScript("OnClick", function()
                SmartMail_Debug("ConfirmFrame minusBtn clicked (Lua SetScript)")
                local edit = this:GetParent().fullEdit
                local maxF = SmartMail.confirmQueue[this:GetParent().index].fullStacks
                local val = tonumber(edit:GetText())
                if not val and string.upper(edit:GetText()) == "MAX" then
                    val = maxF
                elseif not val then
                    val = 0
                end
                if val > 0 then
                    val = val - 1
                    if val >= maxF and maxF > 0 then
                        edit:SetNumeric(false)
                        edit:SetText("MAX")
                    else
                        edit:SetNumeric(true)
                        edit:SetText(tostring(val))
                    end
                end
            end)
            btn.minusBtn = minusBtn
            
            local fullEdit = CreateFrame("EditBox", nil, btn)
            fullEdit:SetWidth(24)
            fullEdit:SetHeight(16)
            fullEdit:SetPoint("LEFT", minusBtn, "RIGHT", 2, 0)
            fullEdit:SetAutoFocus(false)
            fullEdit:SetNumeric(true)
            fullEdit:SetMaxLetters(3)
            fullEdit:SetFontObject("ChatFontNormal")
            fullEdit:SetJustifyH("CENTER")
            
            local fbg = fullEdit:CreateTexture(nil, "BACKGROUND")
            fbg:SetAllPoints()
            fbg:SetTexture(0.2, 0.2, 0.2, 0.8)
            
            fullEdit:SetScript("OnTextChanged", function()
                local textVal = string.upper(this:GetText())
                local index = this:GetParent().index
                local itemData = SmartMail.confirmQueue[index]
                local maxF = itemData.fullStacks
                
                if textVal == "MAX" then
                    itemData.sendFull = maxF
                    SmartMail_SaveItemSetting(SmartMail.selectedProfile, itemData.itemID, "sendFull", "MAX")
                    return
                end
                
                local val = tonumber(this:GetText())
                if not val then val = 0 end
                
                if val >= maxF and maxF > 0 then
                    this:SetNumeric(false)
                    this:SetText("MAX")
                    val = maxF
                else
                    this:SetNumeric(true)
                end
                itemData.sendFull = val
                SmartMail_SaveItemSetting(SmartMail.selectedProfile, itemData.itemID, "sendFull", val)
            end)
            btn.fullEdit = fullEdit
            
            local plusBtn = CreateFrame("Button", nil, btn)
            plusBtn:SetWidth(16)
            plusBtn:SetHeight(16)
            plusBtn:SetPoint("LEFT", fullEdit, "RIGHT", 2, 0)
            plusBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
            plusBtn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
            plusBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
            plusBtn:SetScript("OnClick", function()
                SmartMail_Debug("ConfirmFrame plusBtn clicked (Lua SetScript)")
                local edit = this:GetParent().fullEdit
                local index = this:GetParent().index
                local maxF = SmartMail.confirmQueue[index].fullStacks
                local val = tonumber(edit:GetText())
                if not val and string.upper(edit:GetText()) == "MAX" then
                    val = maxF
                elseif not val then
                    val = 0
                end
                if val < maxF then
                    val = val + 1
                    if val >= maxF and maxF > 0 then
                        edit:SetNumeric(false)
                        edit:SetText("MAX")
                    else
                        edit:SetNumeric(true)
                        edit:SetText(tostring(val))
                    end
                end
            end)
            btn.plusBtn = plusBtn
            
            local partCheck = CreateFrame("CheckButton", nil, btn, "UICheckButtonTemplate")
            partCheck:SetWidth(24)
            partCheck:SetHeight(24)
            partCheck:SetPoint("LEFT", btn, "LEFT", 329, 0)
            
            partCheck:SetScript("OnClick", function()
                SmartMail_Debug("ConfirmFrame partCheck clicked (Lua SetScript)")
                local index = this:GetParent().index
                local state = this:GetChecked()
                local itemData = SmartMail.confirmQueue[index]
                itemData.sendPart = state and itemData.partialStacks or 0
                local saveVal = state and "MAX" or 0
                SmartMail_SaveItemSetting(SmartMail.selectedProfile, itemData.itemID, "sendPart", saveVal)
            end)
            btn.partCheck = partCheck
            
            btn:SetScript("OnClick", function()
                SmartMail_Debug("ConfirmFrame item btn clicked (Lua SetScript)")
                local index = this.index
                local state = this:GetChecked()
                local itemData = SmartMail.confirmQueue[index]
                itemData.selected = state and 1 or 0
                SmartMail_SaveItemSetting(SmartMail.selectedProfile, itemData.itemID, "selected", itemData.selected)
                
                if not state then
                    this.partCheck:SetChecked(nil)
                else
                    if itemData.sendPart > 0 then
                        this.partCheck:SetChecked(1)
                    end
                end
            end)
            
            table.insert(scrollChild.items, btn)
        end
        
        btn.index = i
        btn:SetChecked(itemData.selected == 1 and 1 or nil)
        
        btn.icon:SetTexture(itemData.itemIcon)
        btn.text:SetText(itemData.itemName .. " (" .. itemData.totalCount .. ")")
        
        if itemData.sendFull > 0 then
            if itemData.sendFull >= itemData.fullStacks then
                btn.fullEdit:SetNumeric(false)
                btn.fullEdit:SetText("MAX")
            else
                btn.fullEdit:SetNumeric(true)
                btn.fullEdit:SetText(tostring(itemData.sendFull))
            end
            btn.fullEdit:SetTextColor(1, 1, 1)
        else
            btn.fullEdit:SetNumeric(true)
            btn.fullEdit:SetText(0)
            if itemData.fullStacks > 0 then
                btn.fullEdit:SetTextColor(1, 1, 1)
            else
                btn.fullEdit:SetTextColor(0.5, 0.5, 0.5)
            end
        end
        
        if itemData.partialStacks > 0 then
            btn.partCheck:Show()
            if itemData.sendPart > 0 and itemData.selected == 1 then
                btn.partCheck:SetChecked(1)
            else
                btn.partCheck:SetChecked(nil)
            end
        else
            btn.partCheck:Hide()
        end
        
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        btn:Show()
        
        yOffset = yOffset - 30
    end
end

SmartMailConfirmFrame:SetScript("OnShow", function()
    SmartMail_Debug("SmartMailConfirmFrame shown (Lua SetScript)")
    SmartMail_UpdateConfirmList()
end)

SmartMailConfirmFrameSendButton:SetScript("OnClick", function()
    SmartMail_Debug("SmartMailConfirmFrameSendButton clicked (Lua SetScript)")
    local flatQueue = SmartMailQueue:FlattenConfirmQueue()
    local totalItems = table.getn(flatQueue)
    if totalItems == 0 then
        SmartMail_Debug("Send aborted: 0 items selected.")
        SmartMailConfirmFrame:Hide()
        return
    end
    
    SmartMail_Debug("Starting Send process with " .. totalItems .. " items for " .. tostring(SmartMail.selectedProfile))
    SmartMailConfirmFrame:Hide()
    
    if SmartMailEngine and SmartMailEngine.Start then
        SmartMailEngine:Start(SmartMail.selectedProfile, flatQueue)
    else
        SmartMail_Debug("FATAL: Engine not found!")
    end
end)



-- Hook all child frames to stack logic at the very end to avoid SetScript overwrites
function SmartMail_HookFrameStack(frame)
    SmartMail_Debug("SmartMail_HookFrameStack called...")
    if not frame then return end
    local oldShow = frame:GetScript("OnShow")
    frame:SetScript("OnShow", function()
        SmartMail_Debug((frame:GetName() or "UnknownFrame") .. " shown (HookFrameStack)")
        for i, f in ipairs(SmartMail.openChildFrames) do
            if f == frame then tremove(SmartMail.openChildFrames, i) break end
        end
        tinsert(SmartMail.openChildFrames, frame)
        if oldShow then oldShow() end
        if SmartMail_UpdateActionButtons then SmartMail_UpdateActionButtons() end
    end)
    
    local oldHide = frame:GetScript("OnHide")
    frame:SetScript("OnHide", function()
        SmartMail_Debug((frame:GetName() or "UnknownFrame") .. " hidden (HookFrameStack)")
        for i, f in ipairs(SmartMail.openChildFrames) do
            if f == frame then tremove(SmartMail.openChildFrames, i) break end
        end
        if oldHide then oldHide() end
        if SmartMail_UpdateActionButtons then SmartMail_UpdateActionButtons() end
    end)
    
    local oldDown = frame:GetScript("OnMouseDown")
    frame:SetScript("OnMouseDown", function()
        for i, f in ipairs(SmartMail.openChildFrames) do
            if f == frame then tremove(SmartMail.openChildFrames, i) break end
        end
        tinsert(SmartMail.openChildFrames, frame)
        if oldDown then oldDown() end
    end)
    
    local oldDrag = frame:GetScript("OnDragStart")
    frame:SetScript("OnDragStart", function()
        for i, f in ipairs(SmartMail.openChildFrames) do
            if f == frame then tremove(SmartMail.openChildFrames, i) break end
        end
        tinsert(SmartMail.openChildFrames, frame)
        if oldDrag then oldDrag() end
    end)
end

SmartMail_HookFrameStack(SmartMailOptionsFrame)
SmartMail_HookFrameStack(SmartMailProfileEditorFrame)
SmartMail_HookFrameStack(SmartMailDebugFrame)
SmartMail_HookFrameStack(SmartMailLogFrame)
SmartMail_HookFrameStack(SmartMailConfirmFrame)
SmartMail_HookFrameStack(SmartMailCustomSendFrame)

SmartMail.sendAllProfilesQueue = {}
SmartMail.sendAllStats = { success = 0, fail = 0 }

function SmartMail_SendAll(mode)
    SmartMail_Debug("SmartMail_SendAll called...")
    if SmartMail.isBusy then return end
    
    -- Gather flat queues for every single profile
    SmartMail.sendAllProfilesQueue = {}
    SmartMail.sendAllStats = { expected = 0, success = 0, fail = 0 }
    
    if SmartMailDB_PerChar and SmartMailDB_PerChar.profiles then
        for charName, _ in pairs(SmartMailDB_PerChar.profiles) do
            local flat = SmartMailQueue:GenerateDirectFlatQueue(charName, mode)
            if flat and table.getn(flat) > 0 then
                table.insert(SmartMail.sendAllProfilesQueue, { name = charName, queue = flat })
                SmartMail.sendAllStats.expected = SmartMail.sendAllStats.expected + table.getn(flat)
            end
        end
    end
    
    if table.getn(SmartMail.sendAllProfilesQueue) == 0 then
        SmartMail_Debug("SendAll: No items to send for any profile.")
        DEFAULT_CHAT_FRAME:AddMessage("SmartMail: No items to send.", 1, 1, 0)
        return
    end
    
    local expectedMsg = "SmartMail: Starting Mass Send. Expected to send " .. SmartMail.sendAllStats.expected .. " item(s)."
    DEFAULT_CHAT_FRAME:AddMessage(expectedMsg, 1, 1, 0)
    SmartMail_Debug("SendAll: " .. expectedMsg)
    
    SmartMail_SendAll_Next(0, 0)
end

function SmartMail_SendAll_Next(successCount, failCount, abortReason, failedItems)
    SmartMail.sendAllStats.success = SmartMail.sendAllStats.success + (successCount or 0)
    SmartMail.sendAllStats.fail = SmartMail.sendAllStats.fail + (failCount or 0)
    if abortReason then SmartMail.sendAllStats.reason = abortReason end
    if not SmartMail.sendAllStats.failedItemsList then SmartMail.sendAllStats.failedItemsList = {} end
    if failedItems then
        for _, fi in ipairs(failedItems) do
            table.insert(SmartMail.sendAllStats.failedItemsList, fi)
        end
    end
    
    if table.getn(SmartMail.sendAllProfilesQueue) == 0 then
        local msg = "SmartMail: Mass Send Complete! Expected: " .. SmartMail.sendAllStats.expected .. ". Sent: " .. SmartMail.sendAllStats.success .. ". Failed: " .. SmartMail.sendAllStats.fail .. "."
        if SmartMail.sendAllStats.fail > 0 then
            local r = SmartMail.sendAllStats.reason or "Max Retries Reached"
            msg = msg .. " (" .. r .. ")."
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0)
        SmartMail_Debug("SendAll: " .. msg)
        
        if SmartMail.sendAllStats.fail > 0 and SmartMail.sendAllStats.failedItemsList then
            for _, fi in ipairs(SmartMail.sendAllStats.failedItemsList) do
                local it = fi.item
                local reason = fi.reason or "Unknown Error"
                if it.isMoney then
                    DEFAULT_CHAT_FRAME:AddMessage("  - Failed: Money (" .. tostring(it.amount) .. "c) - " .. reason, 1, 0.5, 0)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("  - Failed: " .. tostring(it.name or "Item") .. " (Bag " .. tostring(it.bag or "?") .. " Slot " .. tostring(it.slot or "?") .. ") - " .. reason, 1, 0.5, 0)
                end
            end
        end
        return
    end
    
    local profileData = table.remove(SmartMail.sendAllProfilesQueue, 1)
    SmartMail_Debug("SendAll: Routing " .. table.getn(profileData.queue) .. " items to " .. profileData.name)
    SmartMailEngine:Start(profileData.name, profileData.queue, SmartMail_SendAll_Next)
end