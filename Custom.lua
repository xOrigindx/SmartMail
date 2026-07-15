-- v1.0.4: persistent cart memory and UI open state
local SMARTMAIL_DISABLE_CUSTOM = false

if SMARTMAIL_DISABLE_CUSTOM then
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and arg1 == "SmartMail" then
            if SmartMailMainFrameCustomSendButton then
                SmartMailMainFrameCustomSendButton:Hide()
            end
        end
    end)
    return -- Stops the rest of Custom.lua from ever loading
end

SmartMailCustom = {
    items = {},
    recipient = ""
}

local scannerTooltip = CreateFrame("GameTooltip", "SmartMailScannerTooltip", nil, "GameTooltipTemplate")
scannerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

function SmartMailCustom:IsItemSoulbound(bag, slot)
    SmartMail_Debug("SmartMailCustom:IsItemSoulbound called...")
    scannerTooltip:ClearLines()
    scannerTooltip:SetBagItem(bag, slot)
    for i = 1, scannerTooltip:NumLines() do
        local line = getglobal("SmartMailScannerTooltipTextLeft" .. i)
        if line then
            local text = line:GetText()
            if text and (string.find(text, "Soulbound") or string.find(text, "Quest Item")) then
                return true
            end
        end
    end
    return false
end

function SmartMailCustom:ScanInventory()
    SmartMail_Debug("SmartMailCustom:ScanInventory called...")
    self.items = {}
    local temp = {}
    local categories = Bridge:GetAllCategoryItems()
    local catNames = Bridge:GetCategoryNames()
    local catOrder = {}
    if catNames then
        for i, name in ipairs(catNames) do
            catOrder[name] = i
        end
    end
    
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local _, _, itemIDStr = string.find(itemLink, "item:(%d+)")
                local itemID = tonumber(itemIDStr)
                if itemID then
                    local texture, itemCount = GetContainerItemInfo(bag, slot)
                    local itemName, _, itemRarity, _, itemType, itemSubType, itemStackCount, _, itemIcon = GetItemInfo(itemID)
                    
                    if itemRarity and itemRarity > 0 then
                        if not self:IsItemSoulbound(bag, slot) then
                            if not temp[itemID] then
                                local libCat = "ZZZ_Unknown"
                                local sortOrder = 99
                                if categories and categories[itemID] then
                                    libCat = categories[itemID]
                                    sortOrder = catOrder[libCat] or 98
                                end
                                
                                local armorRank = 99
                                local weaponRank = 99
                                
                                if itemType == "Recipe" then
                                    sortOrder = 90
                                elseif libCat == "ZZZ_Unknown" then
                                    if itemType == "Weapon" or itemSubType == "Shields" or itemEquipLoc == "INVTYPE_HOLDABLE" then
                                        sortOrder = 92
                                        if itemType == "Weapon" then weaponRank = 1
                                        elseif itemSubType == "Shields" then weaponRank = 2
                                        else weaponRank = 3 end
                                    elseif itemType == "Armor" then
                                        sortOrder = 91
                                        if itemSubType == "Plate" then armorRank = 1
                                        elseif itemSubType == "Mail" then armorRank = 2
                                        elseif itemSubType == "Leather" then armorRank = 3
                                        elseif itemSubType == "Cloth" then armorRank = 4
                                        else armorRank = 5 end
                                    end
                                end
                                
                                temp[itemID] = {
                                    itemID = itemID,
                                    itemName = itemName,
                                    itemRarity = itemRarity or 0,
                                    itemType = itemType or "",
                                    itemSubType = itemSubType or "",
                                    itemEquipLoc = itemEquipLoc or "",
                                    itemLibCat = libCat,
                                    sortOrder = sortOrder,
                                    armorRank = armorRank,
                                    weaponRank = weaponRank,
                                    itemIcon = itemIcon or texture,
                                    maxStack = itemStackCount or 1,
                                    totalCount = 0,
                                    slots = {},
                                    amountToSend = 0
                                }
                            end
                            if temp[itemID] then
                                temp[itemID].totalCount = temp[itemID].totalCount + (tonumber(itemCount) or 1)
                                table.insert(temp[itemID].slots, {bag = bag, slot = slot, count = (tonumber(itemCount) or 1)})
                            end
                        end
                    end
                end
            end
        end
    end
    
    for _, v in pairs(temp) do
        table.insert(self.items, v)
    end
    
    table.sort(self.items, function(a, b)
        if a.sortOrder == b.sortOrder then
            if a.sortOrder == 91 then
                if a.armorRank == b.armorRank then
                    if a.itemRarity == b.itemRarity then
                        if a.itemEquipLoc == b.itemEquipLoc then
                            return (a.itemName or "") < (b.itemName or "")
                        end
                        return (a.itemEquipLoc or "") < (b.itemEquipLoc or "")
                    end
                    return (a.itemRarity or 0) > (b.itemRarity or 0)
                end
                return a.armorRank < b.armorRank
            elseif a.sortOrder == 92 then
                if a.weaponRank == b.weaponRank then
                    if a.itemSubType == b.itemSubType then
                        if a.itemRarity == b.itemRarity then
                            if a.itemEquipLoc == b.itemEquipLoc then
                                return (a.itemName or "") < (b.itemName or "")
                            end
                            return (a.itemEquipLoc or "") < (b.itemEquipLoc or "")
                        end
                        return (a.itemRarity or 0) > (b.itemRarity or 0)
                    end
                    return (a.itemSubType or "") < (b.itemSubType or "")
                end
                return a.weaponRank < b.weaponRank
            end
            
            if a.itemLibCat == b.itemLibCat then
                if a.itemType == b.itemType then
                    if a.itemSubType == b.itemSubType then
                        return (a.itemName or "") < (b.itemName or "")
                    end
                    return (a.itemSubType or "") < (b.itemSubType or "")
                end
                return (a.itemType or "") < (b.itemType or "")
            end
            return (a.itemLibCat or "") < (b.itemLibCat or "")
        end
        return a.sortOrder < b.sortOrder
    end)
    SmartMail_Debug("CustomSend: Scanned " .. table.getn(self.items) .. " unique valid items.")
end

function SmartMailCustom:BuildQueue()
    SmartMail_Debug("SmartMailCustom:BuildQueue called...")
    local queue = {}
    for _, itemData in ipairs(self.items) do
        if itemData.amountToSend > 0 then
            local remaining = itemData.amountToSend
            for _, slotInfo in ipairs(itemData.slots) do
                if remaining <= 0 then break end
                
                local take = tonumber(slotInfo.count) or 1
                if remaining < take then take = remaining end
                
                table.insert(queue, {
                    bag = slotInfo.bag,
                    slot = slotInfo.slot,
                    itemID = itemData.itemID,
                    count = slotInfo.count,
                    amount = take,
                    name = itemData.itemName,
                    category = "Custom"
                })
                
                remaining = remaining - take
            end
        end
    end
    
    local copper = SmartMailCustom.moneyToSend or 0
    if copper > 0 then
        table.insert(queue, {
            isMoney = true,
            name = "MONEY",
            amount = copper,
            count = copper
        })
    end
    
    return queue
end

function SmartMailCustom:Send()
    SmartMail_Debug("SmartMailCustom:Send called...")
    if not self.selectedRecipient or self.selectedRecipient == "" then
        SmartMail_Debug("CustomSend: No recipient specified. Prompting user...")
        if SmartMail_ShowRecipientSelect then
            SmartMail_ShowRecipientSelect()
        end
        return
    end
    
    local queue = self:BuildQueue()
    if table.getn(queue) == 0 then
        SmartMail_Debug("CustomSend: No items selected to send.")
        return
    end
    local expectedCount = table.getn(queue)
    local expectedMsg = "SmartMail: Starting Custom Send. Expected to send " .. expectedCount .. " item(s)."
    DEFAULT_CHAT_FRAME:AddMessage(expectedMsg, 1, 1, 0)
    SmartMail_Debug("CustomSend: " .. expectedMsg)
    
    SmartMailEngine:Start(self.selectedRecipient, queue, function(successCount, failCount, abortReason, failedItems)
        local msg = "SmartMail: Custom Send Complete! Expected: " .. expectedCount .. ". Sent: " .. (successCount or 0) .. ". Failed: " .. (failCount or 0) .. "."
        if failCount and failCount > 0 then 
            local r = abortReason or "Max Retries Reached"
            msg = msg .. " (" .. r .. ")." 
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0)
        SmartMail_Debug("CustomSend: " .. msg)
        
        if failCount and failCount > 0 and failedItems then
            for _, fi in ipairs(failedItems) do
                local it = fi.item
                local reason = fi.reason or "Unknown Error"
                if it.isMoney then
                    DEFAULT_CHAT_FRAME:AddMessage("  - Failed: Money (" .. tostring(it.amount) .. "c) - " .. reason, 1, 0.5, 0)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("  - Failed: " .. tostring(it.name or "Item") .. " (Bag " .. tostring(it.bag or "?") .. " Slot " .. tostring(it.slot or "?") .. ") - " .. reason, 1, 0.5, 0)
                end
            end
        end
        
        for _, itemData in ipairs(SmartMailCustom.items or {}) do
            itemData.amountToSend = 0
        end
        if SmartMailCustomMoneyInput then
            MoneyInputFrame_SetCopper(SmartMailCustomMoneyInput, 0)
        end
        SmartMailCustom.moneyToSend = 0
        
        -- Wipe the selected recipient so the user is forced to choose again
        SmartMailCustom.selectedRecipient = nil
        
        -- Rescan inventory to remove sent items from the UI
        SmartMailCustom:ScanInventory()
        
        if SmartMail_UpdateCustomCartList then
            SmartMail_UpdateCustomCartList()
        end
        if SmartMail_UpdateCustomList then
            SmartMail_UpdateCustomList()
        end
        if SmartMail_UpdateCustomRecipientList then
            SmartMail_UpdateCustomRecipientList()
        end
    end)
end

function SmartMail_UpdateCustomList()
    SmartMail_Debug("SmartMail_UpdateCustomList called...")
    local scrollChild = SmartMailCustomSendFrameListFrameScrollChild
    if not scrollChild then return end
    
    -- Clear existing
    local children = {scrollChild:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
    end
    
    local yOffset = 5
    for i, itemDataTemp in ipairs(SmartMailCustom.items) do
        local itemData = itemDataTemp
        local rowName = "SmartMailCustomItemRow" .. i
        local row = getglobal(rowName)
        if not row then
            row = CreateFrame("Button", rowName, scrollChild)
            row:SetWidth(240)
            row:SetHeight(32)
            
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            
            local icon = row:CreateTexture(rowName .. "Icon", "ARTWORK")
            icon:SetWidth(24)
            icon:SetHeight(24)
            icon:SetPoint("LEFT", row, "LEFT", 0, 0)
            row.icon = icon
            
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            highlight:SetBlendMode("ADD")
            highlight:SetAllPoints(row)
            
            local nameText = row:CreateFontString(rowName .. "Name", "ARTWORK", "GameFontNormalSmall")
            nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameText:SetWidth(120)
            nameText:SetJustifyH("LEFT")
            row.nameText = nameText
            
            row:SetScript("OnEnter", function()
                local itemData = SmartMailCustom.items[this:GetID()]
                if itemData and itemData.itemID then
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    local _, link = GetItemInfo(itemData.itemID)
                    if link then
                        GameTooltip:SetHyperlink(string.gsub(link, "|cff%x%x%x%x%x%x|H(.-)|h.-|h|r", "%1"))
                    else
                        GameTooltip:SetText(itemData.itemName)
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Left-Click: Add 1", 0, 1, 0)
                    GameTooltip:AddLine("Shift+Left-Click: Add max stack", 0, 1, 0)
                    GameTooltip:AddLine("Ctrl+Left-Click: Add all", 0, 1, 0)
                    GameTooltip:AddLine("Right-Click: Remove 1", 1, 0, 0)
                    GameTooltip:AddLine("Shift+Right-Click: Remove max stack", 1, 0, 0)
                    GameTooltip:AddLine("Ctrl+Right-Click: Remove all", 1, 0, 0)
                    GameTooltip:Show()
                end
            end)
            
            row:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            row:SetScript("OnClick", function()
                local itemData = SmartMailCustom.items[this:GetID()]
                if not itemData.amountToSend then itemData.amountToSend = 0 end
                
                if arg1 == "RightButton" then
                    if IsControlKeyDown() then
                        itemData.amountToSend = 0
                        SmartMail_Debug("CustomList: Ctrl+Right-Click removed all " .. itemData.itemName .. ". New amount: 0")
                    elseif IsShiftKeyDown() then
                        local _, _, _, _, _, _, maxStack = GetItemInfo(itemData.itemID)
                        maxStack = tonumber(maxStack) or 20
                        if maxStack < 1 then maxStack = 20 end
                        itemData.amountToSend = itemData.amountToSend - maxStack
                        if itemData.amountToSend < 0 then itemData.amountToSend = 0 end
                        SmartMail_Debug("CustomList: Shift+Right-Click removed stack of " .. itemData.itemName .. ". New amount: " .. itemData.amountToSend)
                    else
                        itemData.amountToSend = itemData.amountToSend - 1
                        if itemData.amountToSend < 0 then itemData.amountToSend = 0 end
                        SmartMail_Debug("CustomList: Right-Click removed 1 " .. itemData.itemName .. ". New amount: " .. itemData.amountToSend)
                    end
                else
                    if IsControlKeyDown() then
                        itemData.amountToSend = itemData.totalCount
                        SmartMail_Debug("CustomList: Ctrl+Left-Click added all " .. itemData.itemName .. ". New amount: " .. itemData.amountToSend)
                    elseif IsShiftKeyDown() then
                        local _, _, _, _, _, _, maxStack = GetItemInfo(itemData.itemID)
                        maxStack = tonumber(maxStack) or 20
                        if maxStack < 1 then maxStack = 20 end
                        itemData.amountToSend = itemData.amountToSend + maxStack
                        if itemData.amountToSend > itemData.totalCount then itemData.amountToSend = itemData.totalCount end
                        SmartMail_Debug("CustomList: Shift+Left-Click added max stack of " .. itemData.itemName .. ". New amount: " .. itemData.amountToSend)
                    else
                        itemData.amountToSend = itemData.amountToSend + 1
                        if itemData.amountToSend > itemData.totalCount then itemData.amountToSend = itemData.totalCount end
                        SmartMail_Debug("CustomList: Left-Click added 1 " .. itemData.itemName .. ". New amount: " .. itemData.amountToSend)
                    end
                end
                
                if SmartMail_UpdateCustomCartList then SmartMail_UpdateCustomCartList() end
                SmartMail_UpdateCustomList()
            end)
        end
        row:SetID(i)
        
        row.icon:SetTexture(itemData.itemIcon)
        if itemData.amountToSend and itemData.amountToSend > 0 then
            row.nameText:SetText(itemData.itemName .. " (x" .. itemData.totalCount .. ") |cFF00FF00[" .. itemData.amountToSend .. "]|r")
        else
            row.nameText:SetText(itemData.itemName .. " (x" .. itemData.totalCount .. ")")
        end
        
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -yOffset)
        row:Show()
        yOffset = yOffset + 36
    end
end

StaticPopupDialogs["SMARTMAIL_CUSTOM_ADD_RECIPIENT"] = {
    text = "Enter Recipient Name:\n\nWARNING: Mail sent to the wrong person cannot be recovered! Double-check your spelling.",
    button1 = "Accept",
    button2 = "Cancel",
    hasEditBox = 1,
    maxLetters = 12,
    OnAccept = function()
        local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
        if text and text ~= "" then
            if not SmartMailDB_PerChar then SmartMailDB_PerChar = {} end
            if not SmartMailDB_PerChar.customRecipients then SmartMailDB_PerChar.customRecipients = {} end
            local exists = false
            for _, r in ipairs(SmartMailDB_PerChar.customRecipients) do
                if r == text then exists = true; break end
            end
            
            if not exists then
                table.insert(SmartMailDB_PerChar.customRecipients, text)
            end
            SmartMailCustom.selectedRecipient = text
            if SmartMail_UpdateCustomRecipientList then
                SmartMail_UpdateCustomRecipientList()
            end
        end
    end,
    OnShow = function()
        getglobal(this:GetName().."EditBox"):SetFocus()
        getglobal(this:GetName().."EditBox"):SetText("")
    end,
    OnHide = function()
        if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
            ChatFrameEditBox:SetFocus()
        end
        getglobal(this:GetName().."EditBox"):SetText("")
    end,
    EditBoxOnEnterPressed = function()
        local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
        if text and text ~= "" then
            if not SmartMailDB_PerChar then SmartMailDB_PerChar = {} end
            if not SmartMailDB_PerChar.customRecipients then SmartMailDB_PerChar.customRecipients = {} end
            local exists = false
            for _, r in ipairs(SmartMailDB_PerChar.customRecipients) do
                if r == text then exists = true; break end
            end
            
            if not exists then
                table.insert(SmartMailDB_PerChar.customRecipients, text)
            end
            SmartMailCustom.selectedRecipient = text
            if SmartMail_UpdateCustomRecipientList then
                SmartMail_UpdateCustomRecipientList()
            end
        end
        this:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function()
        this:GetParent():Hide()
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
}

-- ============================================================
-- Controller Logic for Custom Send Frame
-- All frames are created in UI.lua. This file only attaches
-- SetScript handlers and business logic.
-- ============================================================

-- Grab references to frames created by UI.lua
local frame = SmartMailCustomSendFrame
local moneyInput = SmartMailCustomMoneyInput
local amtFrame = SmartMailCustomAmountFrame
local amtEdit = SmartMailCustomAmountEditBox
local sidePanel = SmartMailCustomSidePanel

if SmartMailCustomTab then
    SmartMailCustomTab:SetScript("OnClick", function()
        SmartMail_Debug("SmartMailCustomTab clicked")
        if SmartMailCustomSendFrame then
            SmartMailCustomSendFrame:Show()
        end
    end)
end

function SmartMailCustom:SaveCart()
    self.savedCart = {}
    if not self.items then return end
    for _, item in ipairs(self.items) do
        if item.amountToSend and item.amountToSend > 0 then
            table.insert(self.savedCart, {
                itemName = item.itemName,
                amountToSend = item.amountToSend
            })
        end
    end
    self.savedMoney = self.moneyToSend or 0
end

function SmartMailCustom:RestoreCart()
    self.moneyToSend = self.savedMoney or 0
    if not self.savedCart or not self.items then return end
    
    for _, saved in ipairs(self.savedCart) do
        local remaining = saved.amountToSend
        for _, item in ipairs(self.items) do
            if item.itemName == saved.itemName and remaining > 0 then
                local available = item.totalCount - (item.amountToSend or 0)
                if available > 0 then
                    local add = math.min(available, remaining)
                    item.amountToSend = (item.amountToSend or 0) + add
                    remaining = remaining - add
                end
            end
        end
    end
end

-- OnShow / OnHide for the Custom Send Frame
frame:SetScript("OnShow", function()
    SmartMail_Debug("SmartMailCustomSendFrame OnShow fired")
    if SmartMail_ToggleMainFrameWidth then SmartMail_ToggleMainFrameWidth(true) end
    SmartMailCustom:ScanInventory()
    SmartMailCustom:RestoreCart()
    SmartMail_UpdateCustomList()
    SmartMail_UpdateCustomCartList()
    if SmartMail_UpdateCustomRecipientList then
        SmartMail_UpdateCustomRecipientList()
    end
end)

frame:SetScript("OnHide", function()
    SmartMail_Debug("SmartMailCustomSendFrame OnHide fired")
    SmartMailCustom:SaveCart()
    if SmartMail_ToggleMainFrameWidth then SmartMail_ToggleMainFrameWidth(false) end
end)

-- Add Money button
SmartMailCustomAddMoneyBtn:SetScript("OnClick", function()
    SmartMail_Debug("CustomSend: AddMoneyBtn clicked")
    local copper = MoneyInputFrame_GetCopper(moneyInput)
    if copper > 0 then
        SmartMailCustom.moneyToSend = (SmartMailCustom.moneyToSend or 0) + copper
        SmartMail_Debug("CustomSend: Added " .. copper .. " copper to cart. Total money queued: " .. SmartMailCustom.moneyToSend)
        MoneyInputFrame_SetCopper(moneyInput, 0)
        if SmartMail_UpdateCustomCartList then SmartMail_UpdateCustomCartList() end
    end
end)

-- Clear Money button
SmartMailCustomClearMoneyBtn:SetScript("OnClick", function()
    SmartMail_Debug("CustomSend: ClearMoneyBtn clicked")
    SmartMailCustom.moneyToSend = 0
    MoneyInputFrame_SetCopper(moneyInput, 0)
    SmartMail_Debug("CustomSend: Cleared all money from cart.")
    if SmartMail_UpdateCustomCartList then SmartMail_UpdateCustomCartList() end
end)

-- Send button
SmartMailCustomSendBtn:SetScript("OnClick", function()
    SmartMail_Debug("CustomSend: SendBtn clicked")
    SmartMailCustom:Send()
end)

-- Cancel button
SmartMailCustomCancelBtn:SetScript("OnClick", function()
    SmartMail_Debug("CustomSend: CancelBtn clicked")
    frame:Hide()
end)

-- ============================================================
-- Amount Entry Dialog — Controller Scripts
-- ============================================================

amtEdit:SetScript("OnEscapePressed", function()
    amtFrame:Hide()
end)

amtEdit:SetScript("OnEnterPressed", function()
    if amtFrame.itemData then
        local val = tonumber(this:GetText()) or 0
        if amtFrame.mode == "remove" then
            val = amtFrame.itemData.amountToSend - val
        else
            val = amtFrame.itemData.amountToSend + val
        end
        if val < 0 then val = 0 end
        if val > amtFrame.itemData.totalCount then val = amtFrame.itemData.totalCount end
        amtFrame.itemData.amountToSend = val
        SmartMail_Debug("CustomSend Popup: Set " .. amtFrame.itemData.itemName .. " amount to " .. val)
        SmartMail_UpdateCustomCartList()
        SmartMail_UpdateCustomList()
    end
    amtFrame:Hide()
end)

-- Max button
SmartMailCustomAmountMaxBtn:SetScript("OnClick", function()
    if amtFrame.itemData then
        if amtFrame.mode == "remove" then
            amtFrame.itemData.amountToSend = 0
            SmartMail_Debug("CustomSend Popup: Set " .. amtFrame.itemData.itemName .. " amount to 0 via Max")
        else
            amtFrame.itemData.amountToSend = amtFrame.itemData.totalCount
            SmartMail_Debug("CustomSend Popup: Set " .. amtFrame.itemData.itemName .. " amount to max (" .. amtFrame.itemData.totalCount .. ")")
        end
        SmartMail_UpdateCustomCartList()
        SmartMail_UpdateCustomList()
        amtFrame:Hide()
    end
end)

-- Accept button
SmartMailCustomAmountOkBtn:SetScript("OnClick", function()
    if amtFrame.itemData then
        local val = tonumber(amtEdit:GetText()) or 0
        if amtFrame.mode == "remove" then
            val = amtFrame.itemData.amountToSend - val
        else
            val = amtFrame.itemData.amountToSend + val
        end
        if val < 0 then val = 0 end
        if val > amtFrame.itemData.totalCount then val = amtFrame.itemData.totalCount end
        amtFrame.itemData.amountToSend = val
        SmartMail_Debug("CustomSend Popup: Set " .. amtFrame.itemData.itemName .. " amount to " .. val)
        SmartMail_UpdateCustomCartList()
        SmartMail_UpdateCustomList()
    end
    amtFrame:Hide()
end)

-- Cancel button
SmartMailCustomAmountCancelBtn:SetScript("OnClick", function() amtFrame:Hide() end)

-- Dragging
amtFrame:SetScript("OnDragStart", function() 
    this:SetFrameStrata("TOOLTIP")
    this:StartMoving() 
end)
amtFrame:SetScript("OnDragStop", function() 
    this:SetFrameStrata("FULLSCREEN_DIALOG")
    this:StopMovingOrSizing() 
end)

-- OnShow — position at cursor
amtFrame:SetScript("OnShow", function() 
    amtEdit:SetText("") 
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    this:ClearAllPoints()
    this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end)

-- ============================================================
-- Side Panel — Controller Scripts
-- ============================================================

if not SmartMailDB_PerChar then SmartMailDB_PerChar = {} end
if not SmartMailDB_PerChar.validatedRecipients then SmartMailDB_PerChar.validatedRecipients = {} end

SmartMailValidator = CreateFrame("Frame")
SmartMailValidator:RegisterEvent("UI_ERROR_MESSAGE")
SmartMailValidator:RegisterEvent("MAIL_SEND_SUCCESS")
SmartMailValidator.isTesting = false

SmartMailValidator:SetScript("OnEvent", function()
    if not SmartMailValidator.isTesting then return end
    if event == "MAIL_SEND_SUCCESS" then
        SmartMailDB_PerChar.validatedRecipients[SmartMailValidator.testName] = true
        SmartMail_Debug("Validation SUCCESS for " .. SmartMailValidator.testName)
        SmartMailValidator.isTesting = false
        SmartMail_UpdateCustomRecipientList()
    elseif event == "UI_ERROR_MESSAGE" then
        if string.find(string.lower(arg1), "recipient") then
            SmartMail_Debug("Validation FAILED for " .. SmartMailValidator.testName)
            SmartMailDB_PerChar.validatedRecipients[SmartMailValidator.testName] = nil
            
            for i, r in ipairs(SmartMailDB_PerChar.customRecipients) do
                if r == SmartMailValidator.testName then
                    table.remove(SmartMailDB_PerChar.customRecipients, i)
                    break
                end
            end
            if SmartMailCustom.selectedRecipient == SmartMailValidator.testName then
                SmartMailCustom.selectedRecipient = nil
            end
            
            SmartMailValidator.isTesting = false
            SmartMail_UpdateCustomRecipientList()
            DEFAULT_CHAT_FRAME:AddMessage("SmartMail: Invalid recipient '" .. SmartMailValidator.testName .. "' removed.")
        end
    end
end)

function SmartMailValidator_Validate(name)
    SmartMail_Debug("SmartMailValidator_Validate called...")
    if not SmartMailDB_PerChar then SmartMailDB_PerChar = {} end
    if not SmartMailDB_PerChar.validatedRecipients then SmartMailDB_PerChar.validatedRecipients = {} end
    if SmartMailDB_PerChar.validatedRecipients[name] == true then return end
    
    if MailFrame and MailFrame:IsVisible() then
        SmartMailValidator.isTesting = true
        SmartMailValidator.testName = name
        SendMail(name, "SmartMail Validation", "This is an automated validation letter.")
        SmartMailDB_PerChar.validatedRecipients[name] = "pending"
        SmartMail_Debug("Validator: Sent test mail to " .. name)
    else
        SmartMailDB_PerChar.validatedRecipients[name] = "waiting"
        SmartMail_Debug("Validator: Not at mailbox, setting " .. name .. " to waiting.")
    end
    SmartMail_UpdateCustomRecipientList()
end

-- Add Recipient button
SmartMailCustomSideAddBtn:SetScript("OnClick", function()
    SmartMail_Debug("CustomSend: SideAddBtn clicked")
    StaticPopup_Show("SMARTMAIL_CUSTOM_ADD_RECIPIENT")
end)

-- History dropdown logic
function SmartMailRecipientHistoryDropdown_OnClick()
    SmartMail_Debug("SmartMailRecipientHistoryDropdown_OnClick called...")
    local name = this.value
    if name then
        if not SmartMailDB_PerChar.customRecipients then SmartMailDB_PerChar.customRecipients = {} end
        local exists = false
        for _, r in ipairs(SmartMailDB_PerChar.customRecipients) do
            if r == name then exists = true; break end
        end
        if not exists then
            table.insert(SmartMailDB_PerChar.customRecipients, name)
        end
        SmartMailCustom.selectedRecipient = name
        SmartMail_UpdateCustomRecipientList()
    end
end

function SmartMailRecipientHistoryDropdown_Initialize()
    SmartMail_Debug("SmartMailRecipientHistoryDropdown_Initialize called...")
    local added = false
    for name, status in pairs(SmartMailDB_PerChar.validatedRecipients or {}) do
        if status == true then
            local info = {}
            info.text = name
            info.value = name
            info.func = SmartMailRecipientHistoryDropdown_OnClick
            info.notCheckable = 1
            UIDropDownMenu_AddButton(info)
            added = true
        end
    end
    
    if not added then
        local info = {}
        info.text = "No saved recipients"
        info.notCheckable = 1
        info.disabled = 1
        UIDropDownMenu_AddButton(info)
    end
end

-- History button
SmartMailCustomHistBtn:SetScript("OnClick", function()
    SmartMail_Debug("CustomSend: HistBtn clicked")
    UIDropDownMenu_Initialize(SmartMailRecipientHistoryDropdown, SmartMailRecipientHistoryDropdown_Initialize, "MENU")
    ToggleDropDownMenu(1, nil, SmartMailRecipientHistoryDropdown, "SmartMailCustomHistBtn", 0, 0)
end)

-- Delete Recipient button
SmartMailCustomSideDelBtn:SetScript("OnClick", function()
    SmartMail_Debug("CustomSend: SideDelBtn clicked")
    if SmartMailCustom.selectedRecipient then
        for i, r in ipairs(SmartMailDB_PerChar.customRecipients or {}) do
            if r == SmartMailCustom.selectedRecipient then
                table.remove(SmartMailDB_PerChar.customRecipients, i)
                break
            end
        end
        SmartMailCustom.selectedRecipient = nil
        SmartMail_UpdateCustomRecipientList()
    end
end)

-- ============================================================
-- Update Functions (Recipient List, Cart List)
-- These reference global scroll child frames by name.
-- ============================================================

function SmartMail_UpdateCustomRecipientList()
    if not SmartMailDB_PerChar then SmartMailDB_PerChar = {} end
    if not SmartMailDB_PerChar.customRecipients then SmartMailDB_PerChar.customRecipients = {} end
    
    local seen = {}
    local cleaned = {}
    for _, recip in ipairs(SmartMailDB_PerChar.customRecipients) do
        if not seen[recip] then
            seen[recip] = true
            table.insert(cleaned, recip)
        end
    end
    table.sort(cleaned)
    SmartMailDB_PerChar.customRecipients = cleaned
    
    local sideScrollChild = SmartMailCustomRecipientListFrameScrollChild
    if not sideScrollChild then return end

    local children = {sideScrollChild:GetChildren()}
    for _, child in ipairs(children) do child:Hide() end
    
    local yOffset = 5
    for i, recip in ipairs(SmartMailDB_PerChar.customRecipients) do
        local rowName = "SmartMailCustomRecipRow" .. i
        local row = getglobal(rowName)
        if not row then
            row = CreateFrame("Button", rowName, sideScrollChild)
            row:SetWidth(170)
            row:SetHeight(20)
            
            local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            text:SetPoint("LEFT", row, "LEFT", 5, 0)
            row.text = text
            
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            highlight:SetBlendMode("ADD")
            highlight:SetAllPoints(row)
            
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture(1, 1, 0, 0.3)
            bg:SetAllPoints(row)
            bg:Hide()
            row.bg = bg
        end
        
        if SmartMailDB_PerChar.validatedRecipients[recip] == nil then
            SmartMailDB_PerChar.validatedRecipients[recip] = true -- backwards compat
        end
        
        if SmartMailDB_PerChar.validatedRecipients[recip] == "waiting" then
            row.text:SetText(recip .. " (Waiting)")
            row.text:SetTextColor(1, 1, 0)
        elseif SmartMailDB_PerChar.validatedRecipients[recip] == "pending" then
            row.text:SetText(recip .. " (Validating...)")
            row.text:SetTextColor(1, 0.5, 0)
        else
            row.text:SetText(recip)
            row.text:SetTextColor(1, 1, 1)
        end
        
        if SmartMailCustom.selectedRecipient == recip then
            row.bg:Show()
        else
            row.bg:Hide()
        end
        
        local currentRecip = recip
        row:SetScript("OnClick", function()
            if SmartMailDB_PerChar.validatedRecipients[currentRecip] == "waiting" then
                if MailFrame and MailFrame:IsVisible() then
                    SmartMailValidator_Validate(currentRecip)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("SmartMail: You must be at a mailbox to validate this recipient.")
                end
            else
                if SmartMailCustom.selectedRecipient == currentRecip then
                    SmartMailCustom.selectedRecipient = nil
                else
                    SmartMailCustom.selectedRecipient = currentRecip
                end
            end
            SmartMail_UpdateCustomRecipientList()
        end)
        
        row:SetPoint("TOPLEFT", sideScrollChild, "TOPLEFT", 0, -yOffset)
        row:Show()
        yOffset = yOffset + 20
    end
end

function SmartMail_UpdateCustomCartList()
    local customListScrollChild = SmartMailCustomListSideFrameScrollChild
    if not customListScrollChild then return end

    local children = {customListScrollChild:GetChildren()}
    for _, child in ipairs(children) do child:Hide() end
    
    local yOffset = 5
    local cartIndex = 1
    
    local copper = SmartMailCustom.moneyToSend or 0
    if copper > 0 then
        local rowName = "SmartMailCustomCartRow" .. cartIndex
        local row = getglobal(rowName)
        if not row then
            row = CreateFrame("Button", rowName, customListScrollChild)
            row:SetWidth(170)
            row:SetHeight(20)
            
            local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", row, "LEFT", 5, 0)
            text:SetWidth(160)
            text:SetJustifyH("LEFT")
            row.text = text
            
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            highlight:SetBlendMode("ADD")
            highlight:SetAllPoints(row)
            row:RegisterForClicks("RightButtonUp")
        end
        
        local g = math.floor(copper / 10000)
        local s = math.floor(math.mod(copper, 10000) / 100)
        local c = math.mod(copper, 100)
        local mStr = ""
        if g > 0 then mStr = mStr .. g .. "g " end
        if s > 0 then mStr = mStr .. s .. "s " end
        if c > 0 or mStr == "" then mStr = mStr .. c .. "c" end
        mStr = string.gsub(mStr, " $", "")
        
        row.text:SetText("|cFFFFFF00Funds:|r " .. mStr)
        row:SetScript("OnClick", function()
            if arg1 == "RightButton" then
                SmartMail_Debug("CustomCart: Removed all money from cart.")
                SmartMailCustom.moneyToSend = 0
                if SmartMail_UpdateCustomCartList then SmartMail_UpdateCustomCartList() end
            end
        end)
        
        row:SetPoint("TOPLEFT", customListScrollChild, "TOPLEFT", 0, -yOffset)
        row:Show()
        yOffset = yOffset + 20
        cartIndex = cartIndex + 1
    end
    
    for _, itemData in ipairs(SmartMailCustom.items or {}) do
        if itemData.amountToSend and itemData.amountToSend > 0 then
            local rowName = "SmartMailCustomCartRow" .. cartIndex
            local row = getglobal(rowName)
            if not row then
                row = CreateFrame("Button", rowName, customListScrollChild)
                row:SetWidth(170)
                row:SetHeight(20)
                
                local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("LEFT", row, "LEFT", 5, 0)
                text:SetWidth(160)
                text:SetJustifyH("LEFT")
                row.text = text
                
                local highlight = row:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                highlight:SetBlendMode("ADD")
                highlight:SetAllPoints(row)
                row:RegisterForClicks("RightButtonUp")
            end
            
            row.text:SetText(itemData.itemName .. " (x" .. itemData.amountToSend .. ")")
            local dataRef = itemData
            
            row:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                if dataRef and dataRef.itemID then
                    local _, link = GetItemInfo(dataRef.itemID)
                    if link then
                        GameTooltip:SetHyperlink(string.gsub(link, "|cff%x%x%x%x%x%x|H(.-)|h.-|h|r", "%1"))
                    else
                        GameTooltip:SetText(dataRef.itemName)
                    end
                else
                    GameTooltip:SetText(dataRef.itemName)
                end
                
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Right-Click: Remove 1 from cart", 1, 0, 0)
                GameTooltip:AddLine("Ctrl+Right-Click: Remove all from cart", 1, 0, 0)
                GameTooltip:AddLine("Shift+Right-Click: Remove specific amount", 1, 0.5, 0)
                GameTooltip:Show()
            end)
            
            row:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            row:SetScript("OnClick", function()
                if arg1 == "RightButton" then
                    if IsControlKeyDown() then
                        dataRef.amountToSend = 0
                        SmartMail_Debug("CustomCart: Ctrl+Right-Click removed all " .. dataRef.itemName .. " from cart. New amount: 0")
                    elseif IsShiftKeyDown() then
                        SmartMailCustomAmountFrame.mode = "remove"
                        if SmartMailCustomAmountTitle then SmartMailCustomAmountTitle:SetText("Remove Amount") end
                        SmartMailCustomAmountFrame.itemData = dataRef
                        SmartMailCustomAmountFrame:Show()
                    else
                        dataRef.amountToSend = dataRef.amountToSend - 1
                        if dataRef.amountToSend < 0 then dataRef.amountToSend = 0 end
                        SmartMail_Debug("CustomCart: Right-Click removed 1 " .. dataRef.itemName .. " from cart. New amount: " .. dataRef.amountToSend)
                    end
                    SmartMail_UpdateCustomCartList()
                    SmartMail_UpdateCustomList()
                end
            end)
            
            row:SetPoint("TOPLEFT", customListScrollChild, "TOPLEFT", 0, -yOffset)
            row:Show()
            yOffset = yOffset + 20
            cartIndex = cartIndex + 1
        end
    end
end

