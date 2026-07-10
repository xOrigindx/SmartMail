# Next Agent Instructions
When you start the next session, you MUST immediately read:
1. `.agents/MEMORY.md` (this file)
2. `.agents/SESSIONSUMMARY.md` (to get up to speed on the current state)

*Note: Do NOT read `API_MANUAL.md` locally anymore. It is now handled globally via Antigravity Skills.*

**CRITICAL INSTRUCTION**: Behavioral alignment is complete. The focus of this session is Phase 3:
1. Address the failed Profile Editor overhaul. Redesign `SmartMailProfileEditorFrame` properly based on user requirements.

# Behavioral Memory
- **The `/rl` Ban (STRICTLY ENFORCED)**: Do NOT tell the user to type `/rl`, `/reload`, "refresh", or "test it". Do not tell the user to test your changes. We are developing the AddOn together, so it is obvious that they will automatically test, reload, or restart the UI as needed. Never mention it.
- **STRICTLY ENFORCED**: Do NOT push any code to GitHub (`git push`) unless the user explicitly asks for it. Always keep commits local unless instructed otherwise.
- **DEBUGGING**: Always include `SmartMail_Debug()` statements for all new logic.
- **UI Style**: Symmetrical buttons, main frame close via `ESC`, child frames LIFO close, unselect profile on background click.
- **Memory Persistence**: Ensure `MAX` text values vs numeric values are distinctly respected across sessions.
- **SCREENSHOTS (CRITICAL)**: When the user types `chk-img-xx` (e.g., `chk-img-01`), you MUST ONLY use `view_file` to open `C:\World of Warcraft - 1.12.1 - Microbot\Screenshots\img_xx.jpg`. NEVER attempt to run python scripts to convert images. NEVER look in `.tempmediaStorage` or wait for artifacts unless explicitly instructed.
- **USER COMMUNICATION**: The user uses CAPITAL letters to indicate IMPORTANT information. When reading user requests, treat any fully capitalized words as critical priority details that dictate exact behavior.
- **ARTIFACT PLANS (WORKFLOW)**: You MUST present an Artifact Plan before modifying code for a new feature or fix. The artifact must use `RequestFeedback`. Wait for the user to approve the plan. Once approved, you MUST execute the file edits automatically without asking for further permission.
- **MODEL ROUTING**: Gemini Pro is the orchestrator. Sonnet 4.6 and Opus 4.6 are explicitly reserved for token burns on Mondays or when deep reasoning is needed (prioritizing Sonnet 4.6 for coding sweeps). On Mondays, you MUST ask the user how much Sonnet/Opus 4.6 usage they have left (since it resets on Wednesday) to ensure efficient token burning.
- **GIT PUSH COMMANDS**: The project uses two repositories. 
  - When the user says "push", push ONLY to the dev repo (`origin`).
  - When the user says "push public", push ONLY to the public repo (`public`).
  - When the user says "push push public", push to BOTH.
