import 'dart:typed_data';
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

class _ProcessingScreenState extends State<ProcessingScreen> {
  String _statusMessage = "Initializing...";
  Uint8List? _currentVisual;
  double? _imgWidth;
  double? _imgHeight;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() async {
    final decoded = await decodeImageFromList(widget.originalBytes);
    if (!mounted) return;
    setState(() {
      _imgWidth = decoded.width.toDouble();
      _imgHeight = decoded.height.toDouble();
    });

    final stream = analyzeImageStream(
      imageBytes: widget.originalBytes, 
      k: kColorClusters, 
      maxDim: kAnalysisMaxDim, 
      blurSigma: null
    );

    stream.listen(
      (event) {
        event.when(
          status: (msg) => setState(() => _statusMessage = msg), 
          debugImage: (bytes) => setState(() => _currentVisual = bytes), 
          result: (mobileResult) {
            if (mounted && _imgWidth != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => InspectorScreen(
                    originalBytes: widget.originalBytes,
                    result: mobileResult,
                    imageWidth: _imgWidth!,
                    imageHeight: _imgHeight!,
                  ),
                ),
              );
            }
          }
        );
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $err")));
          Navigator.pop(context);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _imgWidth != null 
              ? AspectRatio(
                  aspectRatio: _imgWidth! / _imgHeight!,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Image.memory(
                      _currentVisual ?? widget.originalBytes,
                      key: ValueKey(_currentVisual.hashCode),
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  ),
                )
              : const SizedBox(),
          ),
          Positioned(
            bottom: 50, left: 20, right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                // FIX: Replaced withOpacity with withValues
                color: Colors.black.withValues(alpha: 0.7),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusMessage.toUpperCase(),
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 15),
                    const LinearProgressIndicator(backgroundColor: Colors.white10, color: Colors.cyanAccent),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}