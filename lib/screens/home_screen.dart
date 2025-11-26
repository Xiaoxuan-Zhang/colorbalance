import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added
import 'processing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- LOGIC: PICK IMAGE ---
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      
      if (image == null) return; // User canceled

      // Read the bytes directly
      final bytes = await image.readAsBytes();

      if (!context.mounted) return;

      // Navigate to Processing Screen with the ACTUAL bytes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(originalBytes: bytes),
        ),
      );
    } catch (e) {
      debugPrint("Error picking image: $e");
      // Optional: Show snackbar error
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. STATIC BACKGROUND ---
          _buildStaticBackground(),

          // --- 2. MAIN CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: isLandscape 
                  ? _buildLandscapeLayout(context) 
                  : _buildPortraitLayout(context),
            ),
          ),
        ],
      ),
    );
  }

  // --- LAYOUTS ---

  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        _buildHeader(context, TextAlign.center),
        const Spacer(),
        _buildButtons(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildHeader(context, TextAlign.left),
        ),
        const SizedBox(width: 60),
        _buildButtons(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, TextAlign align) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.left ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          "COLOR BALANCE",
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Curate your\nvision.",
          textAlign: align,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        Text(
          "Algorithmic color extraction for\ninterior spaces and fine art.",
          textAlign: align,
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          label: "Analyze Source",
          icon: Icons.camera_alt_outlined,
          isPrimary: true,
          // Pass ImageSource.camera
          onTap: () => _pickImage(context, ImageSource.camera),
        ),
        const SizedBox(height: 16),
        _buildButton(
          label: "Load from Gallery",
          icon: Icons.photo_library_outlined,
          isPrimary: false,
          // Pass ImageSource.gallery
          onTap: () => _pickImage(context, ImageSource.gallery),
        ),
        const SizedBox(height: 32),
        Text(
          "v2.4.0 Live Input",
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildStaticBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -100, left: -50,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A148C).withOpacity(0.2),
            ),
          ),
        ),
        Positioned(
          bottom: -100, right: -50,
          child: Container(
            width: 350, height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withOpacity(0.15),
            ),
          ),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 280,
      height: 56,
      child: isPrimary
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: Colors.black,
              ),
              child: _buildButtonContent(label, icon),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFAAAAAA),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              child: _buildButtonContent(label, icon),
            ),
    );
  }

  Widget _buildButtonContent(String label, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}