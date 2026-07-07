SmartMailQueue = {}

function SmartMailQueue:BuildQueueForProfile(charName)
    SmartMail_Debug("SmartMailQueue:BuildQueueForProfile called...")
    SmartMail_Debug("SmartMailQueue: Building queue for profile '" .. tostring(charName) .. "'")
    local profile = nil
    if SmartMailDB_PerChar and SmartMailDB_PerChar.profiles then
        profile = SmartMailDB_PerChar.profiles[charName]
    end
    if not profile then 
        SmartMail_Debug("SmartMailQueue: Profile not found. Aborting.")
        return {} 
    end
    
    local queue = {}
    local aggregatedQueue = {}
    local allItems = Bridge:GetAllCategoryItems()
    local itemsFound = 0
    
    SmartMail_Debug("SmartMailQueue: Scanning bags...")
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, itemIDStr = string.find(itemLink, "item:(%d+)")
                local itemID = tonumber(itemIDStr)
                if itemID then
                    local catName = allItems[itemID]
                    if catName and profile[catName] then
                        local _, itemCount = GetContainerItemInfo(bag, slot)
                        itemCount = itemCount or 1
                        
                        if not aggregatedQueue[itemID] then
                            local itemName, _, _, _, _, _, itemStackCount, _, itemIcon = GetItemInfo(itemID)
                            aggregatedQueue[itemID] = {
                                itemID = itemID,
                                itemName = itemName or "Unknown Item",
                                itemIcon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
                                maxStack = itemStackCount or 1,
                                fullStacks = 0,
                                partialStacks = 0,
                                totalCount = 0,
                                slots = {},
                                category = catName,
                                selected = 1,
                                sendFull = 0,
                                sendPart = 0
                            }
                            
                            if profile.itemSettings and profile.itemSettings[itemID] then
                                local saved = profile.itemSettings[itemID]
                                if saved.selected ~= nil then aggregatedQueue[itemID].selected = saved.selected end
                                if saved.sendPart ~= nil then aggregatedQueue[itemID].sendPart = saved.sendPart end
                            end
                        end
                        
                        local agg = aggregatedQueue[itemID]
                        agg.totalCount = agg.totalCount + itemCount
                        table.insert(agg.slots, { bag = bag, slot = slot, count = itemCount })
                        
                        if itemCount == agg.maxStack then
                            agg.fullStacks = agg.fullStacks + 1
                        else
                            agg.partialStacks = agg.partialStacks + 1
                        end
                        
                        itemsFound = itemsFound + 1
                        SmartMail_Debug("Found match: itemID " .. itemID .. " (Count: " .. itemCount .. ") in category '" .. catName .. "' (Bag " .. bag .. ", Slot " .. slot .. ")")
                    end
                end
            end
        end
    end
    
    for itemID, data in pairs(aggregatedQueue) do
        if not (profile and profile.itemSettings and profile.itemSettings[itemID]) then
            data.sendFull = data.fullStacks
            data.sendPart = data.partialStacks
        else
            local saved = profile.itemSettings[itemID]
            if saved.sendFull == nil or saved.sendFull == "MAX" then 
                data.sendFull = data.fullStacks 
            else
                data.sendFull = saved.sendFull
            end
            
            if saved.sendPart == nil or saved.sendPart == "MAX" then 
                data.sendPart = data.partialStacks 
            else 
                data.sendPart = saved.sendPart 
            end
        end
        table.insert(queue, data)
    end
    
    table.sort(queue, function(a, b) return a.itemName < b.itemName end)
    
    SmartMail_Debug("SmartMailQueue: Scan complete. Total matches grouped: " .. table.getn(queue) .. " (from " .. itemsFound .. " individual slots)")
    return queue
end

function SmartMailQueue:FlattenConfirmQueue(mode)
    SmartMail_Debug("SmartMailQueue:FlattenConfirmQueue called...")
    local flatQueue = {}
    if not SmartMail.confirmQueue then return flatQueue end
    
    for _, itemData in ipairs(SmartMail.confirmQueue) do
        if itemData.selected == 1 then
            local fNeeded = itemData.sendFull or 0
            local pNeeded = itemData.sendPart or 0
            
            if mode == "ALL" then
                fNeeded = itemData.fullStacks
                pNeeded = itemData.partialStacks
            elseif mode == "FULL" then
                fNeeded = itemData.fullStacks
                pNeeded = 0
            end
            
            for _, slotInfo in ipairs(itemData.slots) do
                local used = false
                if slotInfo.count == itemData.maxStack and fNeeded > 0 then
                    table.insert(flatQueue, {
                        bag = slotInfo.bag,
                        slot = slotInfo.slot,
                        itemID = itemData.itemID,
                        count = slotInfo.count,
                        amount = slotInfo.count,
                        name = itemData.itemName,
                        category = itemData.category
                    })
                    fNeeded = fNeeded - 1
                    used = true
                elseif slotInfo.count < itemData.maxStack and pNeeded > 0 then
                    table.insert(flatQueue, {
                        bag = slotInfo.bag,
                        slot = slotInfo.slot,
                        itemID = itemData.itemID,
                        count = slotInfo.count,
                        amount = slotInfo.count,
                        name = itemData.itemName,
                        category = itemData.category
                    })
                    pNeeded = pNeeded - 1
                    used = true
                end
                
                if fNeeded == 0 and pNeeded == 0 then break end
            end
        end
    end
    
    return flatQueue
end

function SmartMailQueue:GenerateDirectFlatQueue(charName, mode)
    SmartMail_Debug("SmartMailQueue:GenerateDirectFlatQueue called...")
    -- Backup existing confirmQueue
    local oldQueue = SmartMail.confirmQueue
    
    -- Build new queue
    SmartMail.confirmQueue = self:BuildQueueForProfile(charName)
    
    -- Flatten it
    local flat = self:FlattenConfirmQueue(mode)
    
    -- Restore old queue
    SmartMail.confirmQueue = oldQueue
    
    return flat
end
