## What changed

<!-- One or two sentences. Link the issue if there is one: Closes #123 -->

## Why

<!-- Context a reviewer needs that isn't obvious from the diff -->

## How I tested it

<!-- Manual steps, device/emulator, flavor (dev/prod), or test command output -->

## Screenshots / screen recording

<!-- Required for any UI change. Delete this section if the change is non-visual.
     This repo is public: blur balances, account numbers, names, emails and
     phone numbers in screenshots. -->

## Checklist

- [ ] PR title follows Conventional Commits (`feat(wallet): …`) — it becomes the squash commit message
- [ ] `dart format lib test`, `flutter analyze --fatal-infos` and `flutter test` pass locally
- [ ] No `ref.watch` after an `await` in async providers, no manual `state =` inside `build()`
- [ ] No `async void`, no force unwraps (`!`) introduced
- [ ] Notifiers don't hold `BuildContext` or call UI directly
- [ ] New/changed logic has test coverage where practical
- [ ] No generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`) committed — they're gitignored and CI regenerates them
- [ ] No secrets, keystores, `.env` files, tokens or real customer data added (code, tests, fixtures or screenshots)
- [ ] If this touches auth, payments, storage or networking: I've described the security impact under "Why"

## Review notes for reviewers

<!-- If this is a follow-up addressing prior feedback, say what changed since
     the last review so the reviewer only needs to check the new bits. -->
