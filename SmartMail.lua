-- SmartMail.lua
-- Core module: global namespace, SavedVariables defaults, event registration,
-- initialization, and slash command entry point.
--
-- Other files reference the SmartMail table directly; never require() them.
-- Load order (per .toc): SmartMail.xml → SmartMail.lua → Bridge.lua → Queue.lua → Log.lua → UI.lua

-- ============================================================
-- Global namespace
-- ============================================================

SmartMail = SmartMail or {}

-- Runtime state (reset on every session; NOT saved to disk)
SmartMail.selectedIndex  = nil    -- index into SmartMailDB.profiles of the highlighted row
SmartMail.isSending      = false  -- true while the send queue is running
SmartMail.rowButtons     = {      -- references to the XML row button frames
    SmartMailRow1, SmartMailRow2, SmartMailRow3, SmartMailRow4,
    SmartMailRow5, SmartMailRow6, SmartMailRow7, SmartMailRow8,
}
SmartMail.NUM_ROWS       = 8      -- must match the count above

-- Version string shown in /sm info
SmartMail.VERSION = "0.1.0"

-- ============================================================
-- SavedVariables default structure
-- Applied once in SmartMail_Init() if keys are missing.
-- ============================================================

local DB_DEFAULTS = {
    profiles    = {},    -- array of { name, recipient, categories={} }
    minimapPos  = 220,   -- angle in degrees (0-360) around the minimap edge
}

-- Per-character log defaults (SmartMailLog)
local LOG_DEFAULTS = {
    entries = {},        -- array of { timestamp, text } strings (placeholder; Log.lua owns writes)
}

-- ============================================================
-- Internal helpers
-- ============================================================

-- SmartMail_ApplyDefaults(tbl, defaults)
-- Walks `defaults` and sets any missing keys on `tbl`.
-- Shallow only; nested tables get a fresh copy if the key is absent.
local function SmartMail_ApplyDefaults(tbl, defaults)
    for k, v in pairs(defaults) do
        if tbl[k] == nil then
            if type(v) == "table" then
                tbl[k] = {}
            else
                tbl[k] = v
            end
        end
    end
end

-- ============================================================
-- Initialization (called once after SavedVariables are loaded)
-- ============================================================

local initialized = false

function SmartMail_Init()
    if initialized then return end
    initialized = true

    -- Ensure global SavedVariable tables exist
    if type(SmartMailDB) ~= "table" then SmartMailDB = {} end
    if type(SmartMailLog) ~= "table" then SmartMailLog = {} end

    SmartMail_ApplyDefaults(SmartMailDB, DB_DEFAULTS)
    SmartMail_ApplyDefaults(SmartMailLog, LOG_DEFAULTS)

    -- Let the UI module finalize frame layout now that DB is ready
    if SmartMailUI_Init then SmartMailUI_Init() end

    -- Welcome message
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00ccffSmartMail|r v" .. SmartMail.VERSION ..
        " loaded. Type |cffffd700/sm|r for help.",
        1, 1, 1
    )
end

-- ============================================================
-- Frame event handlers  (wired up in SmartMail.xml OnLoad/OnEvent)
-- ============================================================

function SmartMail_OnLoad(self)
    -- Register every event this frame needs to respond to
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LOGIN")

    -- Enable left-button dragging (movable="true" in XML is not enough alone)
    self:RegisterForDrag("LeftButton")

    -- Register with Vanilla's ESC-close system.
    -- UISpecialFrames is a global table; the game hides the topmost
    -- visible entry when the player presses Escape.
    table.insert(UISpecialFrames, "SmartMailFrame")
end

function SmartMail_OnEvent(self, event)
    if event == "ADDON_LOADED" and arg1 == "SmartMail" then
        -- SavedVariables are guaranteed to be loaded at this point
        SmartMail_Init()

    elseif event == "PLAYER_LOGIN" then
        -- Belt-and-suspenders: init if ADDON_LOADED somehow fired before
        -- SavedVariables were ready (shouldn't happen, but guard anyway)
        SmartMail_Init()
    end
end

-- ============================================================
-- Slash commands   /sm  and  /smartmail
-- ============================================================
--
-- Usage:
--   /sm            → toggle the main SmartMail window
--   /sm show       → show the main window
--   /sm hide       → hide the main window
--   /sm log        → toggle the log window
--   /sm profiles   → print all profile names to chat
--   /sm version    → print version
--   /sm help       → print this help

local function SmartMail_SlashHandler(msg)
    local cmd = strtrim(string.lower(msg or ""))

    if cmd == "" or cmd == "toggle" then
        -- Toggle the main window
        if SmartMailFrame:IsShown() then
            SmartMailFrame:Hide()
        else
            SmartMailFrame:Show()
        end

    elseif cmd == "show" then
        SmartMailFrame:Show()

    elseif cmd == "hide" then
        SmartMailFrame:Hide()

    elseif cmd == "log" then
        if SmartMailLogFrame:IsShown() then
            SmartMailLogFrame:Hide()
        else
            SmartMailLogFrame:Show()
        end

    elseif cmd == "profiles" then
        if not SmartMailDB or not SmartMailDB.profiles then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r: No profiles found.", 1, 0.5, 0.5)
            return
        end
        local count = table.getn(SmartMailDB.profiles)
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r: No profiles saved yet.", 1, 1, 0.5)
        else
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff00ccffSmartMail|r: " .. count .. " profile(s):", 1, 1, 1
            )
            for i, profile in ipairs(SmartMailDB.profiles) do
                local cats = table.concat(profile.categories or {}, ", ")
                if cats == "" then cats = "(no categories)" end
                DEFAULT_CHAT_FRAME:AddMessage(
                    "  |cffffff00" .. i .. ".|r " ..
                    "|cffffd700" .. (profile.name or "?") .. "|r" ..
                    " → " .. (profile.recipient or "?") ..
                    "  [" .. cats .. "]",
                    0.8, 0.8, 0.8
                )
            end
        end

    elseif cmd == "version" then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccffSmartMail|r version |cffffff00" .. SmartMail.VERSION .. "|r",
            1, 1, 1
        )

    elseif cmd == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r commands:", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/sm|r          — toggle main window", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/sm show|r     — show main window", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/sm hide|r     — hide main window", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/sm log|r      — toggle log window", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/sm profiles|r — list all profiles in chat", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/sm version|r  — print version", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00/sm help|r     — show this help", 0.8, 0.8, 0.8)

    else
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccffSmartMail|r: Unknown command '" .. cmd .. "'. Type |cffffff00/sm help|r.",
            1, 0.5, 0.5
        )
    end
end

-- Register both aliases
SlashCmdList["SMARTMAIL"] = SmartMail_SlashHandler
SLASH_SMARTMAIL1 = "/smartmail"
SLASH_SMARTMAIL2 = "/sm"

-- ============================================================
-- Stub guards
-- Functions called by button OnClick scripts in SmartMail.xml.
-- These are fully implemented in UI.lua; the stubs here prevent
-- Lua errors if UI.lua hasn't loaded yet (shouldn't happen given
-- load order, but keeps the frame safe during development).
-- ============================================================

if not SmartMail_SendAll then
    function SmartMail_SendAll()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r: UI not ready.", 1, 0.5, 0.5)
    end
end

if not SmartMail_SendSelected then
    function SmartMail_SendSelected()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r: UI not ready.", 1, 0.5, 0.5)
    end
end

if not SmartMail_DeleteProfile then
    function SmartMail_DeleteProfile()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffSmartMail|r: UI not ready.", 1, 0.5, 0.5)
    end
end

if not SmartMail_OpenOptions then
    function SmartMail_OpenOptions()
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccffSmartMail|r: Options panel coming soon.", 1, 1, 0.5
        )
    end
end

if not SmartMail_UpdateProfileList then
    function SmartMail_UpdateProfileList()
        -- no-op until UI.lua loads
    end
end
