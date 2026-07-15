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
11. **Excluding Mail Folder:** Added the `Mail/` folder to `public_repo.gitignore` and to the public push untracking list in `AGENTS.md` to ensure it is kept locally but never pushed to the public repository.
12. **Deleted Local Mail Folder:** The user deleted the redundant `Mail/` folder from the workspace root, as it is already backed up in `Docs/Mail/`.
13. **Cleaned Gitignore and Push Rules:** Removed references to `Mail/` from `public_repo.gitignore` and the `AGENTS.md` public release rules after the local folder was deleted.
14. **Simplified Public Push (Rename Workflow):** Removed the development `.gitignore` file and updated the public push rules to rename `public_repo.gitignore` to `.gitignore` on the temporary branch, eliminating the need to restore `.gitignore` when switching branches.
15. **Granular Public Push commits:** Updated the public release workflow to commit stamped files in historical version groups, ensuring GitHub displays correct version and description commit messages for each file.
16. **Staging public_repo.gitignore checkout:** Added a restoration step for `public_repo.gitignore` to the public push rules to ensure it is checked out from `main` after branch switching.
17. **File Cleanup Rule:** When the README is updated using the contents of `workflow_update.md`, the agent must erase the completed contents from `workflow_update.md`. The same rule applies to `incident_log.md` when rules are resolved and moved to `AGENTS.md`.
18. **Fast-Track Bug Fix Exemption:** Added a rule exemption stating that if a user reports a bug during the testing phase of an approved feature, the agent no longer needs to generate an Artifact Plan and should execute the fix immediately after explaining it.
