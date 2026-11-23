# Shared rules for AI coding agents

`RULES.md` is the **only** copy of the rules every AI agent (Claude Code, Cursor, Codex) follows in
Celero repos: the git/PR process, testing, and the security rules learned from Oneleet checks and the
pentest. Agents load it fresh from this repo at the start of every session, so a change here applies
to every repo as soon as it is merged. No per-repo PRs.

## Change a rule
One PR to this repo editing `RULES.md`. Once merged, every new agent session in every repo uses it
(raw.githubusercontent.com may cache for a few minutes).

## How repos load it
Each repo has, once:
- `AGENTS.md`: a pointer to this file (for Cursor, Codex and others: they fetch it with curl before
  working) plus a `## This repo` section with that repo's own tests, staging checks and deploy notes.
- `CLAUDE.md`: `@AGENTS.md`.
- `.claude/settings.json`: a SessionStart hook that downloads `RULES.md` into every Claude Code session:
  ```json
  {"hooks": {"SessionStart": [{"hooks": [{"type": "command", "command":
    "curl -fsSL --max-time 10 https://raw.githubusercontent.com/Celero-io/.github/master/agents/RULES.md || echo 'WARNING: could not load the shared Celero agent rules. Tell the user before doing any work.'"}]}]}}
  ```

Repo-specific rules (test commands, deploy notes) stay in that repo's `AGENTS.md`.

## Add a repo
Copy the pointer section of any repo's `AGENTS.md`, write its `## This repo` section (all its test
types and staging checks), add `CLAUDE.md` and the hook above.

This repo is public: never put secrets, internal hostnames or credentials in `RULES.md`.
