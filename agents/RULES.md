# Instructions for AI agents (Claude, Cursor, Codex)

Shared Celero rules, the single source for every repo. Each repo's AGENTS.md points here and adds a
"This repo" section with its own tests and staging checks. If a rule here conflicts with what the user
asks, stop and ask.

## 1. Git and PR workflow (mandatory)

### Branches
- One task = one branch, created from the default branch:
  `git fetch origin && git switch -c <type>/<ticket>-<slug> origin/master` (or origin/main).
- Types: feature, fix, security, chore, hotfix. No `-staging` / `-master` suffixes. Never branch from staging.
- Never push, force-push or reset `staging`, `master` or `main`. Only the staging owner resets staging.
- Never merge or rebase `staging` into a feature branch. Never cherry-pick staging commits into a master PR.

### Before opening any PR
- Run every test type listed in "This repo" that the change touches (unit, integration, e2e, build, lint),
  and report the real output of each, plus which ones you did not run and why.
  Add or update tests for the change in the matching suite. A clean build means a fresh worktree, not a warm cache.
- Tests that call a deployed environment run against stage only, never prod, unless the user asks.
- For UI changes, run the app and exercise the change. Check the browser console.
- Never call something tested, passing or fixed unless it was actually run. Write unverified items as "not verified".
- Never commit secrets or `.env*` files (only `.env.example`). Never print secret values.

### PR into staging (first)
- `gh pr create -R Celero-io/<repo> --base staging --head <branch>`.
- Run the drift check first: `git diff --stat origin/master origin/staging`.
  Every differing file should belong to an open PR. Report anything else as drift. Don't fix it yourself.
- Conflict with staging only: never press "Update branch" or "Resolve conflicts" on GitHub.
  Create `integrate/<branch>` from origin/staging, merge the feature branch into it, resolve, test, and PR that into staging.
  It never goes to master. Tell the user staging has drifted.
- Conflict with master: merge or rebase origin/master into the feature branch.

### PR template (fill in every section)
Template: https://github.com/Celero-io/.github/blob/master/pull_request_template.md
- Why: the problem and why now.
- What: the change. Link related PRs in other repos.
- Risk: low, medium or high, and why.
- Test plan: what was run locally plus the results, and what will be checked on staging.
- Rollback plan: "revert this PR", plus anything extra (data, flags, migrations).
- Schedule: when it should reach prod, and the deploy order across repos.
- Emergency change: unchecked unless the user says this is a hotfix that can't wait.

### Verify on staging, then PR into master
- After the staging deploy, run the test plan against staging (see "This repo") and post the results on the staging PR.
- If it fails: fix on the same branch and open a new PR into staging.
- Then open a PR from the same branch with base master (or main). Link the verified staging PR and its results.
- Open the master PR only when the branch is final. A new push dismisses the approval.
- In repos where merging to master/main deploys prod (celero-be, feed-be, celero-viewer, celero-viewer-ssr,
  celero-buildvu, insights2), a merge is a prod deploy: say so in the PR.

### Merging and after prod
- Squash-merge, and only when the user asks. Never merge into master or main without the required approval.
- After the prod deploy: smoke-check the change, note the result on the master PR, then delete the branch.

### Hotfix
- `hotfix/<slug>` from master, PR into master. Right after it merges, PR the same branch into staging.

## 2. Always
- Use `gh ... -R Celero-io/<repo>` (in forks, gh defaults to the upstream parent).
- No AI attribution in commits, PR bodies or comments (no Co-Authored-By, no "Generated with").
- Never invent APIs, config keys or defaults: read the code and copy an existing caller.
- If something is unclear, or is outside the task, stop and ask. Don't widen the scope.
- Staging first, always. Never change prod before the same change is verified on staging and the user says go.

## 3. Infrastructure and AWS (each rule maps to an Oneleet check or a past incident)
Infrastructure changes are code: CloudFormation/SAM templates and committed scripts, reviewed in a PR.
No console clicks or one-off CLI changes. Preview every stack change with a change set and read it before executing.

- **Lambda**: every new function gets an error-rate alarm (errors/invocations >= 10%) to the environment's alert topic.
  (Oneleet: "Lambda functions have error rate monitored".)
- **Logs**: every CloudWatch log group sets `RetentionInDays: 365` or more, including RDS log exports.
  (Oneleet: "log groups retain logs for at least 365 days".)
- **Databases**:
  - An application never uses a database master login. Each application has its own login and its own
    Secrets Manager secret, with only the rights it needs. People use their personal IAM-token accounts.
    (Oneleet: "Unique production database authentication enforced".)
  - Read the DB login (username and password) from the secret at runtime; never hard-code a username, host or secret name per environment in code.
  - New RDS instances: deletion protection on, automated backups on, not publicly accessible, CPU, I/O,
    free space and freeable memory alarms. (Oneleet RDS checks.)
  - A new login secret needs rotation (Secrets Manager, alternating users, 30 days) and a `masterarn` key.
- **IAM least privilege**: grant exact resources. Never `secretsmanager:GetSecretValue` on `secret:*`
  or `Resource: '*'`, never `rds-db:connect` on `dbuser:*/*`. An app can read only its own secrets.
- **Permission changes**: change a function's setting and its permission in an order that never leaves it without access
  (grant the new resource first, switch, then remove the old one). A role updated before its function's settings
  denied a live call on 2026-11-22.
- **EC2**: no public SSH; instances use IAM roles (no access keys on hosts); operators connect with Session Manager.
  Security groups expose no non-essential ports. (Oneleet EC2 checks.)
- **S3**: block public access; bucket policies grant named principals only. (Oneleet S3 checks.)
- **Load balancers**: redirect HTTP to HTTPS; alarms on 5xx errors, latency and unhealthy hosts. (Oneleet ALB checks.)
- **DynamoDB**: point-in-time recovery on; read/write capacity alarms. **SQS**: message-age alarm. (Oneleet checks.)
- **Containers**: ECR repositories have image scanning on; fix critical/high image findings before release.

## 4. Application security (each rule maps to a pentest finding)
- **Tenant isolation**: every endpoint that reads or writes an object checks the caller's company owns it,
  and returns 404 otherwise. (CEL-001, CEL-008.)
- **Authentication by default**: every API route requires authentication unless it is explicitly public and the
  PR says why. Configuration and admin endpoints are never public. (CEL-004.)
- **Gated content is enforced server-side**: never trust the client to hide content; the API returns only what
  the caller's token allows. (CEL-002, CEL-003.)
- **URLs from users**: allow only http, https, mailto, tel and relative URLs, after stripping control characters,
  on every URL field, both on save and on render. Redirect targets come from an allow-list. (CEL-005, CEL-006.)
- **User HTML** renders only in a sandboxed iframe without `allow-same-origin`. (CEL-007.)
- **Errors**: responses never include stack traces, file paths or echoed input; log those server-side. (CEL-013.)
- **No API docs in staging/prod**: OpenAPI/Swagger disabled outside local and dev. (CEL-009.)
- **Headers**: send `Strict-Transport-Security` and `X-Content-Type-Options: nosniff` on every response,
  `Cache-Control: no-store` on authenticated responses, and a Content-Security-Policy without `unsafe-inline`
  scripts (use nonces). (CEL-010, CEL-011, CEL-012.)
- **Public responses** carry no billing, admin or internal fields.
- **SQL**: parameterised queries only; never build SQL with string formatting.

## 5. Dependencies
- Don't add a dependency without saying why in the PR. Pin versions.
- Don't leave known vulnerabilities: when a PR touches a dependency file, check Dependabot alerts for it.
  (Oneleet: "Dependabot alerts are addressed", "Dependency scanning findings are resolved".)
