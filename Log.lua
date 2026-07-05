-- Log.lua
-- Reads and writes SmartMailLog (SavedVariablesPerCharacter).
-- All other modules call SmartMailLog_Add() to append an entry.
-- UI.lua's log window (SmartMailLogOutput) is written to at the same time.
--
-- SmartMailLog structure (per character):
--   SmartMailLog.entries = {
--       { ts = <timestamp string>, text = <message> },
--       ...
--   }
--
-- The in-game log window (SmartMailLogOutput) is a ScrollingMessageFrame
-- declared in SmartMail.xml. We write to it via :AddMessage().

SmartMailLog_Module = SmartMailLog_Module or {}

-- Maximum entries to persist in SavedVariables per character
local MAX_ENTRIES = 500

-- Colour codes used by SmartMailLog_Add
local COLOUR = {
    info  = { r = 0.8,  g = 0.8,  b = 0.8  },   -- grey-white
    ok    = { r = 0.2,  g = 1.0,  b = 0.4  },   -- green
    warn  = { r = 1.0,  g = 0.8,  b = 0.0  },   -- yellow
    error = { r = 1.0,  g = 0.3,  b = 0.3  },   -- red
}


-- ============================================================
-- SmartMailLog_Timestamp()
-- Returns a short human-readable timestamp "[HH:MM:SS]".
-- ============================================================
local function SmartMailLog_Timestamp()
    -- GetGameTime() in 1.12.1 returns a single decimal number: hours since midnight (server time).
    -- math.mod() is the Lua 5.0 equivalent of the 5.1+ % operator.
    local hours = GetGameTime()
    local totalSeconds = math.floor(hours * 3600)
    local ss = math.mod(totalSeconds, 60)
    local mm = math.mod(math.floor(totalSeconds / 60), 60)
    local hh = math.mod(math.floor(totalSeconds / 3600), 24)
    return string.format("[%02d:%02d:%02d]", hh, mm, ss)
end



-- ============================================================
-- SmartMailLog_Add(text, level)
-- Appends a log entry.
--   text  : the message string
--   level : "info" | "ok" | "warn" | "error"  (default "info")
--
-- Writes to:
--   1. SmartMailLog.entries  (SavedVariablesPerCharacter, persisted)
--   2. SmartMailLogOutput    (the in-game ScrollingMessageFrame, session only)
-- ============================================================
function SmartMailLog_Add(text, level)
    level = level or "info"
    local col = COLOUR[level] or COLOUR.info

    local ts   = SmartMailLog_Timestamp()
    local line = ts .. " " .. (text or "")

    -- ── 1. Persist to SavedVariables ──────────────────────────────
    if type(SmartMailLog) == "table" then
        if not SmartMailLog.entries then SmartMailLog.entries = {} end

        table.insert(SmartMailLog.entries, { ts = ts, text = text or "" })

        -- Trim oldest entries if over the cap
        while table.getn(SmartMailLog.entries) > MAX_ENTRIES do
            table.remove(SmartMailLog.entries, 1)
        end
    end

    -- ── 2. Write to the in-game log frame (if it exists) ──────────
    if SmartMailLogOutput then
        SmartMailLogOutput:AddMessage(line, col.r, col.g, col.b)
    end
end


-- ============================================================
-- SmartMailLog_Clear()
-- Clears the in-game frame AND the persisted log for this character.
-- ============================================================
function SmartMailLog_Clear()
    if type(SmartMailLog) == "table" then
        SmartMailLog.entries = {}
    end
    if SmartMailLogOutput then
        SmartMailLogOutput:Clear()
    end
end


-- ============================================================
-- SmartMailLog_Replay()
-- Replays all persisted entries back into the in-game frame.
-- Called by SmartMailLog_OnLoad() (wired in SmartMail.xml) once
-- the frame exists and the saved vars have been loaded.
-- ============================================================
function SmartMailLog_Replay()
    if not SmartMailLogOutput then return end
    if not SmartMailLog or not SmartMailLog.entries then return end

    for _, entry in ipairs(SmartMailLog.entries) do
        local line = (entry.ts or "") .. " " .. (entry.text or "")
        SmartMailLogOutput:AddMessage(line,
            COLOUR.info.r, COLOUR.info.g, COLOUR.info.b)
    end
end


-- ============================================================
-- SmartMailLog_OnLoad(self)
-- Called from SmartMail.xml OnLoad on SmartMailLogFrame.
-- Replays persisted entries once SavedVariables are available.
-- Note: SmartMail_Init() runs before this because SmartMailFrame
-- loads first (XML order) and ADDON_LOADED fires once for the addon.
-- ============================================================
function SmartMailLog_OnLoad(self)
    -- Replay is deferred; SmartMailLog may not be initialised yet.
    -- SmartMail_Init() sets SmartMailLog defaults; we rely on that
    -- having run first (guaranteed by load order + ADDON_LOADED timing).
    -- UI.lua calls SmartMailLog_Replay() from SmartMailUI_Init().

    -- Enable left-button dragging
    self:RegisterForDrag("LeftButton")

    -- ESC can close the log window (lower priority than the editor)
    table.insert(UISpecialFrames, "SmartMailLogFrame")
end
