use anyhow::Result;
use image::GenericImageView;
use crate::frb_generated::StreamSink; // Required for streams
use crate::core::{rgb_to_cmyk_string, lab_to_string, load_image_from_bytes, run_analysis_with_callback, AnalysisEvent};

// --- DART STREAM EVENTS ---
#[derive(Debug, Clone)]
pub enum BridgeEvent {
    Status(String),             // Text update
    DebugImage(Vec<u8>),        // Visual update
    Result(MobileResult),       // Final payload
}

#[derive(Debug, Clone)]
pub struct MobileColor {
    pub red: u8,
    pub green: u8,
    pub blue: u8,
    pub hex: String,
    pub percentage: f32,
    pub label: String,
    // NEW: Pre-calculated strings for the Flutter UI
    pub cmyk: String,
    pub lab: String,
}

#[derive(Debug, Clone)]
pub struct MobileResult {
    pub dominant_colors: Vec<MobileColor>,
    pub width: u32,
    pub height: u32,
    pub segmentation_map: Vec<u8>,
}

// --- STREAMING FUNCTION ---
// Returns Result<()> because the actual data is pushed to the 'sink'
pub fn analyze_image_stream(
    sink: StreamSink<BridgeEvent>, 
    image_bytes: Vec<u8>, 
    k: u32, 
    max_dim: Option<u32>, 
    blur_sigma: Option<f32>
) -> Result<()> {
    
    let img = load_image_from_bytes(&image_bytes)?;

    // Call the engine and hook into the callback
    let result = run_analysis_with_callback(
        img, 
        k as usize, 
        max_dim, 
        blur_sigma, 
        |event| {
            // Map Core Events to Bridge Events
            match event {
                AnalysisEvent::Status(msg) => {
                    sink.add(BridgeEvent::Status(msg)).unwrap();
                },
                AnalysisEvent::IntermediateImage(bytes) => {
                    sink.add(BridgeEvent::DebugImage(bytes)).unwrap();
                }
            }
        }
    )?;

    // --- PREPARE FINAL RESULT ---
    // This runs after the pipeline finishes
    let mobile_colors = result.clusters.iter().map(|c| {
        let r = c.rgba[0];
        let g = c.rgba[1];
        let b = c.rgba[2];

        MobileColor {
            red: r,
            green: g,
            blue: b,
            hex: c.hex.clone(),
            percentage: c.percentage,
            label: "".to_string(), // Can implement color naming later
            // Populate using the new helpers from core.rs
            cmyk: rgb_to_cmyk_string(r, g, b),
            lab: lab_to_string(c.lab),
        }
    }).collect();

    let map_u8: Vec<u8> = result.segmentation_map
        .iter()
        .map(|&id| id as u8)
        .collect();
    
    let (w, h) = result.processed_img.dimensions();

    // Push the final result to the stream
    sink.add(BridgeEvent::Result(MobileResult {
        dominant_colors: mobile_colors,
        width: w,
        height: h,
        segmentation_map: map_u8,
    })).unwrap();

    Ok(())
}