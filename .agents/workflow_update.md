# Workflow Updates (v1.0.4)

This document tracks the tasks and features we complete during this session. At the end of the session, we will use this log to properly update the main `README.md` file.

## Completed Tasks:
- **Custom Send Scroll List Bugfix**: Fixed name mismatches of scroll children in `Custom.lua` to align with the dynamically created lists in `UI.lua`, resolving the issue where the Custom List, Saved Recipients, and Cart were not populating.
- **Profile Editor Overhaul**: Rewrote `SmartMailProfileEditorFrame` to replace the dual-list interface (Available/Active) with a single, streamlined checklist layout using checkboxes, improving user experience and simplifying the underlying logic.
- **SendMail API Fix**: Fixed an issue in `Engine.lua` where the C API `SendMail` would throw a Usage error because it was receiving an empty string for the body instead of a valid character.
- **Confirm Send Target Bugfix**: Fixed a critical bug where clicking Send from the Confirm Frame would prematurely clear the selected profile due to a frame hide hook, resulting in the Engine failing to send due to a `nil` target.
- **Default Custom Tab**: Added a hook to `SmartMailMainFrame.Show` so that opening the mailbox or typing `/sm` automatically defaults to opening the Custom tab, expanding the main frame, and respecting the `disableCustom` user setting.
- **Keep UI Open on Send**: Removed the aggressive closing logic in `Custom.lua` and `SmartMail.Lua` so that the addon windows stay visible while mail is being processed, allowing the user to observe the progress.
- **Auto-Reset Position**: Added logic to `SmartMailMainFrame.Show` to clear any manual dragging anchors and force the main frame to reset to a strict absolute screen position (matching the exact preferred layout next to the mailbox) whenever it opens, preventing overlapping bugs.
- **Recipient Selection Popup**: Updated `SmartMailCustom:Send` and `UI.lua` to dynamically generate and display a dialog list of saved profiles if the user attempts to send without selecting a recipient. Clicking a profile locks it in and immediately resumes the send process.

## README Updates (User-Facing Changes)
*Rule: This section must always contain professional, non-technical summaries of new features and bug fixes, formatted perfectly for direct copy-pasting into the README. Avoid casual phrasing.*

### v1.0.4
**New Features & UI Updates:**
- Completely overhauled the Profile Editor UI to use a streamlined, single-list checkbox interface for easier category management.
- The "Custom" tab now opens automatically by default when opening the mailbox or using the `/sm` command, saving you an extra click.
- The main window and custom tabs no longer close automatically when you click Send, allowing you to easily send multiple batches without reopening the addon.
- The SmartMail window now permanently locks its position to sit perfectly on the screen every time it is opened, ensuring it never overlaps other standard UI windows.
- Added a smart Recipient Selection Popup! If you click Send without selecting a target, the addon will now pop up a list of your saved profiles. You can click a profile to highlight it, and then click the new Send button to instantly confirm and continue sending.
- **Persistent Cart Memory**: The Custom Send Cart now remembers what you added to it! If you close the addon to visit the bank or auction house, your cart will perfectly restore itself when you return (automatically adjusting for any items you deposited). The cart now only clears itself when you manually click "Clear" or after a mail is successfully sent!
- **Strict Target Wiping**: When you successfully send mail using the Custom Send tab, your selected recipient is now forcefully wiped from the system and the UI highlight is cleared. This guarantees you will always be caught by the new Recipient Selection Popup if you queue up another batch and hit Send without explicitly clicking a new target.

**Bug Fixes & Improvements:**
- Fixed a bug where the Custom Send lists (Custom List, Saved Recipients, and Cart) failed to populate.
- Resolved a critical issue that prevented mail from being sent correctly from the confirmation window, which previously triggered a client error.
- Fixed an internal engine bug where the mailing system would sometimes fail to send mail due to empty message bodies.
- Fixed a vanilla Lua compatibility bug that prevented the new Recipient Selection Popup from anchoring correctly to the center of the screen.
- Fixed the Recipient Selection Popup so it correctly pulls from your character's "Saved Recipients" list rather than the global profile list, and fixed a scoping bug that prevented the Send button from working after selecting a name.
- Fixed a bug in the new Persistent Cart Memory where an incorrect variable name (`item.name` instead of `item.itemName`) caused the cart to improperly stack restored items onto the first item in the inventory list upon reopening the frame.
