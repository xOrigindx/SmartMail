# BRIDGE.md — Bridge.lua Design Reference

Bridge.lua is the **only** file in SmartMail that knows PeriodicTable (PT) set names.
It is a thin, **stateless** wrapper. It holds no state between calls.

---

## Purpose

- Map human-readable SmartMail category names → underlying PT set name(s).
- Query PT to resolve which item IDs belong to a category.
- Provide a conflict-detection map (`itemID → categoryName`) across all categories.
- Register the `ingredherbs` custom set at initialization (see below — NOT NEEDED, see note).

---

## Category-to-PT Mapping Table (Internal, hardcoded)

```lua
local CATEGORY_MAP = {
    ["Cloth"]          = { "ingredcloth" },
    ["Bolt"]           = { "ingredbolt" },
    ["Leather"]        = { "ingredleather" },
    ["Hide"]           = { "ingredhide" },
    ["Scale"]          = { "ingredscale" },
    ["Herbs"]          = { "gatherskillherbalism" },  -- ONLY herb set in PT; ingredherbs does NOT exist
    ["Ore"]            = { "ingredore" },
    ["Bar"]            = { "ingredbar" },
    ["Gem"]            = { "ingredgem" },
    ["Pearl"]          = { "ingredpearl" },
    ["Stone"]          = { "ingredstone" },
    ["Oil"]            = { "ingredoil" },
    ["Enchanting Mats"]= { "ingreddust", "ingredessence", "ingredshard" },  -- 3 sets, aggregated
}
```

> [!IMPORTANT]
> **Herbs** — `gatherskillherbalism` is the correct PT set name. `ingredherbs` does NOT exist in the library.
> This was confirmed by a full text search of all files under `Libs/`. Do not attempt to use `ingredherbs`.

> [!IMPORTANT]
> **Enchanting Mats** — Do NOT use `gatherskilldisenchant`. It includes Nexus Crystal (20725) which is
> intentionally excluded. Use only `ingreddust`, `ingredessence`, and `ingredshard`.

---

## Nexus Crystal

- **Item ID:** 20725
- **Status:** Unrouted. Not in any of the 13 categories.
- **Behavior:** Silently skipped during queue build. No log entry. Left in bags untouched.

---

## Public API

### `Bridge:GetItemsForCategory(categoryName)`
- **Input:** A category name string (e.g. `"Herbs"`)
- **Output:** `{ [itemID] = true, ... }` — a set of all item IDs in that category
- **Behavior:** Looks up the PT set name(s) from `CATEGORY_MAP`, queries PT, merges results.

### `Bridge:GetAllCategoryItems()`
- **Output:** `{ [itemID] = categoryName, ... }` — maps every known item ID to its category
- **Usage:** Called once at queue-build time for O(1) conflict detection.
- **Conflict note:** If an itemID appears in two categories (possible given PT set overlap), the last-written value wins in this map — the actual conflict is detected when comparing against profiles, not here.

### `Bridge:GetCategoryNames()`
- **Output:** Ordered list of all 13 category name strings.
- **Usage:** UI uses this to populate checkboxes in the profile editor.

---

## How Bridge Queries PT

PT exposes its sets via the global `PeriodicTable` library object. Bridge calls:

```lua
local PT = LibStub and LibStub("LibPeriodicTable-3.1") or PeriodicTable
-- Then iterate:
PT:IterateSet(setName, function(itemID, ...) ... end)
-- Or check membership:
PT:ItemInSet(itemID, setName)
```

The exact call signature depends on which PT version is embedded in `Libs/`. Bridge.lua must be written
after confirming the exact API exposed by the version present in the workspace.

---

## What Bridge Does NOT Do

- Does NOT cache results between calls.
- Does NOT hold any module-level mutable state.
- Does NOT call `RegisterCustomSet` (not needed — `gatherskillherbalism` is sufficient for herbs).
- Does NOT touch PTTradeskillsEmbed in v1.
- Does NOT know about characters, profiles, or bag contents.
