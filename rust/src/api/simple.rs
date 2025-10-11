// rust/src/api/simple.rs
use flutter_rust_bridge::frb;
use std::collections::HashMap;

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[derive(Debug)]
pub struct ColorData {
    pub hex: String,
    pub percentage: f32,
}

// NEW: A struct to hold the results of our rule analysis
#[derive(Debug)]
pub struct RuleAnalysis {
    pub dominant_hex: String,
    pub dominant_percentage: f32,
    pub secondary_hex: String,
    pub secondary_percentage: f32,
    pub accent_hex: String,
    pub accent_percentage: f32,
    pub is_balanced: bool,
    pub summary: String,
}

// This is our image analysis function from before
pub fn analyze_image_in_memory(image_bytes: Vec<u8>) -> Result<Vec<ColorData>, String> {
    let img = image::load_from_memory(&image_bytes)
        .map_err(|e| e.to_string())?
        .to_rgba8();

    let pixels = img.into_raw();
    let total_pixels = (pixels.len() / 4) as f32;

    let quantizer = color_quant::NeuQuant::new(10, 256, &pixels);

    let mut color_counts: HashMap<[u8; 4], u32> = HashMap::new();
    for chunk in pixels.chunks_exact(4) {
        let mut pixel = [chunk[0], chunk[1], chunk[2], chunk[3]];
        quantizer.map_pixel(&mut pixel);
        *color_counts.entry(pixel).or_insert(0) += 1;
    }

    let mut sorted_colors: Vec<_> = color_counts.into_iter().collect();
    sorted_colors.sort_by(|a, b| b.1.cmp(&a.1));

    let dominant_colors: Vec<ColorData> = sorted_colors
        .into_iter()
        .take(5)
        .map(|(rgba, count)| {
            ColorData {
                hex: format!("#{:02X}{:02X}{:02X}", rgba[0], rgba[1], rgba[2]),
                percentage: (count as f32 / total_pixels) * 100.0,
            }
        })
        .collect();
        
    Ok(dominant_colors)
}

// NEW: This function applies the 60-30-10 rule
pub fn analyze_60_30_10_rule(palette: Vec<ColorData>) -> Result<RuleAnalysis, String> {
    if palette.len() < 3 {
        return Err("Palette must contain at least 3 colors.".to_string());
    }

    // The palette is already sorted by percentage, so we can just take the top 3
    let dominant = &palette[0];
    let secondary = &palette[1];
    let accent = &palette[2];
    
    // Check if the ratios are within a reasonable tolerance (e.g., +/- 10%)
    let is_balanced = (50.0..=70.0).contains(&dominant.percentage) &&
                      (20.0..=40.0).contains(&secondary.percentage) &&
                      (5.0..=15.0).contains(&accent.percentage);

    let summary = if is_balanced {
        "Well Balanced".to_string()
    } else {
        "Unconventional Balance".to_string()
    };

    Ok(RuleAnalysis {
        dominant_hex: dominant.hex.clone(),
        dominant_percentage: dominant.percentage,
        secondary_hex: secondary.hex.clone(),
        secondary_percentage: secondary.percentage,
        accent_hex: accent.hex.clone(),
        accent_percentage: accent.percentage,
        is_balanced,
        summary,
    })
}