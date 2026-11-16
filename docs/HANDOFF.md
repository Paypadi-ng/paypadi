# Paypadi handoff

Where the project stands, what is unfinished and why, and how to pick it up again. Written
2026-11-16, when the project was archived. `dev` was at `df08940` (PR #32).

Read with: [`README.md`](../README.md) (setup, architecture, conventions) and
[`docs/RELEASE_SETUP.md`](RELEASE_SETUP.md) (CI/CD, signing, secrets).

---

## 1. State at archive

- **App:** Flutter 3.47.5 (pinned in `.fvmrc`; `pubspec.yaml` needs `>=3.47.5`). 194 tests pass on
  `dev`. Flavors: dev, staging, prod.
- **Backend:** the API used by every flavor (`API_BASE_URL`) is unreachable. Since about
  2026-10-11 `https://khidr.pythonanywhere.com/` returns PythonAnywhere's "Coming Soon" 404 page,
  including the Swagger docs and `/auth/login/`. Nothing that needs a server can be tested, and the
  schema can't be checked. Don't send real credentials to that host: the subdomain may have been
  released and claimed by someone else.
- **Android CI:** working. Checks and the unsigned dev build run on every PR; signed dev builds go
  to Firebase App Distribution.
- **iOS CI:** off (`IOS_DEPLOY_ENABLED` unset). Signing is not set up yet; see RELEASE_SETUP
  section 3.
- **Store releases:** not set up for either platform (no Play keys, no iOS signing).

## 2. Resume checklist

1. Get a working API address from the backend team. Put it in `.env.dev`, `.env.staging` and
   `.env.prod` (git-ignored: `API_BASE_URL=...`, `SENTRY_DSN=...`) and in the `API_BASE_URL`
   secret of every GitHub environment.
2. Run the app (VS Code launch configs, or
   `flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file .env.dev`) and do the
   manual checks in section 4 that were blocked by the backend.
3. Review the open Dependabot items (section 5).
4. Pick up the backend-dependent features (section 3).
5. Finish release setup when the store accounts are ready (RELEASE_SETUP sections 3 to 5).

Local checks before any PR: `dart run build_runner build -d`, `dart format --set-exit-if-changed
lib test`, `flutter analyze --fatal-infos`, `flutter test`.

## 3. Unfinished work

### Blocked on the backend

| Item | State | Needs from the backend |
|---|---|---|
| Withdraw to other banks | The "To Other Banks" tab has an account field and a bank picker whose selection does nothing. `POST /wallets/withdraw/` is in `TransactionClient` but has no repository method or UI flow. | Withdraw request schema, fee (if any), whether the PIN goes in the payload, whether withdrawals skip the "initiate" step |
| Profile edit and photo | Save and "Edit photo" on the Profile screen do nothing. `PUT`/`PATCH /auth/profile/` take no body; `ProfilePicture.uploadPicture` picks an image but doesn't upload it. The avatar is a hard-coded constant. | Editable profile fields; photo upload endpoint (field name, multipart or not). Hide "Edit photo" if there is no endpoint. |
| Junk Paystack transactions | The transfer flow's initiate step (`/wallets/payments/initiate/`) creates pending Paystack transactions that are never completed. | Whether the initiate step can be removed for in-app transfers |
| Received transfers shown as debits | Incoming transfers arrive typed "transfer" with no direction. | A direction (credit/debit) field on transactions |
| Password reset | Forgot Password only offers "Contact support". | A reset endpoint (OTP purpose `reset_password` exists) |

Planned shape for withdraw (agreed, not built): picking a bank verifies the account with the
existing `verifyBankInformation` call and shows the holder's name; `TransferDraft` gains a bank
withdrawal mode with the bank code and verified name; the existing amount → authenticate →
confirm screens are reused; a new repository `withdraw()` call; then the receipt.

API notes from the last Swagger check (2026-10-01; Swagger omitted the `{status, message, data}`
envelope and some fields, so confirm against real responses):
- No idempotency field in the transfer body (`TransferFunds`).
- The transfer response returns a `TransactionModel` with an integer amount.
- `/wallets/transactions/` paging: paginated in the schema; the client handles it.

### Not blocked, not started

- **Resume a deep link after unlock.** Today unlocking always lands on Home. Not worth building
  until deep links exist: there is no Android intent filter, iOS URL scheme or associated domain.
  `resolver.redirectUntil` in the guard is the way to do it.
- **Dark iOS launch screen.** The native launch screen is always white (it shows before Flutter
  starts, so it can't read the in-app setting). A dark variant would follow the phone's system
  appearance, not the app's toggle.

## 4. Manual checks still owed (need a working backend)

- **#29:** with a saved session, a cold start goes to the unlock screen; after unlocking, Back from
  Home leaves the app instead of returning to sign-in; logout then sign-in works.
- **#30:** background the app for 5+ minutes, and it asks to unlock on return; signing in as a new
  driver (not approved, no vehicle details) lands on Vehicle Information.
- **#31:** walk Home, Transfer, Receipt and Settings in dark mode. Only onboarding and Sign In have
  been seen on a device so far.

## 5. Open dependency items (2026-11-16)

- **6 Dependabot alerts** (5 medium, 1 low), all in the Ruby gem `addressable` in `Gemfile.lock`,
  a fastlane dependency, fixed in 2.9.1. They affect CI tooling only, not the app. Fix with
  `bundle update addressable --conservative` (or update fastlane), then check
  `bundle exec fastlane lanes` still loads.
- **PR #39** (Dependabot): bumps 6 GitHub Actions. All checks passed; waiting for review.
- fastlane 2.241.0 is out (the repo is on 2.240.1).

## 6. Decisions and why

| Decision | Reason |
|---|---|
| Passwords are never stored; biometric unlock renews the session with the refresh token (#21) | Stored passwords were a security risk. Once the refresh token expires, the user signs in with their password. |
| The transaction PIN is stored only behind OS biometrics (`TransactionPinVault`), and is cleared when the PIN changes, biometrics are turned off, or the server rejects it | Keeps the "pay with biometrics" button without keeping a plain PIN on the device |
| Protected routes need an unlock in this app session (`SessionUnlocked`), not just a stored token (#29) | A stored session alone let any navigation skip the unlock |
| Lock again after 5 minutes in the background (#30) | Agreed with the tech lead |
| `DriverAccountGuard` holds back drivers who aren't approved **and** have no vehicle details (#30) | The literal rule ("not approved") would send drivers awaiting approval back to the form on every sign-in |
| `lib/` layers: core ← data ← shared ← features ← app; features never import each other; `test/architecture_test.dart` enforces it (#28, #29) | Keeps dependencies one-way. The one exception: `shared/` and `features/` may use the app's router, theme and session, because AutoRoute's generated router imports every page. |
| Dark palette designed in code (`AppPalette` in `lib/app/theme.dart`), Light/Dark only (#31) | There is no dark design in Figma. Contrast is tested: main text 7:1, secondary 4.5:1, status 3:1. |
| The shared QR image is always dark-on-white | So any app can scan it, in either theme |
| CI Flutter version in `.fvmrc` (#33) | An exact pin in `pubspec.yaml` blocked newer local Flutter versions |

## 7. Where things live

- **Code layout and conventions:** `README.md` (Project Structure, Development Workflow).
- **CI/CD, environments, secrets, signing:** `docs/RELEASE_SETUP.md`.
- **Secret upload scripts:** `scripts/set-android-signing-secrets.sh`, `scripts/set-ios-secrets.sh`.
- **fastlane lanes:** `fastlane/Fastfile`; generated lane list in `fastlane/README.md`.
- **Secret originals:** the team Bitwarden vault (match passphrase, App Store Connect "Paypadi CI"
  key, the ios-certificates read token). Android upload keystores and their passwords are only on
  one Mac (`android/*.jks`, `android/key-*.properties`, git-ignored) and should be backed up there
  too.
- **People:** tech lead laolu-dev (GitHub). Org owner and Apple account holder: Olash, who also
  approves fine-grained tokens and owns the org-level settings.

## 8. Recent history

| PR | What it did |
|---|---|
| #17–#22 | Auth/session expiry, hardened core services, models matching the API, staging Firebase, transfer flow and credential storage, logout and 401 renewal |
| #25 | Medium-severity bugs and the `refactor` branch (biometric PIN vault, change password/PIN, PDF receipt, support links) |
| #26 | fastlane 2.240.1 and CI on Ruby 3.3 (cleared three Dependabot alerts) |
| #28 | `lib/` restructured into layers; provider registry split |
| #29 | Unlock required before protected routes; Home replaces the auth stack; restructure follow-ups |
| #30 | 5-minute background re-lock, driver guard enforced, photo fallbacks |
| #31 | Dark mode |
| #33 | CI on Flutter 3.47.5 |
| #23, #27, #32 | Dependabot updates |
