## This repo
### Tests (run every type the change touches)
- Unit: `pytest tests/unit` (deps in tests/requirements.txt).
- Integration (against a deployed stack): `AWS_SAM_STACK_NAME=<staging stack> pytest tests/integration`.
- Sitemap check: `python tests/check_sitemap_for_token.py` when a change touches sitemaps or tokens.
- Templates: `aws cloudformation validate-template`, then a change set on the staging stack, read before executing.

### Staging and deploy
- Staging verification: execute the reviewed change set on the staging stack and check the changed resources.
- Merging does not deploy: every stack is deployed by a reviewed change set, staging first.
