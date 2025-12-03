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

// --- VISUAL TUNING ---
// Reduced max blur to prevent "foggy" look
const double kMaxBlur = 8.0;
const double kMinBlur = 2.0;

// --- RIPPLE ANIMATION TUNING ---
const Duration kRippleDuration = Duration(milliseconds: 2000); // Speed of the wave
const double kRippleStartScale = 0.9; // <--- THIS CONTROLS STARTING RADIUS (1.0 = Button Size)
const double kRippleEndScale = 1.2;   // How far it expands (1.6 = 160% size)

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
  bool _showTechPanel = false;
  bool _hasInteracted = false; // Track if user has clicked yet

  ui.Image? _dimmingImage;
  ui.Image? _edgeImage;
  bool _processingGlow = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _selectColor(int index) async {
    // Mark interaction as happened to stop the hint animation
    if (!_hasInteracted) {
      setState(() => _hasInteracted = true);
    }

    if (_selectedIndex == index) {
      setState(() {
        _selectedIndex = null;
        _dimmingImage = null;
        _edgeImage = null;
        _processingGlow = false;
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
      _processingGlow = true;
    });

    final request = {
      'width': widget.result.width.toInt(),
      'height': widget.result.height.toInt(),
      'map': widget.result.segmentationMap,
      'target': index,
      'thickness': kEdgeThickness,
      'dimAlpha': kBackgroundDimAlpha,
    };

    try {
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
        // Check if selection changed while processing
        if (_selectedIndex == index) {
          setState(() {
            _dimmingImage = dimImg;
            _edgeImage = edgeImg;
            _processingGlow = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error generating masks: $e");
      if (mounted) {
        setState(() => _processingGlow = false);
      }
    }
  }

  Future<ui.Image> _createImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);

    final displayColors = widget.result.dominantColors.take(5).toList();

    MobileColor? activeColorData;
    Color? activeColor;

    if (_selectedIndex != null) {
      activeColorData = widget.result.dominantColors[_selectedIndex!];
      activeColor = Color.fromARGB(
        255,
        activeColorData.red,
        activeColorData.green,
        activeColorData.blue,
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // --- LAYER 1: IMAGE ---
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(child: _buildImageStack(activeColor)),
            ),
          ),

          // --- LAYER 2: TOP NAVIGATION ---
          Positioned(
            top: 0,
            left: 0,
            right: isLandscape ? 100 : 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (_selectedIndex != null)
                    _GlassButton(
                      icon: Icons.tune,
                      label: "Data",
                      onTap: () => setState(() => _showTechPanel = true),
                    )
                  else
                    const SizedBox(),
                ],
              ),
            ),
          ),

          // --- LAYER 3: FLOATING HUD ---
          if (activeColorData != null && activeColor != null)
            isLandscape
                ? Positioned(
                    // LANDSCAPE: Align Left to avoid blocking center image
                    top: topPadding + 80,
                    left: 24,
                    child: _FloatingHud(
                      color: activeColor,
                      hex: activeColorData.hex,
                      percentage: activeColorData.percentage,
                    ),
                  )
                : Positioned(
                    // PORTRAIT: Top Center alignment
                    top: topPadding + 90,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _FloatingHud(
                        color: activeColor,
                        hex: activeColorData.hex,
                        percentage: activeColorData.percentage,
                      ),
                    ),
                  ),

          // --- LAYER 4: FLOATING PALETTE RAIL ---
          if (isLandscape)
            Positioned(
              right: 24,
              top: 24,
              bottom: 24,
              width: 90,
              child: _SideRail(
                colors: displayColors,
                selectedIndex: _selectedIndex,
                hasInteracted: _hasInteracted,
                onSelect: _selectColor,
              ),
            )
          else
            Positioned(
              left: 24,
              right: 24,
              bottom: 34,
              height: 110,
              child: _BottomRail(
                colors: displayColors,
                selectedIndex: _selectedIndex,
                hasInteracted: _hasInteracted,
                onSelect: _selectColor,
              ),
            ),

          // --- LAYER 5: TECH PANEL ---
          if (_showTechPanel && activeColorData != null && activeColor != null)
            _TechPanelOverlay(
              isLandscape: isLandscape,
              colorData: activeColorData,
              uiColor: activeColor,
              onClose: () => setState(() => _showTechPanel = false),
            ),

          if (_processingGlow)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildImageStack(Color? activeColor) {
    return AspectRatio(
      aspectRatio: widget.imageWidth / widget.imageHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base Image
          Image.memory(widget.originalBytes, fit: BoxFit.fill),

          // 2. Dimming Layer (Targeted darkness)
          if (_dimmingImage != null)
            Opacity(
              opacity: 0.5, // Allows background to remain visible but receded
              child: RawImage(image: _dimmingImage!, fit: BoxFit.fill),
            ),

          // 3. Highlight Lines (Pop)
          if (_edgeImage != null && activeColor != null)
            AnimatedBuilder(
              animation: _glowController,
              builder: (_, __) {
                final pulse = _glowController.value;
                final blurRadius = kMinBlur + (pulse * (kMaxBlur - kMinBlur));

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // A. Tight Glow (Color halo)
                    // Using srcATop prevents it from washing out the background
                    Opacity(
                      opacity: 0.7,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: blurRadius,
                          sigmaY: blurRadius,
                        ),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            activeColor,
                            BlendMode.srcATop,
                          ),
                          child: RawImage(image: _edgeImage!, fit: BoxFit.fill),
                        ),
                      ),
                    ),

                    // B. Crisp Core Line (Sharp definition)
                    // No blur, solid white/bright color to define the edge
                    Opacity(
                      opacity: 1.0,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        child: RawImage(image: _edgeImage!, fit: BoxFit.fill),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 18,
                ),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingHud extends StatelessWidget {
  final Color color;
  final String hex;
  final double percentage;
  const _FloatingHud({
    required this.color,
    required this.hex,
    required this.percentage,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            border: Border(left: BorderSide(color: color, width: 6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SELECTED COLOR",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hex.toUpperCase(),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 2,
                    height: 24,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomRail extends StatelessWidget {
  final List<MobileColor> colors;
  final int? selectedIndex;
  final bool hasInteracted;
  final Function(int) onSelect;
  const _BottomRail({
    required this.colors,
    required this.selectedIndex,
    required this.hasInteracted,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colors.asMap().entries.map((entry) {
                int i = entry.key;
                // Only show hint on the first item (0) if not interacted
                bool showHint = !hasInteracted && i == 0;
                return _RippleSwatch(
                  color: Color.fromARGB(
                    255,
                    colors[i].red,
                    colors[i].green,
                    colors[i].blue,
                  ),
                  isSelected: i == selectedIndex,
                  isHinting: showHint,
                  onTap: () => onSelect(i),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final List<MobileColor> colors;
  final int? selectedIndex;
  final bool hasInteracted;
  final Function(int) onSelect;
  const _SideRail({
    required this.colors,
    required this.selectedIndex,
    required this.hasInteracted,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colors.asMap().entries.map((entry) {
                int i = entry.key;
                bool showHint = !hasInteracted && i == 0;
                return _RippleSwatch(
                  color: Color.fromARGB(
                    255,
                    colors[i].red,
                    colors[i].green,
                    colors[i].blue,
                  ),
                  isSelected: i == selectedIndex,
                  isHinting: showHint,
                  onTap: () => onSelect(i),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// UPDATED: Replaced _Swatch with _RippleSwatch
class _RippleSwatch extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final bool isHinting;
  final VoidCallback onTap;

  const _RippleSwatch({
    required this.color,
    required this.isSelected,
    required this.isHinting,
    required this.onTap,
  });

  @override
  State<_RippleSwatch> createState() => _RippleSwatchState();
}

class _RippleSwatchState extends State<_RippleSwatch>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: kRippleDuration, // Used constant
    );

    if (widget.isHinting) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _RippleSwatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHinting && !oldWidget.isHinting) {
      _rippleController.repeat();
    } else if (!widget.isHinting && oldWidget.isHinting) {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // RIPPLE LAYER
            if (widget.isHinting)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  final value = _rippleController.value;
                  // Scale starts at kRippleStartScale and expands
                  final scale = kRippleStartScale + (value * (kRippleEndScale - kRippleStartScale));
                  // Opacity fades out as it expands
                  final opacity = (1.0 - value).clamp(0.0, 1.0);
                  final borderWidth = 3.0 * (1.0 - value).clamp(0.5, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 1.0),
                            width: borderWidth,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // MAIN SWATCH
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuad,
              width: widget.isSelected ? 50 : 36,
              height: widget.isSelected ? 50 : 36,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                // Selection Border
                border: widget.isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Colors.transparent,
                          blurRadius: 0,
                          spreadRadius: 0,
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechPanelOverlay extends StatelessWidget {
  final bool isLandscape;
  final MobileColor colorData;
  final Color uiColor;
  final VoidCallback onClose;
  const _TechPanelOverlay({
    required this.isLandscape,
    required this.colorData,
    required this.uiColor,
    required this.onClose,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: isLandscape
              ? Alignment.centerRight
              : Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: isLandscape ? 400 : double.infinity,
              height: isLandscape ? double.infinity : 450,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: isLandscape
                    ? const BorderRadius.horizontal(left: Radius.circular(32))
                    : const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TECHNICAL SPECTRUM",
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            colorData.hex.toUpperCase(),
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _DataRow(
                    label: "HEX",
                    value: colorData.hex.toUpperCase(),
                    color: theme.colorScheme.onSurface,
                  ),
                  _DataRow(
                    label: "RGB",
                    value:
                        "${colorData.red}, ${colorData.green}, ${colorData.blue}",
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  _DataRow(
                    label: "CMYK",
                    value: colorData.cmyk,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  _DataRow(
                    label: "LAB",
                    value: colorData.lab,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),
                  Text("HARMONY", style: theme.textTheme.labelSmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: uiColor),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.arrow_forward,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        size: 16,
                      ),
                      const SizedBox(width: 16),
                      CircleAvatar(
                        backgroundColor: uiColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Text("Complementary", style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DataRow({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
