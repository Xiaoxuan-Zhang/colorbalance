use anyhow::Result;
use clap::Parser;
use palette::Lab;
use std::path::Path;
use std::fs;

// Import everything we need from our generic library
use color_balance::core::{
    load_image_from_path, run_analysis, generate_output_path, ColorCluster
};

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    path: String,

    #[arg(short, long, default_value_t = 5)]
    k: usize,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let file_path = Path::new(&args.path);

    println!("--- Starting Analysis ---");
    
    // 1. Load Image (using Lib)
    println!("Loading image: {:?}", file_path);
    let img = load_image_from_path(file_path)?;

    // 2. Run Generic Analysis Pipeline
    // This handles Preprocess -> SLIC -> Cluster -> Merge -> Map -> Vis
    println!("Running pipeline (k={})...", args.k);
    let (final_clusters, vis_bytes) = run_analysis(img, args.k)?;

    // 3. Print Report (CLI Specific Duty)
    // The library gave us the data, we decide how to format it for the user here.
    println!("\n--- 60-30-10 Rule Evaluation ---");
    let targets = [60.0, 30.0, 10.0];
    let tolerance = 8.0;
    let labels = ["Dominant ", "Secondary", "Accent   "];

    let mut top3 = final_clusters.iter().take(3).cloned().collect::<Vec<_>>();
    while top3.len() < 3 {
        top3.push(ColorCluster { 
            lab: Lab::new(0.0,0.0,0.0), count: 0, percentage: 0.0, hex: "#000000".to_string(), rgba: [0,0,0,255]
        });
    }

    for (i, target) in targets.iter().enumerate() {
        let actual = top3[i].percentage;
        let status = if (actual - target).abs() <= tolerance { "✅" } else { "❌" };
        println!("  {}: Target {:.0}% | Actual {:.1}% {} | Color: {}", labels[i], target, actual, status, top3[i].hex);
    }

    // 4. Save Visualization
    let output_path = generate_output_path(file_path);
    println!("\nSaving visualization to: {:?}", output_path);
    fs::write(&output_path, vis_bytes)?;

    Ok(())
}