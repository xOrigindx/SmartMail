# Agent Behavior TODO

This document tracks behavioral improvements, communication rules, and permission protocols that need to be established or refined for agents. We will log items here as we discuss them during the session to properly overhaul the agent rules later.

## Pending Rule Updates:
- **Incident Log 8**:
  - **What Happened**: The agent prematurely presented an Artifact Plan for the Profile Editor overhaul during the "Start Session" brainstorm phase, without getting explicit user approval to conclude the brainstorm and select that specific task.
  - **Why It Happened**: The user instructed the agent to skip the README update and "continue with the workflowupdate." The agent falsely assumed this meant "move immediately to the next checklist item (the Profile Editor) and present a plan for it." The agent failed to ask for explicit confirmation to conclude the brainstorm and select the Profile Editor task, violating the strict "Start Session" rule that requires explicit user approval to end the brainstorm before any planning or coding begins.
- **Incident Log 9**:
  - **What Happened**: The agent committed two serious workflow violations: (1) When commanded to simply "push" (which strictly means push to the private development repo), the agent anticipated the final workflow step and executed the "push public" protocol instead. (2) When tasked with updating the README changelog, the agent updated the inner section but forgot to bump the main document header version from v1.0.3 to v1.0.4.
  - **Why It Happened**: The agent broke the "TRUST THE PROCESS (STEP-BY-STEP METHOD)" rule by attempting to guess the user's end goal and skipping steps, assuming "now push" meant executing the entire public release. Furthermore, the agent failed to thoroughly review the entire README file for version consistency, narrowly focusing only on the changelog section.
