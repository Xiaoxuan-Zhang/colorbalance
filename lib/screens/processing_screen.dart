import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../src/rust/api.dart'; 
import '../constants.dart';    
import 'inspector_screen.dart'; 

class ProcessingScreen extends StatefulWidget {
  final Uint8List originalBytes;
  const ProcessingScreen({super.key, required this.originalBytes});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingStep {
  final String id;
  final String label;
  final String description;
  bool isCompleted = false;
  bool isActive = false;

  _ProcessingStep({
    required this.id,
    required this.label,
    required this.description,
  });
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  // Image Data
  Uint8List? _currentVisual;
  double? _imgWidth;
  double? _imgHeight;

  // UI State
  bool _isErrorState = false; 

  // Animation for the scanner ring
  late AnimationController _spinController;
  
  // Steps Definition
  final List<_ProcessingStep> _steps = [
    _ProcessingStep(
      id: "Smoothing", 
      label: "Softening Details",
      description: "Reducing visual noise...",
    ),
    _ProcessingStep(
      id: "Grouping", 
      label: "Analyzing Structure",
      description: "Mapping color regions...",
    ),
    _ProcessingStep(
      id: "Identifying", 
      label: "Extracting Harmonies",
      description: "Finding dominant tones...",
    ),
    _ProcessingStep(
      id: "Done", 
      label: "Curating Palette",
      description: "Finalizing selection...",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _startAnalysis();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _updateSteps(String statusMsg) {
    if (!mounted) return;
    setState(() {
      int activeIndex = -1;
      for (int i = 0; i < _steps.length; i++) {
        if (statusMsg.contains(_steps[i].id)) {
          activeIndex = i;
          break;
        }
      }

      if (activeIndex != -1) {
        for (int i = 0; i < _steps.length; i++) {
          if (i < activeIndex) {
            _steps[i].isCompleted = true;
            _steps[i].isActive = false;
          } else if (i == activeIndex) {
            _steps[i].isActive = true;
            _steps[i].isCompleted = false;
          } else {
            _steps[i].isActive = false;
            _steps[i].isCompleted = false;
          }
        }
      }
    });
  }

  Future<void> _simulateErrorSequence() async {
    // Step 1: Smoothing starts
    _updateSteps("Smoothing");
    await Future.delayed(const Duration(seconds: 2));
    
    // Step 2: Grouping starts
    _updateSteps("Grouping");
    await Future.delayed(const Duration(seconds: 2));

    // ERROR HAPPENS HERE
    if (mounted) {
      _handleError("Segmentation failure: Image contrast too low.");
    }
  }

  Future<void> _startAnalysis() async {
    // --- 1. SETUP ---
    final buffer = await ui.instantiateImageCodec(widget.originalBytes);
    final frame = await buffer.getNextFrame();
    
    if (!mounted) return;
    setState(() {
      _imgWidth = frame.image.width.toDouble();
      _imgHeight = frame.image.height.toDouble();
    });

    // --- 2. ERROR SIMULATION SWITCH ---
    // Set this to TRUE to trigger the fake error sequence
    bool simulateError = false; 

    if (simulateError) {
      await _simulateErrorSequence();
      return;
    }
    // --------------------------------

    // --- 3. REAL ANALYSIS ---
    final stream = analyzeImageStream(
      imageBytes: widget.originalBytes, 
      k: kColorClusters, 
      maxDim: kAnalysisMaxDim, 
      blurSigma: null
    );

    stream.listen(
      (event) {
        event.when(
          status: (msg) => _updateSteps(msg), 
          debugImage: (bytes) {
            if (mounted) setState(() => _currentVisual = bytes);
          }, 
          result: (mobileResult) {
            if (mounted) {
              setState(() {
                for (var s in _steps) {
                  s.isCompleted = true;
                  s.isActive = false;
                }
              });
            }

            if (mounted && _imgWidth != null) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => InspectorScreen(
                        originalBytes: widget.originalBytes,
                        result: mobileResult,
                        imageWidth: _imgWidth!,
                        imageHeight: _imgHeight!,
                      ),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                      transitionDuration: const Duration(milliseconds: 800),
                    ),
                  );
                }
              });
            }
          }
        );
      },
      onError: (err) => _handleError(err.toString()),
    );
  }

  void _handleError(String errorMsg) {
    if (!mounted) return;
    setState(() {
      _isErrorState = true;
      _spinController.stop(); // Stop the spinner on error
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    final activeColor = _isErrorState ? Colors.red : colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
          child: isLandscape 
              ? _buildLandscapeLayout(theme, activeColor) 
              : _buildPortraitLayout(theme, activeColor),
      ),
    );
  }

  // --- RESPONSIVE LAYOUTS ---

  Widget _buildPortraitLayout(ThemeData theme, Color activeColor) {
    return Column(
              children: [
        // FIXED ZONE: Visualizer
        // Using Expanded ensures this takes up the top half and doesn't move
        // when the list below changes size.
        Expanded(
          flex: 5, 
          child: Center(
            child: _buildVisualizer(activeColor),
          ),
        ),
        
        // FLEXIBLE ZONE: Steps List
        // Aligned to topCenter so it grows downwards, keeping the gap stable.
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.topCenter,
            child: _buildStepList(theme),
          ),
      ),
      ],
    );
  }

  Widget _buildLandscapeLayout(ThemeData theme, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Pane: Visualizer (Centered)
        Expanded(
          child: Center(child: _buildVisualizer(activeColor)),
        ),
        // Right Pane: List or Error (Centered)
        Expanded(
          child: Center(child: _buildStepList(theme)),
        ),
      ],
    );
  }

  // --- COMPONENTS ---

  Widget _buildVisualizer(Color activeColor) {
    return SizedBox(
                  width: 280, height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The Image being processed
                      ClipOval(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: ColorFiltered(
                            colorFilter: _isErrorState 
                                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) 
                                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: Image.memory(
                            _currentVisual ?? widget.originalBytes,
                            key: ValueKey(_currentVisual.hashCode),
                            fit: BoxFit.cover,
                            width: 240, height: 240,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                      ),
                      // Ring (Stops spinning and turns red on error)
                      RotationTransition(
                        turns: _spinController,
                        child: Container(
                          width: 280, height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                activeColor.withValues(alpha: 0.1),
                                activeColor.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Error Icon Overlay
                      if (_isErrorState)
                        Container(
                          width: 240, height: 240,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        )
                      else
                      Container(
                        width: 240, height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
    );
  }

  Widget _buildStepList(ThemeData theme) {
    return Container(
                  constraints: const BoxConstraints(maxWidth: 300), 
                  child: _isErrorState 
        ? _buildErrorText(theme)
        : IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _steps.map((step) => _buildStepItem(step, theme)).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorText(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "PROCESSING FAILED",
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.red, 
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 16
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "We encountered an issue analyzing this image.\nPlease try a different photo.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Text("Return to Studio"),
        )
      ],
    );
  }

  Widget _buildStepItem(_ProcessingStep step, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDone = step.isCompleted;
    final isActive = step.isActive;
    
    final Color activeColor = colorScheme.primary;
    final Color inactiveColor = colorScheme.onSurface.withValues(alpha: 0.2);
    
    Color iconColor = inactiveColor;
    Color textColor = inactiveColor;
    
    if (isDone) {
      iconColor = activeColor;
      textColor = colorScheme.onSurface.withValues(alpha: 0.5);
    } else if (isActive) {
      iconColor = activeColor;
      textColor = colorScheme.onSurface;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Icon
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 1.5),
              color: isDone ? activeColor : Colors.transparent,
            ),
            child: isDone 
              ? Icon(Icons.check, size: 16, color: colorScheme.surface)
              : (isActive 
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2, color: activeColor),
                    ) 
                  : null),
          ),
          const SizedBox(width: 20),
          
          // Description Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16, 
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          step.description,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: activeColor.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}