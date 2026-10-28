import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'src/rust/frb_generated.dart';
import 'screens/home_screen.dart';

// --- Theme Controller ---
final themeController = ValueNotifier<ThemeMode>(ThemeMode.light);

void toggleTheme() {
  themeController.value = themeController.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
}

// --- 1. DEFINE DISTINCT SCHEMES ---

// LIGHT SCHEME: "Editorial Day"
// High contrast: Deep Charcoal secondary elements on light backgrounds.
final FlexSchemeColor lightScheme = FlexSchemeColor.from(
  primary: const Color(0xFFD4AF37), // Muted Gold
  secondary: const Color(
    0xFF1A1A1A,
  ), // Deep Charcoal (High contrast for UI elements)
  tertiary: const Color(
    0xFF6A1B9A,
  ), // Rich Purple (Slightly lighter than dark mode for visibility)
);

// DARK SCHEME: "Digital Atelier Night"
// Soft contrast: Pale Grey secondary elements on dark backgrounds.
final FlexSchemeColor darkScheme = FlexSchemeColor.from(
  primary: const Color(0xFFD4AF37), // Muted Gold
  secondary: const Color(
    0xFFE0E0E0,
  ), // Soft White/Grey (Better readability on dark)
  tertiary: const Color(0xFF4A148C), // Deep Purple (Original blob color)
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Set system UI to transparent so our theme shines through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Color Balance',
          themeMode: currentMode,

          // --- LIGHT THEME CONFIGURATION ---
          theme: FlexThemeData.light(
            colors: lightScheme, // Use the LIGHT definition
            useMaterial3: true,
            // Light Theme Specifics:
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 10, // Subtle blending of primary color into background
            scaffoldBackground: const Color(0xFFF9F9F9), // Soft Cream/White
            // Typography (Shared)
            fontFamily: 'sans-serif',
            textTheme: _buildTextTheme(Colors.black87), // Dark text
          ),

          // --- DARK THEME CONFIGURATION ---
          darkTheme: FlexThemeData.dark(
            colors: darkScheme, // Use the DARK definition
            useMaterial3: true,
            // Dark Theme Specifics:
            surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
            blendLevel: 15, // Higher blend for deeper immersion
            scaffoldBackground: const Color(0xFF1A1A1A), // Your Deep Charcoal
            // Typography (Shared)
            fontFamily: 'sans-serif',
            textTheme: _buildTextTheme(const Color(0xFFEEEEEE)), // Light text
          ),

          home: const HomeScreen(),
        );
      },
    );
  }

  // Helper to keep font sizes consistent while changing text color
  TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'serif',
        fontSize: 48,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        color: color,
      ),
      displayMedium: TextStyle(
        fontFamily: 'serif',
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      labelLarge: TextStyle(
        fontFamily: 'monospace',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: color,
      ),
      bodyMedium: TextStyle(fontSize: 14, letterSpacing: 0.2, color: color),
    );
  }
}
