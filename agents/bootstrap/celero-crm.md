## This repo
### Tests
- Integration (call the deployed stage API): `pytest testing/<file>.py --env stage` for the touched area; say which files ran. Never `--env prod` unless the user asks.
- No offline unit suite: if no test covers the change, write down the manual test you ran.

### Staging and deploy
- Staging verification: run the CRM flow the change touches against stage.
- No pipeline: prod is deployed by hand from a reviewed change set.
