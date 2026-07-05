-- SmartMail.lua (Minimal version)

-- Frame Scripts required by SmartMail.xml
function SmartMail_OnLoad(frame)
    frame:RegisterEvent("ADDON_LOADED")
    table.insert(UISpecialFrames, "SmartMailFrame")
end

function SmartMail_OnEvent(frame, event)
    if event == "ADDON_LOADED" and arg1 == "SmartMail" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r: Minimal version loaded! Type /sm", 1, 1, 1)
    end
end

function SmartMailLog_OnLoad(frame)
    table.insert(UISpecialFrames, "SmartMailLogFrame")
end

-- Dummy functions to prevent XML button OnClick errors
function SmartMail_DeleteProfile() end
function SmartMail_UpdateProfileList() end
function SmartMail_SendAll() end
function SmartMail_SendSelected() end
function SmartMail_OpenOptions() end
function SmartMailMinimap_OnLoad() end
function SmartMailMinimap_OnClick() end
function SmartMailMinimap_OnEnter() end
function SmartMailMinimap_OnDragStop() end

-- Slash Commands
SlashCmdList["SMARTMAIL"] = function(msg)
    if msg == "show" then
        SmartMailFrame:Show()
        if SmartMailLogFrame then SmartMailLogFrame:Show() end
    elseif msg == "hide" then
        SmartMailFrame:Hide()
        if SmartMailLogFrame then SmartMailLogFrame:Hide() end
    else
        if SmartMailFrame:IsShown() then
            SmartMailFrame:Hide()
            if SmartMailLogFrame then SmartMailLogFrame:Hide() end
        else
            SmartMailFrame:Show()
            if SmartMailLogFrame then SmartMailLogFrame:Show() end
        end
    end
end

SLASH_SMARTMAIL1 = "/smartmail"
SLASH_SMARTMAIL2 = "/sm"
