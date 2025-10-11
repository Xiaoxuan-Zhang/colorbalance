// lib/main.dart

import 'dart:typed_data';
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
  RuleAnalysis? _ruleAnalysis; // Store the 60-30-10 analysis
  Uint8List? _imageData;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickAndAnalyzeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
      _ruleAnalysis = null;
      _error = null;
    });

    try {
      final imageBytes = await pickedFile.readAsBytes();
      // Step 1: Get the initial color palette
      final palette = await analyzeImageInMemory(imageBytes: imageBytes);
      // Step 2: Pass the palette to our new 60-30-10 rule function
      final analysis = await analyze603010Rule(palette: palette);

      setState(() {
        _imageData = imageBytes;
        _ruleAnalysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error analyzing image: $e";
        _isLoading = false;
      });
    }
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
              if (_imageData != null)
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
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red))
              else if (_ruleAnalysis != null)
                // Display the new analysis widget
                RuleAnalysisDisplay(analysis: _ruleAnalysis!)
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

// New widget to display the 60-30-10 rule analysis
class RuleAnalysisDisplay extends StatelessWidget {
  final RuleAnalysis analysis;

  const RuleAnalysisDisplay({super.key, required this.analysis});

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              analysis.summary,
              style: textTheme.headlineSmall?.copyWith(
                color: analysis.isBalanced ? Colors.green.shade700 : Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildColorRow('Dominant (60%)', analysis.dominantHex, analysis.dominantPercentage, textTheme),
            _buildColorRow('Secondary (30%)', analysis.secondaryHex, analysis.secondaryPercentage, textTheme),
            _buildColorRow('Accent (10%)', analysis.accentHex, analysis.accentPercentage, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String role, String hex, double percentage, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: textTheme.titleMedium),
                Text(
                  'Actual: ${percentage.toStringAsFixed(1)}%',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(hex, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}