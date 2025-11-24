import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math'; 
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

import '../src/rust/api.dart';
import '../constants.dart';
import '../worker.dart';

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
            .showSnackBar(const SnackBar(content: Text("Saved!")));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar:
          MediaQuery.of(context).orientation == Orientation.portrait,
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
      body: Stack(
        children: [
          OrientationBuilder(
            builder: (context, orientation) {
              return orientation == Orientation.portrait
                  ? _buildPortraitLayout()
                  : _buildLandscapeLayout();
            },
          ),
          if (_processing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // --- LAYOUT: PORTRAIT ---
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: _buildImageStack()),
                _buildColorStrip(isHorizontal: true),
              ],
            ),
          ),
        ),
        _buildHud(),
        _buildPaletteRail(isHorizontal: true),
      ],
    );
  }

  // --- LAYOUT: LANDSCAPE ---
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: _buildImageStack()),
                _buildColorStrip(isHorizontal: true),
              ],
            ),
          ),
        ),
        Container(
          width: 160,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SafeArea(
            left: false,
            child: Column(
              children: [
                _buildHud(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildPaletteRail(isHorizontal: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- COMPONENT 1: IMAGE STACK ---
  Widget _buildImageStack() {
    final selectedColorData = _selectedIndex != null
        ? widget.result.dominantColors[_selectedIndex!]
        : null;

    final uiColor = selectedColorData != null
        ? Color.fromARGB(255, selectedColorData.red, selectedColorData.green,
            selectedColorData.blue)
        : Colors.white;

    final coreColor = Colors.white.withValues(alpha: 0.8);

    return InteractiveViewer(
      maxScale: 5.0,
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
                  final glowOpacity = 0.4 + (_glowController.value * 0.6);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: glowOpacity,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                              sigmaX: kGlowBlurSigma, sigmaY: kGlowBlurSigma),
                          child: ColorFiltered(
                            colorFilter:
                                ColorFilter.mode(uiColor, BlendMode.srcATop),
                            child: RawImage(
                                image: _edgeImage!, fit: BoxFit.fill),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 0.9,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                              sigmaX: kCoreBlurSigma, sigmaY: kCoreBlurSigma),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                                coreColor, BlendMode.srcATop),
                            child: RawImage(
                                image: _edgeImage!, fit: BoxFit.fill),
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
    );
  }

  // --- COMPONENT 2: COLOR STRIP ---
  Widget _buildColorStrip({required bool isHorizontal}) {
    return Container(
      height: 45,
      width: double.infinity,
      margin: const EdgeInsets.only(top: kColorStripTopMargin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.result.dominantColors.map((c) {
          return Expanded(
            flex: c.percentage.round(),
            child: Container(
              color: Color.fromARGB(255, c.red, c.green, c.blue),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- COMPONENT 3: HUD ---
  Widget _buildHud() {
    final selectedColorData = _selectedIndex != null
        ? widget.result.dominantColors[_selectedIndex!]
        : null;

    final uiColor = selectedColorData != null
        ? Color.fromARGB(255, selectedColorData.red, selectedColorData.green,
            selectedColorData.blue)
        : Colors.white;

    return SizedBox(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: uiColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                              color: uiColor.withValues(alpha: 0.3),
                              blurRadius: 15)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${selectedColorData.percentage.toStringAsFixed(1)}%",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(selectedColorData.hex.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                  );
                },
              )
            : const Text("Select a color",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14)),
      ),
    );
  }

  // --- COMPONENT 4: PALETTE RAIL (Adaptive) ---
  Widget _buildPaletteRail({required bool isHorizontal}) {
    Widget buildItem(int index) {
      final c = widget.result.dominantColors[index];
      final isSelected = _selectedIndex == index;
      final color = Color.fromARGB(255, c.red, c.green, c.blue);

      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isHorizontal ? 10 : 0,
            vertical: isHorizontal ? 0 : 10),
        child: GestureDetector(
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
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: color, blurRadius: 10)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
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
        ),
      );
    }

    final children = List.generate(
        widget.result.dominantColors.length, (index) => buildItem(index));

    if (isHorizontal) {
      // PORTRAIT: Fixed Height Row at bottom
      return Container(
        color: Colors.black,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("COLOR PALETTE",
                    style: TextStyle(
                        color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                const SizedBox(height: 15),
                RepaintBoundary(
                  key: _paletteKey,
                  child: Container(
                    color: Colors.black,
                    height: 90,
                    // KEY FIX: Using Row here ensures items are centered
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // LANDSCAPE: Vertical Column
      return RepaintBoundary(
        key: _paletteKey,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text("PALETTE",
                style: TextStyle(
                    color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );
    }
  }
}