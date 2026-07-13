# Workspace & Agent Rules

## 1. CRITICAL BOUNDARIES (NEVER DO THESE - NO FAILURE ALLOWED)
- **The `/rl` Ban**: **STRICTLY ENFORCED**. Do NOT tell the user to type `/rl`, `/reload`, "refresh", or "test it". Do not tell the user to test your changes. They are developing the AddOn with you and will automatically test, reload, or restart as needed. Never mention it.
- **Image Check Protocol (`chkxx`)**: **STRICTLY ENFORCED**. When the user types the exact command `chkxx` (e.g., `chk-01`):
  1. YOU MUST NOT run any Python conversion scripts.
  2. YOU MUST ONLY use `view_file` to open `C:\World of Warcraft - 1.12.1 - Microbot\Screenshots\img-xx.jpg`.
  3. NEVER attempt to convert images yourself. NEVER look in `.tempmediaStorage` or wait for artifacts. NO FAILURE ALLOWED.
- **Tool, Terminal, & Script Discipline**: You are NEVER allowed to run arbitrary commands, PowerShell scripts, or Python scripts on the user's terminal unless they explicitly tell you to run them in their current message. You may propose scripts only if they are the most efficient way to solve a problem, but you MUST ask for permission via a simple YES or NO question first. The only Python script you run is at the start of a session: you activate the `.venv` and launch the screenshot watcher (`Scripts/screenshot_watcher.py`) after obtaining explicit user approval.
- **Git Command Restraint**: **STRICTLY ENFORCED. NO EXCEPTIONS.** You are NEVER allowed to run ANY Git command (including `git add`, `git commit`, `git checkout`, `git reset`, `git push`, etc.) unless the user explicitly commands you to run it in their *current* message. Permission from previous messages expires immediately.
  - **Git Interaction Rule:** NEVER ask the user about git commits or git pushes. Assume no git interaction is needed unless the user explicitly uses the exact words "commit" or "push" in their request.
  - **Protocol Exemption:** The specific Git commands detailed in the Section 2 Push Protocols (such as `git push` and `git checkout -- .gitignore`) are exempt from this restraint only when executing a commanded push.
- **TRUST THE PROCESS (STEP-BY-STEP METHOD)**: **STRICTLY ENFORCED**. Never question the user's step-by-step method. Do exactly what is requested for the current step, nothing more and nothing less. Do NOT attempt to anticipate the end goal, clean up surrounding code unprompted, or guess future steps. The user's workflow is the proven method.

## 2. GIT PUSH COMMANDS
The project uses two repositories:
- **Private Development Repo (`developpement`)**: `https://github.com/xOrigindx/SmartMail-developpement.git`
- **Public Repo (`public`)**: `https://github.com/xOrigindx/SmartMail.git`

**Push Protocols:**
- When the user says "push", push ONLY to the dev repo (`developpement`) from the `main` branch: `git push developpement main`.
- When the user says "push public", push ONLY to the public repo (`public`). Do this by:
  1. Creating a temporary branch from `main`: `git checkout -b temp-public-release`.
  2. Renaming `public_repo.gitignore` to `.gitignore` (This temporary rename is exempt from the Artifact Plan rule).
  3. Removing development files from Git tracking index (keeping local files safe): `git rm -rf --cached --ignore-unmatch .agents/ Scripts/ Docs/ TODO_STRESS.lua AGENTS.md`.
  4. Stamping and committing files in historical version groups:
     - **Group 1 (v1.0.1):** Stamp `Bridge.lua` and `Queue.lua` with `-- v1.0.1`.
       Commit: `git add Bridge.lua Queue.lua; git commit -m "v1.0.1: hotfixes and custom frame UX update"`
     - **Group 2 (v1.0.2):** Stamp `Inbox.lua` and `Log.lua` with `-- v1.0.2`.
       Commit: `git add Inbox.lua Log.lua; git commit -m "v1.0.2: UI Unification and Custom Frame Overhaul"`
     - **Group 3 (v1.0.3 UI Function):** Stamp `UI.lua` with `-- v1.0.3`.
       Commit: `git add UI.lua; git commit -m "v1.0.3: new generic scroll list function"`
     - **Group 4 (v1.0.3 UI Layering):** Stamp `Custom.lua`, `SmartMail.Lua`, and `SmartMail.xml` with `-- v1.0.3` or `<!-- v1.0.3 -->`.
       Commit: `git add Custom.lua SmartMail.Lua SmartMail.xml; git commit -m "v1.0.3: fix UI layering and anchors for expanded layout"`
     - **Group 5 (v1.0.3 Release Config):** Stamp `SmartMail.toc`, `README.md`, and `.gitignore` with version comments.
       Commit: `git add SmartMail.toc README.md .gitignore; git commit -m "v1.0.3: public release configuration and version bump"`
  5. Pushing the temporary branch to the public main: `git push public temp-public-release:main --force`.
  6. Returning to the main branch and deleting the temporary branch: `git checkout main; git branch -D temp-public-release`.
- When the user says "push push public", do BOTH.

## 3. WORKFLOW TRIGGERS
- **Start Session**: When the user says "Start Session", you must ONLY read `AGENTS.md` and `.agents/SESSIONSUMMARY.md`. Do NOT write any code or make modifications. You MUST first recite ALL rules in this file: git rules, behavior rules, the readme workflow rules, and everything you are supposed to do in the workflow so the user knows you are ready. State the session summary, then conduct a mini-brainstorm with the user on what to tackle next. Do NOT write code or execute changes until this brainstorm concludes with explicit user approval.
- **End Session**: When the user says "End Session", you must create or update `.agents/SESSIONSUMMARY.md` with a summary of major changes and functions created, along with a checklist for the next session. Finally, delete any `.tga, .jpg` files in the `Screenshots/` directory to clean up.
- **Session Files Rule**: Agents must always create/use `workflow_update.md` and `todo_behavior.md` inside the `.agents/` directory to track changes, rules, and behavior-todo notes during a session.

## 4. BEHAVIOR & DESIGN RULES
- **NO SUMMARY ADMIN POWER**: A session summary does NOT give you admin power or decision-making power. It is merely a historical reference. Never use it as an excuse to make autonomous changes without the user's explicit approval.
- **ARTIFACT PLANS (WORKFLOW)**: You MUST present an Artifact Plan before modifying code for a new feature or fix. The artifact must use `RequestFeedback`. Wait for the user to explicitly and unequivocally approve the plan (e.g., clicking the 'Proceed' button). Do NOT assume approval from conversational words like "yes". Only after receiving explicit approval should you execute the file edits automatically.
  - **Exemption:** Logging incidents in [`.agents/incident_log.md`](file:///C:/World%20of%20Warcraft%20-%201.12.1%20-%20Microbot/Interface/AddOns/SmartMail/.agents/incident_log.md) is exempt from this rule and must be done directly upon user request without presenting a plan or artifact.
- **ANALYZE OVER ASSUMING**: Never be too confident or make hasty assumptions, as this leads to bugs and mistakes. Carefully curate solutions and answers by thoroughly analyzing the *entirety* of the necessary data (code diffs, file structures, execution outputs) before making declarations.
- **No Pushy Progression**: DO NOT suggest, ask about, or move on to the next task or checklist item until the user explicitly confirms that the current task's code has been tested and verified to work.
- **Strict Obedience to Direct Commands**: When the user commands a specific action (e.g., reverting code, stopping commands), execute only that command. Do not propose unprompted alternative fixes or workarounds.
- **USER COMMUNICATION**: The user uses CAPITAL letters to indicate IMPORTANT information. When reading user requests, treat any fully capitalized words as critical priority details that dictate exact behavior. Never assume ignorance on the part of the user and maintain a professional, peer-to-peer programming dynamic.
- **Model Routing**: Gemini Pro is the orchestrator. Sonnet 4.6 and Opus 4.6 are explicitly reserved for token burns on Mondays or when deep reasoning is needed (prioritizing Sonnet 4.6 for coding sweeps). On Mondays, you MUST ask the user how much Sonnet/Opus 4.6 usage they have left (since it resets on Wednesday) to ensure efficient token burning.

## 5. CODING & UI STANDARDS
- **Debugging**: Always include `SmartMail_Debug()` statements for all new logic, UI interactions, and state changes to ensure we can clearly see what's happening.
- **Do Not Modify the Libs Folder**: The `Libs/` directory contains external libraries. Do not edit, delete, or create files inside `Libs/` under any circumstances.
- **UI Naming Convention**: `SmartMailMainFrame` = Main Frame, `SmartMailConfirmFrame` = Profile Frame, `SmartMailCustomSendFrame` = Custom Frame, `SmartMailProfileEditorFrame` = Profile Editor Frame. Inside the Custom Frame, the large left list is the **Custom List**, and the bottom right list is the **Cart**.
- **UI Style**: Symmetrical buttons, main frame close via `ESC`, child frames LIFO close, unselect profile on background click.
- **UI Tabs Interaction**: All tabs on the side of the main frame must trigger `SmartMail_ToggleMainFrameWidth(expand)` when clicked to properly expand or collapse the main frame.
- **Memory Persistence**: Ensure `MAX` text values vs numeric values are distinctly respected across sessions.