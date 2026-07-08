# Session Summary

## Major Changes
- **API Documentation & Global Skills**: Parsed 99 UI definitions and 85 Engine APIs into `API_MANUAL.md`. Converted it into a global Antigravity Skill (`wow_vanilla_api.md`).
- **UI Template Overhaul**: Standardized major UI frames to inherit from `SmartMailDialogTemplate` in XML, eliminating massive layout boilerplate.
- **Dynamic List Refactor**: Created `SmartMail_CreateListRow()` API factory to dynamically instantiate `SmartMailListRowTemplate` for the Profile Editor and Debug Log. Injected this into `SmartMail.Lua`.
- **Debug Log Streaming**: Refactored `SmartMailCopyFrame` to use a `copyQueue` coroutine system.
- **SendDelay Fix**: Purged `SendDelay = 0.0` from `SmartMail.Lua` so it defaults strictly to `0.15` in `Engine.lua`.
- **Global Rules & Protocols**: Finalized the `model_routing` rule. Gemini Pro is the orchestrator. Claude Opus/Sonnet is explicitly reserved for token burns on Mondays or when deep reasoning is needed. `MEMORY.md` was thoroughly cleaned of all outdated rules, and the strict `view_file` screenshot protocol was permanently hardcoded.

## Next Session Checklist
- [ ] **Bug Fix**: Fix the bug that occurs when opening `/sm` before starting any new UI work.
- [ ] **Phase 3 (Profile Editor Redesign)**: Redesign the `SmartMailProfileEditorFrame` using the new `SmartMailDialogTemplate` standard. The previous 2-column layout failed, so work with the user to determine the optimal layout.
