import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

// --- RUST BRIDGE IMPORTS ---
import 'src/rust/frb_generated.dart';
import 'src/rust/api.dart';

// --- GLOBAL CONFIGURATION ---
const int kAnalysisMaxDim = 600;      
const int kColorClusters = 5;         
const double kGlowBlurSigma = 30.0;   
const double kCoreBlurSigma = 5.0;    
const int kEdgeThickness = 3;         
const int kBackgroundDimAlpha = 180;  

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
      title: 'ColorBalance',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- SCREEN 1: HOME ---

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
      
      final decodedImage = await decodeImageFromList(bytes);
      final originalWidth = decodedImage.width.toDouble();
      final originalHeight = decodedImage.height.toDouble();

      final result = await analyzeImageMobile(
        imageBytes: bytes, 
        k: kColorClusters, 
        maxDim: kAnalysisMaxDim, 
        blurSigma: null 
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InspectorScreen(
              originalBytes: bytes, 
              result: result,
              imageWidth: originalWidth,
              imageHeight: originalHeight,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
        );
      }
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
                  const Icon(Icons.auto_awesome, size: 80, color: Colors.white24),
                  const SizedBox(height: 20),
                  const Text("Discover your palette", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text("Analyze Photo"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// --- SCREEN 2: INSPECTOR ---

class InspectorScreen extends StatefulWidget {
  final Uint8List originalBytes;
  final MobileResult result;
  final double imageWidth;
  final double imageHeight;

  const InspectorScreen({
    super.key,
    required this.originalBytes,
    required this.result,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  ui.Image? _dimmingImage;
  ui.Image? _edgeImage;
  bool _processing = false;
  
  late AnimationController _glowController;
  final GlobalKey _paletteKey = GlobalKey(); 

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2000)
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _selectColor(int index) async {
    if (_selectedIndex == index) {
      setState(() {
        _selectedIndex = null;
        _dimmingImage = null;
        _edgeImage = null;
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
      _processing = true;
    });

    final request = {
      'width': widget.result.width.toInt(),
      'height': widget.result.height.toInt(),
      'map': widget.result.segmentationMap,
      'target': index,
      'thickness': kEdgeThickness,
      'dimAlpha': kBackgroundDimAlpha,
    };

    final layers = await compute(generateLayers, request);

    final dimImg = await _createImageFromPixels(
      layers['dimming']!, 
      widget.result.width.toInt(), 
      widget.result.height.toInt()
    );
    
    final edgeImg = await _createImageFromPixels(
      layers['edges']!, 
      widget.result.width.toInt(), 
      widget.result.height.toInt()
    );

    if (mounted) {
      setState(() {
        _dimmingImage = dimImg;
        _edgeImage = edgeImg;
        _processing = false;
      });
    }
  }

  Future<ui.Image> _createImageFromPixels(Uint8List pixels, int width, int height) {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      pixels, width, height, ui.PixelFormat.rgba8888, 
      (img) => completer.complete(img),
    );
    return completer.future;
  }

  Future<void> _savePalette() async {
    try {
      RenderRepaintBoundary boundary = 
          _paletteKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/palette_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);
      await GallerySaver.saveImage(file.path);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved!")));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final selectedColorData = _selectedIndex != null 
        ? widget.result.dominantColors[_selectedIndex!] 
        : null;
    
    final uiColor = selectedColorData != null
        ? Color.fromARGB(255, selectedColorData.red, selectedColorData.green, selectedColorData.blue)
        : Colors.white;

    final coreColor = Colors.white.withOpacity(0.8);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download), 
            onPressed: _savePalette,
          )
        ],
      ),
      // FIX: We use a Stack here so the Spinner floats ON TOP of the layout
      // instead of inserting itself INTO the layout.
      body: Stack(
        children: [
          // THE MAIN LAYOUT
          Column(
            children: [
              // 1. IMAGE AREA
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    maxScale: 5.0,
                    child: AspectRatio(
                      aspectRatio: widget.imageWidth / widget.imageHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1A. Original Image
                          Image.memory(widget.originalBytes, fit: BoxFit.fill),

                          // 1B. Dimming Mask
                          if (_dimmingImage != null)
                            RawImage(image: _dimmingImage!, fit: BoxFit.fill),

                          // 1C. Neon Edges
                          if (_edgeImage != null)
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (_, __) {
                                final glowOpacity = 0.4 + (_glowController.value * 0.6);
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Opacity(
                                      opacity: glowOpacity,
                                      child: ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(sigmaX: kGlowBlurSigma, sigmaY: kGlowBlurSigma),
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(uiColor, BlendMode.srcATop),
                                          child: RawImage(image: _edgeImage!, fit: BoxFit.fill),
                                        ),
                                      ),
                                    ),
                                    Opacity(
                                      opacity: 0.9,
                                      child: ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(sigmaX: kCoreBlurSigma, sigmaY: kCoreBlurSigma),
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(coreColor, BlendMode.srcATop),
                                          child: RawImage(image: _edgeImage!, fit: BoxFit.fill),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. HUD AREA
              SizedBox(
                height: 100, 
                child: Center(
                  child: selectedColorData != null
                    ? TweenAnimationBuilder<double>(
                        key: ValueKey(selectedColorData.hex), 
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        builder: (context, val, _) {
                          return Transform.scale(
                            scale: val,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: uiColor, width: 1),
                                boxShadow: [BoxShadow(color: uiColor.withOpacity(0.3), blurRadius: 15)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${selectedColorData.percentage.toStringAsFixed(1)}%",
                                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 15),
                                  Container(width: 1, height: 30, color: Colors.white24),
                                  const SizedBox(width: 15),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("HEX CODE", style: TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1)),
                                      Text(
                                        selectedColorData.hex.toUpperCase(), 
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const Text("Select a color below", style: TextStyle(color: Colors.white38, fontSize: 14)),
                ),
              ),

              // 3. PALETTE RAIL
              Container(
                color: Colors.black, 
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 150, // Fixed height prevents layout shifts
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("PALETTE", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                        const SizedBox(height: 15),
                        RepaintBoundary(
                          key: _paletteKey,
                          child: Container(
                            color: Colors.black,
                            height: 90,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.result.dominantColors.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 20),
                              itemBuilder: (context, index) {
                                final c = widget.result.dominantColors[index];
                                final isSelected = _selectedIndex == index;
                                final color = Color.fromARGB(255, c.red, c.green, c.blue);
                                
                                return GestureDetector(
                                  onTap: () => _selectColor(index),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: isSelected ? 55 : 45,
                                        height: isSelected ? 55 : 45,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                          boxShadow: isSelected ? [BoxShadow(color: color, blurRadius: 10)] : null,
                                        ),
                                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${c.percentage.round()}%",
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // SPINNER OVERLAY
          // Positioned absolutely on top so it doesn't impact the column layout
          if (_processing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// --- BACKGROUND WORKER ---

Map<String, Uint8List> generateLayers(Map<String, dynamic> request) {
  final int width = request['width'];
  final int height = request['height'];
  final Uint8List map = request['map'];
  final int target = request['target'];
  final int thickness = request['thickness'];
  final int dimAlpha = request['dimAlpha'];

  final int length = width * height * 4;
  final Uint8List edgeBytes = Uint8List(length);
  final Uint8List dimmingBytes = Uint8List(length);

  bool isTarget(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return map[y * width + x] == target;
  }

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int i = y * width + x;
      final int offset = i * 4;

      if (map[i] == target) {
        dimmingBytes[offset + 3] = 0; 

        bool isEdge = false;
        outerLoop:
        for (int dy = -thickness; dy <= thickness; dy++) {
          for (int dx = -thickness; dx <= thickness; dx++) {
            if (!isTarget(x + dx, y + dy)) {
              isEdge = true;
              break outerLoop;
            }
          }
        }

        if (isEdge) {
          edgeBytes[offset] = 255; edgeBytes[offset+1] = 255; edgeBytes[offset+2] = 255;
          edgeBytes[offset + 3] = 255; 
        }
      } else {
        dimmingBytes[offset] = 0; dimmingBytes[offset+1] = 0; dimmingBytes[offset+2] = 0;
        dimmingBytes[offset + 3] = dimAlpha; 
        
        edgeBytes[offset + 3] = 0; 
      }
    }
  }

  return {'edges': edgeBytes, 'dimming': dimmingBytes};
}