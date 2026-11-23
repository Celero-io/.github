#!/usr/bin/env bash
# Copy agents/RULES.md into the shared block of AGENTS.md in every repo listed in agents/repos.txt,
# by pull request (never a direct push). Idempotent: a repo already up to date is skipped, and an
# open sync PR is updated in place.
#
#   agents/sync.sh                 all repos in agents/repos.txt
#   agents/sync.sh feed-be ...     only these repos
#   DRY_RUN=1 agents/sync.sh       show what would change, write nothing
#
# Each repo's AGENTS.md = the shared block (between the markers, replaced on every sync) + the
# repo's own "## This repo" section below it (never touched by the sync). A repo without AGENTS.md,
# or with one that has no markers yet, gets the block plus agents/bootstrap/<repo>.md; its old
# content is replaced, so check the PR. CLAUDE.md gets an "@AGENTS.md" line if it lacks one (the
# rest of CLAUDE.md is kept).
#
# Needs gh authenticated with write access to the repos (GH_TOKEN in CI).
set -euo pipefail
cd "$(dirname "$0")"
ORG=Celero-io
BRANCH=chore/agent-rules-sync
BEGIN='<!-- celero-shared-rules:begin (synced from Celero-io/.github agents/RULES.md by agents/sync.sh; edit it there, not here) -->'
END='<!-- celero-shared-rules:end -->'
SRC=$(git rev-parse --short HEAD 2>/dev/null || echo local)

block() { printf '%s\n' "$BEGIN"; cat RULES.md; printf '%s\n' "$END"; }

file_on() { # <repo> <ref> <path>: content or empty
  gh api "repos/$ORG/$1/contents/$3?ref=$2" --jq '.content|@base64d' 2>/dev/null || true
}
sha_on() { gh api "repos/$ORG/$1/contents/$3?ref=$2" --jq .sha 2>/dev/null || true; }

put() { # <repo> <path> <content-file> <message>
  local sha; sha=$(sha_on "$1" "$BRANCH" "$2")
  gh api -X PUT "repos/$ORG/$1/contents/$2" -f message="$4" -f branch="$BRANCH" \
    -f content="$(base64 < "$3" | tr -d '\n')" ${sha:+-f sha="$sha"} --jq .commit.sha >/dev/null
}

sync_repo() {
  local repo=$1 def head cur new tmp
  def=$(gh api "repos/$ORG/$repo" --jq .default_branch)
  cur=$(file_on "$repo" "$def" AGENTS.md)
  tmp=$(mktemp)
  if grep -qF "$BEGIN" <<<"$cur"; then
    { block; awk -v e="$END" 'f{print} $0==e{f=1}' <<<"$cur"; } > "$tmp"
  elif [[ -f bootstrap/$repo.md ]]; then
    { block; echo; cat "bootstrap/$repo.md"; } > "$tmp"
  else
    echo "$repo: no markers and no bootstrap/$repo.md; skipped"; rm -f "$tmp"; return
  fi
  claude=$(file_on "$repo" "$def" CLAUDE.md)
  has_import() { grep -qxF '@AGENTS.md' <<<"$claude"; }
  if [[ "$(cat "$tmp")" == "$cur" ]] && has_import; then
    echo "$repo: up to date"; rm -f "$tmp"; return
  fi
  if [[ -n ${DRY_RUN:-} ]]; then
    echo "$repo: would update AGENTS.md ($(wc -l < "$tmp" | tr -d " ") lines)$(has_import || echo " and add @AGENTS.md to CLAUDE.md")"; rm -f "$tmp"; return
  fi
  # Our own branch, recreated from the default branch head on every sync.
  head=$(gh api "repos/$ORG/$repo/git/ref/heads/$def" --jq .object.sha)
  if gh api "repos/$ORG/$repo/git/ref/heads/$BRANCH" >/dev/null 2>&1; then
    gh api -X PATCH "repos/$ORG/$repo/git/refs/heads/$BRANCH" -f sha="$head" -F force=true >/dev/null
  else
    gh api "repos/$ORG/$repo/git/refs" -f ref="refs/heads/$BRANCH" -f sha="$head" >/dev/null
  fi
  put "$repo" AGENTS.md "$tmp" "Agent rules: sync shared block from Celero-io/.github ($SRC)"
  # CLAUDE.md: add the "@AGENTS.md" import line if it is missing; keep everything else in the file.
  if ! has_import; then
    { echo '@AGENTS.md'; if [[ -n $claude ]]; then printf '%s\n' "$claude"; fi; } > "$tmp"
    put "$repo" CLAUDE.md "$tmp" "Agent rules: CLAUDE.md reads AGENTS.md"
  fi
  rm -f "$tmp"
  if [[ -z $(gh pr list -R "$ORG/$repo" --head "$BRANCH" --state open --json number --jq '.[0].number') ]]; then
    gh pr create -R "$ORG/$repo" --base "$def" --head "$BRANCH" \
      --title "Agent rules: sync shared rules from Celero-io/.github" --body "$(cat <<EOF
## Why (description and justification)
The rules for AI coding agents are kept in one place, Celero-io/.github \`agents/RULES.md\`, and copied into every repo so each agent reads the same rules (agents only read files inside the repo).

## What
- \`AGENTS.md\`: shared block updated to Celero-io/.github@$SRC. The "This repo" section below it belongs to this repo and is not changed by the sync (on the first sync it comes from \`agents/bootstrap/$repo.md\`; check it).
- \`CLAUDE.md\`: has the line \`@AGENTS.md\` (added only if missing; the rest of the file is unchanged), so Claude Code reads the same file.

## Risk
Low: documentation for agents only, no code change.

## Test plan
Read the diff. No build or test impact.

## Rollback plan
Revert this PR.

## Schedule
Any time. In repos where merging to the default branch runs the prod pipeline, it redeploys the same code.

## Emergency change
- [ ] This is an emergency change (merged outside the normal approval rule). If checked: say why, and an approver must review this PR within 2 business days.
EOF
)" | tail -1
  else
    echo "$repo: open sync PR updated"
  fi
}

if [[ $# -gt 0 ]]; then repos=("$@"); else repos=(); while read -r r; do [[ -z $r || $r == \#* ]] || repos+=("$r"); done < repos.txt; fi
for r in "${repos[@]}"; do sync_repo "$r"; done
