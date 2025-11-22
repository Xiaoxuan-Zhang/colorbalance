import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// IMPORT 1: The generated Rust initialization code
import 'src/rust/frb_generated.dart'; 

// IMPORT 2: The generated API from api.rs
// (Check your lib/src/rust/api/ folder if this path is slightly different)
import 'src/rust/api.dart'; 

Future<void> main() async {
  // 1. Initialize the Rust Bridge
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepOrange),
      home: const ColorBalanceHome(),
    );
  }
}

class ColorBalanceHome extends StatefulWidget {
  const ColorBalanceHome({super.key});

  @override
  State<ColorBalanceHome> createState() => _ColorBalanceHomeState();
}

class _ColorBalanceHomeState extends State<ColorBalanceHome> {
  bool _loading = false;
  String? _statusMessage;
  
  // Data returned from Rust
  Uint8List? _resultImage; 
  List<MobileColor> _colors = [];

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() {
      _loading = true;
      _statusMessage = "Reading file...";
      _resultImage = null;
      _colors = [];
    });

    try {
      // 1. Read bytes (Dart side)
      final bytes = await image.readAsBytes();

      setState(() => _statusMessage = "Crunching numbers in Rust...");

      // 2. Call Rust (Wrapper -> Core)
      // Note: The snake_case 'analyze_image_mobile' becomes camelCase in Dart
      final result = await analyzeImageMobile(imageBytes: bytes, k: 5);
      
      setState(() {
        _resultImage = result.resultImage;
        _colors = result.dominantColors;
        _loading = false;
        _statusMessage = null;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        _loading = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ColorBalance Rust')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Action Button ---
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickAndAnalyze,
              icon: const Icon(Icons.image_search),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              label: Text(_loading ? 'Processing...' : 'Pick Image from Gallery'),
            ),
            
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_statusMessage!, textAlign: TextAlign.center),
              ),

            const SizedBox(height: 20),

            // --- Visualization Image ---
            if (_resultImage != null) ...[
              const Text("Visualization (From Core Engine):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_resultImage!, fit: BoxFit.contain),
              ),
              const SizedBox(height: 20),
            ],

            // --- Color Palette List ---
            if (_colors.isNotEmpty) ...[
              const Text("Dominant Colors:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._colors.map((color) => Card(
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, color.red, color.green, color.blue),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  title: Text(color.hex.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("R:${color.red} G:${color.green} B:${color.blue}"),
                  trailing: Text(
                    "${color.percentage.toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              )),
            ]
          ],
        ),
      ),
    );
  }
}