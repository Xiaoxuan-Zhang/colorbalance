import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math'; 
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

import '../src/rust/api.dart';
import '../constants.dart';
import '../worker.dart';

// --- UI STYLE CONFIGURATION (Linked Values) ---
class InspectorStyle {
  // 1. Colors
  static const Color scaffoldBackground = Color(0xFF121212); // Matte Black
  static const Color drawerBackground = Color(0xFF1E1E1E);   // Dark Gray Drawer
  
  // 2. Drawer Dimensions
  static const double drawerRadius = 24.0;
  static const double drawerPaddingHorz = 24.0;
  static const double drawerPaddingTop = 20.0;
  static const double drawerPaddingBottom = 10.0;
  
  // 3. Component Sizes
  static const double dnaStripHeight = 32.0;
  static const double dnaStripRadius = 4.0;
  
  static const double infoPanelHeight = 50.0;
  
  static const double swatchRailHeight = 90.0;
  static const double swatchSizeSelected = 60.0;
  static const double swatchSizeUnselected = 50.0;
  
  // 4. Spacing (Linking vertical gaps)
  static const double sectionSpacing = 24.0; // Consistent gap between elements
}

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

class _InspectorScreenState extends State<InspectorScreen>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 2000),
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
      widget.result.height.toInt(),
    );

    final edgeImg = await _createImageFromPixels(
      layers['edges']!,
      widget.result.width.toInt(),
      widget.result.height.toInt(),
    );

    if (mounted) {
      setState(() {
        _dimmingImage = dimImg;
        _edgeImage = edgeImg;
        _processing = false;
      });
    }
  }

  Future<ui.Image> _createImageFromPixels(
      Uint8List pixels, int width, int height) {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );
    return completer.future;
  }

  Future<void> _savePalette() async {
    try {
      RenderRepaintBoundary boundary = _paletteKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/palette_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);
      await GallerySaver.saveImage(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Palette Saved to Photos")));
      }
    } catch (_) {}
  }

  void _copyHex(String hex) {
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Colors.grey[900],
          content: Text("Copied $hex", textAlign: TextAlign.center),
          duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InspectorStyle.scaffoldBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white70),
            onPressed: _savePalette,
            tooltip: "Export Palette",
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- 1. HERO IMAGE CANVAS ---
              Expanded(
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: widget.imageWidth / widget.imageHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(widget.originalBytes, fit: BoxFit.fill),
                          if (_dimmingImage != null)
                            RawImage(image: _dimmingImage!, fit: BoxFit.fill),
                          if (_edgeImage != null)
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (_, __) {
                                final glowOpacity =
                                    0.4 + (_glowController.value * 0.6);
                                final selectedData = widget
                                    .result.dominantColors[_selectedIndex!];
                                final uiColor = Color.fromARGB(
                                    255,
                                    selectedData.red,
                                    selectedData.green,
                                    selectedData.blue);

                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Glow Layer
                                    Opacity(
                                      opacity: glowOpacity,
                                      child: ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(
                                            sigmaX: kGlowBlurSigma,
                                            sigmaY: kGlowBlurSigma),
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.mode(
                                              uiColor, BlendMode.srcATop),
                                          child: RawImage(
                                              image: _edgeImage!,
                                              fit: BoxFit.fill),
                                        ),
                                      ),
                                    ),
                                    // Core Layer
                                    Opacity(
                                      opacity: 0.9,
                                      child: ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(
                                            sigmaX: kCoreBlurSigma,
                                            sigmaY: kCoreBlurSigma),
                                        child: ColorFiltered(
                                          colorFilter: const ColorFilter.mode(
                                              Colors.white, BlendMode.srcATop),
                                          child: RawImage(
                                              image: _edgeImage!,
                                              fit: BoxFit.fill),
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

              // --- 2. THE DESIGNER'S DRAWER ---
              Container(
                decoration: const BoxDecoration(
                  color: InspectorStyle.drawerBackground, 
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(InspectorStyle.drawerRadius),
                    topRight: Radius.circular(InspectorStyle.drawerRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        InspectorStyle.drawerPaddingHorz, 
                        InspectorStyle.drawerPaddingTop, 
                        InspectorStyle.drawerPaddingHorz, 
                        InspectorStyle.drawerPaddingBottom
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A. DNA Strip (Using linked consts)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(InspectorStyle.dnaStripRadius),
                          child: SizedBox(
                            height: InspectorStyle.dnaStripHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.result.dominantColors.map((c) {
                                return Expanded(
                                  flex: c.percentage.round(),
                                  child: Container(
                                    color: Color.fromARGB(
                                        255, c.red, c.green, c.blue),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: InspectorStyle.sectionSpacing),

                        // B. Info Panel
                        _buildInspectorInfo(),

                        const SizedBox(height: InspectorStyle.sectionSpacing),

                        // C. Swatch Rail
                        _buildSwatchRail(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_processing) const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  // --- INFO PANEL ---
  Widget _buildInspectorInfo() {
    final selectedData = _selectedIndex != null
        ? widget.result.dominantColors[_selectedIndex!]
        : null;

    if (selectedData == null) {
      return SizedBox(
        height: InspectorStyle.infoPanelHeight,
        child: Center(
          child: Text(
            "Tap a swatch to analyze",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: InspectorStyle.infoPanelHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hex Code
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "HEX CODE",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _copyHex(selectedData.hex),
                child: Row(
                  children: [
                    Text(
                      selectedData.hex.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ],
          ),

          // Right: Percentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "COVERAGE",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${selectedData.percentage.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SWATCH RAIL ---
  Widget _buildSwatchRail() {
    return RepaintBoundary(
      key: _paletteKey,
      child: Container(
        color: InspectorStyle.drawerBackground, // Linked to drawer color!
        height: InspectorStyle.swatchRailHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.result.dominantColors.asMap().entries.map((entry) {
            final index = entry.key;
            final c = entry.value;
            final isSelected = _selectedIndex == index;
            final color = Color.fromARGB(255, c.red, c.green, c.blue);

            // Dynamic size based on constants
            final size = isSelected 
                ? InspectorStyle.swatchSizeSelected 
                : InspectorStyle.swatchSizeUnselected;

            return GestureDetector(
              onTap: () => _selectColor(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: size,
                height: size * 1.3, // Taller aspect ratio for "Swatches"
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ]
                      : [],
                ),
                child: isSelected
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            width: 4, height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}