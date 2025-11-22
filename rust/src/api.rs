use anyhow::Result;
use crate::core::{load_image_from_bytes, run_analysis};

// --- MOBILE-SPECIFIC STRUCTS (Simple types for Dart) ---

#[derive(Debug, Clone)]
pub struct MobileColor {
    pub hex: String,
    pub percentage: f32,
    pub red: u8,
    pub green: u8,
    pub blue: u8,
}

#[derive(Debug, Clone)]
pub struct MobileResult {
    pub dominant_colors: Vec<MobileColor>,
    pub result_image: Vec<u8>, // PNG bytes for Flutter Image.memory()
}

// --- WRAPPER FUNCTION ---

pub fn analyze_image_mobile(image_bytes: Vec<u8>, k: usize) -> Result<MobileResult> {
    // 1. Adapt Input: Bytes -> DynamicImage
    let img = load_image_from_bytes(&image_bytes)?;

    // 2. Call Generic Engine (lib.rs)
    let (clusters, vis_bytes) = run_analysis(img, k)?;

    // 3. Adapt Output: Generic Cluster -> MobileColor
    let mobile_colors = clusters.iter().map(|c| MobileColor {
        hex: c.hex.clone(),
        percentage: c.percentage,
        red: c.rgba[0],
        green: c.rgba[1],
        blue: c.rgba[2],
    }).collect();

    Ok(MobileResult {
        dominant_colors: mobile_colors,
        result_image: vis_bytes,
    })
}