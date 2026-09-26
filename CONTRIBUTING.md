# Contributing to PayPadi

## Branches, environments and releases

Changes flow one way: **feature → `dev` → `staging` → `main`**. `main` is
production.

```
feature/* ──PR (squash)──▶ dev ──PR (merge)──▶ staging ──PR (merge)──▶ main ──tag vX.Y.Z──▶ stores
    │                        │                    │                       │               │
 PR preview             deploy-dev.yml     deploy-staging.yml       build-prod.yml   deploy-prod.yml
 (approval)            dev → Firebase     staging → Play internal   signed prod      Play production (10%)
                                                  + TestFlight       candidate        + App Store review
```

| Branch / ref | Flavor (app ID) | What happens | GitHub environment |
| --- | --- | --- | --- |
| PR into `dev` | dev (`com.paypadi.dev`) | Unsigned build check; after a maintainer approves, a signed build goes to Firebase (`dev-testers`) | `dev-preview` (required reviewer) |
| `dev` | dev (`com.paypadi.dev`) | Signed build to Firebase App Distribution (`dev-testers`) | `dev` (dev branch only) |
| `staging` | staging (`com.paypadi.staging`) | Play Store internal track + TestFlight | `staging` (staging branch only) |
| `main` | prod (`com.paypadi`) | Signed release candidate kept as a build artifact (90 days); nothing distributed | `prod-build` (main branch only, signing secrets only) |
| `vX.Y.Z` tag on `main` | prod (`com.paypadi`) | Play production track as a 10% staged rollout + App Store submission for review | `prod` (`v*` tags only, required reviewer) |

The **Promotion policy** check enforces the order: PRs into `staging` must
come from `dev` (or `hotfix/*`), and PRs into `main` from `staging` (or
`hotfix/*`).

### Approving PR previews

A PR's workflows run the PR's own copy of `.github/`, so the `dev-preview`
approval is what keeps dev credentials away from unreviewed code. Before
approving a preview, check the PR doesn't modify `.github/`, `fastlane/` or
`android/`/`ios/` build files in a way you haven't reviewed.

### Cutting a release

1. Bump `version:` in `pubspec.yaml` in a PR into `dev`.
2. Promote: PR **`dev` → `staging`**, merge with **"Create a merge commit"**.
   QA the staging app from Play internal testing / TestFlight.
3. Promote: PR **`staging` → `main`**, merge with **"Create a merge commit"**.
   `build-prod.yml` produces the signed release candidate.
4. A maintainer tags `main` and pushes the tag:
   ```bash
   git fetch origin && git tag -s vX.Y.Z origin/main && git push origin vX.Y.Z
   ```
   `deploy-prod.yml` checks the tag matches `pubspec.yaml` and is on `main`,
   waits for a reviewer to approve the `prod` deployment, then:
   - **Play:** releases to 10% of users (`PLAY_ROLLOUT` repo variable). Raise
     the rollout in the Play Console as crash-free rates allow.
   - **App Store:** submits for review with manual release. Release it in
     App Store Connect once approved.

Never squash a promotion PR (`dev` → `staging`, `staging` → `main`): the
branches would diverge and every later promotion would conflict.

### Hotfixes

1. Branch `hotfix/<name>` from `main`, bump the patch version, and open a PR
   into **`main`** (merge commit). Tag the release as above.
2. Open PRs with the same branch into **`staging`** and **`dev`** so the fix
   isn't lost on the next promotion.

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

PRs into `dev` are squash-merged, so **the PR title becomes the commit on
`dev`** — make it a good Conventional Commit.

## Opening a PR

1. Branch off `dev` (the default branch).
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

- A PR is required; direct pushes, force pushes and deletions of `dev`,
  `staging` and `main` are blocked.
- 1 approval from someone other than the author, and the **latest push must be
  approved** — pushing after approval requires re-approval.
- Required checks: **Analyze & Test**, **Dependency review**,
  **Workflow audit (zizmor)** and **Promotion policy**. Feature branches must
  be up to date with `dev` before merging.
- All review conversations must be resolved.
- `dev`: squash merge only, linear history. `staging` and `main`: merge
  commits only (promotions keep their ancestry).

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

Three flavors, three entry points:

```bash
flutter run -t lib/main_dev.dart --flavor dev --dart-define=API_BASE_URL=<dev api url>
flutter run -t lib/main_staging.dart --flavor staging --dart-define=API_BASE_URL=<staging api url>
flutter run -t lib/main_prod.dart --flavor prod --dart-define=API_BASE_URL=<api url>
```

Store uploads are always App Bundles (`flutter build appbundle`), built by CI.

## Secrets and sensitive data

- Never commit keystores, `key*.properties`, `.env` files, Apple `.p8`/`.p12`
  files, service-account JSON, API tokens or real customer data. They're
  gitignored, and GitHub push protection will block most secrets — if it
  blocks your push, remove the secret; don't bypass the block.
- CI secrets live in the `dev`, `dev-preview`, `staging`, `prod-build` and
  `prod` GitHub environments, never at repository level (except
  `CODECOV_TOKEN`). Each flavor has its own Android upload key.
- Firebase client config (`google-services.json`, `GoogleService-Info.plist`,
  `firebase_options*.dart`) *is* committed. It's public by design; the API
  keys in it are restricted to our app IDs in Google Cloud. Don't add
  server-side Firebase credentials anywhere in the repo.
- If a secret is ever committed or leaked, tell a maintainer immediately:
  **rotate it first**, then clean up.

## Maintainers

Maintainers own releases (`v*` tags), approve `prod` deployments and PR previews and own the
paths in `.github/CODEOWNERS`. Current maintainers: @laolu-dev.

When a second maintainer is added:

1. Add them to `.github/CODEOWNERS` alongside @laolu-dev.
2. Turn on **Require review from Code Owners** in the `dev`, `staging` and
   `main` rulesets.
3. Add them as a required reviewer on the `prod` and `dev-preview`
   environments and turn on **Prevent self-review**.

Break-glass: if a ruleset blocks an urgent fix, an org owner may temporarily
disable the specific rule, merge, and re-enable it immediately. Every change to
a ruleset is recorded in the org audit log; post the reason in the PR.
