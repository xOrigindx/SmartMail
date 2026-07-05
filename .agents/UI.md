# UI.md — SmartMail UI Design Reference

All UI is built with vanilla WoW 1.12.1 XML + Lua. No Ace GUI library.

---

## XML vs Lua Split

| File | Responsibility |
|---|---|
| `SmartMail.xml` | Declares all frames, buttons, scroll frames, font strings, textures — the **structure** |
| `UI.lua` | Contains all logic, event handlers, and callbacks that reference frames by their global names — the **behaviour** |

In 1.12.1, the TOC loads both files. XML is processed first, then Lua. Lua handlers reference
frame globals that were created by the XML (e.g. `SmartMailMainFrame`, `SmartMailConfirmFrame`).
**No frames are created in Lua via `CreateFrame` if they can be declared in XML.**

---

## Frames Overview

| Frame Global Name | Purpose |
|---|---|
| `SmartMailMainFrame` | Main window — shown when mailbox opens |
| `SmartMailProfileEditorFrame` | New / Modify profile editor |
| `SmartMailConfirmFrame` | Send [Character] confirmation — user removes items before confirming |
| `SmartMailLogFrame` | Log viewer — shows session history |

---

## SmartMailMainFrame (Main Window)

Shown automatically when the player opens a mailbox.

### Buttons
| Button | Action |
|---|---|
| `New` | Opens `SmartMailProfileEditorFrame` in create mode |
| `Modify` | Opens `SmartMailProfileEditorFrame` in edit mode for the selected profile |
| `Send Amount` | Opens a small input dialog; user types a number of full stacks to send for the selected profile/session |
| `Send All` | Immediately builds queue for ALL profiles → executes send (no confirmation) |
| `Log` | Opens `SmartMailLogFrame` |

### Profile List
- Scrollable list of all saved profiles (destination character names).
- Clicking a character name selects it.
- A **Send [Character]** button (or double-click) triggers the confirmation flow for the selected profile.

### Status Area
- Shows current send status (e.g. "Sending 12/40 stacks...", "Idle", "Busy").
- Reflects `SmartMail.isBusy` state.
- All buttons except `Log` are disabled when `isBusy = true`.

---

## SmartMailProfileEditorFrame (Profile Editor)

Used for both creating new profiles and editing existing ones.

### Fields
- **Destination Character Name** — text input (free text, case-sensitive).
- **Category Checkboxes** — one checkbox per category (13 total), populated by `Bridge:GetCategoryNames()`.

### Buttons
| Button | Action |
|---|---|
| `Save` | Writes the profile to `SmartMailDB.profiles` and closes the editor |
| `Delete` | Removes the selected profile from `SmartMailDB` (only shown in edit mode) |
| `Cancel` | Closes without saving |

---

## SmartMailConfirmFrame (Confirmation UI)

Shown when the user clicks **Send [Character]** for a specific profile.

### Contents
- List of all items matched by the profile (itemName, stack count to be sent, destination character).
- Each row has a **Remove** button — clicking it removes that item from the pending send (it stays in bags).

### Buttons
| Button | Action |
|---|---|
| `Confirm & Send` | Builds queue from the (potentially reduced) list and starts send operation |
| `Cancel` | Closes the frame, nothing is sent |

---

## SmartMailLogFrame (Log Viewer)

Opened via the `Log` button on the main window.

### Display
- Sessions listed **newest first**.
- Each session shows: timestamp (`GetTime()` value), total sent, total failed, total skipped.
- Expandable (or scrollable) to show per-item failure and conflict entries.

### Buttons
| Button | Action |
|---|---|
| `Clear Log` | Wipes `SmartMailLog.sessions` for this character (with confirmation prompt) |
| `Close` | Closes the log frame |

---

## UI Behavior Rules

- **UI only appears when mailbox is open.** It is hidden on `MAIL_CLOSED`.
- **All buttons disabled during send** (`isBusy = true`), except `Log`.
- **Conflict items are not shown in the confirmation list** — they are already skipped before the list is built.
- **Send Amount input** is a per-session value. It is not saved to `SmartMailDB`. It resets when the mailbox closes.

---

## Current XML Frame Names (Generated Reference)

Based on the current `SmartMail.xml` skeleton, the following global names are actually defined:

### Main Window
- `SmartMailMainFrame`
- `SmartMailMainFrameCloseButton`
- `SmartMailMainFrameAddButton`
- `SmartMailMainFrameDeleteButton`
- `SmartMailMainFrameEditButton`
- `SmartMailMainFrameListFrame`
  - `SmartMailMainFrameListFrameScrollFrame`
  - `SmartMailMainFrameListFrameScrollChild`
- `SmartMailMainFrameSendAllButton`
- `SmartMailMainFrameSendSelectedButton`
- `SmartMailMainFrameOptionsButton`
- `SmartMailMainFrameLogButton`

### Log Window
- `SmartMailLogFrame`
- `SmartMailLogFrameContentFrame`
  - `SmartMailLogFrameContentFrameScrollFrame`
  - `SmartMailLogFrameContentFrameScrollChild`
- `SmartMailLogFrameCloseButton`
