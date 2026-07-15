# Workflow Updates (v1.0.5)

This document tracks the tasks and features we complete during this session. At the end of the session, we will use this log to properly update the main `README.md` file.

## Completed Tasks:

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
