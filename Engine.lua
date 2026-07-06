SmartMailEngine = {
    flatQueue = {},
    retryQueue = {},
    target = nil,
    isSending = false,
    currentItem = nil,
    state = 0
}

local engineFrame = CreateFrame("Frame")
engineFrame:RegisterEvent("MAIL_SEND_SUCCESS")
engineFrame:RegisterEvent("MAIL_FAILED")
engineFrame:RegisterEvent("UI_ERROR_MESSAGE")

engineFrame:SetScript("OnEvent", function()
    if not SmartMailEngine.isSending then return end
    
    if event == "MAIL_SEND_SUCCESS" then
        SmartMail_Debug("Engine: MAIL_SEND_SUCCESS received.")
        SmartMailEngine.currentItem = nil
        SmartMailEngine:Next()
    elseif event == "MAIL_FAILED" then
        SmartMail_Debug("Engine: MAIL_FAILED received.")
        SmartMailEngine:FailCurrent()
    elseif event == "UI_ERROR_MESSAGE" then
        if arg1 == "Cannot find mail recipient" then
            SmartMail_Debug("Engine: FATAL - Cannot find mail recipient!")
            SmartMailEngine:Abort()
        elseif arg1 == "You do not have enough money" then
            SmartMail_Debug("Engine: FATAL - Not enough money for postage!")
            SmartMailEngine:Abort()
        end
    end
end)

local waitTime = 0

engineFrame:SetScript("OnUpdate", function()
    if not SmartMailEngine.isSending then return end
    
    if SmartMailEngine.state == 1 then
        -- Wait for Tab Switch to register and UI to clear (0.15s)
        waitTime = waitTime + arg1
        if waitTime > 0.15 then
            waitTime = 0
            SmartMailEngine.state = 2
            
            -- Pick up and attach
            local item = SmartMailEngine.currentItem
            ClearCursor()
            PickupContainerItem(item.bag, item.slot)
            ClickSendMailItemButton()
        end
    elseif SmartMailEngine.state == 2 then
        -- Wait for Attachment drop to register (0.2s)
        waitTime = waitTime + arg1
        if waitTime > 0.2 then
            waitTime = 0
            SmartMailEngine.state = 3
            local item = SmartMailEngine.currentItem
            local subject = "SmartMail: " .. tostring(item.category)
            SendMail(SmartMailEngine.target, subject, "")
        end
    end
end)

function SmartMailEngine:Start(targetName, queue, onComplete)
    if not MailFrame or not MailFrame:IsVisible() then
        SmartMail_Debug("Engine Error: Mailbox is not open!")
        return
    end
    
    self.target = targetName
    self.flatQueue = queue
    self.onComplete = onComplete
    self.retryQueue = {}
    self.isSending = true
    self.state = 0
    SmartMail.isBusy = true
    
    SmartMail_Debug("Engine: Starting mail sequence for " .. tostring(self.target) .. " with " .. table.getn(self.flatQueue) .. " items.")
    self:Next()
end

function SmartMailEngine:Next()
    if table.getn(self.flatQueue) == 0 then
        if table.getn(self.retryQueue) > 0 then
            SmartMail_Debug("Engine: Main queue empty, processing " .. table.getn(self.retryQueue) .. " retries...")
            self.flatQueue = self.retryQueue
            self.retryQueue = {}
            self:Next()
        else
            SmartMail_Debug("Engine: Sequence complete!")
            self:Finish()
        end
        return
    end
    
    local item = table.remove(self.flatQueue, 1)
    self.currentItem = item
    
    SmartMail_Debug("Engine: Sending item ID " .. item.itemID .. " from bag " .. item.bag .. " slot " .. item.slot)
    
    -- Switch Tab
    if not SendMailFrame or not SendMailFrame:IsVisible() then
        if MailFrameTab2 and MailFrameTab2:GetScript("OnClick") then
            local onClick = MailFrameTab2:GetScript("OnClick")
            local oldThis = this
            this = MailFrameTab2
            onClick()
            this = oldThis
        else
            MailFrameTab_OnClick(2)
        end
    end
    
    -- Start State Machine
    waitTime = 0
    self.state = 1
end

function SmartMailEngine:FailCurrent()
    if self.currentItem then
        SmartMail_Debug("Engine: Failed to send item, adding to retry queue.")
        table.insert(self.retryQueue, self.currentItem)
        self.currentItem = nil
    end
    self:Next()
end

function SmartMailEngine:Abort()
    SmartMail_Debug("Engine: Aborting sequence!")
    self.flatQueue = {}
    self.retryQueue = {}
    self:Finish()
end

function SmartMailEngine:Finish()
    ClearCursor()
    self.isSending = false
    SmartMail.isBusy = false
    self.target = nil
    self.currentItem = nil
    SmartMail_Debug("Engine: Done.")
    
    if self.onComplete then
        local cb = self.onComplete
        self.onComplete = nil
        cb()
    end
end

