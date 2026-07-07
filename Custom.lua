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
        SmartMail_Debug("CustomSend: No recipient specified.")
        return
    end
    
    local queue = self:BuildQueue()
    if table.getn(queue) == 0 then
        SmartMail_Debug("CustomSend: No items selected to send.")
        return
    end
    
    if SmartMailCustomSendFrame then SmartMailCustomSendFrame:Hide() end
    if SmartMailMainFrame then SmartMailMainFrame:Hide() end
    SmartMailEngine:Start(self.selectedRecipient, queue, function()
        SmartMail_Debug("CustomSend: Completed!")
        for _, itemData in ipairs(SmartMailCustom.items or {}) do
            itemData.amountToSend = 0
        end
        if SmartMailCustomMoneyInput then
            MoneyInputFrame_SetCopper(SmartMailCustomMoneyInput, 0)
        end
        SmartMailCustom.moneyToSend = 0
        if SmartMail_UpdateCustomCartList then
            SmartMail_UpdateCustomCartList()
        end
        if SmartMail_UpdateCustomList then
            SmartMail_UpdateCustomList()
        end
    end)
end

function SmartMail_UpdateCustomList()
    SmartMail_Debug("SmartMail_UpdateCustomList called...")
    local scrollChild = getglobal("SmartMailCustomSendFrameListFrameScrollFrameScrollChild")
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
            
            row:SetScript("OnClick", function()
                local itemData = SmartMailCustom.items[this:GetID()]
                if not itemData.amountToSend then itemData.amountToSend = 0 end
                
                if arg1 == "RightButton" then
                    if IsShiftKeyDown() then
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
                elseif IsControlKeyDown() then
                    SmartMailCustomAmountFrame.mode = "add"
                    if SmartMailCustomAmountTitle then SmartMailCustomAmountTitle:SetText("Enter Amount") end
                    SmartMailCustomAmountFrame.itemData = itemData
                    SmartMailCustomAmountFrame:Show()
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
    text = "Enter Recipient Name:",
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
            if SmartMailValidator_Validate then SmartMailValidator_Validate(text) end
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
            table.insert(SmartMailDB_PerChar.customRecipients, text)
            SmartMailCustom.selectedRecipient = text
            if SmartMailValidator_Validate then SmartMailValidator_Validate(text) end
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
    hideOnEscape = 1
}

-- Create the Custom Send Frame programmatically
local frame = CreateFrame("Frame", "SmartMailCustomSendFrame", UIParent)
frame:SetWidth(320)
frame:SetHeight(420)
frame:SetPoint("CENTER", UIParent, "CENTER")
frame:SetToplevel(true)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() 
    this:SetFrameStrata("FULLSCREEN_DIALOG")
    this:StartMoving() 
end)
frame:SetScript("OnDragStop", function() 
    this:SetFrameStrata("DIALOG")
    this:StopMovingOrSizing() 
end)
frame:Hide()

local header = frame:CreateTexture(nil, "ARTWORK")
header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
header:SetWidth(300)
header:SetHeight(64)
header:SetPoint("TOP", frame, "TOP", 0, 12)

local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
title:SetPoint("TOP", header, "TOP", 0, -14)
title:SetText("SmartMail Custom Send")

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

local listFrame = CreateFrame("Frame", "SmartMailCustomSendFrameListFrame", frame)
listFrame:SetWidth(280)
listFrame:SetHeight(280)
listFrame:SetPoint("TOP", frame, "TOP", 0, -40)
listFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
listFrame:SetBackdropColor(0, 0, 0, 0.6)

local scrollFrame = CreateFrame("ScrollFrame", "SmartMailCustomSendFrameListFrameScrollFrame", listFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 8, -8)
scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -28, 8)

local scrollChild = CreateFrame("Frame", "SmartMailCustomSendFrameListFrameScrollFrameScrollChild", scrollFrame)
scrollChild:SetWidth(250)
scrollChild:SetHeight(260)
scrollFrame:SetScrollChild(scrollChild)

local moneyInput = CreateFrame("Frame", "SmartMailCustomMoneyInput", frame, "MoneyInputFrameTemplate")
moneyInput:SetPoint("TOP", listFrame, "BOTTOM", 10, -5)
MoneyInputFrame_SetCopper(moneyInput, 0)

local gBox = getglobal("SmartMailCustomMoneyInputGold")
local sBox = getglobal("SmartMailCustomMoneyInputSilver")
local cBox = getglobal("SmartMailCustomMoneyInputCopper")

if gBox then gBox:SetWidth(35) end
if sBox then sBox:SetWidth(35) end
if cBox then cBox:SetWidth(35) end

local addMoneyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
addMoneyBtn:SetWidth(40)
addMoneyBtn:SetHeight(20)
if cBox then
    addMoneyBtn:SetPoint("LEFT", cBox, "RIGHT", 5, 0)
else
    addMoneyBtn:SetPoint("LEFT", moneyInput, "RIGHT", 5, 0)
end
addMoneyBtn:SetText("Add")
addMoneyBtn:SetScript("OnClick", function()
    local copper = MoneyInputFrame_GetCopper(moneyInput)
    if copper > 0 then
        SmartMailCustom.moneyToSend = (SmartMailCustom.moneyToSend or 0) + copper
        SmartMail_Debug("CustomSend: Added " .. copper .. " copper to cart. Total money queued: " .. SmartMailCustom.moneyToSend)
        MoneyInputFrame_SetCopper(moneyInput, 0)
        if SmartMail_UpdateCustomCartList then SmartMail_UpdateCustomCartList() end
    end
end)

local sendBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
sendBtn:SetWidth(100)
sendBtn:SetHeight(24)
sendBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 40, 20)
sendBtn:SetText("Send")
sendBtn:SetScript("OnClick", function()
    SmartMailCustom:Send()
end)

local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
cancelBtn:SetWidth(100)
cancelBtn:SetHeight(24)
cancelBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 20)
cancelBtn:SetText("Cancel")
cancelBtn:SetScript("OnClick", function()
    frame:Hide()
end)

frame:SetScript("OnShow", function()
    SmartMailCustom:ScanInventory()
    for _, item in ipairs(SmartMailCustom.items) do item.amountToSend = 0 end
    SmartMailCustom.moneyToSend = 0
    SmartMail_UpdateCustomList()
    SmartMail_UpdateCustomCartList()
    if SmartMail_UpdateCustomRecipientList then
        SmartMail_UpdateCustomRecipientList()
    end
end)

-- Amount Entry Dialog
local amtFrame = CreateFrame("Frame", "SmartMailCustomAmountFrame", UIParent)
amtFrame:SetFrameStrata("FULLSCREEN_DIALOG")
amtFrame:SetWidth(200)
amtFrame:SetHeight(120)
amtFrame:SetPoint("CENTER", UIParent, "CENTER")
amtFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
amtFrame:SetBackdropColor(0, 0, 0, 1)
amtFrame:Hide()

local amtTitle = amtFrame:CreateFontString("SmartMailCustomAmountTitle", "ARTWORK", "GameFontNormal")
amtTitle:SetPoint("TOP", amtFrame, "TOP", 0, -15)
amtTitle:SetText("Enter Amount")

local amtEdit = CreateFrame("EditBox", "SmartMailCustomAmountEditBox", amtFrame, "InputBoxTemplate")
amtEdit:SetWidth(60)
amtEdit:SetHeight(20)
amtEdit:SetPoint("TOP", amtTitle, "BOTTOM", 0, -15)
amtEdit:SetNumeric(true)
amtEdit:SetAutoFocus(true)
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

local amtMaxBtn = CreateFrame("Button", nil, amtFrame, "UIPanelButtonTemplate")
amtMaxBtn:SetWidth(50)
amtMaxBtn:SetHeight(20)
amtMaxBtn:SetPoint("LEFT", amtEdit, "RIGHT", 5, 0)
amtMaxBtn:SetText("Max")
amtMaxBtn:SetScript("OnClick", function()
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

local amtOkBtn = CreateFrame("Button", nil, amtFrame, "UIPanelButtonTemplate")
amtOkBtn:SetWidth(80)
amtOkBtn:SetHeight(24)
amtOkBtn:SetPoint("BOTTOMLEFT", amtFrame, "BOTTOMLEFT", 15, 15)
amtOkBtn:SetText("Accept")
amtOkBtn:SetScript("OnClick", function()
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

local amtCancelBtn = CreateFrame("Button", nil, amtFrame, "UIPanelButtonTemplate")
amtCancelBtn:SetWidth(80)
amtCancelBtn:SetHeight(24)
amtCancelBtn:SetPoint("BOTTOMRIGHT", amtFrame, "BOTTOMRIGHT", -15, 15)
amtCancelBtn:SetText("Cancel")
amtCancelBtn:SetScript("OnClick", function() amtFrame:Hide() end)

amtFrame:EnableMouse(true)
amtFrame:SetMovable(true)
amtFrame:RegisterForDrag("LeftButton")
amtFrame:SetScript("OnDragStart", function() 
    this:SetFrameStrata("TOOLTIP")
    this:StartMoving() 
end)
amtFrame:SetScript("OnDragStop", function() 
    this:SetFrameStrata("FULLSCREEN_DIALOG")
    this:StopMovingOrSizing() 
end)

amtFrame:SetScript("OnShow", function() 
    amtEdit:SetText("") 
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    this:ClearAllPoints()
    this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end)

tinsert(UISpecialFrames, "SmartMailCustomAmountFrame")

-- Create the Side Panel for Recipients
local sidePanel = CreateFrame("Frame", "SmartMailCustomSidePanel", frame)
sidePanel:SetWidth(240)
sidePanel:SetHeight(420)
sidePanel:SetPoint("TOPLEFT", frame, "TOPRIGHT", -5, 0)
sidePanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
sidePanel:SetBackdropColor(0, 0, 0, 1)

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
sidePanel:EnableMouse(true)
sidePanel:RegisterForDrag("LeftButton")
sidePanel:SetScript("OnDragStart", function() 
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:StartMoving() 
end)
sidePanel:SetScript("OnDragStop", function() 
    frame:SetFrameStrata("DIALOG")
    frame:StopMovingOrSizing() 
end)

local sideHeader = sidePanel:CreateTexture(nil, "ARTWORK")
sideHeader:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
sideHeader:SetWidth(240)
sideHeader:SetHeight(64)
sideHeader:SetPoint("TOP", sidePanel, "TOP", 0, 12)

local sideTitle = sidePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
sideTitle:SetPoint("TOP", sideHeader, "TOP", 0, -14)
sideTitle:SetText("Recipient List")

local sideAddBtn = CreateFrame("Button", nil, sidePanel, "UIPanelButtonTemplate")
sideAddBtn:SetWidth(56)
sideAddBtn:SetHeight(24)
sideAddBtn:SetPoint("TOPLEFT", sidePanel, "TOPLEFT", 34, -40)
sideAddBtn:SetText("Add")
sideAddBtn:SetScript("OnClick", function()
    StaticPopup_Show("SMARTMAIL_CUSTOM_ADD_RECIPIENT")
end)

local histDropdown = CreateFrame("Frame", "SmartMailRecipientHistoryDropdown", sidePanel, "UIDropDownMenuTemplate")
histDropdown:Hide()

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

local sideHistBtn = CreateFrame("Button", "SmartMailCustomHistBtn", sidePanel, "UIPanelButtonTemplate")
sideHistBtn:SetWidth(56)
sideHistBtn:SetHeight(24)
sideHistBtn:SetPoint("LEFT", sideAddBtn, "RIGHT", 2, 0)
sideHistBtn:SetText("Hist")
sideHistBtn:SetScript("OnClick", function()
    UIDropDownMenu_Initialize(SmartMailRecipientHistoryDropdown, SmartMailRecipientHistoryDropdown_Initialize, "MENU")
    ToggleDropDownMenu(1, nil, SmartMailRecipientHistoryDropdown, "SmartMailCustomHistBtn", 0, 0)
end)

local sideDelBtn = CreateFrame("Button", nil, sidePanel, "UIPanelButtonTemplate")
sideDelBtn:SetWidth(56)
sideDelBtn:SetHeight(24)
sideDelBtn:SetPoint("LEFT", sideHistBtn, "RIGHT", 2, 0)
sideDelBtn:SetText("Delete")
sideDelBtn:SetScript("OnClick", function()
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

local sideListFrame = CreateFrame("Frame", "SmartMailCustomRecipientListFrame", sidePanel)
sideListFrame:SetWidth(200)
sideListFrame:SetHeight(80)
sideListFrame:SetPoint("TOP", sidePanel, "TOP", 0, -70)
sideListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
sideListFrame:SetBackdropColor(0, 0, 0, 1)

local sideScrollFrame = CreateFrame("ScrollFrame", "SmartMailCustomRecipientScrollFrame", sideListFrame, "UIPanelScrollFrameTemplate")
sideScrollFrame:SetPoint("TOPLEFT", sideListFrame, "TOPLEFT", 8, -8)
sideScrollFrame:SetPoint("BOTTOMRIGHT", sideListFrame, "BOTTOMRIGHT", -28, 8)

local sideScrollChild = CreateFrame("Frame", "SmartMailCustomRecipientScrollChild", sideScrollFrame)
sideScrollChild:SetWidth(170)
sideScrollChild:SetHeight(80)
sideScrollFrame:SetScrollChild(sideScrollChild)

local customListTitle = sidePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
customListTitle:SetPoint("TOP", sideListFrame, "BOTTOM", 0, -10)
customListTitle:SetText("Custom List")

local customListFrame = CreateFrame("Frame", "SmartMailCustomListSideFrame", sidePanel)
customListFrame:SetWidth(200)
customListFrame:SetHeight(220)
customListFrame:SetPoint("TOP", customListTitle, "BOTTOM", 0, -5)
customListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
customListFrame:SetBackdropColor(0, 0, 0, 1)

local customListScrollFrame = CreateFrame("ScrollFrame", "SmartMailCustomListSideScrollFrame", customListFrame, "UIPanelScrollFrameTemplate")
customListScrollFrame:SetPoint("TOPLEFT", customListFrame, "TOPLEFT", 8, -8)
customListScrollFrame:SetPoint("BOTTOMRIGHT", customListFrame, "BOTTOMRIGHT", -28, 8)

local customListScrollChild = CreateFrame("Frame", "SmartMailCustomListSideScrollChild", customListScrollFrame)
customListScrollChild:SetWidth(170)
customListScrollChild:SetHeight(220)
customListScrollFrame:SetScrollChild(customListScrollChild)

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
    SmartMailDB_PerChar.customRecipients = cleaned
    
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
            SmartMail_Debug("CustomCart: Removed all money from cart.")
            SmartMailCustom.moneyToSend = 0
            if SmartMail_UpdateCustomCartList then SmartMail_UpdateCustomCartList() end
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
            end
            
            row.text:SetText(itemData.itemName .. " (x" .. itemData.amountToSend .. ")")
            local dataRef = itemData
            
            row:SetScript("OnClick", function()
                if IsShiftKeyDown() then
                    SmartMailCustomAmountFrame.mode = "remove"
                    if SmartMailCustomAmountTitle then SmartMailCustomAmountTitle:SetText("Remove Amount") end
                    SmartMailCustomAmountFrame.itemData = dataRef
                    SmartMailCustomAmountFrame:Show()
                else
                    dataRef.amountToSend = dataRef.amountToSend - 1
                    if dataRef.amountToSend < 0 then dataRef.amountToSend = 0 end
                    SmartMail_Debug("CustomCart: Left-Click removed 1 " .. dataRef.itemName .. " from cart. New amount: " .. dataRef.amountToSend)
                end
                SmartMail_UpdateCustomCartList()
                SmartMail_UpdateCustomList()
            end)
            
            row:SetPoint("TOPLEFT", customListScrollChild, "TOPLEFT", 0, -yOffset)
            row:Show()
            yOffset = yOffset + 20
            cartIndex = cartIndex + 1
        end
    end
end
