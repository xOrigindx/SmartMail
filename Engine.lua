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
        SmartMailEngine.successCount = SmartMailEngine.successCount + 1
        SmartMailEngine.currentItem = nil
        SmartMailEngine:Next()
    elseif event == "MAIL_FAILED" then
        SmartMail_Debug("Engine: MAIL_FAILED received.")
        if GetSendMailItem() then
            ClickSendMailItemButton()
            ClearCursor()
        end
        SmartMailEngine:FailCurrent()
    elseif event == "UI_ERROR_MESSAGE" then
        if string.find(string.lower(arg1), "recipient") then
            SmartMail_Debug("Engine: FATAL - Cannot find mail recipient! (" .. arg1 .. ")")
            SmartMailEngine:Abort()
        elseif string.find(string.lower(arg1), "money") then
            SmartMail_Debug("Engine: FATAL - Not enough money for postage! (" .. arg1 .. ")")
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
            if GetSendMailItem() then
                ClickSendMailItemButton()
                ClearCursor()
            end
            
            local item = SmartMailEngine.currentItem
            local texture, itemCount = GetContainerItemInfo(item.bag, item.slot)
            if not texture then
                SmartMail_Debug("Engine: Slot empty, treating as success.")
                SmartMailEngine.successCount = SmartMailEngine.successCount + 1
                waitTime = 0
                SmartMailEngine.state = 0
                SmartMailEngine.currentItem = nil
                SmartMailEngine:Next()
                return
            end
            
            waitTime = 0
            SmartMailEngine.state = 1.5
            
            -- Pick up and wait for cursor
            ClearCursor()
            if item.amount and item.amount < itemCount then
                SplitContainerItem(item.bag, item.slot, item.amount)
            else
                PickupContainerItem(item.bag, item.slot)
            end
        end
    elseif SmartMailEngine.state == 1.5 then
        waitTime = waitTime + arg1
        if CursorHasItem() then
            ClickSendMailItemButton()
            SmartMailEngine.state = 2
            waitTime = 0
        elseif waitTime > 2.0 then
            SmartMail_Debug("Engine: Timeout waiting for cursor.")
            ClearCursor()
            SmartMailEngine:FailCurrent()
        end
    elseif SmartMailEngine.state == 2 then
        -- Wait for Attachment drop to register dynamically
        waitTime = waitTime + arg1
        if GetSendMailItem() then
            waitTime = 0
            SmartMailEngine.state = 3
            local item = SmartMailEngine.currentItem
            local subject = "SmartMail: " .. tostring(item.category)
            SendMail(SmartMailEngine.target, subject, "")
        elseif waitTime > 2.0 then
            SmartMail_Debug("Engine: Timeout waiting for attachment.")
            waitTime = 0
            if GetSendMailItem() then
                ClickSendMailItemButton()
            end
            ClearCursor()
            SmartMailEngine.state = 0
            SmartMailEngine:FailCurrent()
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
    self.successCount = 0
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
        self.currentItem.retries = (self.currentItem.retries or 0) + 1
        if self.currentItem.retries <= 3 then
            SmartMail_Debug("Engine: Failed to send item (Attempt " .. self.currentItem.retries .. "), adding to retry queue.")
            table.insert(self.retryQueue, self.currentItem)
        else
            SmartMail_Debug("Engine: Max retries exceeded for item, dropping.")
        end
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
    
    if self.target and self.successCount and self.successCount > 0 then
        if SmartMail_Log then
            SmartMail_Log("Successfully sent " .. self.successCount .. " item(s) to " .. tostring(self.target) .. ".")
        end
    end
    
    self.target = nil
    self.currentItem = nil
    self.successCount = 0
    SmartMail_Debug("Engine: Done.")
    
    if self.onComplete then
        local cb = self.onComplete
        self.onComplete = nil
        cb()
    end
end

