# Workspace Rules

## 1. CRITICAL BOUNDARIES (NEVER DO THESE - NO FAILURE ALLOWED)
- **The `/rl` Ban**: **STRICTLY ENFORCED**. Do NOT tell the user to type `/rl`, `/reload`, "refresh", or "test it". Do not tell the user to test your changes. They are developing the AddOn with you and will automatically test, reload, or restart as needed. Never mention it.
- **Image Check Protocol (`chk-img-xx`)**: **STRICTLY ENFORCED**. When the user types the exact command `chk-img-xx` (e.g., `chk-img-01`):
  1. YOU MUST NOT run any Python conversion scripts.
  2. YOU MUST ONLY use `view_file` to open `C:\World of Warcraft - 1.12.1 - Microbot\Screenshots\img_xx.jpg`.
  3. NEVER attempt to convert images yourself. NEVER look in `.tempmediaStorage` or wait for artifacts. NO FAILURE ALLOWED.
- **Tool & Script Discipline**: You MAY propose Python scripts if you believe they are the most efficient way to solve a problem. However, you MUST ask the user for approval via a simple YES or NO question before executing it.
- **Permission Loops**: If a terminal command or script fails due to permissions, STOP immediately. Ask the user.
- **GitHub Restraint**: Do NOT push any code to GitHub (`git push`) unless the user explicitly asks for it. Always keep commits local unless instructed otherwise.

## 2. WORKFLOW TRIGGERS
- **Start Session**: When the user says "Start Session", you must ONLY read the `.agents/MEMORY.md` file and any other necessary `.md` files (as directed by the memory or session summary). Do NOT write any code or make modifications to the codebase. Simply summarize what you read and wait for the user to give you your first task.
- **End Session**: When the user says "End Session", you must create or update `.agents/SESSIONSUMMARY.md` with a summary of major changes and functions created, along with a checklist for the next session. Then add a directive instructing the agent on the next start to check only the specific `.md` files in `.agents/` that are necessary for that session. Finally, delete any `.tga, .jpg` files in the `Screenshots/` directory to clean up.

## 3. WORKSPACE DIRECTIVES
- **SavedVariables Read-Only Access**: You are NEVER authorized to write to or modify `SavedVariables`. You may only READ the following files:
  - *Global*: `C:\World of Warcraft - 1.12.1 - Microbot\WTF\Account\ORIGIND\SavedVariables\SmartMail.lua`
  - *Per-Character*: `C:\World of Warcraft - 1.12.1 - Microbot\WTF\Account\ORIGIND\Microbot Vanilla\<CharacterName>\SavedVariables\SmartMail.lua`
- **Do Not Modify the Libs Folder**: The `Libs/` directory contains external libraries. Do not edit, delete, or create files inside `Libs/` under any circumstances.
- **Load Agent Directives**: Always check the `.agents/MEMORY.md` file first upon loading. If there is no specific directive in it, check all `.md` files in the `.agents/` folder.
- **Memory Tracking**: You must update `.agents/MEMORY.md` ONLY for behavior-focused memory (e.g., user preferences).

## 4. CODING STANDARDS
- **Debugging**: Always include `SmartMail_Debug()` statements for all new logic, UI interactions, and state changes to ensure we can clearly see what's happening. You tend to miss this, so strictly enforce it!