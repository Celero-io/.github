# Shared rules for AI coding agents

`RULES.md` is the single source of the rules every AI agent (Claude Code, Cursor, Codex) follows in
Celero repos: the git/PR process, and the security rules learned from Oneleet checks and the pentest.

Agents only read files inside the repo they work in, so the rules are copied into each repo's
`AGENTS.md` (and `CLAUDE.md` = `@AGENTS.md`) by `sync.sh`, always through a pull request.

## Change a rule
1. Edit `RULES.md` in a PR to this repo. Get it approved and merged.
2. The workflow `.github/workflows/sync-agent-rules.yml` then opens (or updates) a PR
   `chore/agent-rules-sync` in every repo in `repos.txt`. Each repo reviews and merges its PR.
   Without the workflow token, run it by hand: `agents/sync.sh` (or `DRY_RUN=1 agents/sync.sh`).

## Repo-specific rules
Below the shared block, each repo's `AGENTS.md` has a `## This repo` section (its tests, staging
checks, deploy notes). Edit that in the repo itself; the sync never touches it. `bootstrap/<repo>.md`
is only used the first time a repo gets the block.

## Add a repo
Add it to `repos.txt` and write `bootstrap/<repo>.md` (its tests of every type and staging checks).

## Workflow token
The workflow needs a secret `AGENT_RULES_SYNC_TOKEN`: a GitHub App installation token or a
fine-grained token with Contents and Pull requests read/write on the repos in `repos.txt`
(the default GITHUB_TOKEN can't write to other repos). An org admin creates it.
