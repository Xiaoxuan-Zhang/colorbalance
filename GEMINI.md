# Gemini CLI Instructions for ColorBalance

Welcome to the ColorBalance project! This project is a Flutter application that integrates with Rust for performance-critical color analysis tasks, using `flutter_rust_bridge`. It also includes Python-based color analysis tools.

## Tech Stack
- **Frontend:** Flutter (Dart) with `flex_color_scheme`.
- **Backend/Native Logic:** Rust (via `flutter_rust_bridge`) using SLIC and K-Means.
- **Analysis Tools:** Python (Prototypes).
- **Project Structure:**
    - `lib/`: Flutter UI and Dart logic.
    - `rust/`: Rust crate for color analysis (`core.rs` for logic, `api.rs` for bridge).
    - `rust_builder/`: CargoKit integration for Flutter/Rust.
    - `colorbalance_python/`: Prototype/Analysis scripts in Python.

## Architectural Principles
- **Performance First:** Keep all heavy mathematical operations (clustering, image manipulation) in Rust.
- **Asynchronous Flow:** Use `analyze_image_stream` in Rust to push status updates and intermediate images back to Dart. Do not block the main UI thread.
- **Theming:** Use `Theme.of(context)` and `flex_color_scheme` definitions in `lib/main.dart`. Avoid hardcoded color values.

## Common Commands

### Workflow Automation
- `flutter_rust_bridge_codegen generate`: **REQUIRED** after any change to `rust/src/api.rs`.
- `dart run build_runner build --delete-conflicting-outputs`: Run this if Dart models or `freezed` classes change.

### Flutter
- `flutter run`: Run the application.
- `flutter test`: Run Dart/Flutter tests.
- `flutter pub get`: Fetch dependencies.

### Rust & flutter_rust_bridge
- `cd rust && cargo build`: Build the Rust library.
- `cd rust && cargo test`: Run Rust unit tests.

### Python
- `source colorbalance_python/.myvenv/bin/activate && pip install -r colorbalance_python/requirements.txt`: Setup Python environment.

## Engineering Standards

### Testing & Validation
- **Rust Logic:** Test all core algorithms in `rust/src/core.rs` using `cargo test`.
- **Integration:** Use `integration_test/` to verify the bridge communication and end-to-end pipeline.
- **Error Handling:** Use `anyhow::Result` in Rust. Surface errors to the UI via `BridgeEvent.Status` or specialized error events.

### Security & Safety
- Never commit `.env` files or API keys.
- Gemini will not stage or commit changes unless explicitly directed.

