## This repo
### Tests
- Unit (no AWS): `pytest testing/tests/unit_tests -m unit`.
- Pipeline integration: `pytest testing/tests/test_pipeline.py --env prod -m "integration and not slow"` (needs AWS_PROFILE=vir); slow CloudFront round-trip: `-m slow` (up to ~1 h). `--env` defaults to prod and these hit prod t.celero.io: run them only when the user asks, with payload `chk=t`.

### Staging and deploy
- Verification: unit tests, plus the pipeline integration test when the user approves it.
