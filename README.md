# Paypadi

> A concise, engaging tagline or one-sentence description of the application.

---

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Architecture & Design Decisions](#architecture--design-decisions)
- [Key Packages & Libraries](#key-packages--libraries)
- [Code Generation](#code-generation)
- [Assets & Theming](#assets--theming)
- [Development Workflow](#development-workflow)
- [Environment & Configuration](#environment--configuration)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [Contact & Support](#contact--support)

---

## Overview

**Paypadi** is a mobile application built with **Flutter** and **Dart**. It aims to [clearly state the primary goal or problem the app solves].

### Key Features

- **[Feature 1]**
- **[Feature 2]**

---

## Getting Started

Follow these steps to get a working copy of the project on your local machine.

### Prerequisites

Ensure the following are installed before proceeding:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — version `3.x.x` or higher (Dart SDK `^3.9.0` required)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) (for iOS builds)
- A configured emulator or physical device

Verify your environment is ready by running:

```bash
flutter doctor
```

All checks should pass before continuing. Resolve any reported issues first.

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-org/paypadi.git
   cd paypadi
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run code generation** *(required before first run — see [Code Generation](#code-generation))*

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Set up environment variables** *(see [Environment & Configuration](#environment--configuration))*

5. **Run the application**

   ```bash
   flutter run
   ```

---

## Project Structure

The project combines a **layered architecture** at the core with a **feature-based structure** for UI modules. The `core/` layer owns all data and business logic; the `src/` layer owns all presentation. These two layers must remain strictly separate — presentation code never reaches into `core/` directly, and `core/` has no knowledge of UI.

```
lib/
├── config/                        # App-wide configuration
│   ├── gen/                       # Generated files — do not edit manually
│   │                              # (AppAssets, AppColors produced by flutter_gen)
│   ├── provider_registry/         # Riverpod provider registration & overrides
│   └── router/                    # AutoRoute route definitions and navigation guards
│
├── core/                          # Business logic and data layer
│   ├── api/                       # Dio HTTP client setup
│   │   ├── exceptions/            # Typed API exception classes
│   │   └── response/              # Standard API response wrappers
│   ├── datasource/                # Raw data access — one folder per domain
│   │   ├── authentication_ds/
│   │   ├── jwt_ds/                # JWT storage, refresh, and token management
│   │   ├── payout_account_ds/
│   │   ├── profile_ds/
│   │   ├── wallet_action_ds/
│   │   └── wallet_ds/
│   ├── models/                    # Freezed domain models (immutable data classes)
│   │   ├── account_payout_model/
│   │   ├── bank_account_model/
│   │   ├── bank_model/
│   │   ├── beneficiary_model/
│   │   ├── driver_model/
│   │   ├── transaction_model/
│   │   ├── user_model/
│   │   └── wallet_model/
│   ├── repositories/              # Repository interfaces + implementations
│   ├── services/                  # Higher-level business services
│   └── utils/                     # Shared utilities and helpers
│
└── src/
    ├── features/                  # Self-contained feature modules
    │   ├── authentication/
    │   │   ├── domain/            # Feature-specific use cases & logic
    │   │   └── presentation/
    │   │       ├── controller/    # Riverpod controllers for this feature
    │   │       ├── views/         # Screens and pages
    │   │       └── widgets/       # Widgets scoped to this feature only
    │   ├── home/
    │   ├── settings/
    │   └── transfer/
    └── shared/                    # Cross-feature UI components
        ├── controllers/           # Shared Riverpod controllers
        ├── views/
        │   ├── password/          # Reusable password entry flow
        │   └── transaction_pin/   # Reusable PIN entry flow
        └── widgets/               # Globally reusable UI components
```

### Where to Start

If you are new to the codebase, work through these layers in order:

1. **`config/router/`** — understand how screens are connected and how AutoRoute navigation guards are applied.
2. **`src/features/authentication/`** — trace the full flow from view → controller → repository → datasource for a concrete example.
3. **`core/api/`** — understand how Dio is configured, how errors are typed via `exceptions/`, and how all responses are normalised before reaching the rest of the app.
4. **`src/shared/`** — familiarise yourself with shared views and widgets before building new UI, to avoid duplicating existing components.

---

## Architecture & Design Decisions

### State Management

The application uses **Riverpod v3** (`hooks_riverpod`, `riverpod_annotation`, `riverpod_generator`) alongside **Flutter Hooks** for state management. Providers are code-generated using annotations — avoid writing providers by hand.

Key conventions:

- Business logic lives in providers (`controller/`), not in widgets or screens.
- Screens should only read state and call controller methods — no logic in `build()`.
- Use `AsyncNotifierProvider` for any operation involving a network call or async work.
- All providers are registered in `config/provider_registry/`. Register new providers there.
- **`riverpod_lint`** is active — run `flutter analyze` and resolve all lint warnings before committing.

### Data Flow

Data moves strictly in one direction:

```
View  →  Controller (Riverpod)  →  Repository  →  Datasource  →  Dio (API)
```

- **Views** consume providers via `ConsumerWidget` / `HookConsumerWidget` and dispatch events.
- **Controllers** call repositories, transform results, and expose `AsyncValue` state to the UI.
- **Repositories** (`core/repositories/`) define the contract for data operations. Always depend on the repository interface, not the datasource directly, so implementations can be swapped out in tests.
- **Datasources** (`core/datasource/`) contain Retrofit-annotated API clients and local storage calls.
- **API layer** (`core/api/`) configures Dio with interceptors and wraps all responses and errors in typed classes before they leave the layer.

### Navigation

Routing is handled by **AutoRoute v10** (`auto_route`, `auto_route_generator`). All route definitions live in `config/router/` and are code-generated — do not use `Navigator.push()` directly in screens.

Before adding a new screen:

1. Define the route in `config/router/`.
2. Run code generation to register it.
3. Apply any necessary route guards (auth check, PIN verification) at the router level, not inside the screen itself.

### JWT & Session Management

Token handling is fully isolated in `core/datasource/jwt_ds/`. This datasource handles storing, reading, and refreshing JWT tokens via `flutter_secure_storage`. Do not read or write tokens from controllers or views — always go through the repository layer.

### Logging

The app uses the **Talker** logging suite across three layers:

- `talker_dio_logger` — logs all HTTP requests and responses.
- `talker_riverpod_logger` — logs provider state changes.
- `talker_flutter` — surfaces logs in an in-app debug overlay during development.

Do not use `print()` — use the Talker instance from `core/utils/`. Logs are visible in the debug overlay during development.

---

## Key Packages & Libraries

| Package | Version | Purpose |
| :--- | :--- | :--- |
| `hooks_riverpod` | `^3.0.3` | State management with Flutter Hooks integration |
| `riverpod_annotation` | `^3.0.3` | Annotations for code-generated providers |
| `flutter_hooks` | `^0.21.2` | React-style hooks for widget lifecycle management |
| `auto_route` | `^10.3.0` | Declarative, code-generated routing |
| `dio` | `^5.8.0+1` | HTTP client |
| `retrofit` | `^4.4.2` | Type-safe REST API client (code-generated from annotations) |
| `freezed_annotation` | `^3.0.0` | Immutable model classes with `copyWith` and union types |
| `json_annotation` | `^4.9.0` | JSON serialisation annotations |
| `flutter_secure_storage` | `^10.0.0` | Encrypted storage for tokens and secrets |
| `shared_preferences` | `^2.5.3` | Lightweight storage for non-sensitive preferences |
| `local_auth` | `^3.0.0` | Biometric authentication (fingerprint / Face ID) |
| `talker_dio_logger` | `^5.0.0` | HTTP request/response logging |
| `talker_riverpod_logger` | `^5.0.0` | Provider state change logging |
| `talker_flutter` | `^5.0.0` | In-app debug log viewer |
| `flutter_svg` | `^2.0.10+1` | SVG asset rendering |
| `flutter_screenutil` | `^5.9.3` | Responsive sizing utilities |
| `toastification` | `^3.0.3` | In-app toast and notification messages |
| `skeletonizer` | `^2.1.2` | Skeleton loading screens |
| `loading_animation_widget` | `^1.3.0` | Loading state animations |
| `mobile_scanner` | `^7.1.3` | QR code and barcode scanning |
| `pretty_qr_code` | `^3.5.0` | QR code generation and display |
| `screenshot` | `^3.0.0` | Capture widgets as images |
| `flutter_to_pdf` | `^0.4.1` | Export widget trees to PDF |
| `share_plus` | `^12.0.1` | Native share sheet integration |
| `image_gallery_saver_plus` | `^4.0.1` | Save images to device gallery |
| `path_provider` | `^2.1.5` | Access to filesystem directories |
| `package_info_plus` | `^9.0.0` | Read app version and build number at runtime |
| `pin_code_text_field` | `^1.8.0` | PIN / OTP input field |
| `icons_plus` | `^5.0.0` | Extended icon set |
| `flutter_launcher_icons` | `^0.14.4` | App icon generation |
| `flutter_native_splash` | `^2.4.6` | Native splash screen configuration |

All dependencies are declared in `pubspec.yaml`. Run `flutter pub get` after any changes to this file.

---

## Code Generation

This project relies heavily on code generation. The output of the generators must be committed and kept up to date. The following tools run via `build_runner`:

| Generator | Produces |
| :--- | :--- |
| `riverpod_generator` | Riverpod provider classes from `@riverpod` annotations |
| `retrofit_generator` | Retrofit API client implementations from annotated interfaces |
| `auto_route_generator` | AutoRoute router and route classes (`*.gr.dart`) |
| `freezed` | Immutable model classes, `copyWith`, union types (`*.freezed.dart`) |
| `json_serializable` | `fromJson` / `toJson` methods (`*.g.dart`) |
| `flutter_gen_runner` | `AppAssets` and `AppColors` in `lib/gen/` |

### Running code generation

**One-time build** — use after pulling changes or adding newly annotated files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Watch mode** — use during active development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

> Never edit generated files by hand (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `lib/gen/`). Your changes will be overwritten on the next build. If a generated file looks wrong, fix the source annotation and re-run the generator.

---

## Assets & Theming

### Assets

Assets are organised into three directories and declared in `pubspec.yaml`:

```text
assets/
├── icons/           # Icon assets (SVG preferred — rendered via flutter_svg)
├── images/          # Raster images (PNG, JPG)
├── illustrations/   # Illustration assets
└── colors.xml       # Design system colour definitions
```

Access all assets through the generated `AppAssets` class — never use raw string paths in code. After adding a new asset file, re-run build_runner to regenerate `AppAssets`.

### Colours

Colours are defined in `assets/colors.xml` and accessed via the generated `AppColors` class. To add or change a colour, edit `colors.xml` and re-run build_runner. Do not hardcode `Color(0xFF...)` values anywhere in UI code.

### Typography

The app ships with two font families declared in `pubspec.yaml`:

- **Poppins** (weights 200–700) — primary display and heading font.
- **Manrope** (weights 300–700) — body and UI text font.

Reference fonts through theme text styles rather than specifying `fontFamily` directly on `Text` widgets.

---

## Development Workflow

### Branching Strategy

- `main` — stable, production-ready code. Do not commit directly.
- `develop` — active integration branch. Branch off here for all new work.
- `feature/your-feature-name` — individual feature branches.
- `fix/issue-description` — bug fix branches.

### Commit Conventions

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```text
feat: add transfer confirmation screen
fix: resolve null pointer on login
chore: update hooks_riverpod to 3.x
codegen: regenerate routes after adding settings screen
```

### Before Committing

Run the following and resolve all issues before opening a pull request:

```bash
flutter analyze                                              # Zero issues required (riverpod_lint is active)
dart run build_runner build --delete-conflicting-outputs     # Generated files must be current
flutter test                                                 # All tests must pass
```

### Pull Requests

- All changes must go through a pull request into `develop`.
- PRs require at least one review before merging.
- Include generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`) in your commit — do not gitignore them.

---

## Environment & Configuration

The app uses environment-specific configuration for API base URLs, keys, and feature flags. **Never commit secrets or API keys to the repository.**

1. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

2. Fill in the required values. Reach out to a team member or check the shared secrets manager for the correct credentials.

3. Use the configurations in launch.json to run the app in `dev` or `prod` mode.

---

## Testing

Run the full test suite with:

```bash
flutter test
```

### Test Structure

```pseudocode
test/
├── unit/           # Tests for repositories, services, and utilities
├── widget/         # Widget rendering and interaction tests
└── integration/    # End-to-end flows (if applicable)
```

When writing tests, mock at the **repository boundary** — inject mock repositories via Riverpod provider overrides. Do not mock datasources or Dio directly.

When adding new features, aim to cover the happy path, error states (`AsyncError`), and loading states (`AsyncLoading`) before submitting a pull request.

---

## Deployment

*Describe the release process — how builds are produced for staging vs. production, how to trigger the CI/CD pipeline, and where builds are distributed (TestFlight, Firebase App Distribution, Google Play internal track).*

```bash
# Build a release APK
flutter build apk --release

# Build a release App Bundle (preferred for Play Store)
flutter build appbundle --release

# Build for iOS
flutter build ipa --release
```

If launcher icons or the splash screen have changed, regenerate them before producing a release build:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Contributing

1. Pick up or create a ticket in the project tracker.
2. Branch off `develop` using the naming conventions above.
3. Run code generation if you have added or modified any annotated files.
4. Write code and corresponding tests, then verify with `flutter analyze` and `flutter test`.
5. Open a pull request with a clear description of the change and the reasoning behind it.
6. Address review feedback and obtain at least one approval before merging.

If you are unsure about an architectural decision or where a piece of logic belongs, ask in the team channel before building — it is faster than a rework after review.

---

## Contact & Support

For questions about the codebase, onboarding issues, or access requests, reach out to:

**Olaoluwa** — Mobile App Developer  
[Portfolio](https://laolu-dev.github.io/my-portfolio/) · [LinkedIn](https://www.linkedin.com/in/laolu-dev) · [tokiolaoluwa01.dev@gmail.com](mailto:tokiolaoluwa01.dev@gmail.com)
