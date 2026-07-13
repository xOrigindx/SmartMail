-- v1.0.2: UI Unification and Custom Frame Overhaul
SmartMailInbox = {
    isOpenAllRunning = false,
    currentIndex = 1
}

local inboxFrame = CreateFrame("Frame")
inboxFrame:RegisterEvent("MAIL_INBOX_UPDATE")
inboxFrame:RegisterEvent("UI_ERROR_MESSAGE")

function SmartMailInbox:Start()
    SmartMail_Debug("SmartMailInbox:Start called...")
    if not InboxFrame or not InboxFrame:IsVisible() then return end
    
    self.startCount = GetInboxNumItems()
    local expectedMsg = "SmartMail: Starting Open All. Expected to process " .. self.startCount .. " mail(s)."
    DEFAULT_CHAT_FRAME:AddMessage(expectedMsg, 1, 1, 0)
    SmartMail_Debug("Inbox: " .. expectedMsg)
    
    SmartMail_Debug("Inbox: Starting Open All...")
    self.isOpenAllRunning = true
    self.currentIndex = GetInboxNumItems()
    
    if SmartMailMainFrameOpenAllButton then
        SmartMailMainFrameOpenAllButton:SetText("Stop")
    end
    
    self:ProcessNext()
end

function SmartMailInbox:Abort()
    SmartMail_Debug("SmartMailInbox:Abort called...")
    SmartMail_Debug("Inbox: Open All stopped.")
    self.isOpenAllRunning = false
    if SmartMailMainFrameOpenAllButton then
        SmartMailMainFrameOpenAllButton:SetText("Open All")
    end
end

-- We use a short delay after MAIL_INBOX_UPDATE because the server sometimes sends multiple rapid updates
local waitTime = 0
local waitingForUpdate = false

inboxFrame:SetScript("OnUpdate", function()
    if not SmartMailInbox.isOpenAllRunning then return end
    if waitingForUpdate then
        waitTime = waitTime + arg1
        if waitTime > SmartMail.OpenDelay then
            waitingForUpdate = false
            SmartMailInbox:ProcessNext()
        end
    end
end)

inboxFrame:SetScript("OnEvent", function()
    if event == "MAIL_INBOX_UPDATE" then
        if GetInboxNumItems() == 0 then
            MiniMapMailFrame:Hide()
        end
        if SmartMailInbox.isOpenAllRunning then
            waitTime = 0
            waitingForUpdate = true
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if SmartMailInbox.isOpenAllRunning then
            if arg1 == ERR_INV_FULL then
                SmartMail_Debug("Inbox: Inventory full, aborting Open All.")
                DEFAULT_CHAT_FRAME:AddMessage("SmartMail: Open All aborted (Inventory Full).", 1, 0, 0)
                SmartMailInbox:Abort()
            elseif arg1 == ERR_ITEM_MAX_COUNT then
                SmartMail_Debug("Inbox: Unique item cap reached, skipping mail.")
                SmartMailInbox.currentIndex = SmartMailInbox.currentIndex - 1
                waitingForUpdate = true
                waitTime = 0
            elseif arg1 == ERR_MAIL_DATABASE_ERROR or (arg1 and string.find(arg1, "Database Error")) then
                SmartMail_Debug("Inbox: Internal Mail Database Error! Rate limit hit, retrying in 1s...")
                waitingForUpdate = true
                waitTime = -0.5
            end
        end
    end
end)

function SmartMailInbox:ProcessNext()
    SmartMail_Debug("SmartMailInbox:ProcessNext called...")
    local numItems = GetInboxNumItems()
    if numItems == 0 then
        MiniMapMailFrame:Hide()
        SmartMail_Debug("Inbox: Open All complete.")
        local msg = "SmartMail: Open All Complete! Processed " .. (self.startCount or 0) .. " mail(s)."
        DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0)
        self:Abort()
        return
    end

    local processableIndex = nil
    
    if SmartMailInbox.isRandom then
        local validIndices = {}
        for i = 1, numItems do
            local _, _, _, _, _, CODAmount, _, _, _, _, _, _, isGM = GetInboxHeaderInfo(i)
            if CODAmount == 0 and not isGM then
                table.insert(validIndices, i)
            end
        end
        if table.getn(validIndices) > 0 then
            processableIndex = validIndices[math.random(1, table.getn(validIndices))]
        end
    else
        for i = 1, numItems do
            local _, _, _, _, _, CODAmount, _, _, _, _, _, _, isGM = GetInboxHeaderInfo(i)
            if CODAmount == 0 and not isGM then
                processableIndex = i
                break
            end
        end
    end

    if not processableIndex then
        SmartMail_Debug("Inbox: Open All complete. (Remaining mails are COD/GM)")
        local remaining = GetInboxNumItems()
        local processed = (self.startCount or remaining) - remaining
        local expected = self.startCount or remaining
        local msg = "SmartMail: Open All Complete! Expected: " .. expected .. ". Processed: " .. processed .. ". Skipped: " .. remaining .. "."
        DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0)
        self:Abort()
        return
    end

    local _, _, sender, _, money, _, _, hasItem = GetInboxHeaderInfo(processableIndex)

    GetInboxText(processableIndex) -- Force server to mark as read

    if money > 0 then
        SmartMail_Debug("Inbox: Taking money at index " .. processableIndex)
        local g = math.floor(money / 10000)
        local s = math.floor(math.mod(money, 10000) / 100)
        local c = math.mod(money, 100)
        local mStr = ""
        if g > 0 then mStr = mStr .. g .. "g " end
        if s > 0 then mStr = mStr .. s .. "s " end
        if c > 0 or mStr == "" then mStr = mStr .. c .. "c" end
        mStr = string.gsub(mStr, " $", "")
        if SmartMail_Log then SmartMail_Log("Received " .. mStr .. " from " .. (sender or "Unknown"), "INCOMING") end
        
        TakeInboxMoney(processableIndex)
        return
    elseif hasItem then
        SmartMail_Debug("Inbox: Taking item at index " .. processableIndex)
        local itemName, _, count = GetInboxItem(processableIndex)
        if SmartMail_Log then SmartMail_Log("Received " .. (count or 1) .. " " .. (itemName or "Unknown Item") .. " from " .. (sender or "Unknown"), "INCOMING") end
        
        TakeInboxItem(processableIndex)
        return
    else
        SmartMail_Debug("Inbox: Deleting empty mail at index " .. processableIndex)
        DeleteInboxItem(processableIndex)
        return
    end
end

-- Hook into MAIL_CLOSED to abort running operations
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("MAIL_CLOSED")
hookFrame:SetScript("OnEvent", function()
    if event == "MAIL_CLOSED" then
        if SmartMailInbox.isOpenAllRunning then
            SmartMailInbox:Abort()
        end
    end
end)
