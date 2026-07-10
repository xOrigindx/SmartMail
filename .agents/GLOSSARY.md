# GLOSSARY.md — SmartMail Definitions, Schemas & Constants

---

## Core Terms

| Term | Definition |
|---|---|
| **Profile** | A named configuration entry that maps a destination character to a set of item categories. One profile per destination character. |
| **Category** | A named group of items (e.g. "Cloth", "Herbs"). Hardcoded in Bridge.lua. Backed by one or more PT set names. |
| **PT Set** | A PeriodicTable set — a string of space-separated item IDs stored in the library. Bridge.lua resolves categories to PT sets. |
| **Send Queue** | The ordered list of (itemID, bagID, slotID, recipient) tuples built before a send operation begins. |
| **Retry Queue** | Items that failed on first send attempt. Appended to the end of the main queue; each item gets one retry. |
| **Reserve** | One partial stack of an item kept in bags. The reserve threshold is: partial stack ≤ 50% of `maxStackSize`. |
| **isBusy** | `SmartMail.isBusy` — global boolean flag. `true` while a send operation is in progress. UI buttons are locked when true. |
| **Bridge.lua** | The thin, stateless module that maps SmartMail category names to PT set names and queries PT for item membership. |

---

## SavedVariable Schemas

### `SmartMailDB` (`SavedVariablesPerCharacter`)
Stores all profile/rule configuration. One DB per character.

```lua
SmartMailDB = {
    profiles = {
        ["DestinationCharName"] = {
            ["Cloth"]          = true,
            ["Bolt"]           = true,
            ["Leather"]        = true,
            -- etc.
        },
        ["AnotherBankChar"] = {
            ["Ore"]  = true,
            ["Bar"]  = true,
            ["Gem"]  = true,
        },
    },
    -- Future: global settings, version, etc.
}
```

### `SmartMailLog` (`SavedVariablesPerCharacter`)
Stores send session records. Flat sequential list. One DB per character.

```lua
SmartMailLog = {
    sessions = {
        -- Each entry is one complete send session
        {
            timestamp   = 12345.67,  -- GetTime() at session start
            sent        = 42,        -- total stacks successfully sent
            failed      = 2,         -- stacks that failed after retry
            skipped     = 1,         -- stacks skipped due to conflict
            entries     = {
                -- Per-item records (failures and conflicts only)
                { itemID = 2447, name = "Peacebloom", reason = "FAILED", attempts = 2 },
                { itemID = 2447, name = "Peacebloom", reason = "CONFLICT" },
            },
        },
        -- Newer sessions appended at the end
    },
}
```

**Notes:**
- `SmartMailDB` stays clean — configuration only.
- `SmartMailLog` is **per-character** (`SavedVariablesPerCharacter`).
- No date grouping — sessions are ordered by `GetTime()` timestamp.
- The Log frame in the UI shows sessions listed newest first.

---

## Item Category Constants (13 total — hardcoded in Bridge.lua)

| # | User Label | Bridge.lua PT Set(s) | PT Set Type | Approx. Item Count |
|---|---|---|---|---|
| 1 | Cloth | `ingredcloth` | Native PT | 7 |
| 2 | Bolt | `ingredbolt` | Native PT | 5 |
| 3 | Leather | `ingredleather` | Native PT | 15 |
| 4 | Hide | `ingredhide` | Native PT | 13 |
| 5 | Scale | `ingredscale` | Native PT | 13 |
| 6 | Herbs | `gatherskillherbalism` | Native PT | 29 |
| 7 | Ore | `ingredore` | Native PT | 10 |
| 8 | Bar | `ingredbar` | Native PT | 13 |
| 9 | Gem | `ingredgem` | Native PT | 18 |
| 10 | Pearl | `ingredpearl` | Native PT | 5 |
| 11 | Stone | `ingredstone` | Native PT | 5 |
| 12 | Oil | `ingredoil` | Native PT | 7 |
| 13 | Enchanting Mats | `ingreddust` + `ingredessence` + `ingredshard` | 3 native PT sets | ~23 |

### Special Cases

- **Herbs use `gatherskillherbalism`** — `ingredherbs` does NOT exist in the library. Confirmed by full search of `Libs/`.
- **Enchanting Mats** — Bridge.lua aggregates three sets into one logical category. Internally it checks all three sets.
- **Nexus Crystal (itemID 20725)** — appears in `gatherskilldisenchant` but is NOT in any of the 13 categories. It is **silently skipped** (left in bags, no log entry written).
- **Enchanting Mats conflict note:** `gatherskilldisenchant` includes Nexus Crystal; we deliberately use the three granular `ingred*` sets instead to exclude it cleanly.
