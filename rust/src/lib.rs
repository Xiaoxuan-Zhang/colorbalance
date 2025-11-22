// src/lib.rs

// 1. Register the Core Module (The engine)
// We make it public so main.rs can access it.
pub mod core;

// 2. Register the API Module (The wrapper)
// We make it public so Flutter Bridge can find it.
pub mod api;