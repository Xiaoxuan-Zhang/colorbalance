# Project instructions for ColorBalance

## Project overview

ColorBalance is a Flutter application for image color analysis. Performance-critical
analysis runs in Rust through `flutter_rust_bridge`. Python scripts support
prototyping and analysis.

## Project structure

- `lib/`: Flutter UI and Dart logic; screens are in `lib/screens/`.
- `lib/main.dart`: App setup and theme definitions using `flex_color_scheme`.
- `rust/src/core.rs`: Core color analysis, including SLIC and K-Means.
- `rust/src/api.rs`: Rust API exposed to Dart.
- `lib/src/rust/` and `rust/src/frb_generated.rs`: Generated bridge bindings.
- `flutter_rust_bridge.yaml`: Bridge code generation configuration.
- `rust_builder/`: CargoKit integration for Flutter and Rust.
- `colorbalance_python/`: Python prototypes and analysis scripts.
- `integration_test/`: Bridge and end-to-end integration tests.

## Architecture and coding conventions

- Keep heavy mathematical operations, clustering, and image manipulation in Rust.
- Use `analyze_image_stream` to send status updates and intermediate images to Dart.
  Do not block the Flutter UI thread.
- Use `Theme.of(context)` and the theme definitions in `lib/main.dart`; avoid
  hardcoded UI colors.
- Use `anyhow::Result` for Rust errors. Surface failures to the UI through
  `BridgeEvent.Status` or specialized error events, following the existing API.
- Edit bridge source definitions and regenerate bindings instead of manually
  editing generated bridge files.

## Development commands

Run commands from the repository root unless otherwise specified.

- Fetch Flutter dependencies: `flutter pub get`.
- Run the app: `flutter run` (select a target device as needed).
- Analyze Dart code: `flutter analyze`.
- Run Flutter unit/widget tests: `flutter test` when such tests exist.
- Run integration tests: `flutter test integration_test/` with a supported device.
- Build Rust: `cargo build --manifest-path rust/Cargo.toml`.
- Run Rust tests: `cargo test --manifest-path rust/Cargo.toml`.
- After any change to `rust/src/api.rs`, run
  `flutter_rust_bridge_codegen generate`. Keep the code generator compatible with
  the project's pinned `flutter_rust_bridge` version.
- When Dart models or Freezed classes change, run
  `dart run build_runner build --delete-conflicting-outputs`.
- For Python work, activate `colorbalance_python/.myvenv/bin/activate` if present,
  then install dependencies using
  `pip install -r colorbalance_python/requirements.txt`.

## Validation and workflow

- Add or update meaningful Rust tests for changes to core algorithms.
- Use integration tests for changes to bridge communication or the end-to-end
  analysis pipeline.
- Run validation relevant to the changed code. Report what ran and any checks
  blocked by missing tools, dependencies, or a target device.
- Preserve existing user edits and keep changes focused on the requested task.
- Never commit `.env` files or API keys.
- Do not stage or commit changes unless explicitly requested.

## Maintaining these instructions

Keep this file current when architecture, commands, or conventions change.
`GEMINI.md` contains equivalent guidance for Gemini; keep shared project rules
consistent when updating either file.
