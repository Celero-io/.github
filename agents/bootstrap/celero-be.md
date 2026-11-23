## This repo
### Tests (run every type the change touches; report which ran)
- Unit (Django, no network): `pytest --ignore=testing` and `python manage.py check`. Test DB is SQLite with `--no-migrations` (pytest.ini).
- Integration / e2e (call the deployed API and write data on the test accounts): `python -m pytest --env=stage testing/<file>.py`, or the guarded runner from feed-be: `python ../feed-be/testing/guarded_run.py --env stage --project-dir . -- testing`. Needs AWS credentials. Never `--env=prod` unless the user asks.
- A bare `pytest` also collects `testing/` (live API), so always pass `--ignore=testing` for unit runs.

### Staging and deploy
- Staging verification: API smoke on the touched endpoints at api-staging.celero.io, plus the integration tests for the touched area.
- Merging to master deploys prod (celero-backend-pipeline-prod).
