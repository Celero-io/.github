## This repo
### Tests
- Integration (call the deployed API): from `testing/`, `pytest <file>.py --env=stage` (see testing/README.md). Never `--env=prod` unless the user asks.
- No offline unit suite: if no test covers the change, write down the manual test you ran.

### Staging and deploy
- Staging verification: run the touched flow against stage.
