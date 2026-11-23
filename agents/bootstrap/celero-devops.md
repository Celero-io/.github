## This repo
### Tests
- Docs, runbooks and operator scripts: no build. Run `bash -n` on scripts you change, and check commands and links you add.
- Never commit secret values: scan run logs before committing.

### Staging and deploy
- Prod-affecting scripts run on staging first; their output goes to the task run log.
