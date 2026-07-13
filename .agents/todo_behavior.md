# Behavior and Rule Trackers - Session 2026-07-13

This document tracks behavioral changes, rule additions, and adjustments made during this session.

## Resolved Behaviors & Rule Integrations:
1. **Consolidation of Rules:** Merged `.agents/MEMORY.md` and `AGENTS.md` into the root [`AGENTS.md`](file:///C:/World%20of%20Warcraft%20-%201.12.1%20-%20Microbot/Interface/AddOns/SmartMail/AGENTS.md) to ensure all workspace rules are loaded automatically at the start of every session.
2. **Git Interaction Restriction:** Enforced the **Git Interaction Rule** to prevent the agent from asking about Git pushes/commits. We will assume no Git interaction is needed unless you explicitly command it.
3. **Session Files Tracking:** Enforced the **Session Files Rule** requiring the use of `workflow_update.md` and `todo_behavior.md` (this file) to record behavioral notes and changes.
4. **Tool & Script Discipline:** Refined the script rule to restrict Python executions to only the screenshot watcher script (`Scripts/screenshot_watcher.py`) at the start of a session, under explicit command.
5. **Git Remote Names:** Renamed the private development remote from `origin` to `developpement` to eliminate naming mismatches.
6. **Git Protocol Exemption:** Added a protocol exemption clarifying that the Git commands needed for the commanded Git push protocol (Section 2) are permitted when executing a commanded push.
7. **Incident Log Exemption:** Added an exemption clarifying that logging incidents in `incident_log.md` does not require presenting an Artifact Plan or obtaining approval.
8. **Temporary Branch Public Push:** Adopted a temporary branch workflow (`temp-public-release`) for public pushes to completely eliminate merge conflicts and keep private development files off the public repository.
9. **Refined Public Push Parameters:** Updated the public push rules to include `Scripts/` and `TODO_STRESS.lua` in the file strip list, and mandated generic version-based release commits (e.g. "Release v[Version]").
10. **GitHub Version Stamping:** Mandated appending version comments to all release files on the temporary release branch before pushing, ensuring that every file displays the release version and description as its latest commit on GitHub.
