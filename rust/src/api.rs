use anyhow::Result;
use image::GenericImageView;
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
    pub width: u32,
    pub height: u32,
    pub segmentation_map: Vec<u8>,
}

// --- WRAPPER FUNCTION ---

pub fn analyze_image_mobile(
    image_bytes: Vec<u8>, 
    k: u32, 
    max_dim: Option<u32>, 
    blur_sigma: Option<f32>
) -> Result<MobileResult> {
    // 1. Adapt Input: Bytes -> DynamicImage
    let img = load_image_from_bytes(&image_bytes)?;

    // 2. Call Generic Engine (lib.rs)
    let result = run_analysis(img, k as usize, max_dim, blur_sigma)?;

    // 3. Adapt Output: Generic Cluster -> MobileColor
    let mobile_colors = result.clusters.iter().map(|c| MobileColor {
        hex: c.hex.clone(),
        percentage: c.percentage,
        red: c.rgba[0],
        green: c.rgba[1],
        blue: c.rgba[2],
    }).collect();

    // 4. Optimize Map (usize -> u8)
    // We do this conversion here to save bandwidth across the bridge
    let map_u8: Vec<u8> = result.segmentation_map
        .iter()
        .map(|&id| id as u8)
        .collect();
    
    let (w, h) = result.processed_img.dimensions();

    Ok(MobileResult {
        dominant_colors: mobile_colors,
        width: w,
        height: h,
        segmentation_map: map_u8,
    })
}