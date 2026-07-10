# LOG.md — SmartMailLog Design Reference

---

## Overview

`SmartMailLog` is a **`SavedVariablesPerCharacter`** — one log per character.
It records send session outcomes: failures, conflicts, and summary counts.
`SmartMailDB` (the config database) is **never** written to by the log system.

---

## Schema

```lua
SmartMailLog = {
    sessions = {
        -- Flat sequential list. Sessions appended in order. Newest = highest index.
        {
            timestamp = 12345.67,  -- GetTime() at session start (seconds since system boot)
            sent      = 42,        -- total stacks successfully sent this session
            failed    = 2,         -- stacks that failed even after retry
            skipped   = 1,         -- stacks skipped due to conflict
            entries   = {
                -- Only failures and conflicts are recorded here.
                -- Successful sends are counted in `sent` only.
                {
                    itemID  = 2447,
                    name    = "Peacebloom",
                    reason  = "FAILED",    -- "FAILED" or "CONFLICT"
                    attempts = 2,          -- only present for FAILED entries
                },
                {
                    itemID  = 4306,
                    name    = "Fadeleaf",
                    reason  = "CONFLICT",
                    -- no `attempts` field for conflicts
                },
            },
        },
        -- More sessions...
    },
}
```

---

## Timestamp Note

There is **no calendar date API** in the WoW 1.12.1 client.

- `GetGameTime()` returns server hours and minutes — no calendar date.
- `GetTime()` returns seconds since system boot — a unique, ordered numeric value.
- **`GetTime()` is used as the session timestamp.** It is sufficient as a unique identifier and ordering key.
- The UI displays the raw numeric value or a formatted uptime string. No "28/07/2026" date display is possible from client-side API alone.

---

## Log.lua Public API

### `Log:StartSession()`
- Creates a new session table `{ timestamp = GetTime(), sent = 0, failed = 0, skipped = 0, entries = {} }`.
- Appends it to `SmartMailLog.sessions`.
- Stores a reference as `Log.currentSession` for the duration of the send operation.

### `Log:RecordFailure(itemID, name)`
- Appends `{ itemID, name, reason = "FAILED", attempts = 2 }` to `Log.currentSession.entries`.
- Increments `Log.currentSession.failed`.

### `Log:RecordConflict(itemID, name)`
- Appends `{ itemID, name, reason = "CONFLICT" }` to `Log.currentSession.entries`.
- Increments `Log.currentSession.skipped`.

### `Log:RecordSuccess()`
- Increments `Log.currentSession.sent`.
- No entry written — successes are counted only.

### `Log:CloseSession()`
- Clears `Log.currentSession`.
- The session is already in `SmartMailLog.sessions` (by reference), so no explicit write needed.

---

## Behavior Rules

- A new session is started each time a send operation begins (Send All or Send [Character]).
- Each send operation produces exactly one session record.
- Sessions are **never merged or grouped** — even if two sends happen in the same real-world day.
- The log frame in the UI displays sessions newest-first (reverse index order).
- `SmartMailLog.sessions` is never cleared automatically. Only the user can clear it via the UI.
