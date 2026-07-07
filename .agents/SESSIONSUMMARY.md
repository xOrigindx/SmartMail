# Session Summary

## Major Changes
- **Custom Send Overhaul**: Completely built out the Custom Send UI, featuring a dual-list design. The left side scans the bags and categorizes items by type/name. The right side is a dual-purpose panel with a `Custom List` cart and a `Recipient List`.
- **Cart Logic & Context Popups**: Users can build a cart. `Click` adds items, `Shift-Click` handles bulk amounts contextually. If Shift-Clicking from the Main List, the popup is `Enter Amount` (add). If Shift-Clicking from the Cart, the popup is `Remove Amount` (subtract/delete).
- **Recipient Validation Engine**: Implemented an advanced recipient validator. Adding a recipient while at a mailbox sends a dummy validation letter. If it triggers a "Cannot find mail recipient" UI error, the invalid recipient is instantly pruned. Added `Waiting` and `Validating...` UI states.
- **Data Persistence**: Ensured Custom Recipient lists and validation states persist across reloads using `SmartMailDB_PerChar` for character-wide memory.
- **Engine Infinite Loop Fix**: Upgraded `Engine.lua` to fuzzy-match UI errors containing "recipient" or "money", instantly aborting rather than infinitely retrying. Also added a strict max 3 retries limit for all items to completely eliminate endless loop hazards.
- **ESC Frame Stack Physics**: Implemented a global `SmartMail_HookFrameStack` system that dynamically intercepts frame logic to ensure child windows, dialog popups, and main frames always close sequentially on ESC based on the order of user interaction, without corrupting Vanilla WoW's global menu logic.

## Next Session Checklist
- [ ] Check `AGENTS.md` and `MEMORY.md` immediately upon starting.
- [x] BUG FIX: The Custom Send button has an issue where it might always be sending the max amount instead of respecting the specific amounts chosen in the Custom Cart. This needs to be investigated and fixed immediately.
- [ ] Continue building out or refining the Custom Send pipeline to the Engine if necessary.


