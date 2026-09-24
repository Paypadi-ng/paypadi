# Contributing to PayPadi

## Branches, environments and releases

Trunk-based development with a staging promotion branch:

```
feature branch ──PR (squash)──▶ main ──PR (merge commit)──▶ staging ──tag vX.Y.Z──▶ prod
                                 │                            │                      │
                            deploy-dev.yml             deploy-staging.yml      deploy-prod.yml
                        dev flavor → Firebase     prod flavor + staging backend  prod flavor → Play internal
                        + Play internal (.dev)    → Firebase (qa-testers)        + TestFlight, after approval
```

| Branch / ref | Purpose | Updated by | Deploys to (GitHub environment) |
| --- | --- | --- | --- |
| `main` | Integration. Always releasable. | Squash-merged PRs from short-lived branches | `dev` |
| `staging` | Release candidates for QA | Promotion PRs from `main` (merge commit), or hotfix PRs | `staging` |
| `vX.Y.Z` tag | Production release | Maintainers only, on a commit already on `staging` | `prod` (needs approval) |

Each GitHub environment only accepts deployments from its own ref, so a
workflow run from any other branch can't read its secrets.

### Cutting a release

1. Bump `version:` in `pubspec.yaml` on `main` (PR as usual).
2. Open a PR **`main` → `staging`** titled `release: vX.Y.Z` and merge it with
   **"Create a merge commit"** (the only method allowed on `staging`; never
   squash a promotion, or `main` and `staging` diverge).
3. QA the staging build from Firebase App Distribution.
4. A maintainer tags the staging commit and pushes the tag:
   ```bash
   git fetch origin && git tag -s vX.Y.Z origin/staging && git push origin vX.Y.Z
   ```
   `deploy-prod.yml` checks the tag matches `pubspec.yaml` and is on
   `staging`, builds, and waits for a reviewer to approve the `prod`
   deployment.

### Hotfixes

Fix on `main` first and promote as above. If `main` has unreleased work that
must not ship, branch `hotfix/…` from `staging`, PR it into `staging`, release,
then open a PR with the same fix into `main` so it isn't lost.

## Branch naming

`type/short-description`, e.g. `feat/qr-payment-retry`,
`fix/wallet-balance-race`, `chore/upgrade-riverpod`.

Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `ci`, `hotfix`.

## Commits and PR titles

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(wallet): add retry logic for failed deposits
fix(auth): correct JWT refresh race condition
chore(deps): bump riverpod to 3.x
```

PRs into `main` are squash-merged, so **the PR title becomes the commit on
`main`** — make it a good Conventional Commit.

## Opening a PR

1. Branch off `main`.
2. Keep PRs scoped to one thing — a feature, a fix, or a refactor.
3. Fill out the PR template, including screenshots for UI changes (redact any
   personal or financial data — this repo is public).
4. Run locally before requesting review:
   ```bash
   dart run build_runner build -d
   dart format lib test
   flutter analyze --fatal-infos
   flutter test
   ```

## Review and merge rules

Enforced by repository rulesets (no one can bypass them, admins included):

- A PR is required; direct pushes, force pushes and deletions of `main` /
  `staging` are blocked.
- 1 approval from someone other than the author, and the **latest push must be
  approved** — pushing after approval requires re-approval.
- Required checks: **Analyze & Test**, **Dependency review**,
  **Workflow audit (zizmor)**. The branch must be up to date with its base.
- All review conversations must be resolved.
- `main`: squash merge only, linear history. `staging`: merge commits only.

Reviews are delta-focused: when you push a follow-up addressing feedback, say
what changed so reviewers only re-check the new bits. Keep feedback concise
and specific: point at the line, state the issue, suggest the fix if it's not
obvious.

## Code standards

Enforced by lint/CI where possible; call them out in review regardless:

- Riverpod: `ref.watch` only inside `build()`; never after an `await` in an
  async provider; never manually set `state` inside `build()`; use `ref.read`
  for non-reactive service deps; let failures `throw` so Riverpod surfaces
  `AsyncError`.
- `keepAlive: true` is a deliberate choice for app-lifetime state (session,
  user profile, theme, infrastructure providers) — justify any new use in the
  PR description.
- No `async void` — every async method needs a real `await` and must not
  silently swallow exceptions.
- No force unwraps (`!`) in production code.
- Notifiers never hold `BuildContext` or call UI directly — use the `ref`
  extension surface (`ref.showExceptionMessage(...)`, etc.).
- Errors go through `AppException` / `ClientException` / `ServerException`.
  Report unexpected errors through `MonitoringService` (Sentry) rather than
  crashing where the user shouldn't see a crash.
- Widgets: `HookConsumerWidget` with `useTextEditingController` / `useState`
  / `useEffect` / `useMemoized`; no stateful class fields for things hooks
  already manage.

## Building locally

Two flavors, two entry points:

```bash
flutter run -t lib/main_dev.dart --flavor dev --dart-define=API_BASE_URL=<dev api url>
flutter run -t lib/main_prod.dart --flavor prod --dart-define=API_BASE_URL=<api url>
```

Store uploads are always App Bundles (`flutter build appbundle`), built by CI.

## Secrets and sensitive data

- Never commit keystores, `key*.properties`, `.env` files, Apple `.p8`/`.p12`
  files, service-account JSON, API tokens or real customer data. They're
  gitignored, and GitHub push protection will block most secrets — if it
  blocks your push, remove the secret; don't bypass the block.
- CI secrets live in the `dev`, `staging` and `prod` GitHub environments,
  never at repository level (except `CODECOV_TOKEN`).
- Firebase client config (`google-services.json`, `GoogleService-Info.plist`,
  `firebase_options*.dart`) *is* committed. It's public by design; the API
  keys in it are restricted to our app IDs in Google Cloud. Don't add
  server-side Firebase credentials anywhere in the repo.
- If a secret is ever committed or leaked, tell a maintainer immediately:
  **rotate it first**, then clean up.

## Maintainers

Maintainers own releases (`v*` tags), approve `prod` deployments and own the
paths in `.github/CODEOWNERS`. Current maintainers: @laolu-dev.

When a second maintainer is added:

1. Add them to `.github/CODEOWNERS` alongside @laolu-dev.
2. Turn on **Require review from Code Owners** in the `main` and `staging`
   rulesets.
3. Add them as a required reviewer on the `prod` environment and turn on
   **Prevent self-review**.

Break-glass: if a ruleset blocks an urgent fix, an org owner may temporarily
disable the specific rule, merge, and re-enable it immediately. Every change to
a ruleset is recorded in the org audit log; post the reason in the PR.
