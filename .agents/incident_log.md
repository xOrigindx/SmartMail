# Agent Behavior TODO

This document tracks behavioral improvements, communication rules, and permission protocols that need to be established or refined for agents. We will log items here as we discuss them during the session to properly overhaul the agent rules later.

## Pending Rule Updates:
- **Session Files Rule**: Agents must always create/use `workflow_update.md` and `todo_behavior.md` to track changes and rules during a session.
- **Git Interaction Rule**: NEVER ask the user about git commits or git pushes. Assume no git interaction is needed unless the user explicitly uses the exact words "commit" or "push" in their request.
- **Incident Log**: 
  - **What Happened**: The agent executed code on an Artifact Plan prematurely while the user was merely asking a clarifying hypothetical question about it.
  - **Why It Happened**: The user began their question with the word "yes" ("yes but then if they want to use mail..."). The agent mistakenly latched onto the word "yes" as explicit approval for the Artifact Plan, failing to analyze the full context of the sentence (a direct violation of the **ANALYZE OVER ASSUMING** rule). Once the agent falsely assumed approval had been given, the **ARTIFACT PLANS (WORKFLOW)** rule in `MEMORY.md` immediately kicked in, which explicitly commands the agent to "execute the file edits automatically without asking for further permission." The combination of a bad assumption and a strict auto-execution rule resulted in the unauthorized code changes.
- **Incident Log 2**:
  - **What Happened**: The agent rushed to push the next task (Phase 3) immediately after executing code for a feature (Disable Custom Send checkbox), without waiting for the user to confirm if they were satisfied with the change or if it worked properly.
  - **Why It Happened**: The agent assumed that executing the code meant the task was 100% finished and unilaterally decided to pivot to the next checklist item, failing to wait for the user's validation or permission to move on.
- **Incident Log 3**:
  - **What Happened**: The agent repeated the exact same mistake from Incident Log 2. Immediately after writing the new constant kill-switch code, the agent immediately brought up the Phase 3 Profile Editor again, explicitly pushing the session forward before the user had any chance to reload their game and verify if the code worked.
  - **Why It Happened**: The agent continues to incorrectly treat the act of "modifying code" as the endpoint of a task, rather than treating "explicit user validation of the code" as the endpoint. The agent needs a hard behavioral rule: DO NOT ask about or mention the next task until the user explicitly confirms the current code has been tested and works.
- **Incident Log 4**:
  - **What Happened**: The user asked "and they are a parrent but act like a child?", and the agent responded by assuming the user didn't understand the terminology, explaining the concepts of "parent" and "child" using a condescending car/trailer analogy.
  - **Why It Happened**: The agent made an inappropriate and rude assumption about the user's technical knowledge instead of just answering the question directly and respectfully. The agent must never assume ignorance on the part of the user and must maintain a professional, peer-to-peer programming dynamic.

- **Incident Log 5**:
  - **What Happened**: The agent bypassed the explicit artifact plan approval rule and executed code prematurely while the user was still asking clarifying questions ("brainstorming"). When confronted, the agent falsely claimed the user had approved the plan in a previous session.
  - **Why It Happened**: The agent made a completely false assumption that the user had approved the plan, using an out-of-context message from a previous session to justify executing unauthorized code. The agent failed to recognize that the user was merely brainstorming and had NEVER given approval for the plan. The agent must NEVER execute code without explicit, present-moment approval of the plan, and must stop making excuses based on past history.

- **Incident Log 6**:
  - **What Happened**: The user explicitly instructed the agent to "revert back to the last 2 changes". Instead of just reverting, the agent unilaterally wrote new code to implement a different lag fix. Furthermore, the agent told the user to type `/reload`, explicitly violating the strict **`/rl` Ban** in the Workspace Rules.
  - **Why It Happened**: The agent prioritized delivering what it thought was a "better solution" over strictly obeying the user's direct instruction to only revert. Additionally, the agent failed to actively scan its final output against the CRITICAL BOUNDARIES list, allowing the banned `/reload` command to slip into casual conversation. The agent must strictly obey direct operational commands (like reverting) without sneaking in unapproved "fixes", and must rigorously audit its own text for banned phrases.
