SmartMail = {
    isBusy      = false,
    lookup      = {},
    db          = nil,
    log         = nil,
    debug       = true,
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
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
        table.insert(SmartMailLog.debugLog, logMsg)
        
        -- Backup
        if not SmartMailLog_PerChar then SmartMailLog_PerChar = {} end
        if not SmartMailLog_PerChar.debugLog then SmartMailLog_PerChar.debugLog = {} end
        table.insert(SmartMailLog_PerChar.debugLog, logMsg)
        
        -- Update UI Debug Window
        if SmartMailDebugFrameText then
            local currentText = SmartMailDebugFrameText:GetText() or ""
            if currentText ~= "" then
                currentText = currentText .. "\n"
            end
            SmartMailDebugFrameText:SetText(currentText .. logMsg)
            
            -- Auto scroll down
            local scrollFrame = SmartMailDebugFrameContentFrameScrollFrame
            if scrollFrame then
                scrollFrame:UpdateScrollChildRect()
                scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
            end
        end
    end
end

-- Slash Command Logic
SLASH_SMARTMAIL1 = "/sm"
SLASH_SMARTMAIL2 = "/smartmail"
SlashCmdList["SMARTMAIL"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "scan" then
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
tinsert(UISpecialFrames, "SmartMailLogFrame")
tinsert(UISpecialFrames, "SmartMailDebugFrame")
tinsert(UISpecialFrames, "SmartMailProfileEditorFrame")

-- Populate Debug Window from saved variables when opened
SmartMailDebugFrame:SetScript("OnShow", function()
    if SmartMailLog and SmartMailLog.debugLog then
        local text = table.concat(SmartMailLog.debugLog, "\n")
        if SmartMailDebugFrameText then
            SmartMailDebugFrameText:SetText(text)
            
            -- Scroll to bottom
            local scrollFrame = SmartMailDebugFrameContentFrameScrollFrame
            if scrollFrame then
                scrollFrame:UpdateScrollChildRect()
                scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
            end
        end
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
    
    if not SmartMailDB then SmartMailDB = { profiles = {} } end
    if not SmartMailDB.profiles then SmartMailDB.profiles = {} end
    
    if not SmartMailDB_PerChar then SmartMailDB_PerChar = { profiles = {} } end
    if not SmartMailDB_PerChar.profiles then SmartMailDB_PerChar.profiles = {} end
    
    local selectedCategories = {}
    local count = 0
    for _, cb in ipairs(SmartMail.checkboxes) do
        if cb:GetChecked() then
            selectedCategories[cb.categoryName] = true
            count = count + 1
        end
    end
    
    SmartMailDB.profiles[charName] = selectedCategories
    SmartMailDB_PerChar.profiles[charName] = selectedCategories
    SmartMail_Debug("Successfully saved profile '" .. charName .. "' with " .. count .. " categories checked.")
    
    SmartMailProfileEditorFrame:Hide()
    SmartMail_UpdateProfileList()
end

function SmartMail_UpdateProfileList()
    if not SmartMailDB_PerChar or not SmartMailDB_PerChar.profiles then return end
    
    local scrollChild = SmartMailMainFrameListFrameScrollFrameScrollChild
    if not scrollChild then 
        SmartMail_Debug("UpdateProfileList failed: scrollChild is nil!")
        return 
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
            line = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            line:SetJustifyH("LEFT")
            table.insert(scrollChild.profileLines, line)
        end
        
        line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        
        local catCount = 0
        for k, v in pairs(categories) do if v then catCount = catCount + 1 end end
        
        line:SetText(charName .. " (" .. catCount .. " categories)")
        line:Show()
        
        yOffset = yOffset - 20
        index = index + 1
    end
end

SmartMailMainFrame:SetScript("OnShow", function()
    SmartMail_UpdateProfileList()
end)

-- Wire up Add Button on Main UI
SmartMailMainFrameAddButton:SetScript("OnClick", function()
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

SmartMailMainFrameLoadGlobalButton:SetScript("OnClick", function()
    SmartMail_LoadGlobalProfiles()
end)