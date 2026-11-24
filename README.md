# hesba

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CI

`.github/workflows/ci.yml` runs on every push to `main`/`master`, on every pull
request, and on demand. It checks:

- `flutter analyze --no-fatal-infos` and `flutter test` (Flutter 3.44.8)
- Firestore rules tests against the **local emulator only**
  (`rules_tests/`, no deploy and no production credentials)
- `node tool/check_i18n.js` (every translation key exists in `ar` and `en`)
- a guard that fails if a signing key or service account is ever committed

Run the same checks locally before pushing:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
node tool/check_i18n.js
npm ci --prefix rules_tests
firebase emulators:exec --only firestore --project hesba-business-demo \
  "npm --prefix rules_tests test"
```

`dart format` is intentionally not a CI gate yet: the existing codebase has
pre-existing formatting drift that would fail every build until it is cleaned
up in one pass.
