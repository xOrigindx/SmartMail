-- ============================================================
-- Stress.lua — DEPRECATED as of v1.0
-- ============================================================
-- This module is not active in the v1.0 release build.
--
-- TODO: Stress 2.0 — planned for a future version targeting
-- vMaNGOS / cMaNGOS private server environments.
--
-- Planned Features:
--   - High-volume barrage testing (100+ mails per session)
--   - Automated Open All → Mass Send cycle loops
--   - Adaptive SendDelay auto-tuning based on success rate
--   - Per-server latency profiling
--
-- Current v1.0 uses a hardcoded 0.15s SendDelay which achieved
-- a 98% success rate in testing on Microbot Vanilla.
-- ============================================================

SmartMailStress = {}
SmartMailStress.deprecated = true  -- Stress 2.0 not yet implemented

local cycleActive = false
local autoIncrement = true
local lastSuccess = 0

function SmartMailStress:Log(msg)
    if not SmartMailStressLog then SmartMailStressLog = {} end
    local charName = UnitName("player") or "Unknown"
    local ms = string.format(".%03d", math.mod(GetTime() * 1000, 1000))
    local timeStr = date("[%H:%M:%S") .. ms .. "] "
    table.insert(SmartMailStressLog, timeStr .. "[" .. charName .. "] " .. msg)
end

local stressFrame = CreateFrame("Frame")
stressFrame:SetScript("OnUpdate", function()
    if not autoIncrement or not SmartMailEngine.isSending then return end
    if SmartMailEngine.successCount and SmartMailEngine.successCount > 0 then
        if SmartMailEngine.successCount ~= lastSuccess then
            lastSuccess = SmartMailEngine.successCount
            if math.mod(lastSuccess, 50) == 0 then
                SmartMail.SendDelay = (SmartMail.SendDelay or 0) + 0.1
                SmartMailStress:Log("50 sends reached! Increased SendDelay to " .. SmartMail.SendDelay)
            end
        end
    else
        lastSuccess = 0
    end
end)

SLASH_SMSTRESS1 = "/smstress"
SlashCmdList["SMSTRESS"] = function(msg)
    local _, _, cmd, arg1, arg2 = string.find(msg, "^(%S+)%s*(%S*)%s*(%S*)")
    if not cmd or cmd == "" then
        DEFAULT_CHAT_FRAME:AddMessage("SmartMail Stress Tests:")
        DEFAULT_CHAT_FRAME:AddMessage("/smstress dump [target] [money] - Empty bags to target.")
        DEFAULT_CHAT_FRAME:AddMessage("/smstress barrage [target] [money] - Empty bags to target 1-by-1.")
        DEFAULT_CHAT_FRAME:AddMessage("/smstress auto - Toggles auto-incrementing SendDelay by 0.1 every 50 sends.")
        DEFAULT_CHAT_FRAME:AddMessage("/smstress cycle - Loops Open All and Mass Send until mailbox is empty.")
        DEFAULT_CHAT_FRAME:AddMessage("/smstress stop - Stops any running cycle.")
        return
    end
    
    cmd = string.lower(cmd)
    
    if cmd == "auto" then
        autoIncrement = not autoIncrement
        if autoIncrement then
            DEFAULT_CHAT_FRAME:AddMessage("SmartMail Stress: Auto-increment Delay is now ON. Delay will increase by 0.1 every 50 sends.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("SmartMail Stress: Auto-increment Delay is now OFF.")
        end
    elseif cmd == "barrage" then
        local target = arg1
        if not target or target == "" then
            DEFAULT_CHAT_FRAME:AddMessage("SmartMail Stress: You must specify a target. e.g. /smstress barrage Ewwor")
            return
        end
        local withMoney = (arg2 == "1")
        SmartMailStress:StartBarrage(target, withMoney, false)
    elseif cmd == "dump" then
        local target = arg1
        if not target or target == "" then
            DEFAULT_CHAT_FRAME:AddMessage("SmartMail Stress: You must specify a target. e.g. /smstress dump Ewwor")
            return
        end
        local withMoney = (arg2 == "1")
        SmartMailStress:StartBarrage(target, withMoney, true)
    elseif cmd == "cycle" then
        SmartMailStress:StartCycle()
    elseif cmd == "stop" then
        cycleActive = false
        SmartMail.infiniteRetries = false
        SmartMail.isStressTest = false
        if SmartMailInbox and SmartMailInbox.isRandom ~= nil then
            SmartMailInbox.isRandom = false
            SmartMailInbox:Abort()
        end
        if SmartMailEngine and SmartMailEngine.isSending then
            SmartMailEngine:Abort("Stress test manually stopped")
        end
        SmartMailStress:Log("Cycle and tests forcefully stopped.")
    end
end

function SmartMailStress:StartBarrage(target, withMoney, isDump)
    SmartMail_Debug("SmartMailStress:StartBarrage called...")
    local queue = {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, itemIDStr = string.find(itemLink, "item:(%d+)")
                local itemID = tonumber(itemIDStr)
                if itemID then
                    local itemName = GetItemInfo(itemID)
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    
                    if isDump then
                        table.insert(queue, {
                            bag = bag,
                            slot = slot,
                            itemID = itemID,
                            count = itemCount,
                            amount = itemCount,
                            name = itemName or "Unknown Item",
                            category = "StressTest"
                        })
                        if withMoney then
                            table.insert(queue, {
                                category = "Funds",
                                amount = 1
                            })
                        end
                    else
                        for i = 1, itemCount do
                            table.insert(queue, {
                                bag = bag,
                                slot = slot,
                                itemID = itemID,
                                count = 1,
                                amount = 1,
                                name = itemName or "Unknown Item",
                                category = "StressTest"
                            })
                            if withMoney then
                                table.insert(queue, {
                                    category = "Funds",
                                    amount = 1
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    if table.getn(queue) == 0 then
        SmartMailStress:Log("Bags are empty!")
        return
    end
    
    if not SmartMail then SmartMail = {} end
    SmartMail.isStressTest = true
    
    SmartMailStress:Log("Starting to " .. target .. " with " .. table.getn(queue) .. " queued actions!")
    SmartMailEngine:Start(target, queue, function(successCount, failCount, abortReason, failedItems)
        SmartMailStress:Log("Complete! Sent: " .. (successCount or 0) .. " Failed: " .. (failCount or 0))
        SmartMail.isStressTest = false
    end)
end

local cycleModes = { "DUMP", "BARRAGE", "DUMP_MONEY", "BARRAGE_MONEY" }
local currentCycleIndex = 1

function SmartMailStress:StartCycle()
    if cycleActive then return end
    cycleActive = true
    currentCycleIndex = 1
    if not SmartMail then SmartMail = {} end
    SmartMail.isStressTest = true
    SmartMail.infiniteRetries = true
    SmartMailInbox.isRandom = true
    SmartMailStress:Log("Starting Cycle (Open All -> Mass Send loop with rotating modes)")
    self:NextCyclePhase("OPEN")
end

function SmartMailStress:CycleSendNext()
    if not cycleActive then return end
    
    if SmartMail.sendAllProfilesQueue and table.getn(SmartMail.sendAllProfilesQueue) > 0 then
        local nextProfile = table.remove(SmartMail.sendAllProfilesQueue, 1)
        SmartMailStress:Log("Routing to " .. nextProfile.name .. " with " .. table.getn(nextProfile.queue) .. " items.")
        SmartMailEngine:Start(nextProfile.name, nextProfile.queue, function()
            SmartMailStress:CycleSendNext()
        end)
    else
        SmartMailStress:Log("Mass Send phase complete. Returning to OPEN.")
        self:NextCyclePhase("OPEN")
    end
end

function SmartMailStress:NextCyclePhase(phase)
    if not cycleActive then return end
    
    if phase == "OPEN" then
        local numItems = GetInboxNumItems()
        if numItems == 0 then
            SmartMailStress:Log("Cycle complete (Mailbox empty).")
            cycleActive = false
            SmartMail.infiniteRetries = false
            SmartMailInbox.isRandom = false
            SmartMail.isStressTest = false
            return
        end
        
        SmartMailStress:Log("Phase OPEN ALL")
        
        local oldAbort = SmartMailInbox.Abort
        SmartMailInbox.Abort = function(self)
            oldAbort(self)
            SmartMailInbox.Abort = oldAbort
            if cycleActive then
                SmartMailStress:NextCyclePhase("SEND")
            end
        end
        SmartMailInbox:Start()
        
    elseif phase == "SEND" then
        local modeName = cycleModes[currentCycleIndex]
        SmartMailStress:Log("Phase MASS SEND (Mode: " .. modeName .. ")")
        
        local isBarrage = (modeName == "BARRAGE" or modeName == "BARRAGE_MONEY")
        local withMoney = (modeName == "DUMP_MONEY" or modeName == "BARRAGE_MONEY")
        
        SmartMail.sendAllProfilesQueue = {}
        if SmartMailDB_PerChar and SmartMailDB_PerChar.profiles then
            for charName, _ in pairs(SmartMailDB_PerChar.profiles) do
                local flat = SmartMailQueue:GenerateDirectFlatQueue(charName, "ALL")
                if flat and table.getn(flat) > 0 then
                    local transformedQueue = {}
                    for _, item in ipairs(flat) do
                        if isBarrage then
                            for i = 1, item.count do
                                table.insert(transformedQueue, {
                                    bag = item.bag, slot = item.slot, itemID = item.itemID,
                                    count = 1, amount = 1, name = item.name, category = item.category
                                })
                                if withMoney then
                                    table.insert(transformedQueue, { category = "Funds", amount = 1 })
                                end
                            end
                        else
                            table.insert(transformedQueue, item)
                            if withMoney then
                                table.insert(transformedQueue, { category = "Funds", amount = 1 })
                            end
                        end
                    end
                    table.insert(SmartMail.sendAllProfilesQueue, { name = charName, queue = transformedQueue })
                end
            end
        end
        
        currentCycleIndex = currentCycleIndex + 1
        if currentCycleIndex > table.getn(cycleModes) then currentCycleIndex = 1 end
        
        if table.getn(SmartMail.sendAllProfilesQueue) == 0 then
            SmartMailStress:Log("Nothing to send, returning to OPEN phase.")
            self:NextCyclePhase("OPEN")
        else
            self:CycleSendNext()
        end
    end
end
