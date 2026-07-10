# ARCHITECTURE.md — SmartMail Addon Structure & Data Flow

---

## High-Level Module Overview

```
SmartMail/
├── SmartMail.toc            -- Addon manifest (lists all files in load order)
├── SmartMail.lua            -- Core: global state, event backbone, initialization
├── SmartMail.xml            -- Frame/widget declarations for all UI (loaded by TOC)
├── Bridge.lua               -- Thin stateless wrapper: category → PT set → item ID lookup
├── Queue.lua                -- Send queue and retry queue management
├── UI.lua                   -- UI logic, event handlers for frames declared in SmartMail.xml
├── Log.lua                  -- SmartMailLog read/write helpers
└── Libs/                    -- External libraries (NEVER TOUCH)
    └── (PeriodicTable, PTTradeskillsEmbed, etc.)
```

> **XML vs Lua split:** In WoW 1.12.1, all frame/widget structure (size, position, anchors, textures,
> font strings, buttons) is declared in `SmartMail.xml`. The corresponding `UI.lua` contains only
> the logic and event handlers that reference those frames by their global names.

---

## Module Responsibilities

### `SmartMail.lua` (Core)
- Defines `SmartMail` as the top-level global table.
- Holds `SmartMail.isBusy` — the global busy flag.
- Registers the `MAIL_SHOW` and `MAIL_CLOSED` event handlers.
- On `MAIL_SHOW`: calls init sequence, registers all other listeners, shows UI.
- On `MAIL_CLOSED`: unregisters all listeners, hides UI, clears transient state.
- On login/`PLAYER_LOGIN`: calls `SmartMail:BuildLookup()` to pre-build the name-to-ID and maxStackSize cache.

### `Bridge.lua` (Stateless PT Wrapper)
- Contains the **hardcoded category-to-PT-set mapping table** (the 13 categories).
- Exposes `Bridge:GetItemsForCategory(categoryName)` → returns a table of `{ itemID = true }`.
- Exposes `Bridge:GetAllCategoryItems()` → returns a flat `{ itemID = categoryName }` map for fast conflict detection.
- Never holds state between calls. All PT queries are done fresh each call.
- For Enchanting Mats: queries all three sets (`ingreddust`, `ingredessence`, `ingredshard`) and merges results.

### `Queue.lua` (Send Queue)
- Builds the send queue from a profile or all profiles.
- Manages the retry queue.
- Exposes `Queue:Build(profiles)` → populates `Queue.items[]`.
- Exposes `Queue:Next()` → returns the next item tuple or nil if empty.
- Exposes `Queue:Fail(item)` → moves item to retry queue.
- Exposes `Queue:Flush()` → appends retry queue to main queue and clears retry list.

### `UI.lua` (All Frames)
- Main SmartMail window with profile list and action buttons.
- Profile editor frame (New / Modify).
- Confirmation frame (shown for Send [Character] — user removes items before confirming).
- Log frame (shown when Log button is clicked).
- All frame names are globally unique (e.g. `SmartMailMainFrame`, `SmartMailConfirmFrame`, `SmartMailLogFrame`).

### `Log.lua` (Logging Helpers)
- Reads from and writes to `SmartMailLog`.
- `Log:StartSession()` → creates a new session entry with `GetTime()` timestamp.
- `Log:RecordFailure(itemID, name, attempts)` → appends a failure entry to current session.
- `Log:RecordConflict(itemID, name)` → appends a conflict entry to current session.
- `Log:CloseSession(sent, failed, skipped)` → finalizes the session totals.

---

## Global State

```lua
SmartMail = {
    isBusy      = false,   -- locked during send operations
    lookup      = {},      -- [itemID] = { name, maxStackSize } — built at login
    db          = nil,     -- reference to SmartMailDB (loaded from SavedVars)
    log         = nil,     -- reference to SmartMailLog (loaded from SavedVars)
}
```

---

## Initialization Sequence

1. **`PLAYER_LOGIN`** fires → `SmartMail:BuildLookup()` runs.
   - Iterates all 13 categories via Bridge.
   - For each itemID: calls `GetItemInfo(itemID)` → stores `{ name, maxStackSize }` in `SmartMail.lookup`.
2. **Player opens mailbox** → `MAIL_SHOW` fires.
   - Register `MAIL_SEND_SUCCESS`, `MAIL_FAILED`, `BAG_UPDATE` listeners.
   - Run `SmartMail:ScanBags()` → builds a current snapshot of bag contents `{ [itemID] = { stacks = {}, totalCount } }`.
   - Show SmartMail UI.
3. **Player closes mailbox** → `MAIL_CLOSED` fires.
   - Unregister all listeners.
   - `SmartMail.isBusy = false`.
   - Hide UI.

---

## Send Flow (Detailed)

### Send All
```
User clicks "Send All"
→ SmartMail.isBusy = true
→ Queue:Build(all profiles)
→ apply reserve logic per item
→ apply conflict detection (skip + log conflicts)
→ Queue:Next() → SetSendMailItem() + SendMail()
→ await MAIL_SEND_SUCCESS or MAIL_FAILED
  → on success: Queue:Next() → continue
  → on failure: Queue:Fail(item) → Queue:Next() → continue
→ when main queue empty: Queue:Flush() → process retry queue
→ when retry queue empty: Log:CloseSession() → SmartMail.isBusy = false
```

### Send [Character]
```
User clicks a character profile
→ SmartMail:BuildCandidateList(profile)
→ Show SmartMailConfirmFrame with candidate list
→ User removes items optionally
→ User clicks Confirm
→ Queue:Build(filtered candidates)
→ same send flow as Send All from here
```

---

## Reserve Logic

For each itemID found in bags:
1. Get `maxStackSize` from `SmartMail.lookup`.
2. Identify all stacks for this itemID (from bag scan).
3. Find partial stacks (count < maxStackSize).
4. If any partial stack count ≤ 50% of maxStackSize → mark ONE partial stack as the reserve (do not queue it).
5. All remaining full stacks → add to send queue.
6. If no partial stack qualifies as reserve but Send Amount was specified → honour Send Amount cap on full stacks.

---

## Conflict Detection

Run once at queue build time:
1. Get the full `{ [itemID] = categoryName }` map from `Bridge:GetAllCategoryItems()`.
2. For each item in bags: check which profiles/categories claim it.
3. If more than one profile claims the same itemID: skip it, call `Log:RecordConflict()`.

---

## Key Design Constraints

- **Bridge.lua is always stateless.** It never caches, never stores between calls.
- **No `SplitContainerItem`.** Whole stacks only.
- **One attachment per mail.** 1.12.1 hard limit.
- **`SmartMailDB` is config only.** Never write session/log data to it.
- **`Libs/` is never touched.** PT and all libraries are read-only external dependencies.
- **PTTradeskillsEmbed** is loaded as a library passenger but its active guard (`TradesUseItem`) is not used in v1.
