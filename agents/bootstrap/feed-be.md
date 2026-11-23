## This repo
### Tests (run every type the change touches; report which ran)
- Unit, no AWS: `pytest testing/tests/unit_tests -m unit` and `pytest testing/tests/test_metadata_*.py -m unit`.
- AIAssistant unit tests (own pytest.ini): `cd AIAssistant && pytest`.
- API integration (stage credentials + network): `pytest testing/tests/api/ --env stage -m integration` (`-m "integration and not slow"` for a quick run).
- Live runs on stage or prod go through the guarded runner: `python testing/guarded_run.py --env stage -- testing/tests` (preflight, one run per environment, environment errors retried; exit codes in testing/README.md). Never `--env prod` unless the user asks.
- `testing/known_failures.txt`: never add a line to hide a failure you have not investigated.

### Staging and deploy
- Staging verification: the guarded run for the touched area on stage, or call the touched routes on the staging API.
- Merging to master deploys prod (celero-feed-pipeline-prod).
