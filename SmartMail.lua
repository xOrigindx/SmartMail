DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r: LUA FILE LOADED!", 1, 1, 1)

SlashCmdList["SMARTMAIL"] = function(msg)
    if SmartMailFrame:IsShown() then
        SmartMailFrame:Hide()
    else
        SmartMailFrame:Show()
    end
end

SLASH_SMARTMAIL1 = "/smartmail"
SLASH_SMARTMAIL2 = "/sm"
