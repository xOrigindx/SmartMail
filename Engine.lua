-- v1.0.4: fixed C API SendMail empty string exception
SmartMailEngine = {
    flatQueue = {},
    retryQueue = {},
    target = nil,
    isSending = false,
    currentItem = nil,
    state = 0
}

-- Save pure native C-functions before any addon hooks them at PLAYER_LOGIN
local OrigPickupContainerItem = PickupContainerItem
local OrigClickSendMailItemButton = ClickSendMailItemButton

local engineFrame = CreateFrame("Frame")
engineFrame:RegisterEvent("MAIL_SEND_SUCCESS")
engineFrame:RegisterEvent("MAIL_FAILED")
engineFrame:RegisterEvent("UI_ERROR_MESSAGE")

engineFrame:SetScript("OnEvent", function()
    if not SmartMailEngine.isSending then return end
    
    if event == "MAIL_SEND_SUCCESS" then
        local elapsed = GetTime() - (SmartMailEngine.lastSendTime or GetTime())
        SmartMail_Debug(string.format("Engine: MAIL_SEND_SUCCESS received (elapsed: %.3fs)", elapsed))
        SmartMailEngine.successCount = SmartMailEngine.successCount + 1
        local item = SmartMailEngine.currentItem
        if item then
            local n = item.name or item.category or "Unknown Item"
            local amt = item.amount or item.count or 1
            if not SmartMailEngine.sentItems[n] then SmartMailEngine.sentItems[n] = 0 end
            SmartMailEngine.sentItems[n] = SmartMailEngine.sentItems[n] + amt
        end
        SmartMailEngine.currentItem = nil
        
        local delay = SmartMail.SendDelay
        if delay > 0 then
            waitTime = 0
            SmartMailEngine.state = 4
        else
            SmartMailEngine:Next()
        end
    elseif event == "MAIL_FAILED" then
        local elapsed = GetTime() - (SmartMailEngine.lastSendTime or GetTime())
        SmartMail_Debug(string.format("Engine: MAIL_FAILED received (elapsed: %.3fs)", elapsed))
        
        -- Ignore phantom failures if we already succeeded and are just waiting out the delay
        if SmartMailEngine.state == 4 then
            SmartMail_Debug("Engine: Ignoring MAIL_FAILED (already succeeded, waiting for delay)")
            return
        end
        
        if GetSendMailItem() then
            OrigClickSendMailItemButton()
            ClearCursor()
        end
        SmartMailEngine:FailCurrent()
    elseif event == "UI_ERROR_MESSAGE" then
        if string.find(string.lower(arg1), "recipient") then
            SmartMail_Debug("Engine: FATAL - Cannot find mail recipient! (" .. arg1 .. ")")
            SmartMailEngine:Abort("Unknown Recipient")
        elseif string.find(string.lower(arg1), "money") then
            SmartMail_Debug("Engine: FATAL - Not enough money for postage! (" .. arg1 .. ")")
            SmartMailEngine:Abort("Not Enough Money")
        end
    end
end)

local waitTime = 0

engineFrame:SetScript("OnUpdate", function()
    if not SmartMailEngine.isSending then return end
    
    if SmartMailEngine.state == 1 then
        -- Wait for Tab Switch to register and UI to clear
        waitTime = waitTime + arg1
        if waitTime > SmartMail.SendDelay then
            if GetSendMailItem() then
                OrigClickSendMailItemButton()
                ClearCursor()
            end
            
            local item = SmartMailEngine.currentItem
            local texture, itemCount, locked = GetContainerItemInfo(item.bag, item.slot)
            itemCount = tonumber(itemCount) or 1
            if not texture then
                SmartMail_Debug("Engine: Slot empty, treating as success.")
                SmartMailEngine.successCount = SmartMailEngine.successCount + 1
                waitTime = 0
                SmartMailEngine.state = 0
                SmartMailEngine.currentItem = nil
                SmartMailEngine:Next()
                return
            end
            
            if locked then return end
            
            ClearCursor()
            local amt = tonumber(item.amount)
            if amt and amt < itemCount then
                local eBag, eSlot = SmartMailEngine:FindEmptySlot()
                if not eBag then
                    SmartMail_Debug("Engine: Bags full! Cannot split item.")
                    waitTime = 0
                    SmartMailEngine.state = 0
                    SmartMailEngine:FailCurrent()
                    return
                end
                SmartMailEngine.splitBag = eBag
                SmartMailEngine.splitSlot = eSlot
                SplitContainerItem(item.bag, item.slot, amt)
                SmartMailEngine.state = 1.1
                waitTime = 0
            else
                OrigPickupContainerItem(item.bag, item.slot)
                SmartMailEngine.state = 1.5
                waitTime = 0
            end
        end
    elseif SmartMailEngine.state == 1.1 then
        waitTime = waitTime + arg1
        if CursorHasItem() then
            OrigPickupContainerItem(SmartMailEngine.splitBag, SmartMailEngine.splitSlot)
            SmartMailEngine.state = 1.2
            waitTime = 0
        elseif waitTime > 2.0 then
            SmartMail_Debug("Engine: Timeout waiting for split to cursor.")
            ClearCursor()
            SmartMailEngine.state = 0
            SmartMailEngine:FailCurrent()
        end
    elseif SmartMailEngine.state == 1.2 then
        waitTime = waitTime + arg1
        local tex, _, locked1 = GetContainerItemInfo(SmartMailEngine.splitBag, SmartMailEngine.splitSlot)
        local _, _, locked2 = GetContainerItemInfo(SmartMailEngine.currentItem.bag, SmartMailEngine.currentItem.slot)
        
        if tex and not locked1 and not locked2 then
            SmartMailEngine.currentItem.bag = SmartMailEngine.splitBag
            SmartMailEngine.currentItem.slot = SmartMailEngine.splitSlot
            SmartMailEngine.currentItem.amount = nil
            SmartMailEngine.state = 1
            waitTime = 0
        elseif waitTime > 3.0 then
            SmartMail_Debug("Engine: Timeout waiting for split to settle.")
            ClearCursor()
            SmartMailEngine.state = 0
            SmartMailEngine:FailCurrent()
        end
    elseif SmartMailEngine.state == 1.5 then
        waitTime = waitTime + arg1
        if CursorHasItem() then
            OrigClickSendMailItemButton()
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
            SmartMailEngine.lastSendTime = GetTime()
            SendMail(SmartMailEngine.target, subject, " ")
        elseif waitTime > 2.0 then
            SmartMail_Debug("Engine: Timeout waiting for attachment.")
            waitTime = 0
            if GetSendMailItem() then
                OrigClickSendMailItemButton()
            end
            ClearCursor()
            SmartMailEngine.state = 0
            SmartMailEngine:FailCurrent()
        end
    elseif SmartMailEngine.state == 3 then
        waitTime = waitTime + arg1
        if waitTime > 4.0 then
            SmartMail_Debug("Engine: Timeout waiting for MAIL_SEND_SUCCESS.")
            if GetSendMailItem() then
                OrigClickSendMailItemButton()
                ClearCursor()
            end
            SmartMailEngine.state = 0
            waitTime = 0
            SmartMailEngine:FailCurrent()
        end
    elseif SmartMailEngine.state == 4 then
        waitTime = waitTime + arg1
        local delay = SmartMail.SendDelay
        if waitTime > delay then
            SmartMailEngine.state = 0
            waitTime = 0
            SmartMailEngine:Next()
        end
    end
end)

function SmartMailEngine:FindEmptySlot()
    SmartMail_Debug("SmartMailEngine:FindEmptySlot called...")
    for slot = 1, GetContainerNumSlots(0) do
        if not GetContainerItemInfo(0, slot) then return 0, slot end
    end
    for bag = 1, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if not GetContainerItemInfo(bag, slot) then return bag, slot end
        end
    end
    return nil, nil
end

function SmartMailEngine:Start(targetName, queue, onComplete)
    SmartMail_Debug("SmartMailEngine:Start called...")
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
    self.failCount = 0
    self.sentItems = {}
    self.failedItems = {}
    SmartMail.isBusy = true
    
    SmartMail_Debug("Engine: Starting mail sequence for " .. tostring(self.target) .. " with " .. table.getn(self.flatQueue) .. " items.")
    self:Next()
end

function SmartMailEngine:Next()
    SmartMail_Debug("SmartMailEngine:Next called...")
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
    
    if item.isMoney then
        SmartMail_Debug("Engine: Sending Money (" .. tostring(item.amount) .. "c)")

        SetSendMailMoney(item.amount)
        SmartMailEngine.lastSendTime = GetTime()
        SendMail(self.target, "SmartMail: Funds", " ")
        waitTime = 0
        self.state = 3
        return
    end
    
    SmartMail_Debug("Engine: Sending item ID " .. tostring(item.itemID) .. " from bag " .. tostring(item.bag) .. " slot " .. tostring(item.slot))
    

    -- Start State Machine
    waitTime = 0
    self.state = 1
end

function SmartMailEngine:FailCurrent()
    SmartMail_Debug("SmartMailEngine:FailCurrent called...")
    if self.currentItem then
        self.currentItem.retries = (self.currentItem.retries or 0) + 1
        SmartMail_Debug("Engine: Failed to send item (Attempt " .. self.currentItem.retries .. "), adding to retry queue.")
        table.insert(self.retryQueue, self.currentItem)
        self.currentItem = nil
    end
    self:Next()
end

function SmartMailEngine:Abort(reason)
    SmartMail_Debug("SmartMailEngine:Abort called...")
    SmartMail_Debug("Engine: Aborting sequence!")
    self.abortReason = reason or "Aborted"
    if not self.failedItems then self.failedItems = {} end
    
    if self.currentItem then
        self.failCount = (self.failCount or 0) + 1
        table.insert(self.failedItems, { item = self.currentItem, reason = self.abortReason })
    end
    for _, it in ipairs(self.flatQueue or {}) do
        self.failCount = (self.failCount or 0) + 1
        table.insert(self.failedItems, { item = it, reason = self.abortReason })
    end
    for _, it in ipairs(self.retryQueue or {}) do
        self.failCount = (self.failCount or 0) + 1
        table.insert(self.failedItems, { item = it, reason = self.abortReason })
    end
    
    self.flatQueue = {}
    self.retryQueue = {}
    self.currentItem = nil
    self:Finish()
end

function SmartMailEngine:Finish()
    SmartMail_Debug("SmartMailEngine:Finish called...")
    ClearCursor()
    self.isSending = false
    SmartMail.isBusy = false
    
    if self.target and self.successCount > 0 then
        local msgs = {}
        
        -- Create Ledger if missing
        if not SmartMailDB then SmartMailDB = {} end
        if not SmartMailDB.ledger then SmartMailDB.ledger = {} end
        
        local tx = {
            sender = UnitName("player"),
            recipient = self.target,
            time = time(),
            date = date("%Y-%m-%d %H:%M:%S"),
            items = {}
        }

        local hasItems = false
        for n, amt in pairs(self.sentItems or {}) do
            if n == "MONEY" then
                local g = math.floor(amt / 10000)
                local s = math.floor(math.mod(amt, 10000) / 100)
                local c = math.mod(amt, 100)
                local mStr = ""
                if g > 0 then mStr = mStr .. g .. "g " end
                if s > 0 then mStr = mStr .. s .. "s " end
                if c > 0 or mStr == "" then mStr = mStr .. c .. "c" end
                mStr = string.gsub(mStr, " $", "")
                
                if SmartMail_Log then
                    SmartMail_Log("Sent " .. mStr .. " to " .. tostring(self.target), "OUTGOING")
                end
                table.insert(tx.items, { name = "Money", count = mStr })
                hasItems = true
            else
                if SmartMail_Log then
                    SmartMail_Log("Sent " .. amt .. " " .. n .. " to " .. tostring(self.target), "OUTGOING")
                end
                table.insert(tx.items, { name = n, count = amt })
                hasItems = true
            end
        end
        
        table.insert(SmartMailDB.ledger, tx)
        
        if not hasItems then
            if SmartMail_Log then
                SmartMail_Log("Successfully sent " .. self.successCount .. " item(s) to " .. tostring(self.target), "OUTGOING")
            end
        end
    end
    
    SmartMail_Debug("Engine: Done.")
    
    if self.onComplete then
        local cb = self.onComplete
        local s = self.successCount
        local f = self.failCount or 0
        local reason = self.abortReason or (f > 0 and "Max Retries Reached" or nil)
        local fItems = self.failedItems or {}
        
        -- Reset engine state AFTER capturing stats for callback
        self.target = nil
        self.currentItem = nil
        self.successCount = 0
        self.failCount = 0
        self.failedItems = {}
        self.onComplete = nil
        self.abortReason = nil
        
        cb(s, f, reason, fItems)
    else
        self.target = nil
        self.currentItem = nil
        self.successCount = 0
        self.failCount = 0
        self.failedItems = {}
        self.abortReason = nil
    end
end

