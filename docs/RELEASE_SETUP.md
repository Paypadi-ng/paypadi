# Release setup: CI/CD, signing and secrets

How builds get from a pull request to the stores, which secrets each step needs, and the steps
still outstanding before iOS and Google Play releases can run. State as of 2026-11-16.

Never paste secret values into chat, issues, commits or logs. GitHub Actions secrets are
write-only, so keep the originals in the team password manager (Bitwarden). The two scripts in
`scripts/` upload values without printing them.

---

## 1. Pipeline

Branch flow: `feature/*` (and `fix/*`, `chore/*`) → `dev` (default branch) → `staging` → `main`
(production). The `Promotion policy` check enforces that order; `hotfix/*` may target `staging` or
`main`.

| Trigger | Workflow | What it builds | Where it goes |
|---|---|---|---|
| Pull request into `dev` | `deploy-dev.yml` | Checks, then an unsigned build; a signed preview after `dev-preview` approval | Firebase App Distribution |
| Push to `dev` | `deploy-dev.yml` | Signed dev flavor | Firebase App Distribution |
| Push to `staging` | `deploy-staging.yml` | Staging flavor (`com.paypadi.staging`) | Play internal track and TestFlight |
| Push to `main` | `build-prod.yml` | Signed prod release candidate | Kept as a build artifact only |
| `v*` tag on `main` | `deploy-prod.yml` | Prod flavor | Play production at a 10% staged rollout (`PLAY_ROLLOUT`), App Store submitted for review with manual release |

Also: `validate.yml` (format, analyze, tests; reused by the others) and `security.yml`
(dependency review, workflow audit with zizmor).

`.github/actions/setup-env` installs Flutter at the exact version in `.fvmrc` (3.47.5), Java and
Ruby 3.3, and runs `flutter pub get --enforce-lockfile`. Actions are pinned by commit SHA.

**iOS jobs are switched off** by two repository variables, both unset today:
`IOS_DEPLOY_ENABLED` (dev and staging) and `IOS_PROD_DEPLOY_ENABLED` (prod). Set
`IOS_DEPLOY_ENABLED=true` only after section 3 is finished, or every push gets a failing iOS job.

---

## 2. Environments, secrets and variables

| Environment | Used by | Secrets present (2026-11-16) | Variables | Missing |
|---|---|---|---|---|
| `dev` | pushes to `dev` | Android signing (4), `API_BASE_URL`, `FIREBASE_SERVICE_ACCOUNT_JSON` | `FIREBASE_ANDROID_APP_ID`, `FIREBASE_IOS_APP_ID` | iOS signing (6) |
| `dev-preview` | PR previews (required reviewer: laolu-dev) | same as `dev` | same as `dev` | iOS signing (6) |
| `staging` | pushes to `staging` | Android signing (4), `API_BASE_URL`, `SENTRY_AUTH_TOKEN`, `SENTRY_DSN` | none | iOS signing (6), `PLAY_STORE_JSON_KEY` |
| `prod-build` | pushes to `main` | Android signing (4), `API_BASE_URL`, `SENTRY_DSN` | none | none for Android |
| `prod` | `v*` tags (required reviewer: laolu-dev) | Android signing (4), `API_BASE_URL`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `SENTRY_AUTH_TOKEN`, `SENTRY_DSN` | `FIREBASE_ANDROID_APP_ID`, `FIREBASE_IOS_APP_ID` | `PLAY_STORE_JSON_KEY`; iOS prod signing (waits for an organization Apple account) |

Repository-level secret: `CODECOV_TOKEN`. Optional variable: `BUILD_NUMBER_OFFSET` (added to the
run number to form the build number).

**Android signing secrets**: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. They come from the upload keystores
`android/paypadi-{dev,staging,prod}.jks` with `android/key-{flavor}.properties`. Those files are
git-ignored and currently exist **only on one Mac**. Back them up (file plus passwords) to the
password manager: a lost upload key has to be reset through Play Console support.

To (re)upload one flavor's Android signing secrets:

```bash
bash scripts/set-android-signing-secrets.sh dev dev dev-preview
```

`API_BASE_URL` is the backend address for each flavor. Locally it lives in `.env.dev`,
`.env.staging` and `.env.prod` (git-ignored, read with `--dart-define-from-file`). As of
2026-11-16 the dev address returns PythonAnywhere's "Coming Soon" 404; update the secrets and the
`.env` files when the backend has a working address.

### Firebase app IDs

`FIREBASE_IOS_APP_ID` is only read by `deploy-dev.yml` (dev iOS builds to Firebase App
Distribution). Staging and prod iOS go to TestFlight and the App Store, so they don't need it.

| Flavor | Bundle ID | Firebase iOS app ID |
|---|---|---|
| dev | `com.paypadi.dev` | `1:513436288323:ios:9dcb074abcbf2bb3369bf6` |
| staging | `com.paypadi.staging` | `1:513436288323:ios:3ed97a4418509fdc369bf6` |
| prod | `com.paypadi` | `1:513436288323:ios:71078e406d2489c7369bf6` |

These are public IDs, also in `lib/firebase_options_{flavor}.dart`.

---

## 3. iOS signing for dev and staging (not done yet)

Team `BGJ9Z72W23` (an individual Apple account, Olash's). fastlane `match` stores the
certificates, encrypted, in the private repo `Paypadi-ng/ios-certificates`, which is still
**empty**: `match` has not completed yet.

The six secrets, needed in `dev`, `dev-preview` and `staging`:
`MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION`,
`APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`,
`APP_STORE_CONNECT_API_KEY_BASE64`.

Progress as of 2026-11-16: the API key (step 3) exists and is in Bitwarden, and a CI token
(step 5) was requested. Steps 1, 2, 6 and 7 are unconfirmed or not done.

1. **Register the app IDs.** developer.apple.com → Certificates, IDs & Profiles → Identifiers →
   **+** → App IDs → App. Create `com.paypadi.dev` and `com.paypadi.staging` with **Push
   Notifications** ticked. Register testers' iPhones under **Devices**: dev builds are signed for
   development and install only on registered devices.
2. **Create the staging app record.** App Store Connect → Apps → **+** → New App, bundle ID
   `com.paypadi.staging`. TestFlight uploads need it.
3. **App Store Connect API key.** Users and Access → Integrations → App Store Connect API →
   Team Keys. Use the key named "Paypadi CI" (Admin access, so `match` can create certificates).
   Its Key ID, Issuer ID and `.p8` file are in Bitwarden. The `.p8` downloads only once. A second
   key named "paypadi" also exists: check its Last Used date and revoke it if nothing uses it.
4. **match passphrase.** A generated password stored in Bitwarden ("Paypadi – match passphrase").
   It decrypts everything in `ios-certificates`; without it the certificates must be regenerated.
5. **Read-only CI token.** GitHub → Settings → Developer settings → Fine-grained tokens. Owner
   Paypadi-ng, only the `ios-certificates` repository, Contents: Read-only, 90+ day expiry. The
   org requires an owner (Olash) to approve fine-grained tokens: Paypadi-ng → Settings →
   Personal access tokens → Pending requests. Store it in Bitwarden with its expiry date.
6. **Run `match` once on a Mac** (uses your own GitHub access, not the CI token). macOS uses zsh,
   so use the zsh `read` form below. Run everything in **one** terminal tab: exported values do
   not carry over to a new tab or shell. Install the gems first:

   ```bash
   bundle install
   ```

   Then load the key and passphrase (fill in the Key ID, Issuer ID and `.p8` path) and create the
   dev certificate and profile, in one command:

   ```bash
   export APP_STORE_CONNECT_API_KEY_ID=KEY_ID APP_STORE_CONNECT_API_ISSUER_ID=ISSUER_ID APP_STORE_CONNECT_API_KEY_BASE64="$(base64 -i /path/to/AuthKey_KEY_ID.p8)"; read -s "MATCH_PASSWORD?match passphrase: "; export MATCH_PASSWORD; echo; bundle exec fastlane ios sync_dev_certs
   ```

   Then, in the same tab, the staging App Store certificate and profile:

   ```bash
   bundle exec fastlane ios sync_appstore_certs flavor:staging
   ```

   Errors seen so far and their causes:
   - `read: -p: no coprocess`: the bash `read -p` form was used in zsh. Use the form above.
   - `:key_content or :key_filepath is required`: the exports were made in a different shell.
   - "Maximum number of certificates": revoke an unused development certificate (limit 2).
7. **Upload the secrets.** Prompts (hidden) for the GitHub username, the read-only token and the
   match passphrase, checks the token can read `ios-certificates`, then sets all six secrets in
   `dev`, `dev-preview` and `staging`:

   ```bash
   bash scripts/set-ios-secrets.sh /path/to/AuthKey_KEY_ID.p8 KEY_ID ISSUER_ID
   ```

8. **Turn iOS CI on.** Set the repository variable `IOS_DEPLOY_ENABLED` to `true`. Leave
   `IOS_PROD_DEPLOY_ENABLED` unset.

Afterwards, delete any local copy of the `.p8` (it's in Bitwarden).

## 4. iOS for production (blocked)

Apple rejects financial-services apps published from individual accounts. Prod iOS waits for a
Paypadi **organization** Apple Developer account, then: a new team ID in `fastlane/Appfile` and
the prod build configurations, `match appstore` for `com.paypadi`, the iOS secrets in `prod` and
`prod-build`, and `IOS_PROD_DEPLOY_ENABLED=true`.

## 5. Google Play (not done yet)

1. Create the staging app (`com.paypadi.staging`) in Play Console.
2. Upload the first AAB by hand (Play requires one before the API can publish), and enable
   **Play App Signing**. Do the same for prod (`com.paypadi`) when ready.
3. Create dedicated Google Cloud service accounts (for example `play-staging-ci` and
   `play-prod-ci`), grant them release access in Play Console → Users and permissions, and download
   a JSON key for each. Use only keys from Paypadi's own Google Cloud project.
4. Store each key in Bitwarden, then set it as `PLAY_STORE_JSON_KEY` in `staging` and `prod`:

   ```bash
   gh secret set PLAY_STORE_JSON_KEY --env staging --repo Paypadi-ng/paypadi < /path/to/play-staging-ci.json
   ```

---

## 6. Repository rules (for reference)

- `dev`, `staging`, `main` each have a protection ruleset (required checks, no deletion, no force
  push; linear history on `dev`) with no bypass, plus a `-review` ruleset holding only the
  pull-request rule: 1 approval, stale approvals dismissed, last-push approval, conversation
  resolution. Merge methods: squash into `dev`, merge commits into `staging` and `main`.
- Members of the `paypadi-maintainers` team (visible, member: laolu-dev) can bypass the `-review`
  rulesets for pull requests only, so a maintainer can merge their own green PR without a second
  approval. CI still has to pass. The team must stay visible: GitHub rejects secret teams as
  bypass actors.
- Required checks: `Analyze & Test`, `Dependency review`, `Workflow audit (zizmor)`,
  `Promotion policy`, plus `Build dev app (unsigned)` on `dev`.
- `release-tags`: only repository admins can create, move or delete `v*` tags.
- "Allow auto-merge" is on. GitHub won't enable auto-merge on a PR that is already approved and
  green; merge those directly.
- Not applied (need the org owner): require 2FA, base permission "No permission", block public
  repository creation.
