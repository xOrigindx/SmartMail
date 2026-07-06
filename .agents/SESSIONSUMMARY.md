# Session Summary

## Major Changes
- **Memory/State Persistence**: Overhauled item setting saves ("MAX" string instead of static integer scaling up/down). `Queue.lua` seamlessly resolves "MAX" to current bags' `fullStacks`/`partialStacks`.
- **UI & Flow Adjustments**: Removed redundant "Delete" button from Profile Editor; correctly aligned Save/Cancel. Ensured `SmartMailDebugFrame` scroll position dynamically snaps to the top on load (latest logs first).
- **PeriodicTable Routing**: Split out generic `ingredcloth` / `ingredbar` tables to natively support granular sub-categories (`Arcanite Bar`, `Arcane Crystal`, `Mooncloth`, `Felcloth`) by mapping to explicit IDs, allowing high-value materials to route differently. Added `Element` (via `ingredelement`).
- **Send All Feature**: Built an engine sequence manager (`SmartMail.sendAllProfilesQueue`) that iterates through all profiles, dynamically generates a `flatQueue` for each (respecting skipped partials/MAX configurations), and chains them to `Engine.lua` seamlessly.
- **Dynamic Hot-Swapping**: Permitted immediate swapping between different character profiles in the main UI list while `SmartMailConfirmFrame` is open to see different character previews fluidly.

## Next Session Checklist
- [ ] Check `AGENTS.md` and `MEMORY.md` immediately upon starting.
- [ ] Investigate recipient validation logic ("the first time ever you send to a recipient it should either send a empty mail to check if the recipient exist... or we make a popup windows").
- [ ] Final stress testing of `Send All` queue chaining if any engine stutters occur.
