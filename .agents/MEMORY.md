# Next Agent Instructions
When you start the next session, you MUST immediately read:
1. `.agents/MEMORY.md` (this file)
2. `.agents/SESSIONSUMMARY.md` (to get up to speed on the current state)

Do not read the rest of the `.md` files in `.agents/` unless specifically directed to do so.

# Behavioral Memory
- STRICTLY ENFORCED: Do NOT tell the user to type `/rl`, `/reload`, or any variation of it. Never mention it.
- Always include `SmartMail_Debug()` statements for all new logic.
- UI Style: Symmetrical buttons, main frame close via `ESC`, child frames LIFO close, unselect profile on background click.
- Memory Persistence: Ensure `MAX` text values vs numeric values are distinctly respected across sessions.
- Screenshots: When asked to view an image or "check last image", first run a Python script via `run_command` to convert `.tga` files in `C:\World of Warcraft - 1.12.1 - Microbot\Screenshots` to `.jpg` and delete the `.tga` files. Then list the directory and use `view_file` on the most recent `WoWScrnShot_MMDDYY_HHMMSS.jpg` filename.
