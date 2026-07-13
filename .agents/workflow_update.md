# Workflow Updates

This document tracks the tasks and features we complete during this session. At the end of the session, we will use this log to properly update the main `README.md` file.

## Completed Tasks:
- **Engine/Addon Conflict Fixed**: Removed intrusive tab switching and implemented a bulletproof universal bypass in `Engine.lua` that saves pure C-functions (`PickupContainerItem`, `ClickSendMailItemButton`) at load time. This makes SmartMail immune to hooks from addons like Postal, Mail, and TurtleMail.
- **UI Expansion Layout**: Removed obsolete backdrops from frames to make the UI look cleaner when expanded. Re-anchored bottom buttons (Options, Log) to absolute bottom-left offsets to prevent shifting during frame expansion.
- **Side Tabs System**: Removed the Custom Send bottom button and replaced it with a vertical side tab. Refactored the tab creation into a generic `SmartMailUI_CreateSideTab(tabName, text)` function.
- **Frame Layering**: Reparented `SmartMailCustomSendFrame` to `SmartMailMainFrame` instead of `UIParent` to solve dragging and strata/layering overlap issues, ensuring it always draws correctly on top of the expanded main frame.
- **Options Checkbox Refactor**: Fixed the "Disable Custom Send" checkbox logic, which broke when we deleted the bottom button. Abstracted the hide/show tab behavior into a reusable `SmartMailUI_DisableSideBarTab` function.
- **Generic List UI**: Created a powerful `SmartMailUI_CreateScrollList` function in `UI.lua` to eliminate redundant UI boilerplate when creating new scrolling lists in the future.

## README Updates (User-Facing Changes)
*Rule: This section must always contain professional, non-technical summaries of new features and bug fixes, formatted perfectly for direct copy-pasting into the README. Avoid casual phrasing.*

**Bug Fixes & Improvements:**
- Resolved a critical addon conflict. SmartMail is now fully compatible with and immune to hooks from other mail addons (e.g., Postal, Mail, TurtleMail).
- Redesigned the UI expansion layout for a cleaner and more stable interface.
- Migrated the Custom Send feature to a dedicated vertical Side Tab, optimizing space in the bottom row.
- Fixed a visual layering bug that caused the Custom Send frame to render behind the main window during dragging.
- The Custom Send feature can now be completely disabled via the Options menu.
