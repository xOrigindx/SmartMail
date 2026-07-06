SmartMailInbox = {
    isOpenAllRunning = false,
    currentIndex = 1
}

local inboxFrame = CreateFrame("Frame")
inboxFrame:RegisterEvent("MAIL_INBOX_UPDATE")
inboxFrame:RegisterEvent("UI_ERROR_MESSAGE")

local openAllButton = nil

local function CreateOpenAllButton()
    if openAllButton then return end
    if not InboxFrame then return end
    
    openAllButton = CreateFrame("Button", "SmartMailOpenAllButton", InboxFrame, "UIPanelButtonTemplate")
    openAllButton:SetPoint("BOTTOM", InboxFrame, "BOTTOM", -10, 90)
    openAllButton:SetWidth(120)
    openAllButton:SetHeight(25)
    openAllButton:SetText("Open All")
    
    openAllButton:SetScript("OnClick", function()
        if SmartMailInbox.isOpenAllRunning then
            SmartMailInbox:Abort()
        else
            SmartMailInbox:Start()
        end
    end)
end

function SmartMailInbox:Start()
    if not InboxFrame or not InboxFrame:IsVisible() then return end
    
    SmartMail_Debug("Inbox: Starting Open All...")
    self.isOpenAllRunning = true
    self.currentIndex = GetInboxNumItems()
    
    if openAllButton then
        openAllButton:SetText("Stop")
    end
    
    self:ProcessNext()
end

function SmartMailInbox:Abort()
    SmartMail_Debug("Inbox: Open All stopped.")
    self.isOpenAllRunning = false
    if openAllButton then
        openAllButton:SetText("Open All")
    end
end

-- We use a short delay after MAIL_INBOX_UPDATE because the server sometimes sends multiple rapid updates
local waitTime = 0
local waitingForUpdate = false

inboxFrame:SetScript("OnUpdate", function()
    if not SmartMailInbox.isOpenAllRunning then return end
    if waitingForUpdate then
        waitTime = waitTime + arg1
        if waitTime > 0.2 then
            waitingForUpdate = false
            SmartMailInbox:ProcessNext()
        end
    end
end)

inboxFrame:SetScript("OnEvent", function()
    if event == "MAIL_INBOX_UPDATE" then
        if SmartMailInbox.isOpenAllRunning then
            waitTime = 0
            waitingForUpdate = true
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if SmartMailInbox.isOpenAllRunning then
            if arg1 == ERR_INV_FULL then
                SmartMail_Debug("Inbox: Inventory full, aborting Open All.")
                SmartMailInbox:Abort()
            elseif arg1 == ERR_ITEM_MAX_COUNT then
                SmartMail_Debug("Inbox: Unique item cap reached, skipping mail.")
                SmartMailInbox.currentIndex = SmartMailInbox.currentIndex - 1
                waitingForUpdate = true
                waitTime = 0
            end
        end
    end
end)

function SmartMailInbox:ProcessNext()
    local numItems = GetInboxNumItems()
    if self.currentIndex > numItems then 
        self.currentIndex = numItems 
    end
    
    while self.currentIndex >= 1 do
        local _, _, _, _, money, CODAmount, _, hasItem, _, _, _, _, isGM = GetInboxHeaderInfo(self.currentIndex)
        
        if CODAmount > 0 or isGM then
            SmartMail_Debug("Inbox: Skipping mail at index " .. self.currentIndex .. " (COD or GM)")
            self.currentIndex = self.currentIndex - 1
        else
            SmartMail_Debug("Inbox: Processing mail at index " .. self.currentIndex)
            
            if money > 0 then TakeInboxMoney(self.currentIndex) end
            if hasItem then TakeInboxItem(self.currentIndex) end
            DeleteInboxItem(self.currentIndex)
            
            self.currentIndex = self.currentIndex - 1
            
            -- Wait for MAIL_INBOX_UPDATE
            return 
        end
    end
    
    SmartMail_Debug("Inbox: Open All complete.")
    self:Abort()
end

-- Hook into MAIL_SHOW to create the button
local originalMailShow = inboxFrame:GetScript("OnEvent")
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("MAIL_SHOW")
hookFrame:RegisterEvent("MAIL_CLOSED")
hookFrame:SetScript("OnEvent", function()
    if event == "MAIL_SHOW" then
        CreateOpenAllButton()
    elseif event == "MAIL_CLOSED" then
        if SmartMailInbox.isOpenAllRunning then
            SmartMailInbox:Abort()
        end
    end
end)
