import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'processing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- LOGIC: PICK IMAGE ---
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(originalBytes: bytes),
        ),
      );
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // LINKING TO THEME: Access the global colors defined in main.dart
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // LINKED: Uses the Dark Gray (#1A1A1A) from main.dart
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildStaticBackground(colorScheme),
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
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildHeader(context, TextAlign.left)),
        const SizedBox(width: 60),
        _buildButtons(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, TextAlign align) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.left ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          "COLOR BALANCE",
          style: textTheme.displayLarge?.copyWith(
            color: colorScheme.onSurface, // LINKED
            height: 0.9,
            fontSize: 28,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
          textAlign: align,
        ),
        const SizedBox(height: 40), // Increased space between header and description
        Text(
          "A digital studio for the modern creative.",
          textAlign: align,
          style: textTheme.bodyMedium?.copyWith(
             color: colorScheme.onSurface.withValues(alpha: 0.6), // LINKED
          ),
        ),
        const SizedBox(height: 4), // Increased space between description
        Text(
          "Extract color harmony from images.",
          textAlign: align,
          style: textTheme.bodyMedium?.copyWith(
             color: colorScheme.onSurface.withValues(alpha: 0.6), // LINKED
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          context,
          label: "Analyze Source",
          icon: Icons.camera_alt_outlined,
          isPrimary: true,
          onTap: () => _pickImage(context, ImageSource.camera),
        ),
        const SizedBox(height: 16),
        _buildButton(
          context,
          label: "Load from Gallery",
          icon: Icons.photo_library_outlined,
          isPrimary: false,
          onTap: () => _pickImage(context, ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildStaticBackground(ColorScheme colors) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -100, left: -50,
          // LINKED: Uses primary color for the blob tint
          child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4A148C).withValues(alpha: 0.2))),
        ),
        Positioned(
          bottom: -100, right: -50,
          // LINKED: Uses primary color for the blob tint
          child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary.withValues(alpha: 0.15))),
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

  Widget _buildButton(BuildContext context, {
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 300, // Wider buttons for better tap target
      height: 60, // Taller buttons
      child: isPrimary
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                // LINKED: Uses Theme Colors
                backgroundColor: colors.onSurface, 
                foregroundColor: colors.surface,
              ),
              child: _buildButtonContent(label, icon),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                // LINKED: Uses Theme Colors
                foregroundColor: colors.onSurface.withValues(alpha: 0.6),
                side: BorderSide(color: colors.onSurface.withValues(alpha: 0.2)),
              ),
              child: _buildButtonContent(label, icon),
            ),
    );
  }

  Widget _buildButtonContent(String label, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ],
    );
  }
}