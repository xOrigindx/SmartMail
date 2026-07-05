-- Slash Command Logic
SLASH_SMARTMAIL1 = "/sm"
SLASH_SMARTMAIL2 = "/smartmail"
SlashCmdList["SMARTMAIL"] = function(msg)
    if SmartMailConfigFrame:IsVisible() then
        SmartMailConfigFrame:Hide()
    else
        SmartMailConfigFrame:Show()
    end
end

-- Initialize Saved Variable
if not SmartMail_Characters then
    SmartMail_Characters = {}
end

-- Function to Update the List Display
function SmartMail_UpdateCharacterList()
    if not SmartMailRulesListFrame.characterLines then
        SmartMailRulesListFrame.characterLines = {}
    end

    -- Hide all existing lines
    for i = 1, getn(SmartMailRulesListFrame.characterLines) do
        SmartMailRulesListFrame.characterLines[i]:Hide()
    end

    -- Create/Show lines for each saved character
    local yOffset = -10
    for index, name in ipairs(SmartMail_Characters) do
        local line = SmartMailRulesListFrame.characterLines[index]
        if not line then
            line = SmartMailRulesListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tinsert(SmartMailRulesListFrame.characterLines, line)
        end

        line:SetPoint("TOPLEFT", SmartMailRulesListFrame, "TOPLEFT", 10, yOffset)
        line:SetText(name)
        line:Show()

        yOffset = yOffset - 20
    end
end

-- Function to Save a New Character
function SmartMail_SaveCharacter(name)
    if name and name ~= "" then
        for _, existingName in ipairs(SmartMail_Characters) do
            if existingName == name then
                return
            end
        end
        tinsert(SmartMail_Characters, name)
        SmartMail_UpdateCharacterList()
    end
end

-- Hook into Config Frame to Update on Open
SmartMailConfigFrame:SetScript("OnShow", function()
    SmartMail_UpdateCharacterList()
end)

-- Popup Configuration
StaticPopupDialogs["SMARTMAIL_ADD_CHARACTER"] = {
    text = "Enter destination character name:",
    button1 = "Accept",
    button2 = "Cancel",
    hasEditBox = 1,
    maxLetters = 12,
    OnAccept = function()
        local editBox = getglobal(this:GetParent():GetName().."EditBox")
        SmartMail_SaveCharacter(editBox:GetText())
    end,
    EditBoxOnEnterPressed = function()
        local editBox = getglobal(this:GetParent():GetName().."EditBox")
        SmartMail_SaveCharacter(editBox:GetText())
        this:GetParent():Hide()
    end,
    OnShow = function()
        getglobal(this:GetName().."EditBox"):SetFocus()
    end,
    OnHide = function()
        getglobal(this:GetName().."EditBox"):SetText("")
    end,
    EditBoxOnEscapePressed = function()
        this:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

-- Function to initiate adding a new rule
function SmartMail_AddRule()
    StaticPopup_Show("SMARTMAIL_ADD_RULE")
end

-- Popup Configuration for adding a rule
StaticPopupDialogs["SMARTMAIL_ADD_RULE"] = {
    text = "Enter item name and destination (Item:Character):",
    button1 = "Accept",
    button2 = "Cancel",
    hasEditBox = 1,
    maxLetters = 64,
    OnAccept = function()
        local editBox = getglobal(this:GetParent():GetName().."EditBox")
        -- Logic to parse "Item:Character" and store the rule
        local text = editBox:GetText()
        if text and text ~= "" then
            -- Implementation logic for storing the new rule goes here
        end
    end,
    EditBoxOnEnterPressed = function()
        local editBox = getglobal(this:GetParent():GetName().."EditBox")
        -- Implementation logic for storing the new rule goes here
        this:GetParent():Hide()
    end,
    OnShow = function()
        getglobal(this:GetName().."EditBox"):SetFocus()
    end,
    OnHide = function()
        getglobal(this:GetName().."EditBox"):SetText("")
    end,
    EditBoxOnEscapePressed = function()
        this:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}