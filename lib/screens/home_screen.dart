import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// For toggleTheme()
import 'processing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the image. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // No more hardcoded colors - use the theme!
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildStaticBackground(colorScheme),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
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
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          "COLOR BALANCE",
          // CHANGED: Use standardized Serif header
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 4, // Keep the wide spacing for style
          ),
          textAlign: align,
        ),
        const SizedBox(height: 40),
        Text(
          "A digital studio for the modern creative.",
          textAlign: align,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Extract color harmony from images.",
          textAlign: align,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          context,
          label: isDesktop ? "Open Image" : "Analyze Source",
          icon: isDesktop
              ? Icons.folder_open_outlined
              : Icons.camera_alt_outlined,
          isPrimary: true,
          onTap: () => _pickImage(
            context,
            isDesktop ? ImageSource.gallery : ImageSource.camera,
          ),
        ),
        if (!isDesktop) ...[
          const SizedBox(height: 16),
          _buildButton(
            context,
            label: "Load from Gallery",
            icon: Icons.photo_library_outlined,
            isPrimary: false,
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
        ],
      ],
    );
  }

  Widget _buildStaticBackground(ColorScheme colors) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -100,
          left: -50,
          // CHANGED: Uses Theme Tertiary (Purple)
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.tertiary.withOpacity(0.2),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -50,
          // CHANGED: Uses Theme Primary (Gold)
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withOpacity(0.15),
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

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 300,
      height: 60,
      child: isPrimary
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: colors.onSurface,
                foregroundColor: colors.surface,
              ),
              child: _buildButtonContent(label, icon),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface.withOpacity(0.6),
                side: BorderSide(color: colors.onSurface.withOpacity(0.2)),
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
        Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
