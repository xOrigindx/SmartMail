# Next Agent Instructions
When you start the next session, you MUST immediately read:
1. `.agents/MEMORY.md` (this file)
2. `.agents/SESSIONSUMMARY.md` (to get up to speed on the current state)

Do not read the rest of the `.md` files in `.agents/` unless specifically directed to do so.

# Behavioral Memory
- Do not type `/rl` for the user.
- Always include `SmartMail_Debug()` statements for all new logic.
- UI Style: Symmetrical buttons, main frame close via `ESC`, child frames LIFO close, unselect profile on background click.
- Memory Persistence: Ensure `MAX` text values vs numeric values are distinctly respected across sessions.
