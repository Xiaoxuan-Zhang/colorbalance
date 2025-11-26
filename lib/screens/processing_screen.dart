import 'dart:async';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'inspector_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final Uint8List originalBytes; // Store actual image data

  const ProcessingScreen({super.key, required this.originalBytes});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  double _progress = 0.0;
  String _status = "Initializing...";
  String _subStatus = "Core :: Connect";
  Color _orbColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _simulateProcessing();
  }

  void _simulateProcessing() {
    final steps = [
      (0.2, "Smoothing Image...", "Gaussian :: Sigma 2.0", Colors.blue),
      (0.4, "Converting Space...", "RGB -> CIELAB", Colors.purple),
      (0.6, "Grouping Pixels...", "SLIC :: Superpixels", Colors.pink),
      (0.8, "Clustering...", "K-Means :: Centroids", Colors.amber),
      (1.0, "Finalizing...", "Pipeline :: Merge", Colors.teal),
    ];

    int currentStep = 0;
    Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (currentStep < steps.length) {
        setState(() {
          _progress = steps[currentStep].$1;
          _status = steps[currentStep].$2;
          _subStatus = steps[currentStep].$3;
          _orbColor = steps[currentStep].$4;
        });
        currentStep++;
      } else {
        timer.cancel();
        // PASS THE DATA TO INSPECTOR
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => InspectorScreen(originalBytes: widget.originalBytes),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Orb
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orbColor.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: _orbColor.withOpacity(0.4),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _orbColor.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(
                    width: 200, height: 200,
                    child: CircularProgressIndicator(
                      value: null,
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Status
          Positioned(
            bottom: 100, left: 32, right: 32,
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _status,
                    key: ValueKey(_status),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      fontFamily: 'serif',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subStatus.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 2,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white10,
                    color: const Color(0xFFD4AF37),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}