# Session Summary

## Major Changes

### 1. Configuration & Delays
- **Exposed Variables**: `SendDelay` (0.15s) and `OpenDelay` (0.50s) are now explicitly exposed at the top of the `SmartMail` global table in `SmartMail.Lua`.
- **Debug Toggle**: Moved `debug` directly into the configurable section at the top of `SmartMail.Lua` so the user can easily toggle chat debug messages without modifying logic further down.

### 2. Git Workflow Refinement
- **Branch-based Release Strategy**: Abandoned swapping `.gitignore` files manually. Adopted a clean branch-based deployment strategy where a permanent `public-release` branch tracks the public remote and uses `public_repo.gitignore`, keeping `main` dedicated purely to dev.
- **Documentation**: Bumped version to `1.0.1` and migrated the changelog to the top of `README.md`.

### 3. Custom Frame Overhaul (`Custom.lua`)
- **Main List Interaction**: Implemented fast, no-popup inventory management shortcuts directly in the main Custom list:
  - `Ctrl+Left-Click` adds MAX stack/all.
  - `Ctrl+Right-Click` removes MAX stack/all.
- **Shopping Cart Interaction**: Rebuilt the cart (queued list) to completely ignore Left-Clicks (preventing accidental removals). Fully implemented Right-Click methodology:
  - `Right-Click` removes 1.
  - `Shift+Right-Click` prompts specific amount dialog.
  - `Ctrl+Right-Click` removes all.
- **Money UI Center Layout**: Shifted the `moneyInput` gold/silver/copper fields to sit perfectly centered under the list. Moved the `Add` button closer, and added a dedicated `Clear` button specifically for gold management.

### 4. Bridge Fix
- **Global `SmartMailDB` Link**: Fixed the inventory scan queueing logic to properly read category groupings from the global database configuration.

## Next Session Checklist
- [ ] **SmartMailProfileEditorFrame Redesign**: Overhaul the Profile Editor visual frame.
- [ ] **Multiple Category Assignment**: Overhaul the database structure to allow the exact same category to be assigned to multiple profiles.
- [ ] **Per-Character Profiles**: Rework the `SavedVariables` structure from Global account-wide arrays to character-specific arrays (or integrate character detection) to support bank alts on different characters.

## Next Session Instructions
When starting the next session, read ONLY:
1. `.agents/MEMORY.md`
2. `.agents/SESSIONSUMMARY.md`
