# Session Summaries

## 2026-07-05 - Session: UI, Profiles, and Save State Isolation
**Summary of Major Changes:**
- **Debug System**: Created `SmartMail_Debug` and wired it into a dedicated, scrollable `SmartMailDebugFrame`. Safely auto-initializes `SmartMailLog` globals on demand.
- **Save State Separation**: Migrated profile storage to a dual-state system. The UI now reads strictly from an isolated, character-specific `SmartMailDB_PerChar` table, while all changes are simultaneously mirrored to the global `SmartMailDB` Account-wide table as a backup.
- **Profile Editor UI**: Built the `SmartMailProfileEditorFrame` XML popup. Hooked it into `Bridge:GetCategoryNames()` to dynamically generate the 13 category checkboxes. 
- **Load Global Feature**: Added a "Load Global" button to the main window (`SmartMail_LoadGlobalProfiles`) that allows new characters to clone the global Account-wide profiles into their empty personal database.

**Checklist for Next Session:**
- [ ] Connect the dynamic checkboxes in the Profile Editor to actually reflect the saved state when editing an *existing* profile.
- [ ] Build the `Queue.lua` engine to loop through the character's inventory, compare it against the active profiles, and physically send the mail.
- [ ] Implement the `SmartMailConfirmFrame` to display the items about to be mailed and allow individual item removal before sending.
