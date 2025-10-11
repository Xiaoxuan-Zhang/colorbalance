// lib/main.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:colorbalance/src/rust/api/simple.dart';
import 'package:colorbalance/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColorBalance',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ColorAnalysisPage(),
    );
  }
}

class ColorAnalysisPage extends StatefulWidget {
  const ColorAnalysisPage({super.key});

  @override
  State<ColorAnalysisPage> createState() => _ColorAnalysisPageState();
}

class _ColorAnalysisPageState extends State<ColorAnalysisPage> {
  ImageAnalysisResult? _analysisResult;
  Uint8List? _imageData;
  bool _isLoading = false;
  String? _error;
  int? _selectedColorIndex; // To track which color to highlight

  Future<void> _pickAndAnalyzeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _error = null;
      _selectedColorIndex = null;
    });

    try {
      final imageBytes = await pickedFile.readAsBytes();
      // Call our Rust function that returns the full analysis
      final result = await analyzeImageInMemory(imageBytes: imageBytes);

      setState(() {
        _imageData = imageBytes;
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error analyzing image: $e";
        _isLoading = false;
      });
    }
  }

  void _onColorSelected(int index) {
    setState(() {
      // Toggle selection: if tapping the same color, deselect it.
      _selectedColorIndex = (_selectedColorIndex == index) ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Balance Analyzer'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_imageData != null && _analysisResult != null)
                // Use a Stack to overlay the highlight
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.memory(
                          _imageData!,
                          height: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (_selectedColorIndex != null)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: CustomPaint(
                              painter: HighlightPainter(
                                result: _analysisResult!,
                                selectedColorIndex: _selectedColorIndex!,
                              ),
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else if (_imageData != null)
                 Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.memory(_imageData!, height: 250, fit: BoxFit.contain),
                   ),
                 ),
              
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red))
              else if (_analysisResult != null)
                PaletteDisplay(
                  palette: _analysisResult!.palette,
                  onColorSelected: _onColorSelected,
                  selectedColorIndex: _selectedColorIndex,
                )
              else
                const Text('Select an image to analyze its color palette.'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndAnalyzeImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }
}

// Updated palette display to be interactive
class PaletteDisplay extends StatelessWidget {
  final List<ColorData> palette;
  final Function(int) onColorSelected;
  final int? selectedColorIndex;

  const PaletteDisplay({
    super.key,
    required this.palette,
    required this.onColorSelected,
    this.selectedColorIndex,
  });
  
  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: List.generate(palette.length, (index) {
          final colorData = palette[index];
          final color = _hexToColor(colorData.hex);
          final isSelected = selectedColorIndex == index;

          return GestureDetector(
            onTap: () => onColorSelected(index),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${colorData.hex} (${colorData.percentage.toStringAsFixed(2)}%)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}


// NEW: A CustomPainter to draw the highlight mask
class HighlightPainter extends CustomPainter {
  final ImageAnalysisResult result;
  final int selectedColorIndex;

  HighlightPainter({required this.result, required this.selectedColorIndex});
  
  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final selectedPaletteColorHex = result.palette[selectedColorIndex].hex;
    final highlightColor = _hexToColor(selectedPaletteColorHex).withOpacity(0.7);

    // Create a list of points (pixels) to draw
    final List<ui.Offset> points = [];
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final index = (y * result.width + x);
        final paletteIndex = result.pixelMap[index];
        
        // Check if the pixel's color is the one we want to highlight
        if (paletteIndex == selectedColorIndex) {
          // Scale the point from the thumbnail size to the display size
          final scaledX = (x / result.width) * size.width;
          final scaledY = (y / result.height) * size.height;
          points.add(ui.Offset(scaledX, scaledY));
        }
      }
    }
    
    paint.color = highlightColor;
    // Draw all the points at once. Adjust strokeWidth to change pixel size.
    canvas.drawPoints(ui.PointMode.points, points, paint..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}