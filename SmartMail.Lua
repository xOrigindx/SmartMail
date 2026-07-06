SmartMail = {
    isBusy      = false,
    lookup      = {},
    db          = nil,
    log         = nil,
    debug       = true,
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "SmartMail" then
        if not SmartMailDB then SmartMailDB = { profiles = {} } end
        if not SmartMailDB.profiles then SmartMailDB.profiles = {} end
        if not SmartMailLog then SmartMailLog = {} end
        if not SmartMailLog.debugLog then SmartMailLog.debugLog = {} end
        
        -- Backups
        if not SmartMailDB_PerChar then SmartMailDB_PerChar = { profiles = {} } end
        if not SmartMailDB_PerChar.profiles then SmartMailDB_PerChar.profiles = {} end
        if not SmartMailLog_PerChar then SmartMailLog_PerChar = {} end
        if not SmartMailLog_PerChar.debugLog then SmartMailLog_PerChar.debugLog = {} end
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

function SmartMail_Debug(msg)
    if SmartMail.debug then
        local formattedMsg = "|cff00ffff[SmartMail Debug]|r " .. tostring(msg)
        DEFAULT_CHAT_FRAME:AddMessage(formattedMsg)
        
        local h, m = GetGameTime()
        local timeStr = string.format("%02d:%02d", h, m)
        local logMsg = "[" .. timeStr .. "] " .. tostring(msg)
        
        -- Safe initialization of SavedVariable
        if not SmartMailLog then SmartMailLog = {} end
        if not SmartMailLog.debugLog then SmartMailLog.debugLog = {} end
        table.insert(SmartMailLog.debugLog, 1, logMsg)
        if table.getn(SmartMailLog.debugLog) > 50 then
            table.remove(SmartMailLog.debugLog)
        end
        
        -- Backup
        if not SmartMailLog_PerChar then SmartMailLog_PerChar = {} end
        if not SmartMailLog_PerChar.debugLog then SmartMailLog_PerChar.debugLog = {} end
        table.insert(SmartMailLog_PerChar.debugLog, 1, logMsg)
        if table.getn(SmartMailLog_PerChar.debugLog) > 50 then
            table.remove(SmartMailLog_PerChar.debugLog)
        end
        
        -- Update UI Debug Window
        if SmartMailDebugFrameText then
            local currentText = SmartMailDebugFrameText:GetText() or ""
            if currentText ~= "" then
                SmartMailDebugFrameText:SetText(logMsg .. "\n" .. currentText)
            else
                SmartMailDebugFrameText:SetText(logMsg)
            end
            
            -- Auto scroll up
            local scrollFrame = SmartMailDebugFrameContentFrameScrollFrame
            if scrollFrame then
                scrollFrame:UpdateScrollChildRect()
                scrollFrame:SetVerticalScroll(0)
            end
        end
    end
end

-- Slash Command Logic
SLASH_SMARTMAIL1 = "/smartmail"
SLASH_SMARTMAIL2 = "/sm"
SlashCmdList["SMARTMAIL"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "clear" then
        if SmartMailLog then SmartMailLog.debugLog = {} end
        if SmartMailLog_PerChar then SmartMailLog_PerChar.debugLog = {} end
        if SmartMailDebugFrameText then SmartMailDebugFrameText:SetText("") end
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
    if not SmartMailLog then SmartMailLog = { sessions = {} } end
    if not SmartMailLog.debugScan then SmartMailLog.debugScan = {} end
    
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
    
    SmartMailLog.debugScan[GetTime()] = scanResults
    SmartMail_Debug("Scan complete. Found " .. found .. " categorised items.")
end


-- Register frames to be closed with the ESC key
tinsert(UISpecialFrames, "SmartMailMainFrame")

-- MainFrame ESC interceptor setup
SmartMail.openChildFrames = {}

local originalMainFrameHide = SmartMailMainFrame.Hide
SmartMailMainFrame.Hide = function(self)
    SmartMail_Debug("SmartMailMainFrame:Hide() called.")
    
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
    if SmartMailLog and SmartMailLog.debugLog then
        local text = table.concat(SmartMailLog.debugLog, "\n")
        if SmartMailDebugFrameText then
            SmartMailDebugFrameText:SetText(text)
            
            -- Scroll to top (newest is on top)
            local scrollFrame = SmartMailDebugFrameContentFrameScrollFrame
            if scrollFrame then
                scrollFrame:UpdateScrollChildRect()
                scrollFrame:SetVerticalScroll(0)
            end
        end
    end
end)

SmartMailLogFrame:SetScript("OnShow", function()
    if SmartMail_UpdateLogFrame then
        SmartMail_UpdateLogFrame()
    end
end)

-- Profile Editor Logic
local createdCheckboxes = false
function SmartMail_InitializeProfileCheckboxes()
    if createdCheckboxes then return end
    SmartMail_Debug("Initializing Category Checkboxes...")
    
    local parent = SmartMailProfileEditorFrameCheckboxContainer
    local categories = Bridge:GetCategoryNames()
    SmartMail.checkboxes = {}
    
    for i, catName in ipairs(categories) do
        local cb = CreateFrame("CheckButton", "SmartMailProfileEditorCheckbox" .. i, parent, "UICheckButtonTemplate")
        cb:SetWidth(24)
        cb:SetHeight(24)
        
        -- Positioning: 2 columns
        local col = math.mod(i - 1, 2)
        local row = math.floor((i - 1) / 2)
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", col * 130, -row * 24)
        
        local text = getglobal(cb:GetName() .. "Text")
        text:SetText(catName)
        
        cb.categoryName = catName
        table.insert(SmartMail.checkboxes, cb)
    end
    
    createdCheckboxes = true
end

function SmartMail_OpenProfileEditor(characterName)
    SmartMail_Debug("Opening Profile Editor for: " .. tostring(characterName or "NEW"))
    SmartMail_InitializeProfileCheckboxes()
    SmartMail.editingProfileName = characterName
    
    SmartMailProfileEditorFrameNameEditBox:SetText(characterName or "")
    
    if not SmartMailDB_PerChar then SmartMailDB_PerChar = { profiles = {} } end
    if not SmartMailDB_PerChar.profiles then SmartMailDB_PerChar.profiles = {} end
    local existingProfile = SmartMailDB_PerChar.profiles[characterName]
    
    for _, cb in ipairs(SmartMail.checkboxes) do
        if existingProfile and existingProfile[cb.categoryName] then
            cb:SetChecked(1)
        else
            cb:SetChecked(nil)
        end
    end
    
    SmartMailProfileEditorFrame:Show()
end

function SmartMail_SaveProfile()
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
    if not SmartMailDB then SmartMailDB = { profiles = {} } end
    if not SmartMailDB.profiles then SmartMailDB.profiles = {} end
    
    local selectedCategories = {}
    local count = 0
    for _, cb in ipairs(SmartMail.checkboxes) do
        if cb:GetChecked() then
            selectedCategories[cb.categoryName] = true
            count = count + 1
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
    SmartMail_UpdateProfileList()
end

function SmartMail_DeleteProfile(charName)
    if not charName then return end
    
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
    local isPopupOpen = false
    if SmartMailConfirmFrame and SmartMailConfirmFrame:IsVisible() then isPopupOpen = true end
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
            line = CreateFrame("Button", nil, scrollChild)
            line:SetWidth(270)
            line:SetHeight(20)
            
            local text = line:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetJustifyH("LEFT")
            text:SetPoint("LEFT", line, "LEFT", 10, 0)
            line.text = text
            
            local highlight = line:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints(line)
            highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            highlight:SetBlendMode("ADD")
            
            local bg = line:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(line)
            bg:SetTexture(1, 1, 1, 0.15)
            line.bg = bg
            
            line:SetScript("OnClick", function()
                if SmartMailProfileEditorFrame and SmartMailProfileEditorFrame:IsVisible() then
                    SmartMail_Debug("Blocked profile selection: Editor Window is open.")
                    return
                end
                
                SmartMail.selectedProfile = this.charName
                SmartMail_Debug("Selected profile: " .. tostring(this.charName))
                SmartMail_UpdateProfileList()
                
                if SmartMailConfirmFrame and not SmartMailConfirmFrame:IsVisible() then
                    SmartMailConfirmFrame:Show()
                else
                    SmartMail_UpdateConfirmList()
                end
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
            line.bg:Show()
        else
            line.text:SetTextColor(1, 0.82, 0) -- Gold (Normal)
            line.bg:Hide()
        end
        
        line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
        line:Show()
        
        yOffset = yOffset - 20
        index = index + 1
    end
    
    SmartMail_UpdateActionButtons()
end

SmartMailMainFrame:SetScript("OnShow", function()
    SmartMail_UpdateProfileList()
end)

-- Wire up Add Button on Main UI
SmartMailMainFrameAddButton:SetScript("OnClick", function()
    SmartMail_Debug("Add Button clicked")
    SmartMail_OpenProfileEditor(nil)
end)



function SmartMail_LoadGlobalProfiles()
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
    SmartMail_LoadGlobalProfiles()
end)

function SmartMail_SaveItemSetting(profileName, itemID, key, value)
    if not SmartMailDB_PerChar then return end
    if not SmartMailDB_PerChar.profiles[profileName] then return end
    
    if not SmartMailDB_PerChar.profiles[profileName].itemSettings then
        SmartMailDB_PerChar.profiles[profileName].itemSettings = {}
    end
    if not SmartMailDB_PerChar.profiles[profileName].itemSettings[itemID] then
        SmartMailDB_PerChar.profiles[profileName].itemSettings[itemID] = {}
    end
    
    SmartMailDB_PerChar.profiles[profileName].itemSettings[itemID][key] = value
end

function SmartMail_UpdateConfirmList()
    local charName = SmartMail.selectedProfile
    if not charName then return end
    
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
                local index = this:GetParent().index
                local state = this:GetChecked()
                local itemData = SmartMail.confirmQueue[index]
                itemData.sendPart = state and itemData.partialStacks or 0
                local saveVal = state and "MAX" or 0
                SmartMail_SaveItemSetting(SmartMail.selectedProfile, itemData.itemID, "sendPart", saveVal)
            end)
            btn.partCheck = partCheck
            
            btn:SetScript("OnClick", function()
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
    SmartMail_UpdateConfirmList()
end)

SmartMailConfirmFrameSendButton:SetScript("OnClick", function()
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

SmartMailDebugFrame:SetScript("OnShow", function()
    if not SmartMailLog then SmartMailLog = {} end
    if not SmartMailLog.debugLog then SmartMailLog.debugLog = {} end
    
    local fullText = table.concat(SmartMailLog.debugLog, "\n")
    if SmartMailDebugFrameText then
        SmartMailDebugFrameText:SetText(fullText)
        local scrollFrame = SmartMailDebugFrameContentFrameScrollFrame
        if scrollFrame then
            scrollFrame:UpdateScrollChildRect()
            scrollFrame:SetVerticalScroll(0)
        end
    end
end)

-- Hook all child frames to stack logic at the very end to avoid SetScript overwrites
function SmartMail_HookFrameStack(frame)
    if not frame then return end
    local oldShow = frame:GetScript("OnShow")
    frame:SetScript("OnShow", function()
        for i, f in ipairs(SmartMail.openChildFrames) do
            if f == frame then tremove(SmartMail.openChildFrames, i) break end
        end
        tinsert(SmartMail.openChildFrames, frame)
        if oldShow then oldShow() end
        if SmartMail_UpdateActionButtons then SmartMail_UpdateActionButtons() end
    end)
    
    local oldHide = frame:GetScript("OnHide")
    frame:SetScript("OnHide", function()
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
function SmartMail_SendAll(mode)
    if SmartMail.isBusy then return end
    
    -- Gather flat queues for every single profile
    SmartMail.sendAllProfilesQueue = {}
    
    if SmartMailDB_PerChar and SmartMailDB_PerChar.profiles then
        for charName, _ in pairs(SmartMailDB_PerChar.profiles) do
            local flat = SmartMailQueue:GenerateDirectFlatQueue(charName, mode)
            if flat and table.getn(flat) > 0 then
                table.insert(SmartMail.sendAllProfilesQueue, { name = charName, queue = flat })
            end
        end
    end
    
    if table.getn(SmartMail.sendAllProfilesQueue) == 0 then
        SmartMail_Debug("SendAll: No items to send for any profile.")
        return
    end
    
    SmartMailMainFrame:Hide()
    SmartMail_SendAll_Next()
end

function SmartMail_SendAll_Next()
    if table.getn(SmartMail.sendAllProfilesQueue) == 0 then
        SmartMail_Debug("SendAll: All profiles completed successfully!")
        return
    end
    
    local profileData = table.remove(SmartMail.sendAllProfilesQueue, 1)
    SmartMail_Debug("SendAll: Routing " .. table.getn(profileData.queue) .. " items to " .. profileData.name)
    SmartMailEngine:Start(profileData.name, profileData.queue, SmartMail_SendAll_Next)
end