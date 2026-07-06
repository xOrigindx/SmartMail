function SmartMail_Log(msg)
    local h, m = GetGameTime()
    local timeStr = string.format("%02d:%02d", h, m)
    local logMsg = "[" .. timeStr .. "] " .. tostring(msg)
    
    if not SmartMailLog then SmartMailLog = {} end
    if not SmartMailLog.history then SmartMailLog.history = {} end
    table.insert(SmartMailLog.history, 1, logMsg)
    if table.getn(SmartMailLog.history) > 100 then
        table.remove(SmartMailLog.history)
    end
    
    if not SmartMailLog_PerChar then SmartMailLog_PerChar = {} end
    if not SmartMailLog_PerChar.history then SmartMailLog_PerChar.history = {} end
    table.insert(SmartMailLog_PerChar.history, 1, logMsg)
    if table.getn(SmartMailLog_PerChar.history) > 100 then
        table.remove(SmartMailLog_PerChar.history)
    end
    
    if SmartMailLogFrame and SmartMailLogFrame:IsVisible() then
        SmartMail_UpdateLogFrame()
    end
end

function SmartMail_UpdateLogFrame()
    if SmartMailLog and SmartMailLog.history then
        local text = table.concat(SmartMailLog.history, "\n")
        if SmartMailLogFrameText then
            SmartMailLogFrameText:SetText(text)
            
            local scrollFrame = SmartMailLogFrameContentFrameScrollFrame
            if scrollFrame then
                scrollFrame:UpdateScrollChildRect()
                scrollFrame:SetVerticalScroll(0)
            end
        end
    end
end
