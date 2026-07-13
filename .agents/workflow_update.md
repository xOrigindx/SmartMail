# Workflow Updates

This document tracks the tasks and features we complete during this session. At the end of the session, we will use this log to properly update the main `README.md` file.

## Completed Tasks:
- **Engine/Addon Conflict Fixed**: Removed intrusive tab switching and implemented a bulletproof universal bypass in `Engine.lua` that saves pure C-functions (`PickupContainerItem`, `ClickSendMailItemButton`) at load time. This makes SmartMail immune to hooks from addons like Postal, Mail, and TurtleMail.
