SmartMailLogMode = "ALL"

function SmartMail_Log(msg, category)
    SmartMail_Debug("SmartMail_Log called...")
    local h, m = GetGameTime()
    local timeStr = string.format("%02d:%02d", h, m)
    category = category or "SYSTEM"
    
    local entry = { time = timeStr, text = msg, cat = category }
    
    if not SmartMailMailLog_PerChar then SmartMailMailLog_PerChar = {} end
    if not SmartMailMailLog_PerChar.history then SmartMailMailLog_PerChar.history = {} end
    table.insert(SmartMailMailLog_PerChar.history, 1, entry)
    
    if SmartMailLogFrame and SmartMailLogFrame:IsVisible() then
        SmartMail_UpdateLogFrame()
    end
end

function SmartMail_UpdateLogFrame()
    SmartMail_Debug("SmartMail_UpdateLogFrame called...")

    if SmartMailLogMode == "DEBUG" then
        if SmartMailDebugLog_PerChar and SmartMailDebugLog_PerChar.debugLog then
            local lines = {}
            for _, entry in ipairs(SmartMailDebugLog_PerChar.debugLog) do
                table.insert(lines, tostring(entry))
            end
            local fullText = table.concat(lines, "\n")
            if SmartMailLogFrameText then
                SmartMailLogFrameText:SetText(fullText)
                local scrollFrame = SmartMailLogFrameContentFrameScrollFrame
                if scrollFrame then
                    local textHeight = SmartMailLogFrameText:GetHeight()
                    if textHeight < 150 then textHeight = 150 end
                    SmartMailLogFrameContentFrameScrollFrameScrollChild:SetHeight(textHeight)
                    scrollFrame:UpdateScrollChildRect()
                    scrollFrame:SetVerticalScroll(0)
                end
            end
        end
        return
    end

    if SmartMailMailLog_PerChar and SmartMailMailLog_PerChar.history then
        local lines = {}
        for _, entry in ipairs(SmartMailMailLog_PerChar.history) do
            local cat = "SYSTEM"
            local time = ""
            local text = ""
            if type(entry) == "table" then
                cat = entry.cat or "SYSTEM"
                time = entry.time or ""
                text = entry.text or ""
            else
                text = tostring(entry)
            end
            
            if SmartMailLogMode == "ALL" or SmartMailLogMode == cat then
                local formatted = ""
                if time ~= "" then formatted = "[" .. time .. "] " end
                
                if cat == "INCOMING" then
                    formatted = "|cff00ff00" .. formatted .. text .. "|r"
                elseif cat == "OUTGOING" then
                    formatted = "|cffff0000" .. formatted .. text .. "|r"
                else
                    formatted = formatted .. text
                end
                
                table.insert(lines, formatted)
            end
        end
        
        local fullText = table.concat(lines, "\n")
        if SmartMailLogFrameText then
            SmartMailLogFrameText:SetText(fullText)
            
            local scrollFrame = SmartMailLogFrameContentFrameScrollFrame
            if scrollFrame then
                local textHeight = SmartMailLogFrameText:GetHeight()
                if textHeight < 150 then textHeight = 150 end
                SmartMailLogFrameContentFrameScrollFrameScrollChild:SetHeight(textHeight)
                
                scrollFrame:UpdateScrollChildRect()
                scrollFrame:SetVerticalScroll(0)
            end
        end
    end
end

StaticPopupDialogs["SMARTMAIL_CLEAR_LOG"] = {
    text = "Are you sure you want to clear the entire mail log?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        SmartMail_Debug("OnAccept (Clear Log) called...")
        SmartMail_ClearLog()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function SmartMail_ClearLog()
    SmartMail_Debug("SmartMail_ClearLog called...")
    if SmartMailLogMode == "DEBUG" then
        if SmartMailDebugLog_PerChar then SmartMailDebugLog_PerChar.debugLog = {} end
    else
        if SmartMailMailLog_PerChar then SmartMailMailLog_PerChar.history = {} end
    end
    if SmartMailLogFrame and SmartMailLogFrame:IsVisible() then
        SmartMail_UpdateLogFrame()
    end
end
