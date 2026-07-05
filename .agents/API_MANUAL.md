# API_MANUAL.md — SmartMail WoW 1.12.1 API Reference

All API calls are vanilla 1.12.1 client functions. No external API, no Ace framework calls.

---

## Bag Scanning

### `GetContainerItemLink(bagID, slotID)`
- **Returns:** Item link string (e.g. `"|cff...|Hitem:2447:...|h[Peacebloom]|h|r"`) or `nil` if slot is empty.
- **Usage:** Called during bag scan for every slot in every bag (bag 0–4, slots 1–N).
- **Purpose:** Extract the numerical item ID from the link string via pattern match: `string.match(link, "item:(%d+)")`.

### `GetContainerNumSlots(bagID)`
- **Returns:** Number of slots in the specified bag.
- **Usage:** Used to iterate slots correctly per bag. Bags 0–4.

### `GetContainerItemInfo(bagID, slotID)`
- **Returns:** `texture, itemCount, locked, quality, readable`
- **Usage:** `itemCount` tells us stack size for reserve/send logic.

---

## Item Info

### `GetItemInfo(itemID)`
- **Returns:** `name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture`
- **Key field:** `stackCount` (= `maxStackSize`) — used to determine reserve logic (partial stack ≤ 50% of maxStackSize is the reserve threshold).
- **Called:** At login/initialization to pre-build the name-to-ID lookup and maxStackSize cache.

---

## Mail Sending

### `SendMail(recipient, subject, body)`
- **Usage:** Opens the send flow. Must be called with the mailbox open.
- **Constraint:** Only one item can be attached per mail in 1.12.1.

### `SetSendMailItem(itemID, bagID, slotID)` *(or equivalent attachment call)*
- **Usage:** Attaches one item from a bag slot to the current mail. Called before `SendMail`.
- **1.12.1 hard constraint:** One attachment per mail. No multi-attach.

### `ClearSendMail()`
- **Usage:** Clears the current SendMailFrame state between sends.

---

## Date / Time

### `GetTime()`
- **Returns:** Seconds since system boot (a floating-point number).
- **Usage:** Session timestamp in `SmartMailLog`. Sufficient as a unique session identifier and ordering key.
- **Note:** There is NO calendar date API in the 1.12.1 client. `GetGameTime()` returns server hours/minutes only. `GetTime()` is the closest to a unique numeric timestamp available.

### `GetGameTime()`
- **Returns:** `hours, minutes` of current server time.
- **Usage:** Not used for logging. Available if needed for UI display purposes only.

---

## Initialization

### `SlashCmdList` and `SLASH_SMARTMAIL1`
- **Usage:** Register `/smartmail` or `/sm` as slash commands for manual UI toggle or debug.

---

## What We Do NOT Use

| API | Reason |
|---|---|
| `SplitContainerItem` | No physical stack merging — whole stacks only |
| `PickupContainerItem` | No cursor-based item manipulation |
| `GetInboxNumItems` | Outbound only; inbox is ignored in v1 |
| Any Ace2/Ace3 library calls | Not using Ace framework |
