## This repo
### Tests
- Unit (jest via react-app-rewired): `CI=true yarn test` (without CI=true it stays in watch mode).
- Build: `yarn build`.
- No e2e suite: for UI changes run the app, exercise the change, check the browser console.

### Staging and deploy
- Staging verification: open a microsite touched by the change on celero-staging.com.
- Merging to master deploys prod.
