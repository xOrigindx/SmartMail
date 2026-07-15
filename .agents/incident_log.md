# Agent Behavior TODO

This document tracks behavioral improvements, communication rules, and permission protocols that need to be established or refined for agents. We will log items here as we discuss them during the session to properly overhaul the agent rules later.

## Pending Rule Updates:
- **Incident Log 8**:
  - **What Happened**: The agent prematurely presented an Artifact Plan for the Profile Editor overhaul during the "Start Session" brainstorm phase, without getting explicit user approval to conclude the brainstorm and select that specific task.
  - **Why It Happened**: The user instructed the agent to skip the README update and "continue with the workflowupdate." The agent falsely assumed this meant "move immediately to the next checklist item (the Profile Editor) and present a plan for it." The agent failed to ask for explicit confirmation to conclude the brainstorm and select the Profile Editor task, violating the strict "Start Session" rule that requires explicit user approval to end the brainstorm before any planning or coding begins.
