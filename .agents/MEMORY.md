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
- Screenshots: When the user says "check image" or "check last image", it ALWAYS refers to the newest `.tga` file in `C:\World of Warcraft - 1.12.1 - Microbot\Screenshots\`. You MUST immediately run a Python script via `run_command` to convert that newest `.tga` file to `.jpg`, DELETE the original `.tga` file, and then use `view_file` on the resulting `.jpg` to inspect it.
- STRICTLY ENFORCED: Do NOT push any code to GitHub (`git push`) unless the user explicitly asks for it. Always keep commits local unless instructed otherwise.
- USER COMMUNICATION: The user uses CAPITAL letters to indicate IMPORTANT information. When reading user requests, treat any fully capitalized words as critical priority details that dictate exact behavior.
