// rust/src/api/simple.rs
use flutter_rust_bridge::frb;
use std::collections::HashMap;
use image::imageops::FilterType;

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[derive(Debug)]
pub struct ColorData {
    pub hex: String,
    pub percentage: f32,
}

// NEW: This struct will hold the full analysis, including the pixel map.
#[derive(Debug)]
pub struct ImageAnalysisResult {
    pub palette: Vec<ColorData>,
    pub pixel_map: Vec<u32>, // A flat list of indices pointing to the palette
    pub width: u32,
    pub height: u32,
}

// We've removed the HSL logic for now to focus on highlighting the current algorithm's results.
pub fn analyze_image_in_memory(image_bytes: Vec<u8>) -> Result<ImageAnalysisResult, String> {
    let img = image::load_from_memory(&image_bytes)
        .map_err(|e| e.to_string())?
        .to_rgba8();

    let thumbnail = image::imageops::resize(&img, 100, 100, FilterType::Gaussian);
    let blurred = image::imageops::blur(&thumbnail, 2.0);
    
    let (width, height) = blurred.dimensions();
    let pixels = blurred.into_raw();
    let total_pixels = (pixels.len() / 4) as f32;

    let quantizer = color_quant::NeuQuant::new(10, 256, &pixels);

    // Get the palette as an array of RGBA values
    let palette_rgba: Vec<[u8; 4]> = quantizer.color_map_rgba()
        .chunks_exact(4)
        .map(|c| [c[0], c[1], c[2], c[3]])
        .collect();

    // Create a map from each palette color to its index (0, 1, 2, etc.)
    let color_to_palette_index: HashMap<[u8; 4], u32> = palette_rgba
        .iter()
        .enumerate()
        .map(|(i, &color)| (color, i as u32))
        .collect();

    let mut color_counts: HashMap<[u8; 4], u32> = HashMap::new();
    let mut pixel_map: Vec<u32> = Vec::with_capacity((width * height) as usize);

    for chunk in pixels.chunks_exact(4) {
        let mut pixel = [chunk[0], chunk[1], chunk[2], chunk[3]];
        quantizer.map_pixel(&mut pixel); // Find the closest palette color
        
        *color_counts.entry(pixel).or_insert(0) += 1;
        
        // Find the index of this pixel's color in our palette
        let palette_index = color_to_palette_index.get(&pixel).unwrap_or(&0);
        pixel_map.push(*palette_index);
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
        
    Ok(ImageAnalysisResult {
        palette: dominant_colors,
        pixel_map,
        width,
        height,
    })
}


// The 60-30-10 rule function is temporarily removed to simplify this step.
// We will add it back later.