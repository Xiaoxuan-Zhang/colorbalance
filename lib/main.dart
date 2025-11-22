import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_lib; // For generating the mask
import 'src/rust/frb_generated.dart';
import 'src/rust/api.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark, // Dark mode looks better for color tools
      ),
      home: const HomeScreen(),
    );
  }
}

// --- SCREEN 1: The Picker ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() => _loading = true);

    try {
      final bytes = await image.readAsBytes();

      // Call Rust!
      // We use the defaults (maxDim=600, sigma=2.0) by passing null
      final result = await analyzeImageMobile(
        imageBytes: bytes, 
        k: 5, 
        maxDim: 600, // Optional: Override Rust default
        blurSigma: null // Optional: Use Rust default (2.0)
      );
      
      if (mounted) {
        // Navigate to the Inspector View
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ColorInspectorScreen(
              originalBytes: bytes,
              result: result,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ColorBalance")),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.color_lens, size: 80, color: Colors.teal),
                  const SizedBox(height: 20),
                  const Text(
                    "Analyze your photo's palette",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text("Pick Image from Gallery"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// --- SCREEN 2: The Interactive Inspector ---

class ColorInspectorScreen extends StatefulWidget {
  final Uint8List originalBytes;
  final MobileResult result;

  const ColorInspectorScreen({
    super.key,
    required this.originalBytes,
    required this.result,
  });

  @override
  State<ColorInspectorScreen> createState() => _ColorInspectorScreenState();
}

class _ColorInspectorScreenState extends State<ColorInspectorScreen> {
  int? _selectedIndex; // Null = Show Original, Int = Show Specific Color
  Uint8List? _maskBytes; // The overlay image
  bool _isGeneratingMask = false;

  @override
  void initState() {
    super.initState();
    // Select the dominant color (index 0) by default, or start null
    _selectedIndex = null; 
  }

  /// Generates a semi-transparent overlay where:
  /// - Pixels matching [targetIndex] are TRANSPARENT (Original photo shows through)
  /// - All other pixels are BLACK/DIMMED
  Future<void> _generateMask(int targetIndex) async {
    setState(() => _isGeneratingMask = true);

    // Run this in a microtask/compute to avoid freezing UI (though 600px is fast)
    // For simplicity here, we do it inline, but 'compute' is better for production.
    
    final width = widget.result.width.toInt();
    final height = widget.result.height.toInt();
    final map = widget.result.segmentationMap;
    
    // Create a blank image buffer
    final maskImage = img_lib.Image(width: width, height: height, numChannels: 4);

    // Loop through the Rust segmentation map
    for (int i = 0; i < map.length; i++) {
      // x and y are implicit from index i
      final x = i % width;
      final y = i ~/ width;

      if (map[i] == targetIndex) {
        // MATCH: Fully Transparent (Show the photo)
        maskImage.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        // NO MATCH: Dark Overlay (Dim the photo)
        // R=0, G=0, B=0, A=200 (out of 255)
        maskImage.setPixelRgba(x, y, 0, 0, 0, 200); 
      }
    }

    // Encode to PNG so Flutter's Image.memory can display it
    final pngBytes = img_lib.encodePng(maskImage);

    if (mounted) {
      setState(() {
        _maskBytes = pngBytes;
        _isGeneratingMask = false;
      });
    }
  }

  void _onColorTap(int index) {
    if (_selectedIndex == index) {
      // Deselect
      setState(() {
        _selectedIndex = null;
        _maskBytes = null;
      });
    } else {
      // Select new
      setState(() => _selectedIndex = index);
      _generateMask(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Grab the currently selected color data for the header
    final activeColor = _selectedIndex != null 
        ? widget.result.dominantColors[_selectedIndex!] 
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: activeColor == null 
          ? const Text("Original Image")
          : Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, activeColor.red, activeColor.green, activeColor.blue),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white)
                  ),
                ),
                const SizedBox(width: 10),
                Text("${activeColor.percentage.toStringAsFixed(1)}% Coverage"),
              ],
            ),
      ),
      body: Column(
        children: [
          // --- 1. THE CANVAS ---
          Expanded(
            child: Center(
              child: Stack(
                fit: StackFit.loose,
                alignment: Alignment.center,
                children: [
                  // Layer A: Original Image
                  Image.memory(
                    widget.originalBytes,
                    fit: BoxFit.contain,
                  ),

                  // Layer B: The Interactive Mask
                  // Only show if we have a mask and we aren't currently generating a new one
                  if (_maskBytes != null && !_isGeneratingMask)
                    Image.memory(
                      _maskBytes!,
                      fit: BoxFit.contain, // Matches Layer A exactly
                      gaplessPlayback: true,
                      // Use low quality to give it a slight "tech/pixel" feel 
                      // and ensure sharp boundaries on the mask
                      filterQuality: FilterQuality.low, 
                    ),
                    
                  if (_isGeneratingMask)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),

          // --- 2. THE PALETTE RAIL ---
          Container(
            height: 120,
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            color: const Color(0xFF1A1A1A),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: widget.result.dominantColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final c = widget.result.dominantColors[index];
                final isSelected = _selectedIndex == index;
                final colorObj = Color.fromARGB(255, c.red, c.green, c.blue);
                
                // Determine text color based on brightness
                final textColor = colorObj.computeLuminance() > 0.5 ? Colors.black : Colors.white;

                return GestureDetector(
                  onTap: () => _onColorTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 80 : 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorObj,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected 
                        ? [BoxShadow(color: colorObj.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)] 
                        : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${c.percentage.round()}%",
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                        if (isSelected)
                           Text(
                            c.hex.toUpperCase(),
                            style: TextStyle(color: textColor, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}